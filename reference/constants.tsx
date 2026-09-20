
import React from 'react';
import { 
  Trophy, 
  Users, 
  Calendar, 
  MessageSquare, 
  Activity, 
  Plus, 
  Search, 
  ChevronRight, 
  Goal, 
  ArrowRightLeft, 
  Camera, 
  Send,
  MoreVertical,
  BarChart2,
  Settings,
  CreditCard
} from 'lucide-react';

export const COLORS = {
  primary: '#0f172a',
  secondary: '#3b82f6',
  accent: '#f59e0b',
  success: '#10b981',
  danger: '#ef4444',
  muted: '#64748b'
};

export const NAV_ITEMS = [
  { id: 'dashboard', label: 'Dashboard', icon: <Activity className="w-5 h-5" /> },
  { id: 'clubs', label: 'My Clubs', icon: <Users className="w-5 h-5" /> },
  { id: 'matches', label: 'Matches', icon: <Calendar className="w-5 h-5" /> },
  //{ id: 'messages', label: 'Chat', icon: <MessageSquare className="w-5 h-5" /> },
  { id: 'stats', label: 'Statistics', icon: <BarChart2 className="w-5 h-5" /> },
  //{ id: 'payments', label: 'Payments', icon: <CreditCard className="w-5 h-5" /> },
];

export const MOCK_USER: any = {
  id: 'u1',
  name: 'Alex Johnson',
  avatar: 'https://picsum.photos/seed/u1/100/100',
  role: 'ADMIN'
};
