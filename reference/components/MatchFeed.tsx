
import React, { useState, useMemo, useRef, useEffect } from 'react';
import { Match, FeedEvent, EventType, Club, User, UserRole, PotmCategory, PotmVotes, MatchSubPlan } from '../types';
import { FORMATIONS, TEAM_SIZES, DEFAULT_FORMATION_BY_SIZE, getFormationsForSize, spreadSlotPosition, TeamSize } from '../lib/formations';
import { 
  Goal, 
  ArrowRightLeft, 
  Send, 
  Trophy, 
  Play, 
  Info, 
  Clock, 
  MapPin, 
  X, 
  Check, 
  Users, 
  Sparkles, 
  MessageSquare, 
  Flag, 
  AlertTriangle, 
  CloudSun, 
  ExternalLink, 
  RefreshCw,
  AlertCircle,
  AlertOctagon,
  Award,
  FileText as ReportIcon,
  LayoutGrid,
  History,
  Shield,
  Plus,
  Coffee,
  ChevronUp,
  ChevronDown,
  Edit2,
  Trash2,
  Wind,
  Star,
  UserX,
  UserCheck,
  MoreHorizontal,
  Camera,
  ImagePlus,
  Loader2,
  Maximize2
} from 'lucide-react';
import { getMatchIntel, generateMatchSummary, MatchIntel } from '../services/geminiService';
import { dbService, normalizePotmVotes, tallyFanVotes, getTiedPotmWinners, formatJointAwardNames } from '../services/dbService';
import { calculateMatchMinutes, formatMinutes, reconstructStartingLineupMap } from '../lib/playingMinutes';
import { SubPlanPanel } from './SubPlanPanel';

interface MatchFeedProps {
  match: Match;
  club?: Club | null;
  events: FeedEvent[];
  /** Season minutes so far (completed matches), used by the sub planner. */
  seasonMinutes?: Record<string, number>;
  onAddEvent: (eventData: Partial<FeedEvent>) => void;
  onDeleteEvent: (eventId: string) => void;
  onUpdateEvent: (eventId: string, updates: { content?: string; timestamp?: Date }) => void;
  onUpdateStatus: (status: Match['status']) => void;
  onUpdateLineup: (playerIds: string[]) => void;
  onUpdateMatchData: (matchId: string, data: Partial<Match>) => void;
  onUpdateClubPreferences?: (clubId: string, prefs: { preferredTeamSize?: TeamSize; preferredFormation?: string }) => void;
  onJoinMatch: (matchId: string, userId?: string) => void;
  onEditMatch: (match: Match) => void;
  onDeleteMatch: (matchId: string) => void;
  onVoteForPotm: (playerId: string, category: PotmCategory) => void;
  onSaveAiSummary: (matchId: string, summary: string) => void;
  currentUser: User | null;
  onApiKeyTrouble: () => void;
}

type ViewMode = 'FEED' | 'SQUAD';
type SquadTab = 'AVAILABILITY' | 'LINEUP' | 'SUBS';

export const MatchFeed: React.FC<MatchFeedProps> = ({
  match,
  club,
  events: initialEvents,
  seasonMinutes = {},
  onAddEvent,
  onDeleteEvent,
  onUpdateEvent,
  onUpdateStatus,
  onUpdateMatchData,
  onUpdateClubPreferences,
  onJoinMatch,
  onEditMatch,
  onDeleteMatch,
  onVoteForPotm,
  onSaveAiSummary,
  currentUser,
  onApiKeyTrouble 
}) => {
  const [activeView, setActiveView] = useState<ViewMode>('FEED');
  const [squadTab, setSquadTab] = useState<SquadTab>('AVAILABILITY');
  const [selectedSlotId, setSelectedSlotId] = useState<string | null>(null);
  const [lineupDrag, setLineupDrag] = useState<{ playerId: string; fromSlotId: string | null } | null>(null);
  const [lineupDropTarget, setLineupDropTarget] = useState<string | null>(null);
  const lineupDragRef = useRef<{ playerId: string; fromSlotId: string | null } | null>(null);
  const [newEventContent, setNewEventContent] = useState('');
  const [selectedPlayerId, setSelectedPlayerId] = useState<string>('');
  const [selectedPlayerId2, setSelectedPlayerId2] = useState<string>('');
  const [selectedAssistId, setSelectedAssistId] = useState<string>('');
  const [selectedTeam, setSelectedTeam] = useState<'A' | 'B'>('A');
  const [activeActionType, setActiveActionType] = useState<EventType | null>(null);
  const [showCommentComposer, setShowCommentComposer] = useState(false);
  /** During LIVE: prioritize timeline logging; hide report/photos/half-times */
  const [liveFocusMode, setLiveFocusMode] = useState(true);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [isDeletingMatch, setIsDeletingMatch] = useState(false);
  const [plannedSubsExpanded, setPlannedSubsExpanded] = useState(true);
  const [eventTime, setEventTime] = useState(() => {
    const now = new Date();
    return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  });
  const [isFetchingIntel, setIsFetchingIntel] = useState(false);
  const [intel, setIntel] = useState<MatchIntel | null>(null);
  
  const [editingEventId, setEditingEventId] = useState<string | null>(null);
  const [editContent, setEditContent] = useState('');
  const [editTime, setEditTime] = useState('');
  const [isEditingReport, setIsEditingReport] = useState(false);
  const [reportDraft, setReportDraft] = useState('');
  const [isGeneratingReport, setIsGeneratingReport] = useState(false);
  const [reportJustSaved, setReportJustSaved] = useState(false);
  const [isUploadingPhotos, setIsUploadingPhotos] = useState(false);
  const [photoError, setPhotoError] = useState<string | null>(null);
  const [lightboxUrl, setLightboxUrl] = useState<string | null>(null);
  const photoInputRef = useRef<HTMLInputElement>(null);

  const events = useMemo(() => {
    return [...initialEvents].sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }, [initialEvents]);

  const teamAName = club?.name || 'Home';
  const teamBName = match.opponentName || 'Away';

  const isMatchOwner = currentUser?.id === club?.ownerId;
  const memberRoles: UserRole[] = club?.members.find(m => m.id === currentUser?.id)?.roles || [];
  const canModerate = isMatchOwner || memberRoles.includes('ADMIN');
  /** Coaches, managers (owner), and admins — see voter identities + record opposition pick */
  const isCoachOrManager = isMatchOwner || memberRoles.includes('ADMIN') || memberRoles.includes('COACH');
  const isMember = club?.members.some(m => m.id === currentUser?.id);
  /** Coach/manager vote → Coach's Player; everyone else (players/spectators) → Fan's Player */
  const myPotmCategory: PotmCategory | null = !isMember
    ? null
    : isCoachOrManager
      ? 'coach'
      : 'fans';
  const potmBallotTitle =
    myPotmCategory === 'coach'
      ? "Coach's Player"
      : myPotmCategory === 'fans'
        ? "Fan's Player of the Match"
        : 'Player of the Match';
  
  const availability = match.availability || {};
  const lineup = match.lineup || {};
  const teamSize: TeamSize = (match.teamSize || club?.preferredTeamSize || 9) as TeamSize;
  const availableFormations = getFormationsForSize(teamSize);
  const formation =
    match.formation && availableFormations.includes(match.formation)
      ? match.formation
      : (club?.preferredFormation && availableFormations.includes(club.preferredFormation)
          ? club.preferredFormation
          : DEFAULT_FORMATION_BY_SIZE[teamSize]);
  const formationSlots = FORMATIONS[formation] || FORMATIONS[DEFAULT_FORMATION_BY_SIZE[teamSize]];

  const persistClubPrefs = (prefs: { preferredTeamSize?: TeamSize; preferredFormation?: string }) => {
    if (club && onUpdateClubPreferences) onUpdateClubPreferences(club.id, prefs);
  };

  const handleSetTeamSize = (size: TeamSize) => {
    const nextFormation = DEFAULT_FORMATION_BY_SIZE[size];
    onUpdateMatchData(match.id, { teamSize: size, formation: nextFormation, lineup: {} });
    persistClubPrefs({ preferredTeamSize: size, preferredFormation: nextFormation });
    setSelectedSlotId(null);
  };

  const handleSetAvailability = (userId: string, status: 'CONFIRMED' | 'UNAVAILABLE' | null) => {
    const newAvailability = { ...availability };
    if (status === null) {
      delete newAvailability[userId];
    } else {
      newAvailability[userId] = status;
    }
    
    let newSignedUp = [...match.signedUpPlayerIds];
    if (status === 'CONFIRMED') {
      if (!newSignedUp.includes(userId)) newSignedUp.push(userId);
    } else {
      newSignedUp = newSignedUp.filter(id => id !== userId);
    }

    let newLineup = { ...lineup };
    if (status !== 'CONFIRMED') {
      Object.entries(newLineup).forEach(([slotId, pid]) => {
        if (pid === userId) delete newLineup[slotId];
      });
    }

    onUpdateMatchData(match.id, { 
      availability: newAvailability,
      signedUpPlayerIds: newSignedUp,
      lineup: newLineup,
    });
  };

  const handleSetFormation = (nextFormation: string) => {
    onUpdateMatchData(match.id, { formation: nextFormation, lineup: {} });
    persistClubPrefs({ preferredTeamSize: teamSize, preferredFormation: nextFormation });
    setSelectedSlotId(null);
  };

  const handleAssignPlayerToSlot = (slotId: string, playerId: string | null) => {
    const newLineup = { ...lineup };
    if (playerId) {
      Object.entries(newLineup).forEach(([sid, pid]) => {
        if (pid === playerId) delete newLineup[sid];
      });
      newLineup[slotId] = playerId;
    } else {
      delete newLineup[slotId];
    }
    onUpdateMatchData(match.id, { lineup: newLineup });
    setSelectedSlotId(null);
  };

  const handleLineupDragStart = (
    e: React.DragEvent,
    playerId: string,
    fromSlotId: string | null
  ) => {
    if (!canModerate) {
      e.preventDefault();
      return;
    }
    const payload = { playerId, fromSlotId };
    lineupDragRef.current = payload;
    setLineupDrag(payload);
    e.dataTransfer.effectAllowed = fromSlotId ? 'move' : 'copy';
    e.dataTransfer.setData('text/plain', JSON.stringify(payload));
  };

  const handleLineupDragEnd = () => {
    lineupDragRef.current = null;
    setLineupDrag(null);
    setLineupDropTarget(null);
  };

  const handleLineupDropOnSlot = (targetSlotId: string) => {
    if (!canModerate) return;
    const drag = lineupDragRef.current;
    if (!drag) return;
    const { playerId, fromSlotId } = drag;
    if (fromSlotId === targetSlotId) {
      handleLineupDragEnd();
      return;
    }

    const newLineup = { ...lineup };
    const occupantId = newLineup[targetSlotId];

    if (fromSlotId && occupantId) {
      newLineup[fromSlotId] = occupantId;
      newLineup[targetSlotId] = playerId;
    } else {
      Object.entries(newLineup).forEach(([sid, pid]) => {
        if (pid === playerId) delete newLineup[sid];
      });
      newLineup[targetSlotId] = playerId;
    }

    onUpdateMatchData(match.id, { lineup: newLineup });
    setSelectedSlotId(null);
    handleLineupDragEnd();
  };

  const handleLineupDropOnBench = () => {
    if (!canModerate) {
      handleLineupDragEnd();
      return;
    }
    const drag = lineupDragRef.current;
    if (!drag?.fromSlotId) {
      handleLineupDragEnd();
      return;
    }
    handleAssignPlayerToSlot(drag.fromSlotId, null);
    handleLineupDragEnd();
  };

  const squadPlayers = useMemo(() => {
    const allMembers = club?.members || [];
    
    return allMembers
      .filter(m => {
        const roles = m.roles || [];
        return roles.some(r => r.toUpperCase() === 'PLAYER');
      })
      .map(member => ({
        ...member,
        status: availability[member.id] || 'PENDING'
      }))
      .sort((a, b) => {
        const order = { CONFIRMED: 0, PENDING: 1, UNAVAILABLE: 2 } as const;
        const statusDiff = order[a.status as keyof typeof order] - order[b.status as keyof typeof order];
        if (statusDiff !== 0) return statusDiff;
        return (a.squadNumber ?? 999) - (b.squadNumber ?? 999) || a.name.localeCompare(b.name);
      });
  }, [club?.members, availability]);

  const confirmedSquad = useMemo(() => squadPlayers.filter(p => p.status === 'CONFIRMED'), [squadPlayers]);
  const pendingSquad = useMemo(() => squadPlayers.filter(p => p.status === 'PENDING'), [squadPlayers]);
  const unavailableSquad = useMemo(() => squadPlayers.filter(p => p.status === 'UNAVAILABLE'), [squadPlayers]);

  const startingPlayerIds = useMemo(() => new Set(Object.values(lineup)), [lineup]);
  const onPitchPlayers = useMemo(
    () => confirmedSquad.filter(p => startingPlayerIds.has(p.id)),
    [confirmedSquad, startingPlayerIds]
  );
  const benchPlayers = useMemo(
    () => confirmedSquad.filter(p => !startingPlayerIds.has(p.id)),
    [confirmedSquad, startingPlayerIds]
  );
  /** Fallback if lineup not set yet: all confirmed players */
  const selectableOnPitch = onPitchPlayers.length > 0 ? onPitchPlayers : confirmedSquad;

  /** Ensure prefilled planned sub players appear in OFF/ON selects even if lineup drifted. */
  const subOffOptions = useMemo(() => {
    const base = [...selectableOnPitch];
    if (selectedPlayerId && !base.some(p => p.id === selectedPlayerId)) {
      const extra =
        confirmedSquad.find(p => p.id === selectedPlayerId) ||
        club?.members.find(m => m.id === selectedPlayerId);
      if (extra) base.unshift(extra as (typeof selectableOnPitch)[number]);
    }
    return base;
  }, [selectableOnPitch, selectedPlayerId, confirmedSquad, club?.members]);

  const subOnOptions = useMemo(() => {
    const base =
      benchPlayers.length > 0
        ? [...benchPlayers]
        : confirmedSquad.filter(p => p.id !== selectedPlayerId);
    if (selectedPlayerId2 && !base.some(p => p.id === selectedPlayerId2)) {
      const extra =
        confirmedSquad.find(p => p.id === selectedPlayerId2) ||
        club?.members.find(m => m.id === selectedPlayerId2);
      if (extra) base.unshift(extra as (typeof confirmedSquad)[number]);
    }
    return base;
  }, [benchPlayers, confirmedSquad, selectedPlayerId, selectedPlayerId2, club?.members]);

  /** Kick-off lineup for the sub planner (reverse live SUBs if needed). */
  const plannerStartingLineup = useMemo(
    () => reconstructStartingLineupMap(match.lineup, initialEvents, match.id),
    [match.lineup, match.id, initialEvents]
  );

  const handleSaveSubPlan = (subPlan: MatchSubPlan | undefined) => {
    onUpdateMatchData(match.id, { subPlan });
  };

  const resolvePlayerName = (playerId: string) => {
    const player =
      squadPlayers.find(p => p.id === playerId) || club?.members.find(m => m.id === playerId);
    if (!player) return 'Unknown';
    return player.squadNumber != null ? `#${player.squadNumber} ${player.name}` : player.name;
  };

  /** Planned swaps for live-feed reminder (coach/admin). */
  const plannedSubReminder = useMemo(() => {
    const swaps = match.subPlan?.swaps || [];
    if (swaps.length === 0) return null;

    const loggedSubs = initialEvents.filter(
      e =>
        e.type === 'SUB' &&
        e.details?.team !== 'B' &&
        e.details?.playerOut &&
        e.details?.playerIn
    );

    const usedEventIds = new Set<string>();
    const rows = swaps.map((swap, index) => {
      const matchEvent = loggedSubs.find(
        e =>
          !usedEventIds.has(e.id) &&
          e.details?.playerOut === swap.playerOut &&
          e.details?.playerIn === swap.playerIn
      );
      if (matchEvent) usedEventIds.add(matchEvent.id);
      return {
        key: `${swap.afterQuarter}-${swap.playerOut}-${swap.playerIn}-${index}`,
        afterQuarter: swap.afterQuarter,
        playerOut: swap.playerOut,
        playerIn: swap.playerIn,
        done: !!matchEvent,
      };
    });

    const byBreak: { afterQuarter: 1 | 2 | 3; swaps: typeof rows }[] = (
      [1, 2, 3] as const
    ).map(q => ({
      afterQuarter: q,
      swaps: rows.filter(r => r.afterQuarter === q),
    })).filter(g => g.swaps.length > 0);

    return {
      rows,
      byBreak,
      doneCount: rows.filter(r => r.done).length,
      total: rows.length,
      next: rows.find(r => !r.done) || null,
    };
  }, [match.subPlan?.swaps, initialEvents]);

  const showPlannedSubsReminder =
    isCoachOrManager &&
    !!plannedSubReminder &&
    (match.status === 'UPCOMING' || match.status === 'LIVE');

  const plannedSubsReminderCard = showPlannedSubsReminder && plannedSubReminder ? (
    <div className="bg-orange-50/80 border border-orange-100 rounded-2xl overflow-hidden shadow-sm">
      <button
        type="button"
        onClick={() => setPlannedSubsExpanded(v => !v)}
        className="w-full flex items-center justify-between gap-2 px-4 py-3 text-left"
      >
        <div className="flex items-center gap-2 min-w-0">
          <ArrowRightLeft className="w-4 h-4 text-orange-600 shrink-0" />
          <div className="min-w-0">
            <p className="text-[10px] font-black uppercase tracking-widest text-orange-700">
              Planned subs
            </p>
            <p className="text-[11px] font-medium text-orange-800/70 truncate">
              {plannedSubReminder.doneCount}/{plannedSubReminder.total} logged
              {match.status === 'UPCOMING' ? ' · reminder for kick-off' : ' · live reminder'}
            </p>
          </div>
        </div>
        {plannedSubsExpanded ? (
          <ChevronUp className="w-4 h-4 text-orange-500 shrink-0" />
        ) : (
          <ChevronDown className="w-4 h-4 text-orange-500 shrink-0" />
        )}
      </button>
      {plannedSubsExpanded && (
        <div className="px-3 pb-3 space-y-2.5">
          {plannedSubReminder.byBreak.map(group => (
            <div key={group.afterQuarter} className="space-y-1">
              <p className="text-[9px] font-black uppercase tracking-widest text-orange-600/80 px-1">
                After Q{group.afterQuarter}
              </p>
              <div className="space-y-1">
                {group.swaps.map(swap => (
                  <div
                    key={swap.key}
                    className={`flex items-center gap-2 rounded-xl px-3 py-2 border text-[11px] font-bold ${
                      swap.done
                        ? 'bg-white/50 border-orange-100/60 text-slate-400 line-through'
                        : 'bg-white border-orange-100 text-slate-800'
                    }`}
                  >
                    {swap.done ? (
                      <Check className="w-3.5 h-3.5 text-green-500 shrink-0" />
                    ) : (
                      <span className="w-3.5 h-3.5 rounded-full border-2 border-orange-300 shrink-0" />
                    )}
                    <span className="truncate text-red-600/90 flex-1 min-w-0">
                      ↓ {resolvePlayerName(swap.playerOut)}
                    </span>
                    <ArrowRightLeft className="w-3 h-3 text-slate-300 shrink-0" />
                    <span className="truncate text-green-600/90 flex-1 min-w-0 text-right">
                      ↑ {resolvePlayerName(swap.playerIn)}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          ))}
          <button
            type="button"
            onClick={() => {
              setActiveView('SQUAD');
              setSquadTab('SUBS');
            }}
            className="w-full text-center text-[9px] font-black uppercase tracking-widest text-orange-700 hover:text-orange-800 py-1"
          >
            Edit plan →
          </button>
        </div>
      )}
    </div>
  ) : null;

  const matchMinutes = useMemo(
    () => calculateMatchMinutes(match, initialEvents),
    [match, initialEvents]
  );

  const matchMinutesRows = useMemo(() => {
    return Object.entries(matchMinutes)
      .map(([id, minutes]) => {
        const player = squadPlayers.find(p => p.id === id) || club?.members.find(m => m.id === id);
        return {
          id,
          minutes,
          name: player?.name || 'Unknown',
          avatar: player?.avatar,
        };
      })
      .sort((a, b) => b.minutes - a.minutes || a.name.localeCompare(b.name));
  }, [matchMinutes, squadPlayers, club?.members]);

  const potmVotes: PotmVotes = useMemo(() => normalizePotmVotes(match.potmVotes), [match.potmVotes]);

  const potmCategoryResults = useMemo(() => {
    const tally = (votes?: Record<string, string>) => {
      const counts: Record<string, number> = {};
      Object.values(votes || {}).forEach((playerId) => {
        counts[playerId] = (counts[playerId] || 0) + 1;
      });
      return counts;
    };
    return {
      coach: tally(potmVotes.coach),
      fans: tallyFanVotes(potmVotes),
      opposition: tally(potmVotes.opposition),
    };
  }, [potmVotes]);

  const potmAward = (counts: Record<string, number>) => {
    const winners = getTiedPotmWinners(counts);
    if (!winners) return null;
    const players = winners.playerIds.map((id) => {
      const player = confirmedSquad.find(p => p.id === id);
      return {
        playerId: id,
        name: player?.name || 'Unknown',
        avatar: player?.avatar,
      };
    });
    const tied = players.length > 1;
    return {
      players,
      playerIds: winners.playerIds,
      playerId: winners.playerIds[0],
      name: formatJointAwardNames(players.map(p => p.name)),
      votes: winners.votes,
      tied,
      label: tied
        ? `Joint award · ${formatJointAwardNames(players.map(p => p.name.split(' ')[0]))}`
        : players[0].name,
    };
  };

  const coachAward = useMemo(() => potmAward(potmCategoryResults.coach), [potmCategoryResults.coach, confirmedSquad]);
  const fansAward = useMemo(() => potmAward(potmCategoryResults.fans), [potmCategoryResults.fans, confirmedSquad]);
  const oppositionAward = useMemo(() => potmAward(potmCategoryResults.opposition), [potmCategoryResults.opposition, confirmedSquad]);

  const myVotePlayerId = useMemo(() => {
    if (!currentUser || !myPotmCategory) return null;
    return potmVotes[myPotmCategory]?.[currentUser.id] || null;
  }, [currentUser, myPotmCategory, potmVotes]);

  const hasVoted = !!myVotePlayerId;
  const myVotePlayer = confirmedSquad.find(p => p.id === myVotePlayerId);
  const usingManualFanCounts = Object.keys(potmVotes.fanCounts || {}).length > 0;
  const fanVoteTotal = useMemo(
    () => Object.values(potmCategoryResults.fans).reduce((a, b) => a + b, 0),
    [potmCategoryResults.fans]
  );

  const handleFanCountChange = (playerId: string, raw: string) => {
    const parsed = raw.trim() === '' ? 0 : Number.parseInt(raw, 10);
    const n = Number.isFinite(parsed) ? Math.max(0, Math.min(9999, Math.floor(parsed))) : 0;
    const nextCounts = { ...(potmVotes.fanCounts || {}) };
    if (n <= 0) delete nextCounts[playerId];
    else nextCounts[playerId] = n;
    onUpdateMatchData(match.id, {
      potmVotes: {
        ...potmVotes,
        fanCounts: nextCounts,
      },
    });
  };

  const [potmExpanded, setPotmExpanded] = useState(!hasVoted || isCoachOrManager);
  useEffect(() => {
    // Collapse once a non-coach member has cast their ballot; coaches keep it open to enter fan counts
    if (hasVoted && !isCoachOrManager) setPotmExpanded(false);
  }, [hasVoted, isCoachOrManager]);

  const potmVoterEntries = (category: PotmCategory) => {
    const votes = potmVotes[category] || {};
    return Object.entries(votes).map(([voterId, playerId]) => {
      const voter = club?.members.find(m => m.id === voterId);
      const player = confirmedSquad.find(p => p.id === playerId);
      return {
        voterId,
        voterName: voter?.name || (category === 'opposition' ? 'Opposition' : 'Voter'),
        playerId,
        playerName: player?.name || 'Unknown',
      };
    });
  };

  const liveIconMapping: Record<string, React.ReactNode> = {
    'GOAL': <Goal className="w-4 h-4 text-green-500 fill-current" />,
    'START': <Play className="w-4 h-4 text-blue-500 fill-current" />,
    'HALF_TIME': <Clock className="w-4 h-4 text-orange-500" />,
    'SECOND_HALF': <Play className="w-4 h-4 text-blue-500 fill-current" />,
    'END': <Flag className="w-4 h-4 text-red-500 fill-current" />,
    'COMMENT': <MessageSquare className="w-4 h-4 text-slate-500" />,
    'YELLOW_CARD': <AlertTriangle className="w-4 h-4 text-yellow-500 fill-current" />,
    'RED_CARD': <AlertOctagon className="w-4 h-4 text-red-600 fill-current" />,
    'CANCELLED': <AlertCircle className="w-4 h-4 text-red-500 fill-current" />,
    'SUB': <ArrowRightLeft className="w-4 h-4 text-orange-500" />
  };

  const hasHalfTime = useMemo(() => initialEvents.some(e => e.type === 'HALF_TIME'), [initialEvents]);
  const hasSecondHalf = useMemo(() => initialEvents.some(e => e.type === 'SECOND_HALF'), [initialEvents]);
  const isMatchInPlay = match.status === 'LIVE' && (!hasHalfTime || hasSecondHalf);
  /** Live logging or post-match timeline entry */
  const canLogEvents = match.status === 'LIVE' || match.status === 'COMPLETED';

  const periodEvents = useMemo(() => ({
    start: initialEvents.find(e => e.type === 'START'),
    halfTime: initialEvents.find(e => e.type === 'HALF_TIME'),
    secondHalf: initialEvents.find(e => e.type === 'SECOND_HALF'),
    end: initialEvents.find(e => e.type === 'END'),
  }), [initialEvents]);

  const hasAnyPeriodEvent = !!(periodEvents.start || periodEvents.halfTime || periodEvents.secondHalf || periodEvents.end);

  const toHHMM = (d: Date) => {
    const t = new Date(d);
    return `${String(t.getHours()).padStart(2, '0')}:${String(t.getMinutes()).padStart(2, '0')}`;
  };

  /** Normalize DB/time values like "11:00:00" for <input type="time"> */
  const normalizeTimeValue = (value?: string | null) => {
    if (!value) return '';
    const matchHHMM = value.match(/^(\d{1,2}):(\d{2})/);
    if (!matchHHMM) return value;
    return `${matchHHMM[1].padStart(2, '0')}:${matchHHMM[2]}`;
  };

  const kickOffTimeValue = normalizeTimeValue(match.kickOffTime);

  const buildEventTimestamp = (timeHHMM: string): Date => {
    const base = match.date ? new Date(match.date) : new Date();
    const [hh, mm] = timeHHMM.split(':').map(Number);
    const ts = new Date(base);
    if (!Number.isNaN(hh) && !Number.isNaN(mm)) {
      ts.setHours(hh, mm, 0, 0);
    }
    return ts;
  };

  const PERIOD_META: Record<'start' | 'halfTime' | 'secondHalf' | 'end', { type: EventType; content: string }> = {
    start: { type: 'START', content: 'Match started! Kick off!' },
    halfTime: { type: 'HALF_TIME', content: 'Half Time! The referee blows for the break.' },
    secondHalf: { type: 'SECOND_HALF', content: 'Second Half underway! Let’s get back to it.' },
    end: { type: 'END', content: 'Full time! The match has ended.' },
  };

  const handlePeriodTimeChange = (
    key: 'start' | 'halfTime' | 'secondHalf' | 'end',
    event: FeedEvent | undefined,
    timeHHMM: string
  ) => {
    if (!timeHHMM) return;
    const timestamp = buildEventTimestamp(timeHHMM);
    if (event) {
      onUpdateEvent(event.id, { timestamp });
    } else {
      const meta = PERIOD_META[key];
      onAddEvent({ type: meta.type, content: meta.content, timestamp });
    }
    // Keep fixture kick-off in sync with 1st half start
    if (key === 'start') {
      onUpdateMatchData(match.id, { kickOffTime: timeHHMM });
    }
  };

  const handleKickOffTimeChange = (timeHHMM: string) => {
    if (!timeHHMM) return;
    onUpdateMatchData(match.id, { kickOffTime: timeHHMM });
    if (periodEvents.start) {
      onUpdateEvent(periodEvents.start.id, { timestamp: buildEventTimestamp(timeHHMM) });
    }
  };

  const handleActionClick = (type: EventType) => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }

    if (!canLogEvents) return;
    setShowCommentComposer(false);
    if (activeActionType === type) {
      setActiveActionType(null);
    } else {
      setActiveActionType(type);
      setSelectedAssistId('');
      setSelectedTeam('A');
      // Prefill next unfinished planned swap when logging a Team A sub
      if (type === 'SUB' && plannedSubReminder?.next) {
        setSelectedPlayerId(plannedSubReminder.next.playerOut);
        setSelectedPlayerId2(plannedSubReminder.next.playerIn);
      } else {
        setSelectedPlayerId('');
        setSelectedPlayerId2('');
      }
      const now = new Date();
      setEventTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`);
    }
  };

  const handleCommentClick = () => {
    if (!isMember) return;
    setActiveActionType(null);
    setShowCommentComposer((open) => {
      const next = !open;
      if (next) {
        const now = new Date();
        setEventTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`);
      }
      return next;
    });
  };

  const handleMatchProgression = () => {
    if (match.status === 'UPCOMING') {
      onUpdateStatus('LIVE');
      onAddEvent({ type: 'START', content: 'Match started! Kick off!', timestamp: buildEventTimestamp(eventTime) });
    } else if (match.status === 'LIVE') {
      if (!hasHalfTime) {
        onAddEvent({ type: 'HALF_TIME', content: 'Half Time! The referee blows for the break.', timestamp: buildEventTimestamp(eventTime) });
        setActiveActionType(null); 
      } else if (!hasSecondHalf) {
        onAddEvent({ type: 'SECOND_HALF', content: 'Second Half underway! Let’s get back to it.', timestamp: buildEventTimestamp(eventTime) });
      } else {
        onUpdateStatus('COMPLETED');
        onAddEvent({ type: 'END', content: 'Full time! The match has ended.', timestamp: buildEventTimestamp(eventTime) });
        setActiveActionType(null);
      }
    }
  };

  const handleSubmitAction = (e: React.FormEvent) => {
    e.preventDefault();
    const typeToUse = activeActionType || 'COMMENT';
    
    if (typeToUse !== 'COMMENT' && !canLogEvents) {
      setActiveActionType(null);
      return;
    }

    const p1Name = squadPlayers.find(p => p.id === selectedPlayerId)?.name || 'Someone';
    const p2Name = squadPlayers.find(p => p.id === selectedPlayerId2)?.name || 'Someone';
    const assistName = squadPlayers.find(p => p.id === selectedAssistId)?.name;
    const teamName = selectedTeam === 'A' ? teamAName : teamBName;
    const timestamp = buildEventTimestamp(eventTime);
    
    let content = newEventContent;
    let details: any = { team: selectedTeam };

    if (typeToUse === 'GOAL') {
      if (selectedTeam === 'A') {
        if (!selectedPlayerId) return;
        content = assistName
          ? `GOAL for ${teamName}! Scored by ${p1Name}, assist ${assistName}. ${newEventContent}`.trim()
          : `GOAL for ${teamName}! Scored by ${p1Name}. ${newEventContent}`.trim();
        details = {
          ...details,
          scorer: selectedPlayerId,
          ...(selectedAssistId ? { assist: selectedAssistId } : {}),
        };
        onUpdateMatchData(match.id, { scoreA: (match.scoreA || 0) + 1 });
      } else {
        content = `GOAL for ${teamName}! ${newEventContent}`.trim() || `GOAL for ${teamName}!`;
        onUpdateMatchData(match.id, { scoreB: (match.scoreB || 0) + 1 });
      }
    } else if (typeToUse === 'YELLOW_CARD') {
      if (selectedTeam === 'A') {
        if (!selectedPlayerId) return;
        content = `YELLOW CARD (${teamName}) shown to ${p1Name}. ${newEventContent}`.trim();
        details = { ...details, scorer: selectedPlayerId };
      } else {
        content = `YELLOW CARD for ${teamName}. ${newEventContent}`.trim() || `YELLOW CARD for ${teamName}.`;
      }
    } else if (typeToUse === 'RED_CARD') {
      if (selectedTeam === 'A') {
        if (!selectedPlayerId) return;
        content = `RED CARD (${teamName}) shown to ${p1Name}. ${newEventContent}`.trim();
        details = { ...details, scorer: selectedPlayerId };
      } else {
        content = `RED CARD for ${teamName}. ${newEventContent}`.trim() || `RED CARD for ${teamName}.`;
      }
    } else if (typeToUse === 'SUB') {
      if (selectedTeam === 'A') {
        if (!selectedPlayerId || !selectedPlayerId2) return;
        content = `SUBSTITUTION (${teamName}): ${p1Name} OFF, ${p2Name} ON.`;
        details = { ...details, playerOut: selectedPlayerId, playerIn: selectedPlayerId2 };
        // Swap on the pitch lineup
        const newLineup = { ...lineup };
        const outSlot = Object.entries(newLineup).find(([, pid]) => pid === selectedPlayerId)?.[0];
        if (outSlot) {
          newLineup[outSlot] = selectedPlayerId2;
          onUpdateMatchData(match.id, { lineup: newLineup });
        }
      } else {
        content = `SUBSTITUTION for ${teamName}. ${newEventContent}`.trim() || `SUBSTITUTION for ${teamName}.`;
      }
    }

    if (!content && typeToUse === 'COMMENT') return;
    if (!content) content = `${typeToUse} recorded for ${teamName}`;

    onAddEvent({ type: typeToUse, content, details, timestamp });
    setNewEventContent('');
    setSelectedPlayerId('');
    setSelectedPlayerId2('');
    setSelectedAssistId('');
    setActiveActionType(null);
    setShowCommentComposer(false);
  };

  const handleStartEdit = (event: FeedEvent) => {
    setEditingEventId(event.id);
    setEditContent(event.content);
    const t = new Date(event.timestamp);
    setEditTime(`${String(t.getHours()).padStart(2, '0')}:${String(t.getMinutes()).padStart(2, '0')}`);
  };

  const handleSaveEdit = (eventId: string) => {
    if (!editContent.trim()) {
      setEditingEventId(null);
      return;
    }
    onUpdateEvent(eventId, {
      content: editContent.trim(),
      timestamp: buildEventTimestamp(editTime),
    });
    setEditingEventId(null);
  };

  const handleFetchIntel = async () => {
    setIsFetchingIntel(true);
    try {
      const data = await getMatchIntel(match.location, match.date, match.kickOffTime);
      setIntel(data);
    } catch (e) {
      onApiKeyTrouble();
    } finally {
      setIsFetchingIntel(false);
    }
  };

  const handleStartEditReport = () => {
    setReportDraft(match.aiSummary || '');
    setIsEditingReport(true);
    setReportJustSaved(false);
  };

  const handleCancelEditReport = () => {
    setIsEditingReport(false);
    setReportDraft('');
    setReportJustSaved(false);
  };

  const handleSaveReport = () => {
    onSaveAiSummary(match.id, reportDraft.trim());
    setIsEditingReport(false);
    setReportJustSaved(true);
    window.setTimeout(() => setReportJustSaved(false), 2000);
  };

  const handleGenerateReport = async () => {
    setIsGeneratingReport(true);
    try {
      const summary = await generateMatchSummary(match, initialEvents);
      setReportDraft(summary);
      if (!isEditingReport) setIsEditingReport(true);
    } catch (e) {
      onApiKeyTrouble();
    } finally {
      setIsGeneratingReport(false);
    }
  };

  const photoUrls = match.photoUrls || [];
  const MAX_MATCH_PHOTOS = 12;

  const handleAddMatchPhotos = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    e.target.value = '';
    if (!files.length || !canModerate) return;

    const remaining = MAX_MATCH_PHOTOS - photoUrls.length;
    if (remaining <= 0) {
      setPhotoError(`You can attach up to ${MAX_MATCH_PHOTOS} photos per match.`);
      return;
    }

    const toUpload = files.slice(0, remaining);
    setPhotoError(null);
    setIsUploadingPhotos(true);
    try {
      const uploaded: string[] = [];
      for (const file of toUpload) {
        if (!file.type.startsWith('image/')) continue;
        const url = await dbService.uploadMatchPhoto(match.clubId, match.id, file);
        uploaded.push(url);
      }
      if (uploaded.length) {
        onUpdateMatchData(match.id, { photoUrls: [...photoUrls, ...uploaded] });
      }
      if (files.length > remaining) {
        setPhotoError(`Only ${remaining} more photo${remaining === 1 ? '' : 's'} could be added (max ${MAX_MATCH_PHOTOS}).`);
      }
    } catch (err: any) {
      setPhotoError(err?.message || 'Failed to upload photo.');
    } finally {
      setIsUploadingPhotos(false);
    }
  };

  const handleRemoveMatchPhoto = async (url: string) => {
    if (!canModerate) return;
    const next = photoUrls.filter(u => u !== url);
    onUpdateMatchData(match.id, { photoUrls: next });
    try {
      await dbService.deleteMatchPhoto(url);
    } catch {
      // URL list already updated; storage cleanup is best-effort
    }
  };

  const progressionButton = useMemo(() => {
    if (match.status === 'UPCOMING') {
      return { label: 'Kick Off', icon: <Play className="w-5 h-5 fill-current" />, color: 'bg-blue-600 text-white shadow-blue-200' };
    }
    if (match.status === 'LIVE') {
      if (!hasHalfTime) {
        return { label: 'Half Time', icon: <Coffee className="w-5 h-5" />, color: 'bg-orange-500 text-white shadow-orange-200' };
      }
      if (!hasSecondHalf) {
        return { label: 'Start 2nd Half', icon: <Play className="w-5 h-5 fill-current" />, color: 'bg-blue-600 text-white shadow-blue-200' };
      }
      return { label: 'Full Time', icon: <Flag className="w-5 h-5" />, color: 'bg-slate-900 text-white shadow-slate-200' };
    }
    return null;
  }, [match.status, hasHalfTime, hasSecondHalf]);

  const inLiveFocus = match.status === 'LIVE' && liveFocusMode && activeView === 'FEED';
  const composerOpen =
    showCommentComposer || (!!activeActionType && canLogEvents);

  const scoreboard = (
    <div className="flex justify-around items-center bg-slate-900 text-white rounded-[2rem] py-4 md:py-5 shadow-xl relative overflow-hidden shrink-0">
      <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-blue-500 to-transparent"></div>
      <div className="text-center relative z-10 px-3 w-1/3 min-w-0">
        <p className="text-[9px] font-black uppercase tracking-[0.2em] mb-1.5 text-slate-500 truncate">{teamAName}</p>
        <p className="text-3xl md:text-4xl font-black tabular-nums tracking-tighter">{match.scoreA}</p>
      </div>
      <div className="text-slate-600 font-black text-sm relative z-10 px-2">VS</div>
      <div className="text-center relative z-10 px-3 w-1/3 min-w-0">
        <p className="text-[9px] font-black uppercase tracking-[0.2em] mb-1.5 text-slate-500 truncate">{teamBName}</p>
        <p className="text-3xl md:text-4xl font-black tabular-nums tracking-tighter">{match.scoreB}</p>
      </div>
    </div>
  );

  const eventActionGrid = canLogEvents ? (
    <div className="grid grid-cols-5 gap-1.5 p-1.5 bg-white rounded-[1.75rem] border border-slate-200 shadow-sm">
      <button type="button" onClick={() => handleActionClick('GOAL')} className={`flex flex-col items-center justify-center gap-1 p-2.5 sm:p-3 rounded-2xl transition-all group ${activeActionType === 'GOAL' ? 'bg-green-100 text-green-700' : 'bg-green-50 text-green-700 hover:bg-green-100'}`}><Goal className="w-5 h-5 group-hover:scale-110 transition-transform" /><span className="font-black text-[7px] sm:text-[8px] uppercase tracking-widest">Goal</span></button>
      <button type="button" onClick={() => handleActionClick('SUB')} className={`flex flex-col items-center justify-center gap-1 p-2.5 sm:p-3 rounded-2xl transition-all group ${activeActionType === 'SUB' ? 'bg-orange-100 text-orange-700' : 'bg-orange-50 text-orange-700 hover:bg-orange-100'}`}><ArrowRightLeft className="w-5 h-5 group-hover:scale-110 transition-transform" /><span className="font-black text-[7px] sm:text-[8px] uppercase tracking-widest">Sub</span></button>
      <button type="button" onClick={() => handleActionClick('YELLOW_CARD')} className={`flex flex-col items-center justify-center gap-1 p-2.5 sm:p-3 rounded-2xl transition-all group ${activeActionType === 'YELLOW_CARD' ? 'bg-yellow-100 text-yellow-700' : 'bg-yellow-50 text-yellow-700 hover:bg-yellow-100'}`}><AlertTriangle className="w-5 h-5 group-hover:scale-110 transition-transform" /><span className="font-black text-[7px] sm:text-[8px] uppercase tracking-widest">Yellow</span></button>
      <button type="button" onClick={() => handleActionClick('RED_CARD')} className={`flex flex-col items-center justify-center gap-1 p-2.5 sm:p-3 rounded-2xl transition-all group ${activeActionType === 'RED_CARD' ? 'bg-red-100 text-red-700' : 'bg-red-50 text-red-700 hover:bg-red-100'}`}><AlertOctagon className="w-5 h-5 group-hover:scale-110 transition-transform" /><span className="font-black text-[7px] sm:text-[8px] uppercase tracking-widest">Red</span></button>
      <button type="button" onClick={handleCommentClick} className={`flex flex-col items-center justify-center gap-1 p-2.5 sm:p-3 rounded-2xl transition-all group ${showCommentComposer && !activeActionType ? 'bg-blue-100 text-blue-700' : 'bg-slate-50 text-slate-600 hover:bg-slate-100'}`}><MessageSquare className="w-5 h-5 group-hover:scale-110 transition-transform" /><span className="font-black text-[7px] sm:text-[8px] uppercase tracking-widest">Comment</span></button>
    </div>
  ) : null;

  const renderPlayerRow = (player: typeof squadPlayers[number]) => {
    const canToggle = canModerate || (currentUser?.id === player.id);
    return (
      <div
        key={player.id}
        className={`flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-4 p-4 rounded-2xl border shadow-sm transition-all ${
          player.status === 'CONFIRMED'
            ? 'bg-green-50/60 border-green-100'
            : player.status === 'UNAVAILABLE'
            ? 'bg-red-50/40 border-red-100'
            : 'bg-white border-slate-100 hover:border-slate-200'
        }`}
      >
        <div className="flex items-center gap-3 sm:gap-4 min-w-0 flex-1">
          <div className="relative shrink-0">
            <img src={player.avatar || `https://i.pravatar.cc/100?u=${player.id}`} className="w-12 h-12 rounded-xl object-cover border border-slate-100" alt="" />
            {player.squadNumber != null && (
              <span className="absolute -bottom-1 -right-1 bg-slate-900 text-white text-[9px] font-black px-1.5 py-0.5 rounded-md shadow">
                #{player.squadNumber}
              </span>
            )}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-black text-slate-900 leading-tight truncate">
              {player.name}{player.id === currentUser?.id && <span className="text-blue-500 ml-1">(You)</span>}
            </p>
            <p className="text-[9px] font-black uppercase text-slate-400 tracking-widest mt-0.5">
              {player.preferredPosition || 'Player'}
              {player.secondaryPosition ? ` · ${player.secondaryPosition}` : ''}
            </p>
          </div>
        </div>

        {canToggle ? (
          <div className="grid grid-cols-2 gap-2 w-full sm:w-auto sm:min-w-[280px] sm:shrink-0">
            <button 
              onClick={() => handleSetAvailability(player.id, player.status === 'CONFIRMED' ? null : 'CONFIRMED')}
              className={`flex items-center justify-center gap-2 px-4 py-3 rounded-xl border text-[10px] font-black uppercase tracking-widest transition-all ${
                player.status === 'CONFIRMED' 
                  ? 'bg-green-600 text-white border-green-700 shadow-md shadow-green-100' 
                  : 'bg-white text-slate-500 border-slate-200 hover:text-green-700 hover:border-green-200 hover:bg-green-50'
              }`}
            >
              <UserCheck className="w-4 h-4" />
              Confirm
            </button>
            <button 
              onClick={() => handleSetAvailability(player.id, player.status === 'UNAVAILABLE' ? null : 'UNAVAILABLE')}
              className={`flex items-center justify-center gap-2 px-4 py-3 rounded-xl border text-[10px] font-black uppercase tracking-widest transition-all ${
                player.status === 'UNAVAILABLE' 
                  ? 'bg-red-600 text-white border-red-700 shadow-md shadow-red-100' 
                  : 'bg-white text-slate-500 border-slate-200 hover:text-red-700 hover:border-red-200 hover:bg-red-50'
              }`}
            >
              <UserX className="w-4 h-4" />
              Out
            </button>
          </div>
        ) : (
          <div className={`self-start sm:self-center px-4 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-widest flex items-center gap-1.5 border ${
            player.status === 'CONFIRMED' ? 'bg-green-50 text-green-700 border-green-100' :
            player.status === 'UNAVAILABLE' ? 'bg-red-50 text-red-700 border-red-100' :
            'bg-slate-50 text-slate-400 border-slate-100'
          }`}>
            {player.status === 'CONFIRMED' && <UserCheck className="w-3.5 h-3.5" />}
            {player.status === 'UNAVAILABLE' && <UserX className="w-3.5 h-3.5" />}
            {player.status}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="flex flex-col h-full bg-slate-50 md:rounded-[2.5rem] p-4 md:p-6 shadow-xl border border-slate-200 overflow-hidden relative">
      <div className="flex items-center justify-between mb-6 shrink-0 gap-3">
        <div className="min-w-0 pr-2 flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <h1 className="text-2xl md:text-3xl font-black text-slate-900 leading-none truncate">{match.title}</h1>
            <span className={`px-2 py-0.5 rounded-lg text-[9px] font-black uppercase tracking-widest border shrink-0 ${
              match.competition === 'LEAGUE'
                ? 'bg-blue-50 text-blue-700 border-blue-100'
                : match.competition === 'CUP'
                  ? 'bg-amber-50 text-amber-700 border-amber-100'
                  : 'bg-emerald-50 text-emerald-700 border-emerald-100'
            }`}>
              {match.competition === 'LEAGUE' ? 'League' : match.competition === 'CUP' ? 'Cup' : 'Friendly'}
            </span>
          </div>
          <p className="text-xs text-slate-500 flex items-center gap-2 mt-2 truncate">
            <MapPin className="w-3.5 h-3.5 text-red-400 shrink-0" /> {match.location}
            <span className="w-1 h-1 bg-slate-300 rounded-full shrink-0"></span>
            <Clock className="w-3.5 h-3.5 text-slate-400 shrink-0" />
            {canModerate ? (
              <input
                type="time"
                value={kickOffTimeValue}
                onChange={(e) => handleKickOffTimeChange(e.target.value)}
                className="bg-transparent text-xs font-bold tabular-nums text-slate-700 focus:outline-none focus:text-blue-600"
                title="Kick off / start time"
              />
            ) : (
              match.kickOffTime
            )}
          </p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          {isCoachOrManager && (
            <button
              type="button"
              onClick={() => onEditMatch(match)}
              className="bg-white p-3 rounded-2xl border border-slate-200 shadow-sm hover:bg-slate-50 transition-all"
              title="Edit match"
            >
              <Edit2 className="w-5 h-5 text-slate-500" />
            </button>
          )}
          {canModerate && (
            <button
              type="button"
              onClick={() => setShowDeleteConfirm(true)}
              className="bg-white p-3 rounded-2xl border border-slate-200 shadow-sm hover:bg-red-50 hover:border-red-100 transition-all"
              title="Delete match"
            >
              <Trash2 className="w-5 h-5 text-red-500" />
            </button>
          )}
          <button 
            onClick={handleFetchIntel}
            disabled={isFetchingIntel}
            className="bg-white p-3 rounded-2xl border border-slate-200 shadow-sm hover:bg-slate-50 transition-all group"
          >
            {isFetchingIntel ? <RefreshCw className="w-5 h-5 animate-spin text-blue-600" /> : <CloudSun className="w-5 h-5 text-blue-500 group-hover:scale-110 transition-transform" />}
          </button>
        </div>
      </div>

      <div className="flex gap-1 p-1 bg-slate-200/50 rounded-2xl mb-3 md:mb-6 shrink-0">
        <button 
          onClick={() => setActiveView('FEED')}
          className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${activeView === 'FEED' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
        >
          <History className="w-4 h-4" /> Live Feed
        </button>
        <button 
          onClick={() => setActiveView('SQUAD')}
          className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${activeView === 'SQUAD' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
        >
          <LayoutGrid className="w-4 h-4" /> Squad
        </button>
      </div>

      {inLiveFocus && (
        <div className="shrink-0 space-y-2 mb-3 z-30">
          {scoreboard}
          {plannedSubsReminderCard}
          {isMember && (
            <div className="space-y-2">
              <div className="flex items-center justify-between gap-2 px-1">
                <p className="text-[9px] font-black uppercase tracking-widest text-slate-400">
                  {match.status === 'LIVE' && !isMatchInPlay ? 'Half-time' : 'Log events'}
                </p>
                <button
                  type="button"
                  onClick={() => setLiveFocusMode(false)}
                  className="text-[9px] font-black uppercase tracking-widest text-blue-600 hover:text-blue-700"
                >
                  Show all
                </button>
              </div>
              {canModerate && progressionButton && (
                <div className="flex gap-2">
                  <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-2xl px-3 py-2 shadow-sm shrink-0">
                    <Clock className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                    <input
                      type="time"
                      value={eventTime}
                      onChange={(e) => setEventTime(e.target.value)}
                      className="bg-transparent text-xs font-bold tabular-nums text-slate-900 focus:outline-none w-[5.5rem]"
                      title="Period time"
                    />
                  </div>
                  <button
                    type="button"
                    onClick={handleMatchProgression}
                    className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all shadow-lg ${progressionButton.color}`}
                  >
                    {progressionButton.icon}
                    <span className="truncate">{progressionButton.label}</span>
                  </button>
                </div>
              )}
              {eventActionGrid}
            </div>
          )}
        </div>
      )}

      <div className="flex-1 overflow-y-auto min-h-0 scrollbar-hide">
        {activeView === 'FEED' ? (
          <div className={`space-y-6 ${composerOpen ? 'pb-56 md:pb-40' : 'pb-8 md:pb-10'}`}>
            {!inLiveFocus && intel && (
              <div className="bg-gradient-to-br from-blue-600 to-indigo-700 p-6 rounded-[2.5rem] text-white shadow-xl animate-in slide-in-from-top-4 duration-500">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2 bg-white/20 rounded-xl">
                    <CloudSun className="w-5 h-5 text-white" />
                  </div>
                  <h4 className="font-black text-xs uppercase tracking-widest">Venue Intelligence</h4>
                </div>
                <div className="space-y-3">
                  <div className="flex items-start gap-3">
                    <Wind className="w-4 h-4 text-blue-200 shrink-0 mt-1" />
                    <p className="text-sm font-medium leading-relaxed">{intel.weather}</p>
                  </div>
                  <div className="flex flex-wrap gap-2 pt-2">
                    {intel.links.map((link, idx) => (
                      <a key={idx} href={link.uri} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 bg-white/10 hover:bg-white/20 px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all border border-white/10">
                        <ExternalLink className="w-3 h-3" /> {link.title}
                      </a>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {!inLiveFocus && scoreboard}

            {match.status === 'LIVE' && !liveFocusMode && activeView === 'FEED' && (
              <button
                type="button"
                onClick={() => setLiveFocusMode(true)}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-2xl bg-blue-600 text-white text-[10px] font-black uppercase tracking-widest shadow-lg shadow-blue-200"
              >
                <Maximize2 className="w-4 h-4" /> Live logging focus
              </button>
            )}

            {!inLiveFocus && canModerate && (hasAnyPeriodEvent || match.status === 'LIVE' || match.status === 'COMPLETED') && (
              <div className="bg-white p-4 rounded-[2rem] border border-slate-200 shadow-sm">
                <div className="flex items-center gap-2 mb-3 px-1">
                  <Clock className="w-3.5 h-3.5 text-slate-400" />
                  <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400">Half times</h3>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {([
                    { key: 'start' as const, label: '1st half start', event: periodEvents.start },
                    { key: 'halfTime' as const, label: '1st half end', event: periodEvents.halfTime },
                    { key: 'secondHalf' as const, label: '2nd half start', event: periodEvents.secondHalf },
                    { key: 'end' as const, label: '2nd half end', event: periodEvents.end },
                  ]).map(({ key, label, event }) => {
                    const value = event
                      ? toHHMM(event.timestamp)
                      : key === 'start'
                        ? kickOffTimeValue
                        : '';
                    return (
                      <div
                        key={key}
                        className={`flex items-center justify-between gap-3 px-3 py-2.5 rounded-2xl border ${
                          event ? 'bg-slate-50 border-slate-100' : 'bg-slate-50/40 border-dashed border-slate-200'
                        }`}
                      >
                        <span className={`text-[10px] font-black uppercase tracking-widest truncate ${event || key === 'start' ? 'text-slate-600' : 'text-slate-300'}`}>
                          {label}
                        </span>
                        <input
                          type="time"
                          value={value}
                          onChange={(e) => handlePeriodTimeChange(key, event, e.target.value)}
                          className="bg-white border border-slate-200 rounded-xl px-2.5 py-1.5 text-xs font-bold tabular-nums text-slate-900 focus:outline-none focus:border-blue-500 shadow-sm"
                        />
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {match.status === 'COMPLETED' && (
              <div className="bg-white p-6 rounded-[2.5rem] border border-slate-200 shadow-sm animate-in slide-in-from-top-4 duration-500">
                <button
                  type="button"
                  onClick={() => setPotmExpanded(v => !v)}
                  className="w-full flex items-center gap-3 text-left"
                >
                  <div className="p-3 bg-amber-100 text-amber-600 rounded-2xl shrink-0">
                    <Award className="w-6 h-6" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <h3 className="text-lg font-black text-slate-900 tracking-tight">{potmBallotTitle}</h3>
                    <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest truncate">
                      {isCoachOrManager
                        ? 'Record fan votes · cast coach pick · opposition pick'
                        : hasVoted
                          ? `You picked ${myVotePlayer?.name || 'a player'}`
                          : myPotmCategory
                            ? 'Tap a player to vote'
                            : 'Members only'}
                    </p>
                  </div>
                  {potmExpanded ? <ChevronUp className="w-5 h-5 text-slate-400 shrink-0" /> : <ChevronDown className="w-5 h-5 text-slate-400 shrink-0" />}
                </button>

                {/* Always show the three awards once any picks exist */}
                {(coachAward || fansAward || oppositionAward) && (
                  <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-2">
                    {([
                      { key: 'coach', label: "Coach's Player", award: coachAward, accent: 'bg-blue-50 border-blue-100 text-blue-700' },
                      { key: 'fans', label: "Fan's Player", award: fansAward, accent: 'bg-amber-50 border-amber-100 text-amber-700' },
                      { key: 'opposition', label: "Opposition's Player", award: oppositionAward, accent: 'bg-slate-50 border-slate-200 text-slate-700' },
                    ] as const).map(({ key, label, award, accent }) => (
                      <div key={key} className={`rounded-2xl border px-3 py-3 ${accent}`}>
                        <p className="text-[9px] font-black uppercase tracking-widest opacity-70 mb-1">{label}</p>
                        {award?.tied ? (
                          <>
                            <p className="text-[10px] font-black uppercase tracking-widest opacity-80 mb-0.5">Joint award</p>
                            <p className="text-sm font-black tracking-tight leading-snug">
                              {award.name}
                            </p>
                          </>
                        ) : (
                          <p className="text-sm font-black tracking-tight truncate">
                            {award?.name || '—'}
                          </p>
                        )}
                      </div>
                    ))}
                  </div>
                )}

                {potmExpanded && (
                  <div className="mt-5 space-y-5 animate-in fade-in slide-in-from-top-2 duration-300">
                    {!isMember ? (
                      <p className="text-sm font-medium text-slate-500 italic text-center py-2">
                        Voting is for club members. Coaches can still record the opposition’s pick below.
                      </p>
                    ) : !hasVoted && myPotmCategory ? (
                      <div>
                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3 px-1">
                          Cast your {potmBallotTitle} vote
                        </p>
                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                          {confirmedSquad.map(player => (
                            <button
                              key={player.id}
                              type="button"
                              onClick={() => onVoteForPotm(player.id, myPotmCategory)}
                              className="flex flex-col items-center gap-3 p-4 bg-slate-50 hover:bg-amber-50 rounded-2xl border border-slate-100 hover:border-amber-200 transition-all group"
                            >
                              <img src={player.avatar || `https://i.pravatar.cc/100?u=${player.id}`} className="w-12 h-12 rounded-xl object-cover border-2 border-white shadow-sm group-hover:scale-110 transition-transform" alt="" />
                              <span className="text-[10px] font-black text-slate-700 uppercase tracking-tight text-center leading-tight truncate w-full px-1">{player.name.split(' ')[0]}</span>
                            </button>
                          ))}
                        </div>
                      </div>
                    ) : hasVoted ? (
                      <div className="rounded-2xl bg-emerald-50 border border-emerald-100 px-4 py-3 flex items-center gap-3">
                        <Check className="w-4 h-4 text-emerald-600 shrink-0" />
                        <p className="text-sm font-bold text-emerald-800">
                          Your {potmBallotTitle} vote: <span className="font-black">{myVotePlayer?.name}</span>
                        </p>
                      </div>
                    ) : null}

                    {/* Fan tallies — coaches enter counts (fans vote offline); everyone sees results */}
                    {(isCoachOrManager || fanVoteTotal > 0) && (
                      <div className="space-y-3 border-t border-slate-100 pt-4">
                        <div>
                          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">
                            Fan&apos;s Player of the Match
                          </p>
                          <p className="text-[11px] text-slate-500 px-1 mt-1">
                            {isCoachOrManager
                              ? `Enter how many fan votes each player received${
                                  fansAward
                                    ? fansAward.tied
                                      ? ` · joint: ${fansAward.name}`
                                      : ` · leader: ${fansAward.name}`
                                    : ''
                                }.`
                              : fansAward
                                ? fansAward.tied
                                  ? `Joint award: ${fansAward.name}`
                                  : `Winner: ${fansAward.name}`
                                : 'Vote counts from the fans.'}
                          </p>
                        </div>

                        {isCoachOrManager ? (
                          <div className="space-y-2">
                            {confirmedSquad.map(player => {
                              const votes = potmVotes.fanCounts?.[player.id] ?? 0;
                              return (
                                <div
                                  key={player.id}
                                  className="flex items-center gap-3 p-2.5 bg-slate-50 rounded-2xl border border-slate-100"
                                >
                                  <img
                                    src={player.avatar || `https://i.pravatar.cc/100?u=${player.id}`}
                                    className="w-9 h-9 rounded-xl object-cover shrink-0"
                                    alt=""
                                  />
                                  <span className="text-xs font-black text-slate-900 truncate flex-1">
                                    {player.name}
                                  </span>
                                  <label className="flex items-center gap-2 shrink-0">
                                    <input
                                      type="number"
                                      min={0}
                                      max={9999}
                                      inputMode="numeric"
                                      value={votes}
                                      onChange={(e) => handleFanCountChange(player.id, e.target.value)}
                                      className="w-16 bg-white border border-slate-200 rounded-xl px-2 py-1.5 text-sm font-black tabular-nums text-slate-900 text-center focus:outline-none focus:border-amber-400 shadow-sm"
                                    />
                                    <span className="text-[9px] font-black uppercase tracking-widest text-slate-400 w-10">
                                      {votes === 1 ? 'vote' : 'votes'}
                                    </span>
                                  </label>
                                </div>
                              );
                            })}
                            <p className="text-[10px] font-bold text-slate-400 px-1 tabular-nums">
                              Total fan votes: {fanVoteTotal}
                              {fansAward
                                ? fansAward.tied
                                  ? ` · Joint Fan's Player: ${fansAward.name}`
                                  : ` · Fan's Player: ${fansAward.name}`
                                : ''}
                            </p>
                          </div>
                        ) : (
                          <div className="space-y-3">
                            {confirmedSquad
                              .map(player => ({ player, votes: potmCategoryResults.fans[player.id] || 0 }))
                              .filter(r => r.votes > 0)
                              .sort((a, b) => b.votes - a.votes)
                              .map(({ player, votes }) => {
                                const percentage = fanVoteTotal > 0 ? (votes / fanVoteTotal) * 100 : 0;
                                return (
                                  <div key={player.id} className="space-y-2">
                                    <div className="flex justify-between items-center px-1">
                                      <span className="text-xs font-black text-slate-900 uppercase tracking-tight truncate flex-1 pr-2">{player.name}</span>
                                      <span className="text-[10px] font-black text-slate-500 tabular-nums">{votes} {votes === 1 ? 'vote' : 'votes'} ({Math.round(percentage)}%)</span>
                                    </div>
                                    <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                                      <div className="h-full bg-amber-400 rounded-full transition-all duration-1000" style={{ width: `${percentage}%` }} />
                                    </div>
                                  </div>
                                );
                              })}
                          </div>
                        )}

                        {isCoachOrManager && !usingManualFanCounts && potmVoterEntries('fans').length > 0 && (
                          <div className="pt-2 space-y-1.5">
                            <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest px-1">In-app fan voters</p>
                            {potmVoterEntries('fans').map(v => (
                              <p key={v.voterId} className="text-[11px] text-slate-500 px-1">
                                <span className="font-bold text-slate-700">{v.voterName}</span>
                                {' → '}
                                {v.playerName}
                              </p>
                            ))}
                          </div>
                        )}
                      </div>
                    )}

                    {isCoachOrManager && Object.keys(potmCategoryResults.coach).length > 0 && (
                      <div className="space-y-1.5">
                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">Coach votes</p>
                        {potmVoterEntries('coach').map(v => (
                          <p key={v.voterId} className="text-[11px] text-slate-500 px-1">
                            <span className="font-bold text-slate-700">{v.voterName}</span>
                            {' → '}
                            {v.playerName}
                          </p>
                        ))}
                      </div>
                    )}

                    {/* Opposition pick — recorded by coaches/managers/admins */}
                    {isCoachOrManager && (
                      <div className="space-y-3 border-t border-slate-100 pt-4">
                        <div>
                          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-1">
                            Opposition&apos;s Player of the Match
                          </p>
                          <p className="text-[11px] text-slate-500 px-1 mt-1">
                            Record who the opposition chose{oppositionAward ? ` (currently ${oppositionAward.name})` : ''}.
                          </p>
                        </div>
                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                          {confirmedSquad.map(player => {
                            const selected = oppositionAward?.playerIds.includes(player.id);
                            return (
                              <button
                                key={player.id}
                                type="button"
                                onClick={() => onVoteForPotm(player.id, 'opposition')}
                                className={`flex flex-col items-center gap-3 p-4 rounded-2xl border transition-all group ${
                                  selected
                                    ? 'bg-slate-900 text-white border-slate-900'
                                    : 'bg-slate-50 hover:bg-slate-100 border-slate-100 hover:border-slate-300'
                                }`}
                              >
                                <img src={player.avatar || `https://i.pravatar.cc/100?u=${player.id}`} className={`w-12 h-12 rounded-xl object-cover border-2 shadow-sm group-hover:scale-110 transition-transform ${selected ? 'border-slate-700' : 'border-white'}`} alt="" />
                                <span className={`text-[10px] font-black uppercase tracking-tight text-center leading-tight truncate w-full px-1 ${selected ? 'text-white' : 'text-slate-700'}`}>{player.name.split(' ')[0]}</span>
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}

            {!inLiveFocus && (match.status === 'COMPLETED' || !!match.aiSummary) && (
              <div className="bg-white p-6 rounded-[2.5rem] border border-slate-200 shadow-sm">
                <div className="flex items-start justify-between gap-3 mb-4">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="p-3 bg-slate-100 text-slate-600 rounded-2xl shrink-0">
                      <ReportIcon className="w-6 h-6" />
                    </div>
                    <div className="min-w-0">
                      <h3 className="text-lg font-black text-slate-900 tracking-tight">Match Report</h3>
                      <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                        {reportJustSaved ? 'Saved for the season booklet' : 'Season booklet archive'}
                      </p>
                    </div>
                  </div>
                  {canModerate && !isEditingReport && (
                    <div className="flex items-center gap-2 shrink-0">
                      {match.aiSummary && (
                        <button
                          type="button"
                          onClick={handleStartEditReport}
                          className="p-2.5 bg-slate-50 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-xl border border-slate-100 transition-all"
                          title="Edit report"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  )}
                </div>

                {isEditingReport ? (
                  <div className="space-y-3">
                    <textarea
                      value={reportDraft}
                      onChange={(e) => setReportDraft(e.target.value)}
                      rows={10}
                      placeholder="Write the match report for the season booklet — flow of the game, key moments, scorers, and the result…"
                      className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-4 py-3 text-sm font-medium text-slate-800 leading-relaxed focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/10 resize-y min-h-[180px]"
                    />
                    <div className="flex flex-col sm:flex-row gap-2">
                      <button
                        type="button"
                        onClick={handleGenerateReport}
                        disabled={isGeneratingReport}
                        className="flex items-center justify-center gap-2 px-4 py-3 rounded-2xl bg-slate-900 text-white text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 transition-all disabled:opacity-60"
                      >
                        {isGeneratingReport ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Sparkles className="w-3.5 h-3.5" />}
                        {isGeneratingReport ? 'Drafting…' : 'Draft with AI'}
                      </button>
                      <div className="flex gap-2 flex-1">
                        <button
                          type="button"
                          onClick={handleSaveReport}
                          className="flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-2xl bg-blue-600 text-white text-[10px] font-black uppercase tracking-widest hover:bg-blue-700 transition-all shadow-sm"
                        >
                          <Check className="w-3.5 h-3.5" /> Save report
                        </button>
                        <button
                          type="button"
                          onClick={handleCancelEditReport}
                          className="px-4 py-3 rounded-2xl bg-slate-100 text-slate-500 text-[10px] font-black uppercase tracking-widest hover:bg-slate-200 transition-all"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  </div>
                ) : match.aiSummary ? (
                  <p className="text-sm text-slate-600 font-medium leading-relaxed whitespace-pre-wrap">{match.aiSummary}</p>
                ) : canModerate ? (
                  <div className="py-6 text-center space-y-4">
                    <p className="text-sm font-medium text-slate-400">
                      No report yet. Add one for the end-of-season booklet.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-2 justify-center">
                      <button
                        type="button"
                        onClick={handleStartEditReport}
                        className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-2xl bg-blue-600 text-white text-[10px] font-black uppercase tracking-widest hover:bg-blue-700 transition-all"
                      >
                        <ReportIcon className="w-3.5 h-3.5" /> Write report
                      </button>
                      <button
                        type="button"
                        onClick={handleGenerateReport}
                        disabled={isGeneratingReport}
                        className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-2xl bg-slate-900 text-white text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 transition-all disabled:opacity-60"
                      >
                        {isGeneratingReport ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Sparkles className="w-3.5 h-3.5" />}
                        {isGeneratingReport ? 'Drafting…' : 'Draft with AI'}
                      </button>
                    </div>
                  </div>
                ) : (
                  <p className="text-sm font-medium text-slate-400 italic text-center py-4">
                    Match report not published yet.
                  </p>
                )}
              </div>
            )}

            {!inLiveFocus && (match.status === 'COMPLETED' || photoUrls.length > 0) && (
              <div className="bg-white p-6 rounded-[2.5rem] border border-slate-200 shadow-sm">
                <div className="flex items-start justify-between gap-3 mb-4">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="p-3 bg-rose-50 text-rose-500 rounded-2xl shrink-0">
                      <ImagePlus className="w-6 h-6" />
                    </div>
                    <div className="min-w-0">
                      <h3 className="text-lg font-black text-slate-900 tracking-tight">Match Photos</h3>
                      <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                        Season booklet · {photoUrls.length}/{MAX_MATCH_PHOTOS}
                      </p>
                    </div>
                  </div>
                  {canModerate && photoUrls.length < MAX_MATCH_PHOTOS && (
                    <button
                      type="button"
                      onClick={() => photoInputRef.current?.click()}
                      disabled={isUploadingPhotos}
                      className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 text-white text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 transition-all disabled:opacity-50 shrink-0"
                    >
                      {isUploadingPhotos ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Camera className="w-3.5 h-3.5" />}
                      {isUploadingPhotos ? 'Uploading…' : 'Add'}
                    </button>
                  )}
                  <input
                    ref={photoInputRef}
                    type="file"
                    accept="image/*"
                    multiple
                    className="hidden"
                    onChange={handleAddMatchPhotos}
                  />
                </div>

                {photoError && (
                  <div className="mb-4 bg-red-50 border border-red-100 text-red-700 text-xs font-medium px-4 py-3 rounded-2xl">
                    {photoError}
                  </div>
                )}

                {photoUrls.length > 0 ? (
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                    {photoUrls.map((url) => (
                      <div key={url} className="relative group aspect-[4/3] rounded-2xl overflow-hidden border border-slate-100 bg-slate-50">
                        <button
                          type="button"
                          onClick={() => setLightboxUrl(url)}
                          className="absolute inset-0"
                          title="View photo"
                        >
                          <img src={url} alt="" className="w-full h-full object-cover" />
                        </button>
                        {canModerate && (
                          <button
                            type="button"
                            onClick={() => handleRemoveMatchPhoto(url)}
                            className="absolute top-2 right-2 p-2 rounded-xl bg-slate-900/70 text-white opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity"
                            title="Remove photo"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                ) : canModerate ? (
                  <button
                    type="button"
                    onClick={() => photoInputRef.current?.click()}
                    disabled={isUploadingPhotos}
                    className="w-full py-10 rounded-[2rem] border border-dashed border-slate-200 bg-slate-50/60 hover:bg-slate-50 transition-all flex flex-col items-center gap-3 disabled:opacity-50"
                  >
                    {isUploadingPhotos ? (
                      <Loader2 className="w-6 h-6 text-slate-400 animate-spin" />
                    ) : (
                      <Camera className="w-6 h-6 text-slate-300" />
                    )}
                    <p className="text-sm font-bold text-slate-400">
                      {isUploadingPhotos ? 'Uploading…' : 'Add photos for the season booklet'}
                    </p>
                    <p className="text-[10px] font-black uppercase tracking-widest text-slate-300">
                      Up to {MAX_MATCH_PHOTOS} images
                    </p>
                  </button>
                ) : (
                  <p className="text-sm font-medium text-slate-400 italic text-center py-4">
                    No match photos yet.
                  </p>
                )}
              </div>
            )}

            {lightboxUrl && (
              <div
                className="fixed inset-0 z-[130] bg-slate-950/85 backdrop-blur-sm flex items-center justify-center p-4"
                onClick={() => setLightboxUrl(null)}
              >
                <button
                  type="button"
                  onClick={() => setLightboxUrl(null)}
                  className="absolute top-4 right-4 p-3 rounded-full bg-white/10 text-white hover:bg-white/20"
                >
                  <X className="w-5 h-5" />
                </button>
                <img
                  src={lightboxUrl}
                  alt=""
                  className="max-w-full max-h-[85vh] rounded-2xl object-contain shadow-2xl"
                  onClick={(e) => e.stopPropagation()}
                />
              </div>
            )}

            {!inLiveFocus && isMember && (match.status === 'UPCOMING' || match.status === 'LIVE' || (canLogEvents && canModerate)) && (
              <div className="space-y-3">
                {canModerate && progressionButton && (
                  <div className="flex flex-col sm:flex-row gap-2">
                    <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-[2rem] px-4 py-3 sm:py-0 shadow-sm shrink-0">
                      <Clock className="w-4 h-4 text-slate-400 shrink-0" />
                      <label className="text-[9px] font-black uppercase tracking-widest text-slate-400 sm:hidden">Time</label>
                      <input
                        type="time"
                        value={eventTime}
                        onChange={(e) => setEventTime(e.target.value)}
                        className="bg-transparent text-xs font-bold tabular-nums text-slate-900 focus:outline-none"
                        title="Period time"
                      />
                    </div>
                    <button onClick={handleMatchProgression} className={`flex-1 flex items-center justify-center gap-3 py-5 rounded-[2rem] font-black text-xs uppercase tracking-[0.2em] transition-all group shadow-xl hover:-translate-y-1 active:translate-y-0 ${progressionButton.color}`}>
                      <div className="group-hover:scale-110 transition-transform">{progressionButton.icon}</div>
                      <span>{progressionButton.label}</span>
                    </button>
                  </div>
                )}
                {eventActionGrid}
                {match.status === 'UPCOMING' && isMember && !canLogEvents && (
                  <button
                    type="button"
                    onClick={handleCommentClick}
                    className={`w-full flex items-center justify-center gap-2 py-4 rounded-[2rem] border text-[10px] font-black uppercase tracking-widest transition-all ${
                      showCommentComposer
                        ? 'bg-blue-100 text-blue-700 border-blue-200'
                        : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <MessageSquare className="w-4 h-4" /> Comment
                  </button>
                )}
                {match.status === 'UPCOMING' && <div className="text-center py-4 bg-slate-100/50 rounded-[2rem] border border-dashed border-slate-200"><p className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Waiting for Kick Off</p></div>}
                {match.status === 'LIVE' && !isMatchInPlay && <div className="text-center py-4 bg-slate-100/50 rounded-[2rem] border border-dashed border-slate-200"><p className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Match at Half-Time</p></div>}
                {match.status === 'COMPLETED' && canModerate && <div className="text-center py-2"><p className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Post-match · add or edit timeline events</p></div>}
              </div>
            )}

            {!inLiveFocus && matchMinutesRows.length > 0 && (match.status === 'COMPLETED' || match.status === 'LIVE') && (
              <div className="bg-white p-5 rounded-[2rem] border border-slate-200 shadow-sm space-y-3">
                <div className="flex items-center justify-between gap-2 px-1">
                  <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2">
                    <Clock className="w-3.5 h-3.5" /> Minutes played
                  </h3>
                  <span className="text-[10px] font-bold text-slate-400 tabular-nums">
                    {matchMinutesRows.reduce((sum, r) => sum + r.minutes, 0)}′ total
                  </span>
                </div>
                <div className="space-y-1.5 max-h-64 overflow-y-auto pr-1">
                  {matchMinutesRows.map(row => (
                    <div
                      key={row.id}
                      className="flex items-center gap-3 p-2 rounded-xl bg-slate-50 border border-slate-100"
                    >
                      <img
                        src={row.avatar || `https://i.pravatar.cc/100?u=${row.id}`}
                        className="w-8 h-8 rounded-lg object-cover shrink-0"
                        alt=""
                      />
                      <span className="text-xs font-black text-slate-900 truncate flex-1">{row.name}</span>
                      <span className="text-sm font-black tabular-nums text-slate-900">{formatMinutes(row.minutes)}</span>
                    </div>
                  ))}
                </div>
                {(!periodEvents.start || !periodEvents.end) && (
                  <p className="text-[10px] font-medium text-amber-600 px-1">
                    Tip: set half times for more accurate minutes.
                  </p>
                )}
              </div>
            )}

            <div className="space-y-4">
              {!inLiveFocus && plannedSubsReminderCard}
              <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2 px-2"><History className="w-3.5 h-3.5" /> Match Timeline</h3>
              {events.length === 0 ? (
                <div className="py-20 text-center"><div className="bg-slate-100 w-16 h-16 rounded-3xl flex items-center justify-center mx-auto mb-4"><History className="w-6 h-6 text-slate-300" /></div><p className="text-sm font-bold text-slate-300 italic">Waiting for events...</p></div>
              ) : (
                events.map(event => (
                  <div key={event.id} className="bg-white p-5 rounded-[2rem] border border-slate-100 shadow-sm flex items-start gap-4 animate-in slide-in-from-top-2 duration-300 relative group">
                    <div className="p-3 bg-slate-50 rounded-2xl shrink-0">{liveIconMapping[event.type] || <Info className="w-4 h-4 text-slate-400" />}</div>
                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-center mb-1">
                        <p className="text-[10px] font-black text-slate-900 uppercase tracking-widest">{event.userName}</p>
                        <div className="flex items-center gap-2">
                          <p className="text-[9px] text-slate-400 font-bold">{new Date(event.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</p>
                          {(event.userId === currentUser?.id || canModerate) && editingEventId !== event.id && (
                            <div className="flex items-center gap-1 md:opacity-0 md:group-hover:opacity-100 transition-opacity">
                              <button onClick={() => handleStartEdit(event)} className="p-1 text-slate-300 hover:text-blue-500 transition-colors" title="Edit event"><Edit2 className="w-3 h-3" /></button>
                              <button onClick={() => onDeleteEvent(event.id)} className="p-1 text-slate-300 hover:text-red-500 transition-colors" title="Delete event"><Trash2 className="w-3 h-3" /></button>
                            </div>
                          )}
                        </div>
                      </div>
                      {editingEventId === event.id ? (
                        <div className="flex flex-col gap-2 mt-2">
                          <div className="flex items-center gap-2">
                            <Clock className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                            <input
                              type="time"
                              value={editTime}
                              onChange={(e) => setEditTime(e.target.value)}
                              className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                            />
                          </div>
                          <div className="flex gap-2 items-center">
                            <input autoFocus type="text" value={editContent} onChange={(e) => setEditContent(e.target.value)} className="flex-1 bg-slate-50 border border-slate-200 rounded-xl px-4 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-blue-500/20" />
                            <button onClick={() => handleSaveEdit(event.id)} className="p-2 bg-blue-600 text-white rounded-xl shadow-sm"><Check className="w-4 h-4" /></button>
                            <button onClick={() => setEditingEventId(null)} className="p-2 bg-slate-100 text-slate-400 rounded-xl"><X className="w-4 h-4" /></button>
                          </div>
                        </div>
                      ) : <p className="text-sm text-slate-600 font-medium leading-snug">{event.content}</p>}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        ) : (
          <div className="space-y-6 animate-in fade-in duration-500 pb-10">
            <div className="flex gap-1 p-1 bg-slate-200/50 rounded-2xl">
              <button
                onClick={() => setSquadTab('AVAILABILITY')}
                className={`flex-1 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${
                  squadTab === 'AVAILABILITY' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500'
                }`}
              >
                Availability ({confirmedSquad.length}/{squadPlayers.length})
              </button>
              <button
                onClick={() => setSquadTab('LINEUP')}
                className={`flex-1 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${
                  squadTab === 'LINEUP' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500'
                }`}
              >
                Lineup ({Object.keys(lineup).length}/{teamSize})
              </button>
              <button
                onClick={() => setSquadTab('SUBS')}
                className={`flex-1 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${
                  squadTab === 'SUBS' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500'
                }`}
              >
                Subs
              </button>
            </div>

            {squadTab === 'AVAILABILITY' ? (
              <div className="space-y-8">
                <div className="text-center py-4">
                  <div className="inline-flex p-4 bg-blue-50 text-blue-600 rounded-[1.5rem] mb-3"><Users className="w-7 h-7" /></div>
                  <h2 className="text-xl font-black text-slate-900 tracking-tight">Player Availability</h2>
                  <p className="text-sm text-slate-500 font-medium mt-1">Players only · confirm who can play</p>
                </div>

                {squadPlayers.length === 0 ? (
                  <div className="p-8 text-center bg-white rounded-[2rem] border border-dashed border-slate-200">
                    <p className="text-xs text-slate-400 font-bold">No players found in club roster</p>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {confirmedSquad.length > 0 && (
                      <div className="space-y-3">
                        <h3 className="text-[10px] font-black uppercase tracking-widest text-green-600 flex items-center gap-2 px-1">
                          <UserCheck className="w-3.5 h-3.5" /> Confirmed ({confirmedSquad.length})
                        </h3>
                        <div className="space-y-2">{confirmedSquad.map(renderPlayerRow)}</div>
                      </div>
                    )}
                    {pendingSquad.length > 0 && (
                      <div className="space-y-3">
                        <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2 px-1">
                          Pending ({pendingSquad.length})
                        </h3>
                        <div className="space-y-2">{pendingSquad.map(renderPlayerRow)}</div>
                      </div>
                    )}
                    {unavailableSquad.length > 0 && (
                      <div className="space-y-3">
                        <h3 className="text-[10px] font-black uppercase tracking-widest text-red-500 flex items-center gap-2 px-1">
                          <UserX className="w-3.5 h-3.5" /> Unavailable ({unavailableSquad.length})
                        </h3>
                        <div className="space-y-2">{unavailableSquad.map(renderPlayerRow)}</div>
                      </div>
                    )}
                  </div>
                )}

                {canModerate && confirmedSquad.length > 0 && (
                  <button
                    onClick={() => setSquadTab('LINEUP')}
                    className="w-full py-4 bg-slate-900 text-white rounded-2xl font-black text-[10px] uppercase tracking-widest hover:bg-slate-800 transition-all"
                  >
                    Set Starting Lineup →
                  </button>
                )}
              </div>
            ) : squadTab === 'SUBS' ? (
              <SubPlanPanel
                match={match}
                confirmedSquad={confirmedSquad}
                startingLineup={plannerStartingLineup}
                seasonMinutes={seasonMinutes}
                canEdit={isCoachOrManager}
                clubName={club?.name}
                onSave={handleSaveSubPlan}
                onGoToLineup={() => setSquadTab('LINEUP')}
              />
            ) : (
              <div className="space-y-6">
                {confirmedSquad.length === 0 ? (
                  <div className="p-10 text-center bg-white rounded-[2rem] border border-dashed border-slate-200">
                    <Users className="w-8 h-8 text-slate-300 mx-auto mb-3" />
                    <p className="text-sm font-bold text-slate-500">Confirm players first</p>
                    <p className="text-xs text-slate-400 mt-1">Mark availability, then pick a formation and lineup.</p>
                    <button
                      onClick={() => setSquadTab('AVAILABILITY')}
                      className="mt-4 px-5 py-2.5 bg-blue-600 text-white rounded-xl text-[10px] font-black uppercase tracking-widest"
                    >
                      Go to Availability
                    </button>
                  </div>
                ) : (
                  <>
                    <div className="space-y-3">
                      <div className="space-y-1.5">
                        <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 px-1">Format</label>
                        <div className="flex flex-wrap gap-1.5">
                          {TEAM_SIZES.map(({ size, label }) => (
                            <button
                              key={size}
                              disabled={!canModerate}
                              onClick={() => handleSetTeamSize(size)}
                              className={`px-3 py-2 rounded-xl text-[10px] font-black tracking-widest transition-all border ${
                                teamSize === size
                                  ? 'bg-blue-600 text-white border-blue-600'
                                  : 'bg-white text-slate-500 border-slate-200 hover:border-slate-300'
                              } disabled:opacity-60`}
                            >
                              {label}
                            </button>
                          ))}
                        </div>
                      </div>

                      <div className="space-y-1.5">
                        <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 px-1">Formation</label>
                        <div className="flex flex-wrap gap-1.5">
                          {availableFormations.map(name => (
                            <button
                              key={name}
                              disabled={!canModerate}
                              onClick={() => handleSetFormation(name)}
                              className={`px-3 py-2 rounded-xl text-[10px] font-black tracking-widest transition-all border ${
                                formation === name
                                  ? 'bg-slate-900 text-white border-slate-900'
                                  : 'bg-white text-slate-500 border-slate-200 hover:border-slate-300'
                              } disabled:opacity-60`}
                            >
                              {name}
                            </button>
                          ))}
                        </div>
                        {!canModerate && (
                          <p className="text-[10px] text-slate-400 font-medium px-1">Only admins can edit the lineup.</p>
                        )}
                      </div>
                    </div>

                    {/* Desktop: players left, compact half-pitch right */}
                    <div className="flex flex-col lg:flex-row gap-3 lg:gap-4 lg:items-stretch">
                      {/* Player pool / bench (left on PC) */}
                      <div className="w-full lg:w-64 xl:w-72 shrink-0 space-y-2 order-2 lg:order-1">
                        <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2 px-1">
                          <Users className="w-3.5 h-3.5" /> Available ({benchPlayers.length})
                        </h3>

                        {canModerate && (
                          <p className="text-[10px] text-slate-400 font-medium px-1">
                            Drag players onto the pitch · drag back here to bench
                          </p>
                        )}

                        {canModerate && selectedSlotId && (
                          <div className="bg-amber-50 border border-amber-200 rounded-xl px-3 py-2 text-[10px] font-black uppercase tracking-widest text-amber-700">
                            Place · {formationSlots.find(s => s.id === selectedSlotId)?.label}
                            <button type="button" onClick={() => setSelectedSlotId(null)} className="ml-2 underline">Cancel</button>
                          </div>
                        )}

                        <div
                          onDragOver={(e) => {
                            if (!canModerate || !lineupDragRef.current?.fromSlotId) return;
                            e.preventDefault();
                            e.dataTransfer.dropEffect = 'move';
                            setLineupDropTarget('bench');
                          }}
                          onDragLeave={(e) => {
                            if (!e.currentTarget.contains(e.relatedTarget as Node)) {
                              setLineupDropTarget(t => (t === 'bench' ? null : t));
                            }
                          }}
                          onDrop={(e) => {
                            e.preventDefault();
                            handleLineupDropOnBench();
                          }}
                          className={`rounded-xl transition-all ${
                            lineupDropTarget === 'bench'
                              ? 'ring-2 ring-red-400 ring-offset-2 bg-red-50/80'
                              : ''
                          }`}
                        >
                          {benchPlayers.length === 0 ? (
                            <div className={`p-4 text-center bg-slate-50 rounded-xl border border-dashed ${
                              lineupDropTarget === 'bench' ? 'border-red-300' : 'border-slate-200'
                            }`}>
                              <p className="text-[11px] text-slate-400 font-bold">
                                {lineupDropTarget === 'bench'
                                  ? 'Drop to bench'
                                  : Object.keys(lineup).length === 0
                                  ? 'Drag a player onto a pitch slot'
                                  : 'All confirmed players are on the pitch'}
                              </p>
                            </div>
                          ) : (
                            <div className="space-y-1.5 max-h-48 lg:max-h-[280px] overflow-y-auto pr-1">
                              {benchPlayers.map(player => (
                                <div
                                  key={player.id}
                                  draggable={canModerate}
                                  onDragStart={(e) => handleLineupDragStart(e, player.id, null)}
                                  onDragEnd={handleLineupDragEnd}
                                  className={`flex items-center gap-2.5 p-2 bg-white rounded-xl border border-slate-100 ${
                                    canModerate ? 'cursor-grab active:cursor-grabbing' : ''
                                  } ${lineupDrag?.playerId === player.id ? 'opacity-50' : ''}`}
                                >
                                  <img src={player.avatar || `https://i.pravatar.cc/100?u=${player.id}`} className="w-8 h-8 rounded-lg object-cover shrink-0 pointer-events-none" alt="" />
                                  <div className="min-w-0 flex-1 pointer-events-none">
                                    <p className="text-[11px] font-black text-slate-900 truncate">
                                      {player.squadNumber != null ? `#${player.squadNumber} ` : ''}{player.name}
                                    </p>
                                    <p className="text-[8px] font-bold text-slate-400 uppercase tracking-widest">
                                      {player.preferredPosition || 'Bench'}
                                    </p>
                                  </div>
                                  {canModerate && selectedSlotId && (
                                    <button
                                      type="button"
                                      onClick={() => handleAssignPlayerToSlot(selectedSlotId, player.id)}
                                      className="px-2.5 py-1 bg-blue-600 text-white rounded-lg text-[8px] font-black uppercase tracking-widest shrink-0"
                                    >
                                      Place
                                    </button>
                                  )}
                                </div>
                              ))}
                            </div>
                          )}
                        </div>

                        {canModerate && selectedSlotId && lineup[selectedSlotId] && (
                          <button
                            type="button"
                            onClick={() => handleAssignPlayerToSlot(selectedSlotId, null)}
                            className="w-full text-left px-3 py-2 rounded-xl border border-red-100 bg-red-50 text-red-600 text-[11px] font-bold"
                          >
                            Clear {formationSlots.find(s => s.id === selectedSlotId)?.label}
                          </button>
                        )}

                        {Object.keys(lineup).length > 0 && (
                          <div className="space-y-1 pt-2 border-t border-slate-100">
                            <h3 className="text-[10px] font-black uppercase tracking-widest text-green-600 px-1">
                              Starting ({Object.keys(lineup).length}/{teamSize})
                            </h3>
                            <div className="max-h-36 lg:max-h-[160px] overflow-y-auto space-y-1 pr-1">
                              {formationSlots.map(slot => {
                                const assigned = squadPlayers.find(p => p.id === lineup[slot.id]);
                                if (!assigned) return null;
                                return (
                                  <button
                                    key={slot.id}
                                    type="button"
                                    disabled={!canModerate}
                                    draggable={canModerate}
                                    onDragStart={(e) => handleLineupDragStart(e, assigned.id, slot.id)}
                                    onDragEnd={handleLineupDragEnd}
                                    onClick={() => setSelectedSlotId(selectedSlotId === slot.id ? null : slot.id)}
                                    className={`w-full flex items-center gap-2 p-1.5 rounded-lg border text-left transition-all ${
                                      selectedSlotId === slot.id ? 'border-amber-300 bg-amber-50' : 'border-slate-100 bg-white'
                                    } ${canModerate ? 'cursor-grab active:cursor-grabbing' : ''} ${
                                      lineupDrag?.playerId === assigned.id ? 'opacity-50' : ''
                                    }`}
                                  >
                                    <span className="text-[8px] font-black text-slate-400 w-6 pointer-events-none">{slot.label}</span>
                                    <img src={assigned.avatar || `https://i.pravatar.cc/100?u=${assigned.id}`} className="w-6 h-6 rounded-md object-cover pointer-events-none" alt="" />
                                    <span className="text-[11px] font-black text-slate-900 truncate flex-1 pointer-events-none">
                                      {assigned.squadNumber != null ? `#${assigned.squadNumber} ` : ''}{assigned.name}
                                    </span>
                                  </button>
                                );
                              })}
                            </div>
                          </div>
                        )}

                        {canModerate && Object.keys(lineup).length > 0 && (
                          <button
                            type="button"
                            onClick={() => setSquadTab('SUBS')}
                            className="w-full py-3 bg-orange-500 text-white rounded-xl font-black text-[10px] uppercase tracking-widest hover:bg-orange-600 transition-all"
                          >
                            Plan substitutions →
                          </button>
                        )}
                      </div>

                      {/* Compact half-pitch */}
                      <div className="flex-1 order-1 lg:order-2 min-w-0 flex flex-col">
                        <div className="relative w-full max-w-md lg:max-w-lg mx-auto h-[340px] sm:h-[380px] lg:h-[420px] rounded-2xl overflow-hidden border-[3px] border-green-800 shadow-lg bg-gradient-to-b from-green-500 to-green-700">
                          {/* Half-pitch markings: halfway at top, goal at bottom */}
                          <div className="absolute inset-0 opacity-15" style={{ backgroundImage: 'repeating-linear-gradient(90deg, transparent, transparent 10%, rgba(255,255,255,0.35) 10%, rgba(255,255,255,0.35) 10.5%)' }} />
                          <div className="absolute left-0 right-0 top-0 h-0.5 bg-white/50" />
                          <div className="absolute left-1/2 top-0 w-12 h-6 border-2 border-t-0 border-white/40 rounded-b-full -translate-x-1/2" />
                          <div className="absolute left-[28%] right-[28%] bottom-0 h-[18%] border-2 border-b-0 border-white/45" />
                          <div className="absolute left-[38%] right-[38%] bottom-0 h-[8%] border-2 border-b-0 border-white/45" />

                          {formationSlots.map(slot => {
                            const assigned = squadPlayers.find(p => p.id === lineup[slot.id]);
                            const isSelected = selectedSlotId === slot.id;
                            const isDropTarget = lineupDropTarget === slot.id;
                            const pos = spreadSlotPosition(slot.x, slot.y);
                            return (
                              <button
                                key={slot.id}
                                type="button"
                                disabled={!canModerate}
                                draggable={canModerate && !!assigned}
                                onClick={() => setSelectedSlotId(isSelected ? null : slot.id)}
                                onDragStart={(e) => {
                                  if (!assigned) {
                                    e.preventDefault();
                                    return;
                                  }
                                  handleLineupDragStart(e, assigned.id, slot.id);
                                }}
                                onDragEnd={handleLineupDragEnd}
                                onDragOver={(e) => {
                                  if (!canModerate || !lineupDragRef.current) return;
                                  e.preventDefault();
                                  e.dataTransfer.dropEffect = lineupDragRef.current.fromSlotId ? 'move' : 'copy';
                                  setLineupDropTarget(slot.id);
                                }}
                                onDragLeave={(e) => {
                                  if (!e.currentTarget.contains(e.relatedTarget as Node)) {
                                    setLineupDropTarget(t => (t === slot.id ? null : t));
                                  }
                                }}
                                onDrop={(e) => {
                                  e.preventDefault();
                                  e.stopPropagation();
                                  handleLineupDropOnSlot(slot.id);
                                }}
                                className={`absolute -translate-x-1/2 -translate-y-1/2 flex flex-col items-center gap-1 transition-transform ${
                                  isSelected || isDropTarget ? 'scale-110 z-20' : 'z-10 hover:scale-105'
                                } ${canModerate && assigned ? 'cursor-grab active:cursor-grabbing' : 'disabled:cursor-default'}`}
                                style={{ left: `${pos.x}%`, top: `${pos.y}%` }}
                              >
                                <div
                                  className={`w-12 h-12 sm:w-14 sm:h-14 rounded-full border-2 flex items-center justify-center shadow-md overflow-hidden pointer-events-none ${
                                    isDropTarget
                                      ? 'border-amber-300 ring-2 ring-amber-300/70 bg-slate-900'
                                      : isSelected
                                      ? 'border-amber-300 ring-2 ring-amber-300/50 bg-slate-900'
                                      : assigned
                                      ? 'border-white bg-slate-900'
                                      : 'border-dashed border-white/70 bg-black/25'
                                  } ${lineupDrag?.playerId === assigned?.id ? 'opacity-40' : ''}`}
                                >
                                  {assigned ? (
                                    <img src={assigned.avatar || `https://i.pravatar.cc/100?u=${assigned.id}`} className="w-full h-full object-cover" alt="" />
                                  ) : (
                                    <span className="text-[9px] font-black text-white/90">{slot.label}</span>
                                  )}
                                </div>
                                <span className="text-[9px] font-black text-white bg-black/55 px-1.5 py-px rounded max-w-[80px] truncate leading-tight pointer-events-none">
                                  {assigned ? assigned.name.split(' ')[0] : slot.label}
                                </span>
                              </button>
                            );
                          })}
                        </div>

                        <p className="mt-2 text-center text-[10px] font-black uppercase text-slate-400 tracking-widest">
                          {teamSize}v{teamSize} · {formation} · vs {match.opponentName || 'TBC'}
                        </p>
                      </div>
                    </div>
                  </>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {composerOpen && isMember && (match.status !== 'COMPLETED' || canModerate) && activeView === 'FEED' && (
        <div className="absolute bottom-20 md:bottom-8 left-0 right-0 p-4 z-40 pointer-events-none">
          <div className="max-w-4xl mx-auto pointer-events-auto">
            <div className="bg-white/95 backdrop-blur-xl rounded-[2rem] shadow-[0_20px_50px_-12px_rgba(0,0,0,0.25)] border border-white/50 overflow-hidden transition-all duration-300 ring-1 ring-black/5">
              {activeActionType && canLogEvents && (
                <div className="p-4 sm:p-5 bg-slate-50/80 border-b border-slate-100 animate-in slide-in-from-bottom-4 duration-300 max-h-[45vh] overflow-y-auto">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2"><div className="p-2 bg-blue-600 text-white rounded-xl shadow-lg shadow-blue-100">{liveIconMapping[activeActionType]}</div><span className="font-black text-[10px] uppercase tracking-widest text-slate-900">{activeActionType.replace('_', ' ')} Detail</span></div>
                    <button type="button" onClick={() => setActiveActionType(null)} className="p-1.5 text-slate-400 hover:text-slate-600 hover:bg-white rounded-full transition-all border border-transparent hover:border-slate-200"><X className="w-5 h-5" /></button>
                  </div>
                  <div className="flex flex-col gap-3">
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4 text-slate-400 shrink-0" />
                      <label className="text-[10px] font-black uppercase tracking-widest text-slate-400">Event time</label>
                      <input
                        type="time"
                        value={eventTime}
                        onChange={(e) => setEventTime(e.target.value)}
                        className="bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold focus:outline-none focus:border-blue-500 shadow-sm"
                      />
                    </div>
                    <div className="flex gap-2 p-1.5 bg-white rounded-2xl border border-slate-200">
                      <button type="button" onClick={() => { setSelectedTeam('A'); setSelectedPlayerId(''); setSelectedPlayerId2(''); setSelectedAssistId(''); }} className={`flex-1 py-2 rounded-xl font-black text-[10px] uppercase tracking-widest transition-all ${selectedTeam === 'A' ? 'bg-slate-900 text-white shadow-md' : 'text-slate-400'}`}>{teamAName}</button>
                      <button type="button" onClick={() => { setSelectedTeam('B'); setSelectedPlayerId(''); setSelectedPlayerId2(''); setSelectedAssistId(''); }} className={`flex-1 py-2 rounded-xl font-black text-[10px] uppercase tracking-widest transition-all ${selectedTeam === 'B' ? 'bg-slate-900 text-white shadow-md' : 'text-slate-400'}`}>{teamBName}</button>
                    </div>

                    {selectedTeam === 'A' && activeActionType === 'GOAL' && (
                      <div className="flex flex-col sm:flex-row gap-3">
                        <select required value={selectedPlayerId} onChange={(e) => { setSelectedPlayerId(e.target.value); if (e.target.value === selectedAssistId) setSelectedAssistId(''); }} className="flex-1 bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold focus:outline-none focus:border-blue-500 appearance-none shadow-sm text-slate-900">
                          <option value="">Scorer (on pitch)...</option>
                          {selectableOnPitch.map(p => <option key={p.id} value={p.id}>{p.squadNumber != null ? `#${p.squadNumber} ` : ''}{p.name}</option>)}
                        </select>
                        <select value={selectedAssistId} onChange={(e) => setSelectedAssistId(e.target.value)} className="flex-1 bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold focus:outline-none focus:border-blue-500 appearance-none shadow-sm text-slate-900">
                          <option value="">Assist (optional)...</option>
                          {selectableOnPitch.filter(p => p.id !== selectedPlayerId).map(p => <option key={p.id} value={p.id}>{p.squadNumber != null ? `#${p.squadNumber} ` : ''}{p.name}</option>)}
                        </select>
                      </div>
                    )}

                    {selectedTeam === 'A' && (activeActionType === 'YELLOW_CARD' || activeActionType === 'RED_CARD') && (
                      <select required value={selectedPlayerId} onChange={(e) => setSelectedPlayerId(e.target.value)} className="w-full bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold focus:outline-none focus:border-blue-500 appearance-none shadow-sm text-slate-900">
                        <option value="">Player (on pitch)...</option>
                        {selectableOnPitch.map(p => <option key={p.id} value={p.id}>{p.squadNumber != null ? `#${p.squadNumber} ` : ''}{p.name}</option>)}
                      </select>
                    )}

                    {selectedTeam === 'A' && activeActionType === 'SUB' && (
                      <div className="space-y-2">
                        {plannedSubReminder?.next &&
                          selectedPlayerId === plannedSubReminder.next.playerOut &&
                          selectedPlayerId2 === plannedSubReminder.next.playerIn && (
                          <p className="text-[10px] font-bold text-orange-600 px-1">
                            Prefill from plan · after Q{plannedSubReminder.next.afterQuarter} — change if needed
                          </p>
                        )}
                        <div className="flex flex-col sm:flex-row gap-3">
                          <select required value={selectedPlayerId} onChange={(e) => setSelectedPlayerId(e.target.value)} className="flex-1 bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold focus:outline-none focus:border-blue-500 appearance-none shadow-sm text-slate-900">
                            <option value="">Player OFF (pitch)...</option>
                            {subOffOptions.map(p => <option key={p.id} value={p.id}>{p.squadNumber != null ? `#${p.squadNumber} ` : ''}{p.name}</option>)}
                          </select>
                          <select required value={selectedPlayerId2} onChange={(e) => setSelectedPlayerId2(e.target.value)} className="flex-1 bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-bold focus:outline-none focus:border-blue-500 appearance-none shadow-sm text-slate-900">
                            <option value="">Player ON (bench)...</option>
                            {subOnOptions.map(p => <option key={p.id} value={p.id}>{p.squadNumber != null ? `#${p.squadNumber} ` : ''}{p.name}</option>)}
                          </select>
                        </div>
                      </div>
                    )}

                    {selectedTeam === 'B' && (
                      <p className="text-[10px] font-bold text-slate-400 px-1">
                        Opposition event — no scorer/assister needed.
                      </p>
                    )}

                    {selectedTeam === 'A' && selectableOnPitch.length === 0 && activeActionType !== 'COMMENT' && (
                      <p className="text-[10px] font-bold text-amber-600 px-1">
                        Set a starting lineup first so on-pitch players can be selected.
                      </p>
                    )}
                  </div>
                </div>
              )}
              <form onSubmit={handleSubmitAction} className="p-3 sm:p-4 flex flex-col sm:flex-row gap-2 sm:gap-3 items-stretch sm:items-center">
                {showCommentComposer && !activeActionType && (
                  <div className="flex items-center justify-between sm:hidden px-1">
                    <span className="text-[10px] font-black uppercase tracking-widest text-slate-400">Commentary</span>
                    <button type="button" onClick={() => setShowCommentComposer(false)} className="p-1 text-slate-400"><X className="w-4 h-4" /></button>
                  </div>
                )}
                {!activeActionType && (
                  <div className="flex items-center gap-2 shrink-0">
                    <Clock className="w-4 h-4 text-slate-400" />
                    <input
                      type="time"
                      value={eventTime}
                      onChange={(e) => setEventTime(e.target.value)}
                      className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-3 text-xs font-bold focus:outline-none focus:border-blue-500"
                      title="Event time"
                    />
                    {showCommentComposer && (
                      <button type="button" onClick={() => setShowCommentComposer(false)} className="hidden sm:flex p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-50">
                        <X className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                )}
                <div className="relative flex-1">
                  <input
                    autoFocus={showCommentComposer || !!activeActionType}
                    type="text"
                    value={newEventContent}
                    onChange={(e) => setNewEventContent(e.target.value)}
                    placeholder={activeActionType ? 'Add highlight notes (optional)...' : 'Post live commentary...'}
                    className="w-full bg-slate-50 border border-slate-200 rounded-[1.25rem] pl-5 pr-4 py-3.5 text-sm font-medium focus:outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all placeholder:text-slate-300"
                  />
                  {activeActionType && <div className="absolute right-3 top-1/2 -translate-y-1/2"><div className="px-2 py-1 bg-blue-50 text-blue-600 text-[8px] font-black uppercase rounded-md tracking-widest border border-blue-100">{activeActionType.split('_')[0]}</div></div>}
                </div>
                <button type="submit" className="h-12 w-12 sm:h-14 sm:w-14 bg-blue-600 text-white rounded-[1.25rem] shadow-xl shadow-blue-100 hover:bg-blue-700 hover:scale-105 active:scale-95 transition-all flex items-center justify-center shrink-0 self-end sm:self-auto"><Send className="w-5 h-5 sm:w-6 sm:h-6" /></button>
              </form>
            </div>
          </div>
        </div>
      )}

      {showDeleteConfirm && (
        <div className="fixed inset-0 z-[120] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-white rounded-[2rem] shadow-2xl w-full max-w-sm overflow-hidden animate-in zoom-in-95 duration-300">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <h3 className="text-xl font-bold text-red-900">Delete match</h3>
              <button
                type="button"
                onClick={() => !isDeletingMatch && setShowDeleteConfirm(false)}
                className="p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-400"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-8 text-center space-y-6">
              <AlertCircle className="w-16 h-16 text-red-500 mx-auto" />
              <div className="space-y-2">
                <p className="text-slate-700 font-medium leading-relaxed">
                  Delete <span className="font-black text-slate-900">{match.title}</span>? This removes the timeline, photos, votes, and any stats from this match.
                </p>
                <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">This cannot be undone</p>
              </div>
              <div className="flex gap-3">
                <button
                  type="button"
                  disabled={isDeletingMatch}
                  onClick={() => setShowDeleteConfirm(false)}
                  className="flex-1 py-3.5 rounded-xl font-black text-slate-500 bg-slate-100 hover:bg-slate-200 transition-all uppercase tracking-widest text-[10px] disabled:opacity-50"
                >
                  Keep match
                </button>
                <button
                  type="button"
                  disabled={isDeletingMatch}
                  onClick={async () => {
                    setIsDeletingMatch(true);
                    try {
                      await onDeleteMatch(match.id);
                    } finally {
                      setIsDeletingMatch(false);
                      setShowDeleteConfirm(false);
                    }
                  }}
                  className="flex-1 py-3.5 rounded-xl font-black text-white bg-red-600 shadow-xl shadow-red-100 hover:bg-red-700 transition-all uppercase tracking-widest text-[10px] disabled:opacity-60"
                >
                  {isDeletingMatch ? 'Deleting…' : 'Yes, delete'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
