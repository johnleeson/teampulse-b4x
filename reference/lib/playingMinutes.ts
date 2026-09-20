import { FeedEvent, Match } from '../types';

type PlayWindow = { startMs: number; endMs: number };

type SubEvent = {
  atMs: number;
  playerOut: string;
  playerIn: string;
};

function eventTimeMs(e: FeedEvent): number {
  return new Date(e.timestamp).getTime();
}

function parseKickOffMs(match: Match): number | null {
  if (!match.date || !match.kickOffTime) return null;
  const base = new Date(match.date);
  const parts = match.kickOffTime.match(/^(\d{1,2}):(\d{2})/);
  if (!parts) return null;
  base.setHours(Number(parts[1]), Number(parts[2]), 0, 0);
  return base.getTime();
}

function addMinutes(ms: number, minutes: number): number {
  return ms + minutes * 60_000;
}

function findPeriodMs(events: FeedEvent[], type: FeedEvent['type']): number | null {
  const ev = events.find(e => e.type === type);
  return ev ? eventTimeMs(ev) : null;
}

/** Playing windows: 1st half [START, HT) and 2nd half [2nd, END). */
export function getMatchPlayWindows(match: Match, events: FeedEvent[]): PlayWindow[] {
  const matchEvents = events.filter(e => e.matchId === match.id);
  const startMs = findPeriodMs(matchEvents, 'START') ?? parseKickOffMs(match);
  const halfTimeMs = findPeriodMs(matchEvents, 'HALF_TIME');
  const secondHalfMs = findPeriodMs(matchEvents, 'SECOND_HALF');
  let endMs = findPeriodMs(matchEvents, 'END');

  if (!endMs) {
    if (secondHalfMs != null) endMs = addMinutes(secondHalfMs, 45);
    else if (startMs != null) endMs = addMinutes(startMs, 90);
  }

  const windows: PlayWindow[] = [];
  if (startMs != null && halfTimeMs != null && halfTimeMs > startMs) {
    windows.push({ startMs, endMs: halfTimeMs });
  }
  if (secondHalfMs != null && endMs != null && endMs > secondHalfMs) {
    windows.push({ startMs: secondHalfMs, endMs });
  }

  // Degraded: only start + end (counts half-time as playing — better than nothing)
  if (windows.length === 0 && startMs != null && endMs != null && endMs > startMs) {
    windows.push({ startMs, endMs });
  }

  return windows;
}

function teamASubs(events: FeedEvent[], matchId: string): SubEvent[] {
  return events
    .filter(
      e =>
        e.matchId === matchId &&
        e.type === 'SUB' &&
        e.details?.team !== 'B' &&
        e.details?.playerOut &&
        e.details?.playerIn
    )
    .map(e => ({
      atMs: eventTimeMs(e),
      playerOut: e.details!.playerOut!,
      playerIn: e.details!.playerIn!,
    }))
    .sort((a, b) => a.atMs - b.atMs);
}

/** Reverse SUBs on a slot map to recover kick-off lineup. */
function reverseSubsOntoLineup(
  finalLineup: Record<string, string> | undefined,
  subs: SubEvent[]
): Record<string, string> {
  const slots: Record<string, string> = { ...(finalLineup || {}) };
  for (const sub of [...subs].reverse()) {
    const slot = Object.entries(slots).find(([, pid]) => pid === sub.playerIn)?.[0];
    if (slot) {
      slots[slot] = sub.playerOut;
    }
  }
  return slots;
}

/** Final lineup is post-subs; reverse SUBs to recover kick-off XI. */
export function reconstructStartingLineup(
  finalLineup: Record<string, string> | undefined,
  subs: SubEvent[]
): Set<string> {
  return new Set(Object.values(reverseSubsOntoLineup(finalLineup, subs)).filter(Boolean));
}

/** Kick-off slot → player map (reverses Team A SUBs from feed events). */
export function reconstructStartingLineupMap(
  finalLineup: Record<string, string> | undefined,
  events: FeedEvent[],
  matchId: string
): Record<string, string> {
  return reverseSubsOntoLineup(finalLineup, teamASubs(events, matchId));
}

function overlapMs(aStart: number, aEnd: number, bStart: number, bEnd: number): number {
  const start = Math.max(aStart, bStart);
  const end = Math.min(aEnd, bEnd);
  return Math.max(0, end - start);
}

/**
 * Minutes each club player was on the pitch for a match.
 * Uses period timestamps, reverse-engineered start XI, team-A SUBs, and red cards (ends minutes).
 */
export function calculateMatchMinutes(
  match: Match,
  events: FeedEvent[]
): Record<string, number> {
  const matchEvents = events.filter(e => e.matchId === match.id);
  const windows = getMatchPlayWindows(match, matchEvents);
  if (windows.length === 0) return {};

  const matchStartMs = windows[0].startMs;
  const matchEndMs = windows[windows.length - 1].endMs;
  const subs = teamASubs(matchEvents, match.id);
  const starters = reconstructStartingLineup(match.lineup, subs);

  // playerId -> list of [onMs, offMs]
  const stints = new Map<string, { onMs: number; offMs: number | null }[]>();

  const ensure = (id: string) => {
    if (!stints.has(id)) stints.set(id, []);
    return stints.get(id)!;
  };

  const openStint = (id: string, onMs: number) => {
    const list = ensure(id);
    const open = list.find(s => s.offMs == null);
    if (open) return;
    list.push({ onMs, offMs: null });
  };

  const closeStint = (id: string, offMs: number) => {
    const list = stints.get(id);
    if (!list) return;
    const open = [...list].reverse().find(s => s.offMs == null);
    if (open) open.offMs = Math.max(open.onMs, offMs);
  };

  starters.forEach(id => openStint(id, matchStartMs));

  const timeline = [
    ...subs.map(s => ({ atMs: s.atMs, kind: 'SUB' as const, ...s })),
    ...matchEvents
      .filter(e => e.type === 'RED_CARD' && e.details?.team !== 'B' && e.details?.scorer)
      .map(e => ({
        atMs: eventTimeMs(e),
        kind: 'RED' as const,
        playerOut: e.details!.scorer!,
        playerIn: '',
      })),
  ].sort((a, b) => a.atMs - b.atMs);

  for (const item of timeline) {
    if (item.atMs < matchStartMs || item.atMs > matchEndMs) continue;
    if (item.kind === 'SUB') {
      closeStint(item.playerOut, item.atMs);
      openStint(item.playerIn, item.atMs);
    } else {
      closeStint(item.playerOut, item.atMs);
    }
  }

  // Anyone still on at full time
  for (const [, list] of stints) {
    for (const stint of list) {
      if (stint.offMs == null) stint.offMs = matchEndMs;
    }
  }

  const minutes: Record<string, number> = {};
  for (const [playerId, list] of stints) {
    let totalMs = 0;
    for (const stint of list) {
      const off = stint.offMs ?? matchEndMs;
      for (const w of windows) {
        totalMs += overlapMs(stint.onMs, off, w.startMs, w.endMs);
      }
    }
    const mins = Math.round(totalMs / 60_000);
    if (mins > 0) minutes[playerId] = mins;
  }

  return minutes;
}

/** Season totals keyed by player id. */
export function calculateSeasonMinutes(
  matches: Match[],
  events: FeedEvent[]
): Record<string, number> {
  const totals: Record<string, number> = {};
  matches.forEach(match => {
    const perMatch = calculateMatchMinutes(match, events);
    Object.entries(perMatch).forEach(([playerId, mins]) => {
      totals[playerId] = (totals[playerId] || 0) + mins;
    });
  });
  return totals;
}

export function formatMinutes(mins: number): string {
  if (mins <= 0) return '0′';
  return `${mins}′`;
}
