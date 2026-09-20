
import React, { useState } from 'react';
import { Club, Match, User } from '../types';
import { Calendar, Users, Trophy, ChevronRight, Play, Plus, Shield, MapPin, Check, Clock, AlertCircle, Trash2, X, Bell } from 'lucide-react';

interface DashboardProps {
  clubs: Club[];
  matches: Match[];
  currentUser: User;
  onViewMatch: (id: string) => void;
  onJoinMatch: (id: string) => void;
  onViewClub: (id: string) => void;
  onCreateClub: () => void;
  onCreateMatch: () => void;
  onCancelMatch: (matchId: string) => void;
  onTestNotify?: () => void;
}

const Dashboard: React.FC<DashboardProps> = ({ clubs, matches, currentUser, onViewMatch, onJoinMatch, onViewClub, onCreateClub, onCreateMatch, onCancelMatch, onTestNotify }) => {
  const liveMatches = matches.filter(m => m.status === 'LIVE');
  const relevantMatches = matches.filter(m => m.status === 'UPCOMING' || m.status === 'CANCELLED' || m.status === 'LIVE')
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  const [showConfirmCancelModal, setShowConfirmCancelModal] = useState(false);
  const [matchToCancelId, setMatchToCancelId] = useState<string | null>(null);

  const handleCancelClick = (e: React.MouseEvent, matchId: string) => {
    e.stopPropagation();
    setMatchToCancelId(matchId);
    setShowConfirmCancelModal(true);
  };

  const confirmCancel = () => {
    if (matchToCancelId) {
      onCancelMatch(matchToCancelId);
      setShowConfirmCancelModal(false);
      setMatchToCancelId(null);
    }
  };

  const canManageMatch = (match: Match) => {
    const club = clubs.find(c => c.id === match.clubId);
    if (!club) return false;
    const isMatchOwner = currentUser.id === club.ownerId;
    const isAdminInClub = club.members.some(m => m.id === currentUser.id && m.roles.includes('ADMIN'));
    return isMatchOwner || isAdminInClub;
  };

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-20">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 tracking-tight">Your Pulse</h1>
          <div className="flex items-center gap-2 mt-1">
            <p className="text-slate-500 font-medium">You've got action scheduled this week.</p>
            <button 
              onClick={onTestNotify}
              className="text-[9px] font-black uppercase text-blue-500 hover:text-blue-700 tracking-widest flex items-center gap-1 bg-blue-50 px-2 py-1 rounded-md"
              title="Test if notifications work on this device"
            >
              <Bell className="w-2.5 h-2.5" /> Test Alerts
            </button>
          </div>
        </div>
        <button
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            alert("DASHBOARD BUTTON CLICKED");
            onCreateMatch();
          }} 
          // onClick={onCreateMatch}
          className="bg-blue-600 text-white px-6 py-3 rounded-2xl font-black text-xs uppercase tracking-widest shadow-xl shadow-blue-100 hover:bg-blue-700 hover:-translate-y-0.5 transition-all flex items-center justify-center gap-2"
        >
          <Calendar className="w-4 h-4" />
          Plan Game
        </button>
      </div>

      {/* Live Feed Banner */}
      {liveMatches.length > 0 && (
        <section className="bg-gradient-to-br from-red-600 to-rose-500 rounded-[2.5rem] p-8 text-white shadow-2xl shadow-red-100 relative overflow-hidden group cursor-pointer" onClick={() => onViewMatch(liveMatches[0].id)}>
          <div className="absolute top-0 right-0 p-8 opacity-10 group-hover:scale-110 transition-transform">
             <Play className="w-48 h-48 fill-current" />
          </div>
          <div className="flex flex-col md:flex-row items-center justify-between gap-8 relative z-10">
            <div className="flex items-center gap-6">
              <div className="animate-pulse bg-white/20 p-5 rounded-3xl backdrop-blur-md">
                <Play className="w-8 h-8 fill-current" />
              </div>
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span className="bg-white text-red-600 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest">Live Now</span>
                  <span className="w-2 h-2 bg-white rounded-full animate-ping"></span>
                </div>
                <h3 className="text-2xl font-black">{liveMatches[0].title}</h3>
                <p className="text-red-100 font-medium flex items-center gap-1.5 mt-1">
                  <MapPin className="w-4 h-4" /> {liveMatches[0].location}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-10">
              <div className="text-center">
                <p className="text-6xl font-black tabular-nums tracking-tighter">{liveMatches[0].scoreA} - {liveMatches[0].scoreB}</p>
                <p className="text-[10px] text-red-100 uppercase font-black tracking-widest mt-2 opacity-80">Current Score</p>
              </div>
              <button 
                className="bg-white text-red-600 px-8 py-4 rounded-2xl font-black text-xs uppercase tracking-widest hover:bg-slate-50 transition-all shadow-xl whitespace-nowrap"
              >
                Join Stream
              </button>
            </div>
          </div>
        </section>
      )}

      {/* Upcoming & Hubs Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div>
          <div className="flex items-center justify-between mb-6 px-2">
            <h2 className="text-xl font-black text-slate-900 uppercase tracking-tight">Coming Up</h2>
            <button className="text-[10px] font-black text-blue-600 hover:text-blue-800 uppercase tracking-widest transition-colors">View Schedule</button>
          </div>
          <div className="space-y-4">
            {relevantMatches.length === 0 ? (
              <div className="bg-slate-50 border-2 border-dashed border-slate-200 rounded-[2rem] p-12 text-center">
                <Calendar className="w-12 h-12 text-slate-300 mx-auto mb-4" />
                <p className="text-sm font-black text-slate-400 uppercase tracking-widest">No games planned yet</p>
                <button onClick={onCreateMatch} className="text-blue-600 text-[10px] font-black uppercase tracking-widest mt-4 hover:underline">Create a Fixture</button>
              </div>
            ) : relevantMatches.map(match => {
              const isSignedUp = match.signedUpPlayerIds.includes(currentUser.id);
              const club = clubs.find(c => c.id === match.clubId);
              const userRoleInClub = club?.members.find(m => m.id === currentUser.id)?.roles || [];
              const isCancelled = match.status === 'CANCELLED';
              const isLive = match.status === 'LIVE';
              const canJoin = userRoleInClub.includes('PLAYER') && !isSignedUp && !isCancelled && !isLive;
              const userCanManageMatch = canManageMatch(match);

              return (
                <div 
                  key={match.id} 
                  onClick={() => onViewMatch(match.id)}
                  className={`p-6 rounded-[2rem] border flex items-center justify-between hover:shadow-xl hover:-translate-y-1 transition-all group cursor-pointer ${
                    isCancelled ? 'bg-red-50/30 border-red-100' : isLive ? 'bg-blue-50/30 border-blue-100 ring-2 ring-blue-500/20' : 'bg-white border-slate-200 shadow-sm'
                  }`}
                >
                  <div className="flex items-center gap-5 min-w-0">
                    <div className={`text-center rounded-2xl p-4 min-w-[80px] border transition-all ${
                      isCancelled 
                        ? 'bg-red-100/50 border-red-200 text-red-400' 
                        : isLive
                        ? 'bg-blue-600 border-blue-700 text-white'
                        : 'bg-slate-50 border-slate-100 group-hover:bg-blue-600 group-hover:border-blue-700 group-hover:text-white'
                    }`}>
                      <p className="text-[10px] font-black uppercase tracking-tighter opacity-70">
                        {new Date(match.date).toLocaleDateString('en-US', { month: 'short' })}
                      </p>
                      <p className="text-2xl font-black tabular-nums">
                        {new Date(match.date).getDate()}
                      </p>
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <h4 className={`font-black text-slate-900 truncate transition-colors ${
                          isCancelled ? 'line-through text-slate-400' : isLive ? 'text-blue-900' : 'group-hover:text-blue-600'
                        }`}>{match.title}</h4>
                        {isCancelled && <AlertCircle className="w-3.5 h-3.5 text-red-500" />}
                        {isLive && <span className="flex items-center gap-1 bg-red-500 text-white px-1.5 py-0.5 rounded-md text-[8px] font-black uppercase animate-pulse">Live</span>}
                      </div>
                      <p className="text-xs text-slate-500 font-bold flex items-center gap-1.5 mt-1">
                        <MapPin className="w-3.5 h-3.5 text-red-400" /> {match.location}
                      </p>
                      <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-2">
                        {isCancelled ? 'MATCH CANCELLED' : isLive ? `${match.scoreA} - ${match.scoreB} (LIVE)` : `Kickoff: ${match.kickOffTime}`}
                      </p>
                    </div>
                  </div>
                  <div className="flex gap-2 items-center">
                    {canJoin && (
                      <button 
                        onClick={(e) => { e.stopPropagation(); onJoinMatch(match.id); }}
                        className="bg-green-600 text-white px-5 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-green-700 shadow-lg shadow-green-100 transition-all flex items-center gap-1.5"
                      >
                        Join
                      </button>
                    )}
                    {isSignedUp && !isCancelled && (
                      <div className="bg-slate-100 text-slate-400 px-4 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest flex items-center gap-1.5 border border-slate-200">
                        <Check className="w-3 h-3" />
                        In
                      </div>
                    )}
                    {match.status === 'UPCOMING' && userCanManageMatch && (
                       <button 
                        onClick={(e) => handleCancelClick(e, match.id)}
                        className="p-3 text-red-500 hover:bg-red-50 rounded-xl transition-all border border-transparent hover:border-red-100 shadow-sm"
                        title="Cancel Match"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    )}
                    <div className={`p-3 rounded-xl transition-colors shadow-lg ${isCancelled ? 'bg-red-200 text-red-600' : isLive ? 'bg-blue-600 text-white' : 'bg-slate-900 text-white group-hover:bg-blue-600'}`}>
                      <ChevronRight className="w-4 h-4" />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div>
          <div className="flex items-center justify-between mb-6 px-2">
            <h2 className="text-xl font-black text-slate-900 uppercase tracking-tight">Your Hubs</h2>
            <button 
              onClick={onCreateClub}
              className="flex items-center gap-1.5 text-[10px] font-black text-blue-600 hover:text-blue-800 uppercase tracking-widest transition-colors"
            >
              <Plus className="w-4 h-4" />
              New Setup
            </button>
          </div>
          <div className="space-y-4">
            {clubs.length === 0 ? (
               <div className="bg-slate-50 border-2 border-dashed border-slate-200 rounded-[2rem] p-12 text-center">
                 <Shield className="w-12 h-12 text-slate-300 mx-auto mb-4" />
                 <p className="text-sm font-black text-slate-400 uppercase tracking-widest">Join a club to start</p>
               </div>
            ) : clubs.map(club => (
              <div 
                key={club.id} 
                onClick={() => onViewClub(club.id)}
                className="bg-white p-5 rounded-[2rem] border border-slate-200 flex items-center gap-5 hover:shadow-xl hover:-translate-y-1 transition-all group cursor-pointer"
              >
                <div className="relative">
                  <img src={club.logo} className="w-16 h-16 rounded-[1.5rem] object-cover shadow-lg border border-slate-100" alt={club.name} />
                  <div className={`absolute -top-1 -right-1 p-1.5 rounded-xl border-2 border-white shadow-md ${club.type === 'TEAM' ? 'bg-blue-600' : 'bg-indigo-600'}`}>
                    {club.type === 'TEAM' ? <Shield className="w-3 h-3 text-white" /> : <Users className="w-3 h-3 text-white" />}
                  </div>
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-1">
                    <h4 className="font-black text-slate-900 group-hover:text-blue-600 transition-colors text-lg tracking-tight">{club.name}</h4>
                  </div>
                  <div className="flex items-center gap-3">
                     <span className={`text-[8px] font-black uppercase px-2 py-0.5 rounded-full border ${
                        club.type === 'TEAM' ? 'bg-blue-50 text-blue-600 border-blue-100' : 'bg-indigo-50 text-indigo-600 border-indigo-100'
                      }`}>
                        {club.type}
                      </span>
                      <p className="text-[10px] font-bold text-slate-400">{club.members.length} Members • {club.type === 'TEAM' ? 'Competitive' : 'Social'}</p>
                  </div>
                </div>
                <div className="p-3 bg-slate-50 rounded-xl group-hover:bg-slate-100 transition-colors">
                  <ChevronRight className="w-5 h-5 text-slate-300 group-hover:text-slate-600" />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Confirm Cancel Modal */}
      {showConfirmCancelModal && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-white rounded-[2rem] shadow-2xl w-full max-sm overflow-hidden animate-in zoom-in-95 duration-300">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <h3 className="text-xl font-bold text-red-900">Confirm Cancellation</h3>
              <button onClick={() => setShowConfirmCancelModal(false)} className="p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-400">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-8 text-center space-y-6">
              <AlertCircle className="w-16 h-16 text-red-500 mx-auto" />
              <p className="text-slate-700 font-medium leading-relaxed">
                Are you sure you want to cancel this match? This action cannot be undone.
              </p>
              <div className="flex gap-4">
                <button 
                  type="button" 
                  onClick={() => setShowConfirmCancelModal(false)}
                  className="flex-1 py-3.5 rounded-xl font-black text-slate-500 bg-slate-100 hover:bg-slate-200 transition-all uppercase tracking-widest text-[10px]"
                >
                  Keep Match
                </button>
                <button 
                  type="button" 
                  onClick={confirmCancel}
                  className="flex-1 py-3.5 rounded-xl font-black text-white bg-red-600 shadow-xl shadow-red-100 hover:bg-red-700 transition-all uppercase tracking-widest text-[10px]"
                >
                  <X className="w-4 h-4 inline-block mr-1" /> Yes, Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;
