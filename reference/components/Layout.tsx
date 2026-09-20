
import React from 'react';
import { NAV_ITEMS, COLORS } from '../constants';
import { Trophy, LogOut, Bell, Search, Shield, RefreshCcw, CloudOff, Zap, WifiOff, BellOff } from 'lucide-react';
import { User, Club } from '../types';
import { isSupabaseEnabled } from '../lib/supabase';

interface LayoutProps {
  activeTab: string;
  onTabChange: (id: string) => void;
  currentUser: User | null;
  onLogout: () => void;
  children: React.ReactNode;
  clubs?: Club[];
  notificationCount?: number;
  onOpenNotifications?: () => void;
  isSyncing?: boolean;
  isPulsing?: boolean;
  realtimeStatus?: 'SUBSCRIBED' | 'TIMED_OUT' | 'CLOSED' | 'CHANNEL_ERROR' | 'INITIAL' | 'CONNECTING';
  notifPermission?: NotificationPermission;
  onRequestNotifPermission?: () => void;
}

const Layout: React.FC<LayoutProps> = ({ 
  activeTab, 
  onTabChange, 
  currentUser, 
  onLogout, 
  children, 
  clubs = [], 
  notificationCount = 0, 
  onOpenNotifications,
  isSyncing = false,
  isPulsing = false,
  realtimeStatus = 'INITIAL',
  notifPermission = 'default',
  onRequestNotifPermission
}) => {
  if (!currentUser) return <>{children}</>;

  const allUserRoles = clubs
    .filter(c => c.members.some(m => m.id === currentUser.id))
    .flatMap(c => c.members.find(m => m.id === currentUser.id)?.roles || []);
  
  const hasAdmin = allUserRoles.includes('ADMIN');
  const hasPlayer = allUserRoles.includes('PLAYER');
  
  let roleLabel = 'Spectator';
  if (hasAdmin) roleLabel = 'Administrator';
  else if (hasPlayer) roleLabel = 'Player';

  const getStatusConfig = () => {
    if (!isSupabaseEnabled) return { label: 'Local Mode', icon: <CloudOff className="w-3 h-3" />, color: 'bg-amber-50 text-amber-600 border-amber-100' };
    
    switch (realtimeStatus) {
      case 'SUBSCRIBED': 
        return { label: 'Live', icon: <Zap className="w-3 h-3 fill-current" />, color: isPulsing ? 'bg-blue-600 text-white border-blue-700' : 'bg-green-50 text-green-600 border-green-100' };
      case 'CONNECTING':
      case 'INITIAL':
        return { label: 'Connecting...', icon: <RefreshCcw className="w-3 h-3 animate-sync" />, color: 'bg-blue-50 text-blue-600 border-blue-100' };
      case 'CHANNEL_ERROR':
      case 'TIMED_OUT':
        return { label: 'Sync Error', icon: <WifiOff className="w-3 h-3" />, color: 'bg-red-50 text-red-600 border-red-100' };
      default:
        return { label: 'Disconnected', icon: <WifiOff className="w-3 h-3" />, color: 'bg-slate-100 text-slate-500 border-slate-200' };
    }
  };

  const statusConfig = getStatusConfig();

  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-slate-200 hidden md:flex flex-col">
        <div className="p-6 flex items-center gap-3">
          <div className="bg-blue-600 p-2 rounded-lg text-white">
            <Trophy className="w-6 h-6" />
          </div>
          <span className="font-bold text-xl tracking-tight text-slate-900">TeamPulse</span>
        </div>

        <nav className="flex-1 px-4 py-4 space-y-1">
          {NAV_ITEMS.map((item) => (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                activeTab === item.id
                  ? 'bg-blue-600 text-white shadow-lg shadow-blue-200'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              {item.icon}
              <span className="font-medium">{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-slate-200">
          <button 
            onClick={onLogout}
            className="flex items-center gap-3 px-4 py-3 text-slate-600 hover:text-red-500 w-full transition-colors"
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Sign Out</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
      <header className="min-h-16 pt-[env(safe-area-inset-top)] bg-white border-b border-slate-200 flex items-center justify-between px-6 sticky top-0 z-10 shadow-sm">
        {/* <header className="h-16 bg-white border-bottom border-slate-200 flex items-center justify-between px-6 sticky top-0 z-10 shadow-sm"> */}
          <div className="flex items-center gap-4 bg-slate-100 px-4 py-2 rounded-full w-full max-w-md">
            <Search className="w-4 h-4 text-slate-400" />
            <input 
              type="text" 
              placeholder="Search..." 
              className="bg-transparent outline-none w-full text-sm text-slate-700"
            />
          </div>
          
          <div className="flex items-center gap-4">
            {/* Notif Status */}
            {notifPermission !== 'granted' && (
              <button 
                onClick={onRequestNotifPermission}
                className="flex items-center gap-2 px-3 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest bg-amber-50 text-amber-600 border border-amber-100 hover:bg-amber-100 transition-all"
                title="Notifications are blocked"
              >
                <BellOff className="w-3 h-3" />
                Enable Alerts
              </button>
            )}

            {/* Sync Indicator */}
            <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest transition-all duration-300 border ${statusConfig.color}`}>
              {statusConfig.icon}
              <span className="hidden sm:inline">
                {isSyncing ? 'Refreshing...' : statusConfig.label}
              </span>
            </div>

            <button 
              onClick={onOpenNotifications}
              className="p-2 text-slate-500 hover:bg-slate-100 rounded-full relative group transition-all"
            >
              <Bell className="w-5 h-5 group-hover:rotate-12" />
              {notificationCount > 0 && (
                <span className="absolute top-1 right-1 w-4 h-4 bg-red-500 text-white text-[9px] font-black rounded-full border-2 border-white flex items-center justify-center pulse-notification">
                  {notificationCount > 9 ? '9+' : notificationCount}
                </span>
              )}
            </button>
            <div className="flex items-center gap-3 border-l border-slate-200 pl-4 ml-2">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-semibold text-slate-900 leading-tight">{currentUser.name}</p>
                <div className="flex items-center justify-end gap-1">
                  {hasAdmin && <Shield className="w-2.5 h-2.5 text-blue-500" />}
                  <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">{roleLabel}</p>
                </div>
              </div>
              <img 
                src={currentUser.avatar} 
                alt="Profile" 
                className="w-10 h-10 rounded-full border-2 border-white shadow-sm object-cover"
              />
            </div>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-4 md:p-8">
          {children}
        </main>
      </div>

      {/* Mobile Nav */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 flex justify-around px-2 z-50 pb-[env(safe-area-inset-bottom)] h-[calc(64px+env(safe-area-inset-bottom))]">
          {NAV_ITEMS.slice(0, 4).map((item) => (
          <button
            key={item.id}
            onClick={() => onTabChange(item.id)}
            className={`flex flex-col items-center gap-1 transition-colors ${
              activeTab === item.id ? 'text-blue-600' : 'text-slate-400'
            }`}
          >
            {item.icon}
            <span className="text-[10px] font-medium">{item.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default Layout;
