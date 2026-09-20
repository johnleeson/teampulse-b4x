
import { Club, Match, User, FeedEvent, Message, AppNotification } from './types';

const STORAGE_KEY = 'teampulse_data_v1';

export interface AppState {
  clubs: Club[];
  matches: Match[];
  feedEvents: FeedEvent[];
  messages: Record<string, Message[]>;
  currentUser: User | null;
  notifications: AppNotification[];
}

export const DUMMY_USERS: User[] = [
  { id: '00000000-0000-0000-0000-000000000001', name: 'Alex Johnson', avatar: 'https://i.pravatar.cc/150?u=u1', roles: ['ADMIN', 'PLAYER'] },
  { id: '00000000-0000-0000-0000-000000000002', name: 'Sam Smith', avatar: 'https://i.pravatar.cc/150?u=u2', roles: ['PLAYER'] },
  { id: '00000000-0000-0000-0000-000000000003', name: 'Jordan Lee', avatar: 'https://i.pravatar.cc/150?u=u3', roles: ['PLAYER'] },
  { id: '00000000-0000-0000-0000-000000000004', name: 'Casey Wright', avatar: 'https://i.pravatar.cc/150?u=u4', roles: ['PLAYER'] },
  { id: '00000000-0000-0000-0000-000000000005', name: 'Charlie Brown', avatar: 'https://i.pravatar.cc/150?u=u5', roles: ['SPECTATOR'] },
];

const INITIAL_STATE: AppState = {
  currentUser: null,
  clubs: [],
  matches: [],
  feedEvents: [],
  notifications: [
    {
      id: 'n1',
      title: 'Welcome to TeamPulse!',
      body: 'Get started by creating a club or joining one with an invite code.',
      timestamp: new Date(),
      isRead: false,
      type: 'SYSTEM'
    }
  ],
  messages: {}
};

export const loadData = (): AppState => {
  const data = localStorage.getItem(STORAGE_KEY);
  if (!data) return INITIAL_STATE;
  
  try {
    const parsed = JSON.parse(data);
    
    if (parsed.notifications) {
      parsed.notifications = parsed.notifications.map((n: any) => ({ 
        ...n, 
        timestamp: new Date(n.timestamp) 
      }));
    }
    
    if (parsed.feedEvents) {
      parsed.feedEvents = parsed.feedEvents.map((e: any) => ({
        ...e,
        timestamp: new Date(e.timestamp)
      }));
    }

    if (parsed.messages) {
      Object.keys(parsed.messages).forEach(key => {
        parsed.messages[key] = parsed.messages[key].map((m: any) => ({
          ...m,
          timestamp: new Date(m.timestamp)
        }));
      });
    }

    return {
      ...INITIAL_STATE,
      ...parsed,
      clubs: parsed.clubs || INITIAL_STATE.clubs,
      matches: parsed.matches || INITIAL_STATE.matches,
      currentUser: parsed.currentUser || null
    };
  } catch (error) {
    console.error("Failed to rehydrate app state:", error);
    return INITIAL_STATE;
  }
};

export const saveData = (state: AppState) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
};

export const generateInviteCode = () => {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
};
