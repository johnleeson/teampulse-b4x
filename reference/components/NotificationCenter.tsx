
import React from 'react';
import { AppNotification } from '../types';
import { X, Bell, Trophy, Zap, Info, Clock, CheckCheck, Play, Flag, AlertTriangle, AlertOctagon } from 'lucide-react';

interface NotificationCenterProps {
  notifications: AppNotification[];
  onClose: () => void;
  onMarkRead: (id: string) => void;
  onMarkAllRead: () => void;
}

const NotificationCenter: React.FC<NotificationCenterProps> = ({ notifications, onClose, onMarkRead, onMarkAllRead }) => {
  const sorted = [...notifications].sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  const unreadCount = notifications.filter(n => !n.isRead).length;

  const getIcon = (type: AppNotification['type'], body: string) => {
    if (body.includes('YELLOW')) return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
    if (body.includes('RED CARD')) return <AlertOctagon className="w-4 h-4 text-red-600" />;
    
    switch (type) {
      case 'GOAL': return <Trophy className="w-4 h-4 text-green-500" />;
      case 'MATCH_START': return <Play className="w-4 h-4 text-blue-500 fill-current" />;
      case 'SUB': return <Clock className="w-4 h-4 text-orange-500" />;
      default: 
        if (body.includes('Full time') || body.includes('ended')) return <Flag className="w-4 h-4 text-slate-900" />;
        return <Info className="w-4 h-4 text-slate-400" />;
    }
  };

  return (
    // Change this line:
    // <div className="fixed inset-y-0 right-0 w-full max-w-sm bg-white/95 backdrop-blur-xl border-l border-slate-200 shadow-2xl z-[150] animate-in slide-in-from-right duration-300 pt-[env(safe-area-inset-top)]">

    // To this (adding pt-[env(safe-area-inset-top)]):
    <div className="fixed inset-y-0 right-0 w-full max-w-sm bg-white/95 backdrop-blur-xl border-l border-slate-200 shadow-2xl z-[150] animate-in slide-in-from-right duration-300 pt-[env(safe-area-inset-top)] mt-5">
     
      <div className="flex flex-col h-full">
        <div className="p-6 border-b border-slate-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-slate-900 text-white p-2 rounded-xl">
              <Bell className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-xl font-black text-slate-900 tracking-tight">Alert Center</h2>
              <p className="text-xs text-slate-500 font-medium">You have {unreadCount} unread alerts</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-full transition-colors">
            <X className="w-5 h-5 text-slate-400" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-4 space-y-3 scrollbar-hide">
          {sorted.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-center p-10">
              <div className="p-5 bg-slate-50 rounded-full mb-4">
                <Bell className="w-10 h-10 text-slate-200" />
              </div>
              <h3 className="font-bold text-slate-900">Quiet for now</h3>
              <p className="text-xs text-slate-500 mt-1">We'll alert you about match updates, club activity, and goal highlights.</p>
            </div>
          ) : (
            sorted.map((notif) => (
              <div 
                key={notif.id} 
                onClick={() => onMarkRead(notif.id)}
                className={`p-4 rounded-2xl border transition-all cursor-pointer group ${
                  notif.isRead ? 'bg-white border-slate-100 opacity-60' : 'bg-blue-50/30 border-blue-100 ring-1 ring-blue-50'
                }`}
              >
                <div className="flex gap-4">
                  <div className={`shrink-0 w-10 h-10 rounded-xl flex items-center justify-center ${
                    notif.isRead ? 'bg-slate-50' : 'bg-white shadow-sm border border-blue-50'
                  }`}>
                    {getIcon(notif.type, notif.body)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-0.5">
                      <h4 className={`text-[10px] font-black uppercase tracking-widest truncate mr-2 ${notif.isRead ? 'text-slate-400' : 'text-slate-900'}`}>
                        {notif.title}
                      </h4>
                      <span className="text-[9px] font-bold text-slate-400 shrink-0">
                        {new Date(notif.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <p className={`text-xs leading-relaxed font-medium ${notif.isRead ? 'text-slate-400' : 'text-slate-700'}`}>
                      {notif.body}
                    </p>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {notifications.length > 0 && (
          <div className="p-4 border-t border-slate-100">
            <button 
              onClick={onMarkAllRead}
              className="w-full py-4 bg-slate-900 text-white rounded-xl font-black text-[10px] uppercase tracking-[0.2em] flex items-center justify-center gap-2 hover:bg-black transition-all shadow-lg"
            >
              <CheckCheck className="w-4 h-4" />
              Clear all alerts
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default NotificationCenter;
