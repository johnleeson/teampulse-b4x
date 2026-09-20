import React, { useMemo, useState } from 'react';
import { Club, FeedEvent, Match, User } from '../types';
import { normalizePotmVotes, tallyFanVotes, getTiedPotmWinners } from '../services/dbService';
import { calculateMatchMinutes } from '../lib/playingMinutes';
import {
  Trophy,
  Goal,
  Target,
  Shield,
  Award,
  TrendingUp,
  Users,
  BarChart2,
  Clock,
} from 'lucide-react';

interface StatisticsProps {
  clubs: Club[];
  matches: Match[];
  feedEvents: FeedEvent[];
  currentUser: User;
}

interface PlayerRow {
  id: string;
  name: string;
  avatar?: string;
  goals: number;
  assists: number;
  yellowCards: number;
  redCards: number;
  coachPotm: number;
  fansPotm: number;
  oppositionPotm: number;
  appearances: number;
  minutes: number;
}

const competitionLabel = (c?: string) =>
  c === 'LEAGUE' ? 'League' : c === 'CUP' ? 'Cup' : 'Friendly';

const Statistics: React.FC<StatisticsProps> = ({ clubs, matches, feedEvents, currentUser }) => {
  const [clubFilter, setClubFilter] = useState<string>('all');

  const memberMap = useMemo(() => {
    const map = new Map<string, { name: string; avatar?: string }>();
    clubs.forEach(club => {
      club.members.forEach(m => {
        if (!map.has(m.id)) map.set(m.id, { name: m.name, avatar: m.avatar });
      });
    });
    return map;
  }, [clubs]);

  const filteredMatches = useMemo(() => {
    return matches.filter(m => clubFilter === 'all' || m.clubId === clubFilter);
  }, [matches, clubFilter]);

  const completed = useMemo(
    () => filteredMatches.filter(m => m.status === 'COMPLETED'),
    [filteredMatches]
  );

  const matchIds = useMemo(() => new Set(filteredMatches.map(m => m.id)), [filteredMatches]);

  const relevantEvents = useMemo(
    () => feedEvents.filter(e => matchIds.has(e.matchId)),
    [feedEvents, matchIds]
  );

  const record = useMemo(() => {
    let won = 0;
    let drawn = 0;
    let lost = 0;
    let gf = 0;
    let ga = 0;

    completed.forEach(m => {
      const a = m.scoreA || 0;
      const b = m.scoreB || 0;
      gf += a;
      ga += b;
      if (a > b) won += 1;
      else if (a < b) lost += 1;
      else drawn += 1;
    });

    return {
      played: completed.length,
      won,
      drawn,
      lost,
      gf,
      ga,
      gd: gf - ga,
      winPct: completed.length ? Math.round((won / completed.length) * 100) : 0,
    };
  }, [completed]);

  const form = useMemo(() => {
    return [...completed]
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 8)
      .map(m => {
        const a = m.scoreA || 0;
        const b = m.scoreB || 0;
        const result: 'W' | 'D' | 'L' = a > b ? 'W' : a < b ? 'L' : 'D';
        return { match: m, result, score: `${a}–${b}` };
      });
  }, [completed]);

  const byCompetition = useMemo(() => {
    const buckets: Record<string, { played: number; won: number; drawn: number; lost: number; gf: number; ga: number }> = {};
    completed.forEach(m => {
      const key = m.competition || 'FRIENDLY';
      if (!buckets[key]) buckets[key] = { played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0 };
      const a = m.scoreA || 0;
      const b = m.scoreB || 0;
      buckets[key].played += 1;
      buckets[key].gf += a;
      buckets[key].ga += b;
      if (a > b) buckets[key].won += 1;
      else if (a < b) buckets[key].lost += 1;
      else buckets[key].drawn += 1;
    });
    return Object.entries(buckets).sort((a, b) => b[1].played - a[1].played);
  }, [completed]);

  const playerStats = useMemo(() => {
    const rows = new Map<string, PlayerRow>();

    const ensure = (id: string, fallbackName?: string): PlayerRow => {
      let row = rows.get(id);
      if (!row) {
        const member = memberMap.get(id);
        row = {
          id,
          name: member?.name || fallbackName || 'Unknown',
          avatar: member?.avatar,
          goals: 0,
          assists: 0,
          yellowCards: 0,
          redCards: 0,
          coachPotm: 0,
          fansPotm: 0,
          oppositionPotm: 0,
          appearances: 0,
          minutes: 0,
        };
        rows.set(id, row);
      }
      return row;
    };

    completed.forEach(m => {
      const matchEvents = relevantEvents.filter(e => e.matchId === m.id);
      const matchMinutes = calculateMatchMinutes(m, matchEvents);
      const appeared = new Set<string>();

      Object.entries(matchMinutes).forEach(([pid, mins]) => {
        if (mins > 0) {
          appeared.add(pid);
          ensure(pid).minutes += mins;
        }
      });

      // Fallback appearance if period times aren't logged yet
      if (appeared.size === 0) {
        Object.values(m.lineup || {}).forEach(pid => {
          if (pid) appeared.add(pid);
        });
        (m.signedUpPlayerIds || []).forEach(pid => appeared.add(pid));
        Object.entries(m.availability || {}).forEach(([pid, status]) => {
          if (status === 'CONFIRMED') appeared.add(pid);
        });
      }

      appeared.forEach(pid => {
        ensure(pid).appearances += 1;
      });

      const votes = normalizePotmVotes(m.potmVotes);
      (['coach', 'fans', 'opposition'] as const).forEach(category => {
        const tally: Record<string, number> =
          category === 'fans'
            ? tallyFanVotes(votes)
            : (() => {
                const counts: Record<string, number> = {};
                Object.values(votes[category] || {}).forEach(playerId => {
                  counts[playerId] = (counts[playerId] || 0) + 1;
                });
                return counts;
              })();
        const winners = getTiedPotmWinners(tally);
        if (!winners) return;
        winners.playerIds.forEach(playerId => {
          const row = ensure(playerId);
          if (category === 'coach') row.coachPotm += 1;
          else if (category === 'fans') row.fansPotm += 1;
          else row.oppositionPotm += 1;
        });
      });
    });

    relevantEvents.forEach(e => {
      if (e.type === 'GOAL') {
        if (e.details?.scorer) ensure(e.details.scorer).goals += 1;
        if (e.details?.assist) ensure(e.details.assist).assists += 1;
      } else if (e.type === 'YELLOW_CARD' && e.details?.scorer) {
        ensure(e.details.scorer).yellowCards += 1;
      } else if (e.type === 'RED_CARD' && e.details?.scorer) {
        ensure(e.details.scorer).redCards += 1;
      }
    });

    return Array.from(rows.values());
  }, [completed, relevantEvents, memberMap]);

  const topScorers = useMemo(
    () => [...playerStats].filter(p => p.goals > 0).sort((a, b) => b.goals - a.goals || b.assists - a.assists).slice(0, 8),
    [playerStats]
  );

  const topAssists = useMemo(
    () => [...playerStats].filter(p => p.assists > 0).sort((a, b) => b.assists - a.assists || b.goals - a.goals).slice(0, 8),
    [playerStats]
  );

  const coachPotmLeaders = useMemo(
    () => [...playerStats].filter(p => p.coachPotm > 0).sort((a, b) => b.coachPotm - a.coachPotm).slice(0, 8),
    [playerStats]
  );

  const fansPotmLeaders = useMemo(
    () => [...playerStats].filter(p => p.fansPotm > 0).sort((a, b) => b.fansPotm - a.fansPotm).slice(0, 8),
    [playerStats]
  );

  const oppositionPotmLeaders = useMemo(
    () => [...playerStats].filter(p => p.oppositionPotm > 0).sort((a, b) => b.oppositionPotm - a.oppositionPotm).slice(0, 8),
    [playerStats]
  );

  const minutesLeaders = useMemo(
    () => [...playerStats].filter(p => p.minutes > 0).sort((a, b) => b.minutes - a.minutes).slice(0, 8),
    [playerStats]
  );

  const discipline = useMemo(
    () =>
      [...playerStats]
        .filter(p => p.yellowCards > 0 || p.redCards > 0)
        .sort((a, b) => b.redCards - a.redCards || b.yellowCards - a.yellowCards)
        .slice(0, 8),
    [playerStats]
  );

  const myStats = useMemo(
    () => playerStats.find(p => p.id === currentUser.id) || {
      id: currentUser.id,
      name: currentUser.name,
      avatar: currentUser.avatar,
      goals: 0,
      assists: 0,
      yellowCards: 0,
      redCards: 0,
      coachPotm: 0,
      fansPotm: 0,
      oppositionPotm: 0,
      appearances: 0,
      minutes: 0,
    },
    [playerStats, currentUser]
  );

  const StatCard = ({
    label,
    value,
    sub,
    accent = 'slate',
  }: {
    label: string;
    value: string | number;
    sub?: string;
    accent?: 'slate' | 'green' | 'amber' | 'red' | 'blue';
  }) => {
    const accents = {
      slate: 'bg-white border-slate-200',
      green: 'bg-emerald-50 border-emerald-100',
      amber: 'bg-amber-50 border-amber-100',
      red: 'bg-rose-50 border-rose-100',
      blue: 'bg-blue-50 border-blue-100',
    };
    return (
      <div className={`rounded-2xl border p-4 shadow-sm ${accents[accent]}`}>
        <p className="text-[10px] font-black uppercase tracking-widest text-slate-500">{label}</p>
        <p className="text-3xl font-black tabular-nums text-slate-900 mt-1">{value}</p>
        {sub && <p className="text-xs font-medium text-slate-500 mt-1">{sub}</p>}
      </div>
    );
  };

  const PlayerList = ({
    title,
    icon,
    rows,
    metric,
    empty,
  }: {
    title: string;
    icon: React.ReactNode;
    rows: PlayerRow[];
    metric: (p: PlayerRow) => { value: number; label?: string };
    empty: string;
  }) => (
    <section className="bg-white rounded-3xl border border-slate-200 shadow-sm p-5">
      <div className="flex items-center gap-2 mb-4">
        <div className="text-blue-600">{icon}</div>
        <h3 className="text-sm font-black uppercase tracking-widest text-slate-900">{title}</h3>
      </div>
      {rows.length === 0 ? (
        <p className="text-sm text-slate-500 font-medium py-6 text-center">{empty}</p>
      ) : (
        <ul className="space-y-3">
          {rows.map((p, i) => {
            const m = metric(p);
            return (
              <li key={p.id} className="flex items-center gap-3">
                <span className="w-6 text-center text-xs font-black text-slate-400 tabular-nums">{i + 1}</span>
                {p.avatar ? (
                  <img src={p.avatar} alt="" className="w-9 h-9 rounded-xl object-cover border border-slate-100" />
                ) : (
                  <div className="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center text-xs font-black text-slate-500">
                    {p.name.charAt(0)}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-slate-900 truncate text-sm">{p.name}</p>
                  {m.label && <p className="text-[10px] font-medium text-slate-400">{m.label}</p>}
                </div>
                <span className="text-lg font-black tabular-nums text-slate-900">{m.value}</span>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-20">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">Statistics</h1>
          <p className="text-slate-500 font-medium mt-1">Season snapshot across your clubs.</p>
        </div>
        {clubs.length > 1 && (
          <select
            value={clubFilter}
            onChange={e => setClubFilter(e.target.value)}
            className="bg-white border border-slate-200 rounded-2xl px-4 py-3 text-sm font-bold text-slate-900 shadow-sm outline-none focus:ring-2 focus:ring-blue-500/30"
          >
            <option value="all">All clubs</option>
            {clubs.map(c => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
        )}
      </div>

      {record.played === 0 && topScorers.length === 0 ? (
        <div className="bg-white rounded-[2rem] border border-slate-200 p-12 text-center shadow-sm">
          <BarChart2 className="w-12 h-12 text-slate-300 mx-auto mb-4" />
          <h2 className="text-xl font-black text-slate-900">No stats yet</h2>
          <p className="text-sm text-slate-500 font-medium mt-2 max-w-sm mx-auto">
            Complete matches and log goals, assists, and cards to build your leaderboard.
          </p>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <StatCard label="Played" value={record.played} accent="blue" />
            <StatCard label="Won" value={record.won} sub={`${record.winPct}% win rate`} accent="green" />
            <StatCard label="Drawn" value={record.drawn} accent="amber" />
            <StatCard label="Lost" value={record.lost} accent="red" />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <StatCard label="Goals for" value={record.gf} />
            <StatCard label="Goals against" value={record.ga} />
            <StatCard
              label="Goal difference"
              value={record.gd > 0 ? `+${record.gd}` : record.gd}
              accent={record.gd > 0 ? 'green' : record.gd < 0 ? 'red' : 'slate'}
            />
          </div>

          {form.length > 0 && (
            <section className="bg-white rounded-3xl border border-slate-200 shadow-sm p-5">
              <div className="flex items-center gap-2 mb-4">
                <TrendingUp className="w-4 h-4 text-blue-600" />
                <h3 className="text-sm font-black uppercase tracking-widest text-slate-900">Recent form</h3>
              </div>
              <div className="flex flex-wrap gap-2">
                {form.map(({ match, result, score }) => (
                  <div
                    key={match.id}
                    className={`min-w-[72px] rounded-2xl px-3 py-2.5 text-center border ${
                      result === 'W'
                        ? 'bg-emerald-50 border-emerald-100 text-emerald-700'
                        : result === 'L'
                          ? 'bg-rose-50 border-rose-100 text-rose-700'
                          : 'bg-amber-50 border-amber-100 text-amber-700'
                    }`}
                    title={`${match.opponentName || match.title} ${score}`}
                  >
                    <p className="text-lg font-black leading-none">{result}</p>
                    <p className="text-[10px] font-bold mt-1 opacity-80 tabular-nums">{score}</p>
                  </div>
                ))}
              </div>
            </section>
          )}

          <section className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-[2rem] p-6 text-white shadow-xl shadow-slate-200">
            <div className="flex items-center gap-3 mb-5">
              {currentUser.avatar ? (
                <img src={currentUser.avatar} alt="" className="w-12 h-12 rounded-2xl object-cover border-2 border-white/20" />
              ) : (
                <div className="w-12 h-12 rounded-2xl bg-white/10 flex items-center justify-center font-black">
                  {currentUser.name.charAt(0)}
                </div>
              )}
              <div>
                <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">Your numbers</p>
                <h3 className="text-xl font-black">{currentUser.name}</h3>
              </div>
            </div>
            <div className="grid grid-cols-3 sm:grid-cols-5 lg:grid-cols-9 gap-3">
              {[
                { label: 'Apps', value: myStats.appearances },
                { label: 'Mins', value: myStats.minutes },
                { label: 'Goals', value: myStats.goals },
                { label: 'Assists', value: myStats.assists },
                { label: "Coach's", value: myStats.coachPotm },
                { label: "Fan's", value: myStats.fansPotm },
                { label: 'Opp.', value: myStats.oppositionPotm },
                { label: 'Yellow', value: myStats.yellowCards },
                { label: 'Red', value: myStats.redCards },
              ].map(item => (
                <div key={item.label} className="bg-white/10 rounded-2xl p-3 text-center border border-white/10">
                  <p className="text-2xl font-black tabular-nums">{item.value}</p>
                  <p className="text-[9px] font-black uppercase tracking-widest text-slate-400 mt-1">{item.label}</p>
                </div>
              ))}
            </div>
          </section>

          {byCompetition.length > 0 && (
            <section className="bg-white rounded-3xl border border-slate-200 shadow-sm p-5">
              <div className="flex items-center gap-2 mb-4">
                <Trophy className="w-4 h-4 text-blue-600" />
                <h3 className="text-sm font-black uppercase tracking-widest text-slate-900">By competition</h3>
              </div>
              <div className="space-y-3">
                {byCompetition.map(([key, stats]) => (
                  <div key={key} className="flex items-center justify-between gap-4 p-3 rounded-2xl bg-slate-50 border border-slate-100">
                    <div>
                      <p className="font-bold text-slate-900 text-sm">{competitionLabel(key)}</p>
                      <p className="text-[10px] font-medium text-slate-500 mt-0.5">
                        {stats.played} played · GF {stats.gf} GA {stats.ga}
                      </p>
                    </div>
                    <p className="font-black tabular-nums text-slate-900 text-sm">
                      {stats.won}W {stats.drawn}D {stats.lost}L
                    </p>
                  </div>
                ))}
              </div>
            </section>
          )}

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <PlayerList
              title="Minutes played"
              icon={<Clock className="w-4 h-4" />}
              rows={minutesLeaders}
              metric={p => ({
                value: p.minutes,
                label: p.appearances ? `${p.appearances} apps · avg ${Math.round(p.minutes / p.appearances)}′` : undefined,
              })}
              empty="Log half times and a lineup to track minutes."
            />
            <PlayerList
              title="Top scorers"
              icon={<Goal className="w-4 h-4" />}
              rows={topScorers}
              metric={p => ({ value: p.goals, label: p.assists ? `${p.assists} assists` : undefined })}
              empty="No goals logged yet."
            />
            <PlayerList
              title="Top assists"
              icon={<Target className="w-4 h-4" />}
              rows={topAssists}
              metric={p => ({ value: p.assists, label: p.goals ? `${p.goals} goals` : undefined })}
              empty="No assists logged yet."
            />
            <PlayerList
              title="Coach's Player"
              icon={<Award className="w-4 h-4" />}
              rows={coachPotmLeaders}
              metric={p => ({ value: p.coachPotm, label: 'awards' })}
              empty="No coach awards yet."
            />
            <PlayerList
              title="Fan's Player"
              icon={<Award className="w-4 h-4" />}
              rows={fansPotmLeaders}
              metric={p => ({ value: p.fansPotm, label: 'awards' })}
              empty="No fan awards yet."
            />
            <PlayerList
              title="Opposition's Player"
              icon={<Award className="w-4 h-4" />}
              rows={oppositionPotmLeaders}
              metric={p => ({ value: p.oppositionPotm, label: 'awards' })}
              empty="No opposition awards yet."
            />
            <PlayerList
              title="Discipline"
              icon={<Shield className="w-4 h-4" />}
              rows={discipline}
              metric={p => ({
                value: p.yellowCards + p.redCards * 2,
                label: `${p.yellowCards}Y · ${p.redCards}R`,
              })}
              empty="Clean sheets on cards so far."
            />
          </div>

          {clubs.length > 0 && clubFilter === 'all' && (
            <section className="bg-white rounded-3xl border border-slate-200 shadow-sm p-5">
              <div className="flex items-center gap-2 mb-4">
                <Users className="w-4 h-4 text-blue-600" />
                <h3 className="text-sm font-black uppercase tracking-widest text-slate-900">Clubs</h3>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {clubs.map(club => {
                  const clubMatches = completed.filter(m => m.clubId === club.id);
                  let w = 0;
                  let d = 0;
                  let l = 0;
                  clubMatches.forEach(m => {
                    const a = m.scoreA || 0;
                    const b = m.scoreB || 0;
                    if (a > b) w += 1;
                    else if (a < b) l += 1;
                    else d += 1;
                  });
                  return (
                    <button
                      key={club.id}
                      type="button"
                      onClick={() => setClubFilter(club.id)}
                      className="flex items-center gap-3 p-3 rounded-2xl border border-slate-100 bg-slate-50 hover:border-blue-200 hover:bg-blue-50 transition-all text-left"
                    >
                      <div className="w-11 h-11 rounded-xl overflow-hidden bg-blue-100 flex items-center justify-center shrink-0">
                        {club.logo ? (
                          <img src={club.logo} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <span className="font-black text-blue-600">{club.name.charAt(0)}</span>
                        )}
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="font-bold text-slate-900 truncate text-sm">{club.name}</p>
                        <p className="text-[10px] font-medium text-slate-500 mt-0.5">
                          {clubMatches.length} completed · {w}W {d}D {l}L
                        </p>
                      </div>
                    </button>
                  );
                })}
              </div>
            </section>
          )}
        </>
      )}
    </div>
  );
};

export default Statistics;
