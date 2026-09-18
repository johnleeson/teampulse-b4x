
import { auth, db } from '../firebase';
import { 
  collection, 
  doc, 
  getDoc, 
  getDocs, 
  setDoc, 
  deleteDoc, 
  query, 
  where, 
  orderBy, 
  limit, 
  Timestamp,
  getDocFromServer
} from 'firebase/firestore';
import { Club, Match, FeedEvent, User, UserRole } from '../types';
import { AppState } from '../store';

export enum OperationType {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
  LIST = 'list',
  GET = 'get',
  WRITE = 'write',
}

interface FirestoreErrorInfo {
  error: string;
  operationType: OperationType;
  path: string | null;
  authInfo: {
    userId: string | undefined;
    email: string | null | undefined;
    emailVerified: boolean | undefined;
    isAnonymous: boolean | undefined;
    tenantId: string | null | undefined;
    providerInfo: {
      providerId: string;
      displayName: string | null;
      email: string | null;
      photoUrl: string | null;
    }[];
  }
}

export function handleFirestoreError(error: unknown, operationType: OperationType, path: string | null) {
  const errInfo: FirestoreErrorInfo = {
    error: error instanceof Error ? error.message : String(error),
    authInfo: {
      userId: auth.currentUser?.uid,
      email: auth.currentUser?.email,
      emailVerified: auth.currentUser?.emailVerified,
      isAnonymous: auth.currentUser?.isAnonymous,
      tenantId: auth.currentUser?.tenantId,
      providerInfo: auth.currentUser?.providerData.map(provider => ({
        providerId: provider.providerId,
        displayName: provider.displayName,
        email: provider.email,
        photoUrl: provider.photoURL
      })) || []
    },
    operationType,
    path
  }
  console.error('Firestore Error: ', JSON.stringify(errInfo));
  throw new Error(JSON.stringify(errInfo));
}

export const dbService = {
  /**
   * Translates a raw Firestore match document to the Match frontend type.
   */
  mapMatch(m: any, id: string): Match {
    return {
      id: id,
      clubId: m.clubId,
      title: m.title,
      date: m.date,
      meetTime: m.meetTime,
      kickOffTime: m.kickOffTime,
      location: m.location,
      status: m.status,
      scoreA: m.scoreA,
      scoreB: m.scoreB,
      signedUpPlayerIds: m.signedUpPlayerIds || [],
      availability: m.availability || {},
      opponentName: m.opponentName,
      isHome: m.isHome,
      potmVotes: m.potmVotes || {},
      aiSummary: m.aiSummary,
      managerSummary: m.managerSummary,
      startingLineupIds: m.startingLineupIds || [],
      benchIds: m.benchIds || [],
      starPlayerIds: m.starPlayerIds || [],
      weakerPlayerIds: m.weakerPlayerIds || [],
      teamA: m.teamA || [], 
      teamB: m.teamB || [],
      playerStats: m.playerStats || {},
      formation: m.formation || '4-4-2',
      tacticalLineup: m.tacticalLineup || {}
    };
  },

  /**
   * Translates a raw Firestore event document to the FeedEvent frontend type.
   */
  mapEvent(e: any, id: string): FeedEvent {
    let timestamp: Date;
    if (e.timestamp instanceof Timestamp) {
      timestamp = e.timestamp.toDate();
    } else if (typeof e.timestamp === 'string') {
      timestamp = new Date(e.timestamp);
    } else {
      timestamp = new Date();
    }

    return {
      ...e,
      id: id,
      matchId: e.matchId,
      userId: e.userId,
      userName: e.userName,
      type: e.type,
      content: e.content,
      details: e.details,
      mediaUrl: e.mediaUrl,
      timestamp: timestamp
    };
  },

  async fetchInitialData(): Promise<Partial<AppState>> {
    try {
      // Test connection
      try {
        await getDocFromServer(doc(db, 'test', 'connection'));
      } catch (e) {}

      const clubsSnap = await getDocs(collection(db, 'clubs'));
      const clubs = clubsSnap.docs.map(d => ({ ...d.data(), id: d.id } as any));

      const matchesSnap = await getDocs(query(collection(db, 'matches'), orderBy('date', 'asc')));
      const matches = matchesSnap.docs.map(d => this.mapMatch(d.data(), d.id));

      const eventsSnap = await getDocs(query(collection(db, 'feed_events'), orderBy('timestamp', 'desc'), limit(100)));
      const feedEvents = eventsSnap.docs.map(d => this.mapEvent(d.data(), d.id));

      // Fetch members for each club
      const clubsWithMembers = await Promise.all(clubs.map(async (c: any) => {
        const membersSnap = await getDocs(query(collection(db, 'club_members'), where('clubId', '==', c.id)));
        const members = await Promise.all(membersSnap.docs.map(async (md) => {
          const mData = md.data();
          const profileSnap = await getDoc(doc(db, 'profiles', mData.userId));
          const pData = profileSnap.data();
          return {
            id: mData.userId,
            name: pData?.name || 'Unknown',
            avatar: pData?.avatar || '',
            roles: mData.roles || ['PLAYER'],
            age: pData?.age || null,
            gender: pData?.gender || null,
            favPosition: pData?.favPosition || null,
            kitSize: pData?.kitSize || null,
            abilityRating: mData.abilityRating || 0
          };
        }));
        return {
          id: c.id,
          name: c.name,
          logo: c.logo,
          description: c.description,
          type: c.type,
          ownerId: c.ownerId,
          inviteCode: c.inviteCode,
          ageGroup: c.ageGroup || null,
          gender: c.gender || null,
          teamPhoto: c.teamPhoto || null,
          members
        };
      }));

      return {
        clubs: clubsWithMembers,
        matches,
        feedEvents
      };
    } catch (error) {
      handleFirestoreError(error, OperationType.GET, 'initial_data');
      return {};
    }
  },

  async saveProfile(user: User): Promise<void> {
    try {
      await setDoc(doc(db, 'profiles', user.id), {
        name: user.name,
        avatar: user.avatar,
        roles: user.roles,
        age: user.age || null,
        gender: user.gender || null,
        favPosition: user.favPosition || null,
        kitSize: user.kitSize || null
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `profiles/${user.id}`);
    }
  },

  async getClubByInviteCode(code: string): Promise<Club | null> {
    try {
      const q = query(collection(db, 'clubs'), where('inviteCode', '==', code), limit(1));
      const snap = await getDocs(q);
      if (snap.empty) return null;
      const data = snap.docs[0].data();
      return {
        id: snap.docs[0].id,
        name: data.name,
        logo: data.logo,
        description: data.description,
        type: data.type,
        ownerId: data.ownerId,
        inviteCode: data.inviteCode,
        members: [] 
      };
    } catch (error) {
      handleFirestoreError(error, OperationType.GET, 'clubs_by_invite');
      return null;
    }
  },

  async saveClub(club: Club, owner: User): Promise<void> {
    try {
      await this.saveProfile(owner);
      await setDoc(doc(db, 'clubs', club.id), {
        name: club.name,
        logo: club.logo,
        description: club.description,
        type: club.type,
        ownerId: owner.id,
        inviteCode: club.inviteCode,
        ageGroup: club.ageGroup || null,
        gender: club.gender || null,
        teamPhoto: club.teamPhoto || null
      }, { merge: true });

      // Use the roles defined for the owner in the club's members list if available
      const ownerInMembers = club.members.find(m => m.id === owner.id);
      const roles = ownerInMembers?.roles || ['ADMIN', 'PLAYER'];

      await setDoc(doc(db, 'club_members', `${club.id}_${owner.id}`), {
        clubId: club.id,
        userId: owner.id,
        roles: roles
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `clubs/${club.id}`);
    }
  },

  async deleteClub(clubId: string): Promise<void> {
    try {
      await deleteDoc(doc(db, 'clubs', clubId));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `clubs/${clubId}`);
    }
  },

  async saveMatch(match: Match): Promise<void> {
    try {
      await setDoc(doc(db, 'matches', match.id), {
        clubId: match.clubId,
        title: match.title,
        date: match.date,
        meetTime: match.meetTime || '',
        kickOffTime: match.kickOffTime,
        location: match.location,
        status: match.status,
        scoreA: match.scoreA || 0,
        scoreB: match.scoreB || 0,
        signedUpPlayerIds: match.signedUpPlayerIds || [],
        availability: match.availability || {},
        opponentName: match.opponentName || '',
        isHome: !!match.isHome,
        potmVotes: match.potmVotes || {},
        aiSummary: match.aiSummary || '',
        managerSummary: match.managerSummary || '',
        startingLineupIds: match.startingLineupIds || [],
        benchIds: match.benchIds || [],
        starPlayerIds: match.starPlayerIds || [],
        weakerPlayerIds: match.weakerPlayerIds || [],
        teamA: match.teamA || [],
        teamB: match.teamB || [],
        playerStats: match.playerStats || {},
        formation: match.formation || '4-4-2',
        tacticalLineup: match.tacticalLineup || {}
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `matches/${match.id}`);
    }
  },

  async deleteMatch(matchId: string): Promise<void> {
    try {
      await deleteDoc(doc(db, 'matches', matchId));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `matches/${matchId}`);
    }
  },

  async saveEvent(event: FeedEvent): Promise<void> {
    try {
      await setDoc(doc(db, 'feed_events', event.id), {
        matchId: event.matchId,
        userId: event.userId,
        userName: event.userName,
        type: event.type,
        timestamp: Timestamp.fromDate(event.timestamp),
        content: event.content,
        details: event.details || {},
        mediaUrl: event.mediaUrl || null
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `feed_events/${event.id}`);
    }
  },

  async deleteEvent(eventId: string): Promise<void> {
    try {
      await deleteDoc(doc(db, 'feed_events', eventId));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `feed_events/${eventId}`);
    }
  },

  async joinClub(clubId: string, userId: string, roles: UserRole[]): Promise<void> {
    try {
      await setDoc(doc(db, 'club_members', `${clubId}_${userId}`), {
        clubId: clubId,
        userId: userId,
        roles: roles
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `club_members/${clubId}_${userId}`);
    }
  },

  async updateMemberRoles(clubId: string, userId: string, roles: UserRole[]): Promise<void> {
    try {
      await setDoc(doc(db, 'club_members', `${clubId}_${userId}`), {
        roles: roles
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `club_members/${clubId}_${userId}`);
    }
  },

  async removeMember(clubId: string, userId: string): Promise<void> {
    try {
      await deleteDoc(doc(db, 'club_members', `${clubId}_${userId}`));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `club_members/${clubId}_${userId}`);
    }
  },

  async addMember(clubId: string, member: User): Promise<void> {
    try {
      // Try to save profile, but don't let it block the member addition if it fails (e.g. already exists or permission)
      try {
        await this.saveProfile(member);
      } catch (e) {
        console.warn("Profile save failed during addMember, continuing...", e);
      }
      
      await setDoc(doc(db, 'club_members', `${clubId}_${member.id}`), {
        clubId: clubId,
        userId: member.id,
        roles: member.roles
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `club_members/${clubId}_${member.id}`);
    }
  },

  async updateMemberRating(clubId: string, userId: string, rating: number): Promise<void> {
    try {
      await setDoc(doc(db, 'club_members', `${clubId}_${userId}`), {
        abilityRating: rating
      }, { merge: true });
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, `club_members/${clubId}_${userId}`);
    }
  }
};
