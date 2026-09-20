
import React, { useState } from 'react';
import { User, UserRole } from '../types';
import { Trophy, ArrowRight, Mail, Lock, User as UserIcon, Eye, AlertCircle, Loader2, ShieldCheck, Zap, Shield } from 'lucide-react';
import { supabase, isSupabaseEnabled } from '../lib/supabase';
import { dbService } from '../services/dbService';

interface LoginProps {
  onLogin: (user: User) => void;
}

const Login: React.FC<LoginProps> = ({ onLogin }) => {
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState<UserRole>('PLAYER');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isSupabaseEnabled || !supabase) {
      setError("Supabase configuration missing. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in Vercel.");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      if (isSignUp) {
        // 1. Sign up user in Supabase Auth
        const { data, error: signUpError } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: { 
              full_name: name,
              primary_role: role 
            }
          }
        });

        if (signUpError) throw signUpError;
        if (data.user) {
          // 2. Create the associated profile record in our custom table
          const newUser: User = {
            id: data.user.id,
            name: name,
            avatar: `https://i.pravatar.cc/150?u=${data.user.id}`,
            roles: [role]
          };
          await dbService.saveProfile(newUser);
          onLogin(newUser);
        }
      } else {
        // Sign in existing user
        const { data, error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (signInError) throw signInError;
        if (data.user) {
          // Fetch their custom profile data
          const { data: profile } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', data.user.id)
            .single();
          
          if (profile) {
            onLogin({
              id: profile.id,
              name: profile.name,
              avatar: profile.avatar || `https://i.pravatar.cc/150?u=${profile.id}`,
              roles: profile.roles || ['SPECTATOR']
            });
          } else {
            // Fallback if profile doesn't exist yet
            onLogin({
              id: data.user.id,
              name: data.user.user_metadata?.full_name || 'User',
              avatar: `https://i.pravatar.cc/150?u=${data.user.id}`,
              roles: ['SPECTATOR']
            });
          }
        }
      }
    } catch (err: any) {
      setError(err.message || "Authentication failed. Please check your credentials.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4 selection:bg-blue-500/30">
      {/* Animated Glow Background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-[-20%] left-[-10%] w-[70%] h-[70%] bg-blue-600/10 blur-[150px] rounded-full animate-pulse"></div>
        <div className="absolute bottom-[-20%] right-[-10%] w-[70%] h-[70%] bg-indigo-600/10 blur-[150px] rounded-full animate-pulse" style={{ animationDelay: '2s' }}></div>
      </div>

      <div className="max-w-md w-full relative z-10 animate-in fade-in zoom-in-95 duration-700">
        <div className="bg-slate-900/80 backdrop-blur-2xl rounded-[3rem] shadow-2xl border border-white/5 p-8 md:p-12">
          <div className="flex flex-col items-center text-center mb-10">
            <div className="bg-gradient-to-br from-blue-500 to-indigo-600 p-5 rounded-[2rem] text-white mb-6 shadow-2xl shadow-blue-500/20 ring-4 ring-white/5">
              <Trophy className="w-10 h-10" />
            </div>
            <h1 className="text-4xl font-black text-white tracking-tight mb-2">TeamPulse</h1>
            <p className="text-slate-400 font-medium tracking-wide">Grassroots sports, professionalized.</p>
          </div>

          <div className="flex p-1.5 bg-slate-800/50 rounded-[1.5rem] mb-10 border border-white/5">
            <button 
              type="button"
              onClick={() => setIsSignUp(false)}
              className={`flex-1 py-3.5 rounded-2xl text-[10px] font-black uppercase tracking-[0.2em] transition-all ${!isSignUp ? 'bg-white text-blue-600 shadow-xl' : 'text-slate-500 hover:text-slate-300'}`}
            >
              Sign In
            </button>
            <button 
              type="button"
              onClick={() => setIsSignUp(true)}
              className={`flex-1 py-3.5 rounded-2xl text-[10px] font-black uppercase tracking-[0.2em] transition-all ${isSignUp ? 'bg-white text-blue-600 shadow-xl' : 'text-slate-500 hover:text-slate-300'}`}
            >
              Sign Up
            </button>
          </div>

          <form onSubmit={handleAuth} className="space-y-6">
            {error && (
              <div className="bg-red-500/10 border border-red-500/20 p-4 rounded-[1.5rem] flex items-center gap-3 text-red-400 animate-in slide-in-from-top-2">
                <AlertCircle className="w-5 h-5 shrink-0" />
                <p className="text-xs font-bold leading-relaxed">{error}</p>
              </div>
            )}

            {isSignUp && (
              <div className="space-y-2">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-4">Full Name</label>
                <div className="relative">
                  <UserIcon className="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
                  <input 
                    type="text" 
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Alex Johnson"
                    className="w-full bg-slate-800/50 border border-white/5 rounded-[1.5rem] pl-14 pr-6 py-4.5 text-white placeholder:text-slate-600 focus:outline-none focus:ring-4 focus:ring-blue-500/20 focus:border-blue-500/50 transition-all font-semibold"
                    required={isSignUp}
                  />
                </div>
              </div>
            )}

            <div className="space-y-2">
              <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-4">Email</label>
              <div className="relative">
                <Mail className="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
                <input 
                  type="email" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="alex@example.com"
                  className="w-full bg-slate-800/50 border border-white/5 rounded-[1.5rem] pl-14 pr-6 py-4.5 text-white placeholder:text-slate-600 focus:outline-none focus:ring-4 focus:ring-blue-500/20 focus:border-blue-500/50 transition-all font-semibold"
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-4">Password</label>
              <div className="relative">
                <Lock className="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
                <input 
                  type="password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-slate-800/50 border border-white/5 rounded-[1.5rem] pl-14 pr-6 py-4.5 text-white placeholder:text-slate-600 focus:outline-none focus:ring-4 focus:ring-blue-500/20 focus:border-blue-500/50 transition-all font-semibold"
                  required
                />
              </div>
            </div>

            {isSignUp && (
              <div className="space-y-4 pt-2">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest text-center block">Account Type</label>
                <div className="grid grid-cols-3 gap-4">
                  <button
                    type="button"
                    onClick={() => setRole('PLAYER')}
                    className={`flex flex-col items-center gap-3 p-5 rounded-[2rem] border-2 transition-all ${role === 'PLAYER' ? 'border-blue-500 bg-blue-500/10 text-blue-400' : 'border-white/5 bg-slate-800/30 text-slate-500 hover:border-white/10'}`}
                  >
                    <Zap className="w-6 h-6" />
                    <span className="text-[10px] font-black uppercase tracking-widest">Player</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setRole('COACH')}
                    className={`flex flex-col items-center gap-3 p-5 rounded-[2rem] border-2 transition-all ${role === 'COACH' ? 'border-purple-500 bg-purple-500/10 text-purple-400' : 'border-white/5 bg-slate-800/30 text-slate-500 hover:border-white/10'}`}
                  >
                    <Shield className="w-6 h-6" />
                    <span className="text-[10px] font-black uppercase tracking-widest">Coach</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setRole('SPECTATOR')}
                    className={`flex flex-col items-center gap-3 p-5 rounded-[2rem] border-2 transition-all ${role === 'SPECTATOR' ? 'border-blue-500 bg-blue-500/10 text-blue-400' : 'border-white/5 bg-slate-800/30 text-slate-500 hover:border-white/10'}`}
                  >
                    <Eye className="w-6 h-6" />
                    <span className="text-[10px] font-black uppercase tracking-widest">Fan</span>
                  </button>
                </div>
              </div>
            )}

            <button 
              type="submit"
              disabled={loading}
              className="w-full bg-blue-600 text-white rounded-[1.5rem] py-5 font-black text-[10px] uppercase tracking-[0.25em] shadow-2xl shadow-blue-500/40 hover:bg-blue-500 hover:translate-y-[-2px] active:translate-y-0 transition-all flex items-center justify-center gap-3 disabled:opacity-50 disabled:translate-y-0 mt-4"
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <>
                  {isSignUp ? 'Create Account' : 'Sign In'}
                  <ArrowRight className="w-5 h-5" />
                </>
              )}
            </button>
          </form>

          <div className="mt-12 text-center">
            <div className="flex items-center justify-center gap-2 text-[9px] text-slate-600 font-black leading-relaxed uppercase tracking-[0.3em]">
              <ShieldCheck className="w-3 h-3" />
              <span>{isSupabaseEnabled ? 'Real-time Auth Active' : 'Offline Mode'}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
