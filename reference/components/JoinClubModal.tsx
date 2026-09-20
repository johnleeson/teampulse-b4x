
import React, { useState } from 'react';
import { X, Hash, Check, User as UserIcon, Eye } from 'lucide-react';
import { UserRole } from '../types';

interface JoinClubModalProps {
  onJoin: (code: string, role: 'PLAYER' | 'SPECTATOR') => void;
  onCancel: () => void;
  error?: string | null;
}

const JoinClubModal: React.FC<JoinClubModalProps> = ({ onJoin, onCancel, error }) => {
  const [code, setCode] = useState('');
  const [selectedRole, setSelectedRole] = useState<'PLAYER' | 'SPECTATOR'>('PLAYER');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (code.trim()) {
      onJoin(code.trim().toUpperCase(), selectedRole);
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300">
      <div className="bg-white rounded-[2rem] shadow-2xl w-full max-w-sm overflow-hidden animate-in zoom-in-95 duration-300">
        <div className="p-6 border-b border-slate-100 flex items-center justify-between">
          <h3 className="text-xl font-bold text-slate-900">Join a Club</h3>
          <button onClick={onCancel} className="p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-8 space-y-6">
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-widest flex items-center gap-2">
              <Hash className="w-3 h-3" />
              Invite Code
            </label>
            <input 
              autoFocus
              type="text" 
              maxLength={10}
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="e.g. TITAN99"
              className={`w-full bg-slate-50 border ${error ? 'border-red-500 ring-2 ring-red-500/10' : 'border-slate-200'} rounded-2xl px-5 py-4 text-center text-2xl font-black tracking-widest text-slate-900 placeholder:text-slate-200 focus:outline-none focus:border-blue-500 transition-all`}
            />
            {error && <p className="text-red-500 text-xs font-bold text-center mt-2">{error}</p>}
          </div>

          <div className="space-y-3">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">Join as</label>
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setSelectedRole('PLAYER')}
                className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${
                  selectedRole === 'PLAYER' 
                    ? 'border-blue-600 bg-blue-50 text-blue-600' 
                    : 'border-slate-100 bg-white text-slate-400 grayscale hover:grayscale-0 hover:border-slate-200'
                }`}
              >
                <UserIcon className="w-6 h-6" />
                <span className="text-xs font-black uppercase tracking-widest">Player</span>
              </button>
              <button
                type="button"
                onClick={() => setSelectedRole('SPECTATOR')}
                className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${
                  selectedRole === 'SPECTATOR' 
                    ? 'border-blue-600 bg-blue-50 text-blue-600' 
                    : 'border-slate-100 bg-white text-slate-400 grayscale hover:grayscale-0 hover:border-slate-200'
                }`}
              >
                <Eye className="w-6 h-6" />
                <span className="text-xs font-black uppercase tracking-widest">Spectator</span>
              </button>
            </div>
          </div>

          <button 
            type="submit"
            className="w-full bg-slate-900 text-white rounded-2xl py-4 font-bold shadow-lg hover:bg-slate-800 transition-all flex items-center justify-center gap-2"
          >
            <Check className="w-5 h-5" />
            Join Team
          </button>
          
          <p className="text-[10px] text-center text-slate-400 font-medium">
            Ask your club admin for the unique invite code.
          </p>
        </form>
      </div>
    </div>
  );
};

export default JoinClubModal;
