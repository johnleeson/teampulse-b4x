
import React, { useState } from 'react';
import { Club, User, ClubType, UserRole } from '../types';
import { X, Camera, Shield, Info, Check, Users, MapPin, Eye, User as UserIcon, Loader2, AlertCircle } from 'lucide-react';

interface ClubFormProps {
  onSave: (club: Club) => Promise<void>;
  onCancel: () => void;
  currentUser: User;
}

const ClubForm: React.FC<ClubFormProps> = ({ onSave, onCancel, currentUser }) => {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [type, setType] = useState<ClubType>('TEAM');
  const [logoUrl, setLogoUrl] = useState(`https://picsum.photos/seed/${Math.random()}/200/200`);
  const [myRole, setMyRole] = useState<'PLAYER' | 'COACH' | 'SPECTATOR'>('PLAYER');
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || isSaving) return;

    setIsSaving(true);
    setError(null);
    
    try {
      const roles: UserRole[] = ['ADMIN', myRole];
      const newClub: Club = {
        // Use crypto.randomUUID() for valid database UUIDs
        id: crypto.randomUUID(),
        name: name.trim(),
        description: description.trim(),
        logo: logoUrl,
        type,
        ownerId: currentUser.id,
        members: [{ ...currentUser, roles }],
        inviteCode: Math.random().toString(36).substring(2, 8).toUpperCase()
      };

      await onSave(newClub);
    } catch (err: any) {
      console.error("Club creation failed:", err);
      setError(err.message || "Something went wrong while creating your club. Please try again.");
      setIsSaving(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto animate-in fade-in slide-in-from-bottom-8 duration-500 pb-20 px-4">
      <div className="bg-white rounded-[2.5rem] shadow-2xl border border-slate-200 overflow-hidden">
        <div className="px-6 py-8 md:p-10 border-b border-slate-100 flex items-center justify-between bg-slate-50/30">
          <div>
            <h2 className="text-2xl md:text-3xl font-black text-slate-900 tracking-tight">Create Hub</h2>
            <p className="text-slate-500 font-medium mt-1 text-sm">Setup your team or social group.</p>
          </div>
          <button 
            type="button"
            onClick={onCancel}
            disabled={isSaving}
            className="p-2 md:p-3 text-slate-400 hover:text-slate-600 hover:bg-white rounded-full transition-all border border-transparent hover:border-slate-100 disabled:opacity-50"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="px-6 py-8 md:p-10 space-y-10">
          {error && (
            <div className="bg-red-50 border border-red-100 p-4 rounded-2xl flex items-center gap-3 text-red-600 animate-in slide-in-from-top-2">
              <AlertCircle className="w-5 h-5 shrink-0" />
              <p className="text-sm font-bold">{error}</p>
            </div>
          )}

          <div className="space-y-4">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1">
              Select Setup Style
            </label>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <button
                type="button"
                disabled={isSaving}
                onClick={() => setType('TEAM')}
                className={`flex items-start gap-4 p-5 rounded-2xl border-2 transition-all text-left ${
                  type === 'TEAM' 
                    ? 'border-blue-600 bg-blue-50/50 ring-4 ring-blue-50' 
                    : 'border-slate-100 hover:border-slate-200 bg-white'
                } disabled:opacity-50`}
              >
                <div className={`p-3 rounded-xl shrink-0 ${type === 'TEAM' ? 'bg-blue-600 text-white shadow-lg shadow-blue-200' : 'bg-slate-100 text-slate-400'}`}>
                  <Shield className="w-6 h-6" />
                </div>
                <div>
                  <h4 className={`font-black text-sm uppercase tracking-tight ${type === 'TEAM' ? 'text-blue-900' : 'text-slate-900'}`}>Competitive Club</h4>
                  <p className="text-[11px] text-slate-500 mt-1 font-medium leading-relaxed">Playing matches against other clubs, fixed rosters, and season stats.</p>
                </div>
              </button>

              <button
                type="button"
                disabled={isSaving}
                onClick={() => setType('SOCIAL')}
                className={`flex items-start gap-4 p-5 rounded-2xl border-2 transition-all text-left ${
                  type === 'SOCIAL' 
                    ? 'border-indigo-600 bg-indigo-50/50 ring-4 ring-indigo-50' 
                    : 'border-slate-100 hover:border-slate-200 bg-white'
                } disabled:opacity-50`}
              >
                <div className={`p-3 rounded-xl shrink-0 ${type === 'SOCIAL' ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-200' : 'bg-slate-100 text-slate-400'}`}>
                  <Users className="w-6 h-6" />
                </div>
                <div>
                  <h4 className={`font-black text-sm uppercase tracking-tight ${type === 'SOCIAL' ? 'text-indigo-900' : 'text-slate-900'}`}>Social Group</h4>
                  <p className="text-[11px] text-slate-500 mt-1 font-medium leading-relaxed">Organizing internal 5-a-sides, games with mates, and mixed lineups.</p>
                </div>
              </button>
            </div>
          </div>

          <div className="space-y-4">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1">
              Your Role in this Hub
            </label>
            <div className="grid grid-cols-3 gap-4">
              <button
                type="button"
                disabled={isSaving}
                onClick={() => setMyRole('PLAYER')}
                className={`flex items-center justify-center gap-3 p-4 rounded-2xl border-2 transition-all ${
                  myRole === 'PLAYER' 
                    ? 'border-green-600 bg-green-50 text-green-700' 
                    : 'border-slate-100 bg-white text-slate-400'
                } disabled:opacity-50`}
              >
                <UserIcon className="w-5 h-5" />
                <span className="font-black text-[10px] uppercase tracking-widest">Player</span>
              </button>
              <button
                type="button"
                disabled={isSaving}
                onClick={() => setMyRole('COACH')}
                className={`flex items-center justify-center gap-3 p-4 rounded-2xl border-2 transition-all ${
                  myRole === 'COACH' 
                    ? 'border-purple-600 bg-purple-50 text-purple-700' 
                    : 'border-slate-100 bg-white text-slate-400'
                } disabled:opacity-50`}
              >
                <Shield className="w-5 h-5" />
                <span className="font-black text-[10px] uppercase tracking-widest">Coach</span>
              </button>
              <button
                type="button"
                disabled={isSaving}
                onClick={() => setMyRole('SPECTATOR')}
                className={`flex items-center justify-center gap-3 p-4 rounded-2xl border-2 transition-all ${
                  myRole === 'SPECTATOR' 
                    ? 'border-amber-600 bg-amber-50 text-amber-700' 
                    : 'border-slate-100 bg-white text-slate-400'
                } disabled:opacity-50`}
              >
                <Eye className="w-5 h-5" />
                <span className="font-black text-[10px] uppercase tracking-widest">Spectator</span>
              </button>
            </div>
          </div>

          <div className="flex flex-col items-center gap-4 py-4">
            <div className="relative group cursor-pointer">
              <img 
                src={logoUrl} 
                className="w-32 h-32 md:w-40 md:h-40 rounded-[2.5rem] object-cover ring-8 ring-slate-50 shadow-2xl transition-transform group-hover:scale-105 duration-500" 
                alt="Logo Preview" 
              />
              <button 
                type="button"
                disabled={isSaving}
                onClick={() => setLogoUrl(`https://picsum.photos/seed/${Date.now()}/200/200`)}
                className="absolute inset-0 bg-slate-900/40 rounded-[2.5rem] flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 disabled:pointer-events-none"
              >
                <div className="bg-white/20 backdrop-blur-md p-3 md:p-4 rounded-2xl">
                  <Camera className="w-6 h-6 md:w-8 md:h-8 text-white" />
                </div>
              </button>
            </div>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Click photo to randomize</p>
          </div>

          <div className="space-y-8">
            <div className="space-y-2">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1">
                {type === 'TEAM' ? 'Club Name' : 'Group Name'}
              </label>
              <input 
                autoFocus
                type="text" 
                required
                disabled={isSaving}
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder={type === 'TEAM' ? 'e.g. North London Titans' : 'e.g. Tuesday Night Ballers'}
                className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-5 py-4 text-slate-900 placeholder:text-slate-200 focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500 transition-all font-bold text-base md:text-lg disabled:opacity-50"
              />
            </div>

            <div className="space-y-2">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 ml-1">
                About Us
              </label>
              <textarea 
                rows={3}
                disabled={isSaving}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder={type === 'TEAM' ? 'Team mission and goals...' : 'Group rules and venue details...'}
                className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-5 py-4 text-slate-900 placeholder:text-slate-200 focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500 transition-all font-semibold resize-none text-sm disabled:opacity-50"
              />
            </div>
          </div>

          <div className="flex flex-col-reverse md:flex-row gap-4 pt-4">
            <button 
              type="button"
              disabled={isSaving}
              onClick={onCancel}
              className="flex-1 px-8 py-4 md:py-5 rounded-2xl font-black text-slate-500 bg-slate-100 hover:bg-slate-200 transition-all uppercase tracking-widest text-[10px] md:text-xs disabled:opacity-50"
            >
              Cancel
            </button>
            <button 
              type="submit"
              disabled={isSaving}
              className={`flex-[2] px-8 py-4 md:py-5 rounded-2xl font-black text-white shadow-xl hover:translate-y-[-2px] active:translate-y-[0px] transition-all flex items-center justify-center gap-3 uppercase tracking-widest text-[10px] md:text-xs ${
                type === 'TEAM' ? 'bg-blue-600 shadow-blue-100 hover:bg-blue-700' : 'bg-indigo-600 shadow-indigo-100 hover:bg-indigo-700'
              } disabled:opacity-50 disabled:translate-y-0`}
            >
              {isSaving ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  <span>Creating...</span>
                </>
              ) : (
                <>
                  <Check className="w-5 h-5" />
                  <span>{type === 'TEAM' ? 'Form Club' : 'Create Group'}</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ClubForm;
