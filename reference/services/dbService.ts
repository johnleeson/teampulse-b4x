
import { supabase, isSupabaseEnabled } from '../lib/supabase';
import { Club, Match, FeedEvent, User, UserRole, PotmVotes } from '../types';
import { AppState } from '../store';

/** Normalize legacy flat potm_votes or new category-shaped object. */
export function normalizePotmVotes(raw: unknown): PotmVotes {
  if (!raw || typeof raw !== 'object') {
    return { coach: {}, fans: {}, fanCounts: {}, opposition: {} };
  }
  const obj = raw as Record<string, unknown>;
  if (
    obj.coach !== undefined ||
    obj.fans !== undefined ||
    obj.fanCounts !== undefined ||
    obj.opposition !== undefined
  ) {
    const fanCountsRaw = obj.fanCounts && typeof obj.fanCounts === 'object' ? obj.fanCounts as Record<string, unknown> : {};
    const fanCounts: Record<string, number> = {};
    Object.entries(fanCountsRaw).forEach(([playerId, value]) => {
      const n = typeof value === 'number' ? value : Number(value);
      if (Number.isFinite(n) && n > 0) fanCounts[playerId] = Math.floor(n);
    });
    return {
      coach: (obj.coach && typeof obj.coach === 'object' ? obj.coach : {}) as Record<string, string>,
      fans: (obj.fans && typeof obj.fans === 'object' ? obj.fans : {}) as Record<string, string>,
      fanCounts,
      opposition: (obj.opposition && typeof obj.opposition === 'object' ? obj.opposition : {}) as Record<string, string>,
    };
  }
  // Legacy: voterId -> playerId (treat as fan votes)
  return {
    coach: {},
    fans: { ...(obj as Record<string, string>) },
    fanCounts: {},
    opposition: {},
  };
}

/** Fan tallies: prefer manual fanCounts when any are set, else count individual fan ballots. */
export function tallyFanVotes(votes: PotmVotes): Record<string, number> {
  const counts = votes.fanCounts || {};
  if (Object.keys(counts).length > 0) {
    return { ...counts };
  }
  const tallied: Record<string, number> = {};
  Object.values(votes.fans || {}).forEach((playerId) => {
    tallied[playerId] = (tallied[playerId] || 0) + 1;
  });
  return tallied;
}

/** All players tied on the top vote total (joint award when more than one). */
export function getTiedPotmWinners(tally: Record<string, number>): { playerIds: string[]; votes: number } | null {
  let best = 0;
  Object.values(tally).forEach((n) => {
    if (n > best) best = n;
  });
  if (best <= 0) return null;
  const playerIds = Object.entries(tally)
    .filter(([, n]) => n === best)
    .map(([id]) => id);
  return { playerIds, votes: best };
}

export function formatJointAwardNames(names: string[]): string {
  const cleaned = names.filter(Boolean);
  if (cleaned.length === 0) return '';
  if (cleaned.length === 1) return cleaned[0];
  if (cleaned.length === 2) return `${cleaned[0]} & ${cleaned[1]}`;
  return `${cleaned.slice(0, -1).join(', ')} & ${cleaned[cleaned.length - 1]}`;
}

export const dbService = {
  /**
   * Translates a raw database match row to the Match frontend type.
   */
  mapMatch(m: any): Match {
    return {
      id: m.id,
      clubId: m.club_id,
      title: m.title,
      date: m.date,
      meetTime: m.meet_time,
      kickOffTime: m.kick_off_time,
      location: m.location,
      status: m.status,
      competition: (m.competition === 'LEAGUE' || m.competition === 'CUP' || m.competition === 'FRIENDLY')
        ? m.competition
        : 'FRIENDLY',
      scoreA: m.score_a,
      scoreB: m.score_b,
      signedUpPlayerIds: m.signed_up_player_ids || [],
      availability: m.availability || {},
      opponentName: m.opponent_name,
      isHome: m.is_home,
      potmVotes: normalizePotmVotes(m.potm_votes),
      aiSummary: m.ai_summary,
      photoUrls: Array.isArray(m.photo_urls) ? m.photo_urls.filter(Boolean) : [],
      formation: m.formation || undefined,
      lineup: m.lineup || {},
      teamSize: m.team_size || undefined,
      subPlan: m.sub_plan || undefined,
      teamA: [], 
      teamB: []
    };
  },

  /**
   * Translates a raw database event row to the FeedEvent frontend type.
   */
  mapEvent(e: any): FeedEvent {
    return {
      ...e,
      id: e.id,
      matchId: e.match_id,
      userId: e.user_id,
      userName: e.user_name,
      type: e.type,
      content: e.content,
      details: e.details,
      timestamp: new Date(e.timestamp)
    };
  },

  /**
   * Fetches clubs with members. Does NOT embed profiles in the join so that:
   * - We only read from public.profiles (no join to auth.users).
   * - Dummy members (no auth account) still show up; we look up profile by id in a separate query.
   * - No inner join on profiles: members appear even if profile is missing or mismatched.
   */
  async fetchInitialData(): Promise<Partial<AppState>> {
    if (!isSupabaseEnabled || !supabase) return {};

    try {
      // 1. Clubs + club_members only (no profiles embed – avoids auth.users and keeps all members)
      const { data: clubsData, error: clubsError } = await supabase
        .from('clubs')
        .select('*, members:club_members(user_id, roles)');

      if (clubsError) throw clubsError;

      // 2. All distinct user_ids from members, then load from public.profiles only
      const userIds = new Set<string>();
      (clubsData || []).forEach((c: any) => (c.members || []).forEach((m: any) => m.user_id && userIds.add(m.user_id)));
      const profileMap: Record<string, { name: string; avatar: string; squadNumber?: number; preferredPosition?: string; secondaryPosition?: string; phone?: string; emergencyContact?: string; dateOfBirth?: string; medicalNotes?: string }> = {};
      if (userIds.size > 0) {
        const { data: profilesData, error: profilesError } = await supabase
          .from('profiles')
          .select('id, name, avatar, squad_number, preferred_position, secondary_position, phone, emergency_contact, date_of_birth, medical_notes')
          .in('id', [...userIds]);
        if (!profilesError && profilesData) {
          profilesData.forEach((p: any) => {
            profileMap[p.id] = {
              name: p.name ?? 'Unknown',
              avatar: p.avatar ?? '',
              squadNumber: p.squad_number ?? undefined,
              preferredPosition: p.preferred_position ?? undefined,
              secondaryPosition: p.secondary_position ?? undefined,
              phone: p.phone ?? undefined,
              emergencyContact: p.emergency_contact ?? undefined,
              dateOfBirth: p.date_of_birth ?? undefined,
              medicalNotes: p.medical_notes ?? undefined,
            };
          });
        }
      }

      const { data: matchesData, error: matchesError } = await supabase
        .from('matches')
        .select('*')
        .order('date', { ascending: true });

      if (matchesError) throw matchesError;

      const { data: eventsData, error: eventsError } = await supabase
        .from('feed_events')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(100);

      if (eventsError) throw eventsError;

      return {
        clubs: (clubsData || []).map((c: any) => ({
          id: c.id,
          name: c.name,
          logo: c.logo,
          description: c.description,
          type: c.type,
          ownerId: c.owner_id,
          inviteCode: c.invite_code,
          preferredTeamSize: c.preferred_team_size || undefined,
          preferredFormation: c.preferred_formation || undefined,
          members: (c.members || []).map((m: any) => {
            const profile = profileMap[m.user_id];
            return {
              id: m.user_id,
              name: profile?.name ?? 'Unknown',
              avatar: profile?.avatar ?? '',
              roles: m.roles || ['PLAYER'],
              squadNumber: profile?.squadNumber,
              preferredPosition: profile?.preferredPosition,
              secondaryPosition: profile?.secondaryPosition,
              phone: profile?.phone,
              emergencyContact: profile?.emergencyContact,
              dateOfBirth: profile?.dateOfBirth,
              medicalNotes: profile?.medicalNotes,
            };
          })
        })),
        matches: (matchesData || []).map(m => this.mapMatch(m)),
        feedEvents: (eventsData || []).map(e => this.mapEvent(e))
      };
    } catch (error) {
      console.error("Supabase fetch failed:", error);
      return {};
    }
  },

  async saveProfile(user: User): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const { error } = await supabase.from('profiles').upsert({
      id: user.id,
      name: user.name,
      avatar: user.avatar,
      roles: user.roles,
      squad_number: user.squadNumber ?? null,
      preferred_position: user.preferredPosition ?? null,
      secondary_position: user.secondaryPosition ?? null,
      phone: user.phone ?? null,
      emergency_contact: user.emergencyContact ?? null,
      date_of_birth: user.dateOfBirth ?? null,
      medical_notes: user.medicalNotes ?? null,
    });
    if (error) throw error;
  },

  async getClubByInviteCode(code: string): Promise<Club | null> {
    if (!isSupabaseEnabled || !supabase) return null;
    const { data, error } = await supabase
      .from('clubs')
      .select('*')
      .eq('invite_code', code)
      .maybeSingle();
    
    if (error || !data) return null;
    return {
      id: data.id,
      name: data.name,
      logo: data.logo,
      description: data.description,
      type: data.type,
      ownerId: data.owner_id,
      inviteCode: data.invite_code,
      members: [] 
    };
  },

  async saveClub(club: Club, owner: User): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    await supabase.from('profiles').upsert({
      id: owner.id,
      name: owner.name,
      avatar: owner.avatar,
      roles: owner.roles
    });
    const { error: clubError } = await supabase.from('clubs').upsert({
      id: club.id,
      name: club.name,
      logo: club.logo,
      description: club.description,
      type: club.type,
      owner_id: owner.id,
      invite_code: club.inviteCode,
      preferred_team_size: club.preferredTeamSize ?? null,
      preferred_formation: club.preferredFormation ?? null,
    });
    if (clubError) throw clubError;
    await supabase.from('club_members').upsert({
      club_id: club.id,
      user_id: owner.id,
      roles: club.members.find(m => m.id === owner.id)?.roles || ['ADMIN', 'PLAYER']
    });
  },

  async deleteClub(clubId: string): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const { error } = await supabase.from('clubs').delete().eq('id', clubId);
    if (error) throw error;
  },

  async saveMatch(match: Match): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const { error } = await supabase.from('matches').upsert({
      id: match.id,
      club_id: match.clubId,
      title: match.title,
      date: match.date,
      meet_time: match.meetTime,
      kick_off_time: match.kickOffTime,
      location: match.location,
      status: match.status,
      competition: match.competition || 'FRIENDLY',
      score_a: match.scoreA,
      score_b: match.scoreB,
      signed_up_player_ids: match.signedUpPlayerIds,
      availability: match.availability,
      opponent_name: match.opponentName,
      is_home: match.isHome,
      potm_votes: normalizePotmVotes(match.potmVotes),
      ai_summary: match.aiSummary,
      photo_urls: match.photoUrls ?? [],
      formation: match.formation ?? null,
      lineup: match.lineup ?? {},
      team_size: match.teamSize ?? null,
      sub_plan: match.subPlan ?? null,
    });
    if (error) throw error;
  },

  /** Deletes a match plus its timeline events and stored photos. */
  async deleteMatch(match: Match): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;

    const { error: eventsError } = await supabase
      .from('feed_events')
      .delete()
      .eq('match_id', match.id);
    if (eventsError) throw eventsError;

    const photoUrls = match.photoUrls || [];
    await Promise.all(photoUrls.map((url) => this.deleteMatchPhoto(url)));

    const { error } = await supabase.from('matches').delete().eq('id', match.id);
    if (error) throw error;
  },

  async updateClubPreferences(
    clubId: string,
    prefs: { preferredTeamSize?: 5 | 7 | 9 | 11; preferredFormation?: string }
  ): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const payload: Record<string, unknown> = {};
    if (prefs.preferredTeamSize !== undefined) payload.preferred_team_size = prefs.preferredTeamSize;
    if (prefs.preferredFormation !== undefined) payload.preferred_formation = prefs.preferredFormation;
    if (Object.keys(payload).length === 0) return;
    const { error } = await supabase.from('clubs').update(payload).eq('id', clubId);
    if (error) throw error;
  },

  async saveEvent(event: FeedEvent): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const { error } = await supabase.from('feed_events').upsert({
      id: event.id,
      match_id: event.matchId,
      user_id: event.userId,
      user_name: event.userName,
      type: event.type,
      timestamp: event.timestamp.toISOString(),
      content: event.content,
      details: event.details
    });
    if (error) throw error;
  },

  async deleteEvent(eventId: string): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    await supabase.from('feed_events').delete().eq('id', eventId);
  },

  async joinClub(clubId: string, userId: string, roles: UserRole[]): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const { error } = await supabase.from('club_members').upsert({
      club_id: clubId,
      user_id: userId,
      roles: roles
    });
    if (error) throw error;
  },

  async updateMemberRoles(clubId: string, userId: string, roles: UserRole[]): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const { error } = await supabase
      .from('club_members')
      .update({ roles })
      .eq('club_id', clubId)
      .eq('user_id', userId);
    if (error) throw error;
  },

  async removeClubMember(clubId: string, userId: string): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const { error } = await supabase
      .from('club_members')
      .delete()
      .eq('club_id', clubId)
      .eq('user_id', userId);
    if (error) throw error;
  },

  /**
   * Add a dummy/placeholder member to a club (creates profile + club_members row).
   * Uses a single DB transaction via RPC so the profile exists before the club_members insert,
   * avoiding foreign key constraint "profiles_id_fkey" (club_members.user_id -> profiles.id).
   * Run supabase_add_dummy_member.sql in the Supabase SQL Editor once to create the function.
   */
  async addDummyMember(
    clubId: string,
    name: string,
    role: UserRole,
    avatar: string,
    extra?: {
      squadNumber?: number;
      preferredPosition?: string;
      secondaryPosition?: string;
      phone?: string;
      emergencyContact?: string;
      dateOfBirth?: string;
      medicalNotes?: string;
    }
  ): Promise<User> {
    if (!isSupabaseEnabled || !supabase) throw new Error("Database not connected");

    const { data, error } = await supabase.rpc('add_dummy_member', {
      p_club_id: clubId,
      p_name: name,
      p_avatar: avatar,
      p_role: role,
      p_squad_number: extra?.squadNumber ?? null,
      p_preferred_position: extra?.preferredPosition ?? null,
      p_secondary_position: extra?.secondaryPosition ?? null,
      p_phone: extra?.phone ?? null,
      p_emergency_contact: extra?.emergencyContact ?? null,
      p_date_of_birth: extra?.dateOfBirth ?? null,
      p_medical_notes: extra?.medicalNotes ?? null,
    });

    if (error) throw error;
    if (!data) throw new Error("Add member returned no data");

    const rolesArr = Array.isArray(data.roles) ? data.roles : (data.roles ? [data.roles] : [role]);
    return {
      id: data.id,
      name: data.name ?? name,
      avatar: data.avatar ?? avatar,
      roles: rolesArr as UserRole[],
      squadNumber: data.squad_number ?? undefined,
      preferredPosition: data.preferred_position ?? undefined,
      secondaryPosition: data.secondary_position ?? undefined,
      phone: data.phone ?? undefined,
      emergencyContact: data.emergency_contact ?? undefined,
      dateOfBirth: data.date_of_birth ?? undefined,
      medicalNotes: data.medical_notes ?? undefined,
    };
  },

  /**
   * Update a member's profile (name, avatar, squad/contact fields).
   * Writes directly to public.profiles (no RPC).
   * If updates fail under RLS, run supabase_update_member.sql once.
   */
  async updateMember(
    userId: string,
    updates: {
      name: string;
      avatar?: string;
      squadNumber?: number;
      preferredPosition?: string;
      secondaryPosition?: string;
      phone?: string;
      emergencyContact?: string;
      dateOfBirth?: string;
      medicalNotes?: string;
    }
  ): Promise<Partial<User>> {
    if (!isSupabaseEnabled || !supabase) throw new Error("Database not connected");

    const payload = {
      id: userId,
      name: updates.name,
      avatar: updates.avatar ?? undefined,
      squad_number: updates.squadNumber ?? null,
      preferred_position: updates.preferredPosition ?? null,
      secondary_position: updates.secondaryPosition ?? null,
      phone: updates.phone ?? null,
      emergency_contact: updates.emergencyContact ?? null,
      date_of_birth: updates.dateOfBirth || null,
      medical_notes: updates.medicalNotes ?? null,
    };

    const { data: row, error } = await supabase
      .from('profiles')
      .upsert(payload, { onConflict: 'id' })
      .select('*')
      .maybeSingle();

    if (error) {
      throw new Error(
        error.message ||
          'Failed to update member. Run supabase_update_member.sql in the Supabase SQL Editor if RLS is blocking updates.'
      );
    }
    if (!row) {
      throw new Error(
        'Update returned no row. Run supabase_update_member.sql in the Supabase SQL Editor to allow profile updates.'
      );
    }

    return {
      id: row.id ?? userId,
      name: row.name ?? updates.name,
      avatar: row.avatar ?? updates.avatar,
      roles: (Array.isArray(row.roles) ? row.roles : row.roles ? [row.roles] : undefined) as UserRole[] | undefined,
      squadNumber: row.squad_number ?? undefined,
      preferredPosition: row.preferred_position ?? undefined,
      secondaryPosition: row.secondary_position ?? undefined,
      phone: row.phone ?? undefined,
      emergencyContact: row.emergency_contact ?? undefined,
      dateOfBirth: row.date_of_birth ?? undefined,
      medicalNotes: row.medical_notes ?? undefined,
    };
  },

  /**
   * Compress an image in the browser, then upload to the match-photos bucket.
   * Returns a public URL. Run supabase_match_photos.sql once to create the bucket + column.
   */
  async uploadMatchPhoto(clubId: string, matchId: string, file: File): Promise<string> {
    if (!isSupabaseEnabled || !supabase) throw new Error('Database not connected');

    const blob = await compressImageFile(file);
    const ext = blob.type === 'image/png' ? 'png' : blob.type === 'image/webp' ? 'webp' : 'jpg';
    const path = `${clubId}/${matchId}/${crypto.randomUUID()}.${ext}`;

    const { error } = await supabase.storage.from('match-photos').upload(path, blob, {
      contentType: blob.type || 'image/jpeg',
      upsert: false,
    });

    if (error) {
      throw new Error(
        error.message.includes('Bucket not found') || error.message.includes('not found')
          ? 'Photo storage is not set up. Run supabase_match_photos.sql in the Supabase SQL Editor.'
          : error.message
      );
    }

    const { data } = supabase.storage.from('match-photos').getPublicUrl(path);
    if (!data?.publicUrl) throw new Error('Upload succeeded but no public URL was returned');
    return data.publicUrl;
  },

  /** Best-effort delete of a stored match photo (ignores missing objects). */
  async deleteMatchPhoto(publicUrl: string): Promise<void> {
    if (!isSupabaseEnabled || !supabase) return;
    const marker = '/object/public/match-photos/';
    const idx = publicUrl.indexOf(marker);
    if (idx === -1) return;
    const path = decodeURIComponent(publicUrl.slice(idx + marker.length));
    if (!path) return;
    await supabase.storage.from('match-photos').remove([path]);
  },
};

async function compressImageFile(file: File, maxWidth = 1600, quality = 0.82): Promise<Blob> {
  if (!file.type.startsWith('image/') || typeof createImageBitmap === 'undefined') {
    return file;
  }
  try {
    const bitmap = await createImageBitmap(file);
    const scale = Math.min(1, maxWidth / Math.max(bitmap.width, bitmap.height));
    const width = Math.max(1, Math.round(bitmap.width * scale));
    const height = Math.max(1, Math.round(bitmap.height * scale));
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      bitmap.close();
      return file;
    }
    ctx.drawImage(bitmap, 0, 0, width, height);
    bitmap.close();
    const mime = file.type === 'image/png' ? 'image/png' : 'image/jpeg';
    const blob = await new Promise<Blob | null>((resolve) =>
      canvas.toBlob((b) => resolve(b), mime, quality)
    );
    return blob || file;
  } catch {
    return file;
  }
}
