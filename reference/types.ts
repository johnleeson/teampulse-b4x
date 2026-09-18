
export type UserRole = 'ADMIN' | 'PLAYER' | 'SPECTATOR';
export type ClubType = 'TEAM' | 'SOCIAL';

export interface User {
  id: string;
  name: string;
  avatar: string;
  roles: UserRole[];
  age?: string;
  gender?: string;
  favPosition?: string;
  kitSize?: string;
  abilityRating?: number;
}

export interface Club {
  id: string;
  name: string;
  logo: string;
  description: string;
  type: ClubType;
  members: User[];
  ownerId: string;
  inviteCode?: string;
  ageGroup?: string;
  gender?: 'Boys' | 'Girls' | 'Mixed';
  teamPhoto?: string;
}

export interface Match {
  id: string;
  clubId: string;
  title: string;
  date: string;
  meetTime?: string;
  kickOffTime: string;
  location: string;
  status: 'UPCOMING' | 'LIVE' | 'COMPLETED' | 'CANCELLED';
  teamA: string[]; // Player IDs
  teamB: string[]; // Player IDs
  scoreA: number;
  scoreB: number;
  signedUpPlayerIds: string[];
  availability?: Record<string, 'CONFIRMED' | 'UNAVAILABLE'>;
  opponentName?: string;
  isHome?: boolean;
  potmVotes?: Record<string, string>; // userId -> votedPlayerId
  aiSummary?: string;
  managerSummary?: string;
  startingLineupIds?: string[]; // For TEAM matches
  benchIds?: string[]; // For TEAM matches
  starPlayerIds?: string[]; // For highlighting and sub balancing
  weakerPlayerIds?: string[]; // For highlighting and sub balancing
  formation?: string; // e.g., '4-4-2', '4-3-3'
  tacticalLineup?: Record<string, string>; // positionId -> playerId
  playerStats?: Record<string, PlayerStats>; // userId -> stats
}

export interface PlayerStats {
  goals: number;
  assists: number;
  yellowCards: number;
  redCards: number;
  ballsOverFence?: number;
  isInjured?: boolean;
  isLastMinuteDropout?: boolean;
  minutesPlayed?: number;
}

export type EventType = 'GOAL' | 'SUB' | 'COMMENT' | 'MEDIA' | 'START' | 'HALF_TIME' | 'SECOND_HALF' | 'END' | 'CORNER' | 'FREE_KICK' | 'PENALTY' | 'YELLOW_CARD' | 'RED_CARD' | 'CANCELLED';

export interface FeedEvent {
  id: string;
  matchId: string;
  userId: string;
  userName: string;
  type: EventType;
  timestamp: Date;
  content: string;
  mediaUrl?: string;
  details?: {
    playerIn?: string;
    playerOut?: string;
    scorer?: string;
    assist?: string;
    player?: string;
    team?: 'A' | 'B';
  };
}

export interface Message {
  id: string;
  senderId: string;
  senderName: string;
  text: string;
  timestamp: Date;
}

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  timestamp: Date;
  isRead: boolean;
  type: 'MATCH_START' | 'GOAL' | 'SUB' | 'SYSTEM';
  linkId?: string;
}
