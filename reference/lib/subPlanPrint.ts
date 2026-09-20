import { Match, MatchSubPlan, User } from '../types';
import { formatMinutes } from './playingMinutes';
import {
  DEFAULT_MATCH_MINUTES,
  lineupsByQuarter,
  minutesPerQuarter,
  projectMatchMinutes,
  Quarter,
} from './subPlan';

function esc(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function displayName(player: User | undefined, id: string): string {
  if (!player) return 'Unknown';
  return player.squadNumber != null ? `#${player.squadNumber} ${player.name}` : player.name;
}

function formatMatchDate(dateIso: string): string {
  try {
    return new Date(dateIso).toLocaleDateString(undefined, {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return dateIso;
  }
}

/** Build a sideline-friendly HTML sheet and open the browser print dialog (Save as PDF). */
export function printSubPlan(opts: {
  match: Match;
  plan: MatchSubPlan;
  startingLineup: Record<string, string>;
  confirmedSquad: User[];
  seasonMinutes: Record<string, number>;
  clubName?: string;
}): void {
  const { match, plan, startingLineup, confirmedSquad, seasonMinutes, clubName } = opts;
  const playerById = new Map(confirmedSquad.map(p => [p.id, p]));
  const squadIds = confirmedSquad.map(p => p.id);
  const perQ = Math.round(minutesPerQuarter(plan));
  const byQ = lineupsByQuarter(startingLineup, plan.swaps || []);
  const projected = projectMatchMinutes(startingLineup, plan, squadIds);
  const matchMins = plan.matchMinutes || DEFAULT_MATCH_MINUTES;

  const starters = Object.values(startingLineup)
    .filter(Boolean)
    .map(id => {
      const p = playerById.get(id);
      const pos = p?.preferredPosition ? ` (${p.preferredPosition})` : '';
      return `${displayName(p, id)}${pos}`;
    });

  const bench = confirmedSquad
    .filter(p => !Object.values(startingLineup).includes(p.id))
    .map(p => {
      const pos = p.preferredPosition ? ` (${p.preferredPosition})` : '';
      return `${displayName(p, p.id)}${pos}`;
    });

  const quarterBlocks = ([1, 2, 3, 4] as Quarter[])
    .map(q => {
      const onPitch = Object.values(byQ[q])
        .map(id => esc(displayName(playerById.get(id), id)))
        .join(', ');
      const after = q < 4 ? (q as 1 | 2 | 3) : null;
      const swaps = after
        ? (plan.swaps || []).filter(s => s.afterQuarter === after)
        : [];
      const swapHtml =
        after == null
          ? ''
          : swaps.length === 0
            ? `<p class="muted">No swaps after Q${after}</p>`
            : `<ul class="swaps">${swaps
                .map(
                  s =>
                    `<li><span class="off">OFF ${esc(displayName(playerById.get(s.playerOut), s.playerOut))}</span>
                     → <span class="on">ON ${esc(displayName(playerById.get(s.playerIn), s.playerIn))}</span></li>`
                )
                .join('')}</ul>`;

      return `
        <section class="quarter">
          <h3>Quarter ${q} · ${perQ}′</h3>
          <p class="onpitch">${onPitch || '—'}</p>
          ${after != null ? `<div class="break"><h4>Break after Q${after}</h4>${swapHtml}</div>` : ''}
        </section>`;
    })
    .join('');

  const minuteRows = [...squadIds]
    .sort((a, b) => (projected[a] || 0) - (projected[b] || 0) || (seasonMinutes[a] || 0) - (seasonMinutes[b] || 0))
    .map(id => {
      const p = playerById.get(id);
      const matchPlan = projected[id] || 0;
      const season = seasonMinutes[id] || 0;
      const pos = p?.preferredPosition || '';
      return `<tr>
        <td>${esc(displayName(p, id))}</td>
        <td>${esc(pos)}</td>
        <td class="num">${formatMinutes(matchPlan)}</td>
        <td class="num">${formatMinutes(season)}</td>
        <td class="num">${formatMinutes(season + matchPlan)}</td>
      </tr>`;
    })
    .join('');

  const title = match.title || 'Match';
  const when = [formatMatchDate(match.date), match.kickOffTime].filter(Boolean).join(' · ');
  const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Sub plan · ${esc(title)}</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
           color: #0f172a; margin: 24px; font-size: 12px; line-height: 1.4; }
    h1 { font-size: 20px; margin: 0 0 4px; }
    h2 { font-size: 13px; text-transform: uppercase; letter-spacing: 0.08em; color: #64748b; margin: 20px 0 8px; }
    h3 { font-size: 13px; margin: 0 0 6px; }
    h4 { font-size: 11px; text-transform: uppercase; letter-spacing: 0.06em; color: #ea580c; margin: 8px 0 4px; }
    .meta { color: #64748b; margin-bottom: 16px; }
    .quarter { border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 12px; margin-bottom: 10px; page-break-inside: avoid; }
    .onpitch { margin: 0; }
    .break { margin-top: 6px; padding-top: 6px; border-top: 1px dashed #fed7aa; }
    .swaps { margin: 0; padding-left: 16px; }
    .off { color: #dc2626; font-weight: 600; }
    .on { color: #16a34a; font-weight: 600; }
    .muted { color: #94a3b8; margin: 0; font-style: italic; }
    table { width: 100%; border-collapse: collapse; margin-top: 4px; }
    th, td { text-align: left; padding: 6px 8px; border-bottom: 1px solid #e2e8f0; }
    th { font-size: 10px; text-transform: uppercase; letter-spacing: 0.06em; color: #64748b; }
    td.num, th.num { text-align: right; font-variant-numeric: tabular-nums; }
    .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    ul.plain { margin: 0; padding-left: 16px; }
    .footer { margin-top: 20px; color: #94a3b8; font-size: 10px; }
    @media print {
      body { margin: 12mm; }
      .no-print { display: none !important; }
    }
  </style>
</head>
<body>
  <button class="no-print" onclick="window.print()" style="margin-bottom:16px;padding:8px 14px;font-weight:700;cursor:pointer;">
    Print / Save as PDF
  </button>
  <h1>${esc(title)}</h1>
  <p class="meta">
    ${clubName ? esc(clubName) + ' · ' : ''}Sub plan
    ${when ? ' · ' + esc(when) : ''}
    ${match.location ? ' · ' + esc(match.location) : ''}
    · ${matchMins}′ · 4 × ${perQ}′
  </p>

  <div class="cols">
    <div>
      <h2>Starting XI</h2>
      <ul class="plain">${starters.map(s => `<li>${esc(s)}</li>`).join('') || '<li>—</li>'}</ul>
    </div>
    <div>
      <h2>Bench</h2>
      <ul class="plain">${bench.map(s => `<li>${esc(s)}</li>`).join('') || '<li>None</li>'}</ul>
    </div>
  </div>

  <h2>Quarter plan</h2>
  ${quarterBlocks}

  <h2>Game time</h2>
  <table>
    <thead>
      <tr>
        <th>Player</th>
        <th>Pos</th>
        <th class="num">This match</th>
        <th class="num">Season</th>
        <th class="num">After</th>
      </tr>
    </thead>
    <tbody>${minuteRows}</tbody>
  </table>

  <p class="footer">TeamPulse sub plan · guide only — adjust live for injuries and game situation.</p>
  <script>window.onload = function () { window.print(); };</script>
</body>
</html>`;

  const win = window.open('', '_blank', 'noopener,noreferrer,width=800,height=900');
  if (!win) {
    // Popup blocked — fall back to downloading an HTML file
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `sub-plan-${(match.title || 'match').replace(/[^\w\-]+/g, '-').toLowerCase()}.html`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
    return;
  }
  win.document.open();
  win.document.write(html);
  win.document.close();
}
