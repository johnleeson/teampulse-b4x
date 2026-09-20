import React, { useState } from 'react';
import { Club, Match, MatchCompetition } from '../types';
import { DEFAULT_FORMATION_BY_SIZE, TeamSize } from '../lib/formations';
import { X, Calendar, Clock, MapPin, Trophy, Shield, Users, Check, Swords } from 'lucide-react';

interface MatchFormProps {
  club: Club;
  onSave: (match: Match) => void;
  onCancel: () => void;
  currentUserId?: string;
  initialMatch?: Match;
}

const COMPETITION_OPTIONS: { value: MatchCompetition; label: string }[] = [
  { value: 'LEAGUE', label: 'League' },
  { value: 'CUP', label: 'Cup' },
  { value: 'FRIENDLY', label: 'Friendly' },
];

const MatchForm: React.FC<MatchFormProps> = ({ club, onSave, onCancel, currentUserId, initialMatch }) => {
  const isTeam = club.type === 'TEAM';
  const isEditing = !!initialMatch;

  const [title, setTitle] = useState(initialMatch?.title || (isTeam ? '' : 'Weekly 5-a-side'));
  const [opponentName, setOpponentName] = useState(initialMatch?.opponentName || '');
  const [isHome, setIsHome] = useState(initialMatch?.isHome !== undefined ? initialMatch.isHome : true);
  const [date, setDate] = useState(initialMatch ? new Date(initialMatch.date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]);
  const [kickOffTime, setKickOffTime] = useState(() => {
    const raw = initialMatch?.kickOffTime || '19:00';
    const m = raw.match(/^(\d{1,2}):(\d{2})/);
    return m ? `${m[1].padStart(2, '0')}:${m[2]}` : raw;
  });
  const [meetTime, setMeetTime] = useState(() => {
    const raw = initialMatch?.meetTime || '18:30';
    const m = raw.match(/^(\d{1,2}):(\d{2})/);
    return m ? `${m[1].padStart(2, '0')}:${m[2]}` : raw;
  });
  const [location, setLocation] = useState(initialMatch?.location || '');
  const [competition, setCompetition] = useState<MatchCompetition>(initialMatch?.competition || 'FRIENDLY');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const signedUpPlayerIds = isEditing 
      ? initialMatch!.signedUpPlayerIds 
      : (currentUserId ? [currentUserId] : []);

    const teamSize = (initialMatch?.teamSize || club.preferredTeamSize || 9) as TeamSize;
    const formation = initialMatch?.formation || club.preferredFormation || DEFAULT_FORMATION_BY_SIZE[teamSize];

    const matchData: Match = {
      ...(initialMatch || {}),
      id: initialMatch?.id || crypto.randomUUID(),
      clubId: club.id,
      title: isTeam ? (isHome ? `${club.name} vs ${opponentName}` : `${opponentName} vs ${club.name}`) : title,
      date: new Date(date).toISOString(),
      kickOffTime,
      meetTime: isTeam ? meetTime : undefined,
      location,
      competition,
      status: initialMatch?.status || 'UPCOMING',
      teamA: initialMatch?.teamA || [],
      teamB: initialMatch?.teamB || [],
      scoreA: initialMatch?.scoreA || 0,
      scoreB: initialMatch?.scoreB || 0,
      signedUpPlayerIds,
      opponentName: isTeam ? opponentName : undefined,
      isHome: isTeam ? isHome : undefined,
      teamSize: initialMatch?.teamSize || teamSize,
      formation: initialMatch?.formation || formation,
      lineup: initialMatch?.lineup || {},
    };

    onSave(matchData);
  };

  return (
    <div className="max-w-xl mx-auto animate-in fade-in slide-in-from-bottom-8 duration-500 pb-20 px-2 sm:px-4 overflow-x-hidden">
      <div className="bg-white rounded-[2rem] shadow-2xl border border-slate-200 overflow-hidden w-full box-border">
        <div className="px-4 py-5 md:px-8 md:py-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/30">
          <div className="min-w-0 pr-2">
            <h2 className="text-lg md:text-2xl font-black text-slate-900 tracking-tight truncate">
              {isEditing ? 'Edit Match' : (isTeam ? 'Schedule Match' : 'Plan Game')}
            </h2>
            <p className="text-slate-500 text-[10px] md:text-xs font-medium mt-0.5 truncate">
              {isEditing ? `Updating ${initialMatch!.title}` : (isTeam ? `Fixture for ${club.name}` : `Social kickabout for group`)}
            </p>
          </div>
          <button type="button" onClick={onCancel} className="shrink-0 p-2 text-slate-400 hover:text-slate-600 hover:bg-white rounded-full transition-all border border-transparent hover:border-slate-100"><X className="w-5 h-5 md:w-6 md:h-6" /></button>
        </div>

        <form onSubmit={handleSubmit} className="px-4 py-5 md:px-8 md:py-8 space-y-5 md:space-y-6 w-full box-border">
          {isTeam && (
            <div className="space-y-4">
              <div className="flex gap-2 p-1 bg-slate-100 rounded-xl">
                <button type="button" onClick={() => setIsHome(true)} className={`flex-1 py-2 rounded-lg font-black text-[10px] uppercase tracking-widest transition-all ${isHome ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500'}`}>Home</button>
                <button type="button" onClick={() => setIsHome(false)} className={`flex-1 py-2 rounded-lg font-black text-[10px] uppercase tracking-widest transition-all ${!isHome ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500'}`}>Away</button>
              </div>
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1"><Shield className="w-3 h-3 text-blue-600" />Opponent</label>
                <input type="text" required value={opponentName} onChange={(e) => setOpponentName(e.target.value)} placeholder="Opponent team..." className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-900 focus:outline-none focus:ring-4 focus:ring-blue-500/10 transition-all font-bold text-sm box-border" />
              </div>
            </div>
          )}

          {!isTeam && (
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1"><Users className="w-3 h-3 text-indigo-600" />Game Title</label>
              <input type="text" required value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Weekly match..." className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-900 focus:outline-none focus:ring-4 focus:ring-blue-500/10 transition-all font-bold text-sm box-border" />
            </div>
          )}

          <div className="space-y-2">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1">
              <Trophy className="w-3 h-3 text-amber-500" /> Competition
            </label>
            <div className="grid grid-cols-3 gap-2">
              {COMPETITION_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => setCompetition(opt.value)}
                  className={`flex flex-col items-center gap-1.5 py-3 px-2 rounded-2xl border-2 transition-all ${
                    competition === opt.value
                      ? opt.value === 'LEAGUE'
                        ? 'border-blue-600 bg-blue-50 text-blue-700'
                        : opt.value === 'CUP'
                          ? 'border-amber-500 bg-amber-50 text-amber-700'
                          : 'border-emerald-600 bg-emerald-50 text-emerald-700'
                      : 'border-slate-100 bg-white text-slate-400 hover:border-slate-200'
                  }`}
                >
                  {opt.value === 'FRIENDLY' ? <Swords className="w-4 h-4" /> : <Trophy className="w-4 h-4" />}
                  <span className="text-[9px] font-black uppercase tracking-widest">{opt.label}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-4 w-full">
            <div className="flex-1 space-y-1.5 min-w-0">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1"><Calendar className="w-3 h-3 text-blue-600" />Date</label>
              <input type="date" required value={date} onChange={(e) => setDate(e.target.value)} className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-900 focus:outline-none focus:ring-4 focus:ring-blue-500/10 transition-all font-bold text-sm appearance-none box-border" />
            </div>
            <div className="flex-1 space-y-1.5 min-w-0">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1"><Clock className="w-3 h-3 text-blue-600" />Kick Off</label>
              <input type="time" required value={kickOffTime} onChange={(e) => setKickOffTime(e.target.value)} className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-900 focus:outline-none focus:ring-4 focus:ring-blue-500/10 transition-all font-bold text-sm appearance-none box-border" />
            </div>
          </div>

          {isTeam && (
            <div className="space-y-1.5 min-w-0">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1"><Clock className="w-3 h-3 text-orange-500" />Meet Time</label>
              <input type="time" value={meetTime} onChange={(e) => setMeetTime(e.target.value)} className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-900 focus:outline-none focus:ring-4 focus:ring-blue-500/10 transition-all font-bold text-sm appearance-none box-border" />
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1"><MapPin className="w-3 h-3 text-red-500" />Location</label>
            <input type="text" required value={location} onChange={(e) => setLocation(e.target.value)} placeholder="Venue name..." className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-900 focus:outline-none focus:ring-4 focus:ring-blue-500/10 transition-all font-bold text-sm box-border" />
          </div>

          <div className="flex flex-col-reverse sm:flex-row gap-3 pt-4">
            <button type="button" onClick={onCancel} className="w-full sm:flex-1 px-4 py-3.5 rounded-xl font-black text-slate-500 bg-slate-100 hover:bg-slate-200 transition-all uppercase tracking-widest text-[10px]">Cancel</button>
            <button type="submit" className="w-full sm:flex-[2] px-4 py-3.5 rounded-xl font-black text-white bg-blue-600 shadow-xl shadow-blue-100 hover:bg-blue-700 transition-all flex items-center justify-center gap-2 uppercase tracking-widest text-[10px]"><Check className="w-4 h-4" />{isEditing ? 'Save Changes' : 'Confirm Fixture'}</button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default MatchForm;
