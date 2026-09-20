
import React, { useState, useRef } from 'react';
import { User, UserRole, Club, PlayerPosition } from '../types';
import { Shield, User as UserIcon, Eye, Trash2, ArrowLeft, Star, ToggleLeft, ToggleRight, Plus, X, Check, Camera, RefreshCw, AlertTriangle, Loader2, Pencil } from 'lucide-react';

type MemberExtra = {
  squadNumber?: number;
  preferredPosition?: string;
  secondaryPosition?: string;
  phone?: string;
  emergencyContact?: string;
  dateOfBirth?: string;
  medicalNotes?: string;
};

interface ClubMembersProps {
  club: Club;
  currentUser: User;
  onUpdateRoles: (userId: string, newRoles: UserRole[]) => void;
  onRemoveMember: (userId: string) => void;
  onAddMember: (name: string, role: UserRole, avatar: string, extra?: MemberExtra) => void | Promise<void>;
  onUpdateMember: (userId: string, updates: { name: string; avatar?: string } & MemberExtra) => void | Promise<void>;
  onDeleteClub?: (clubId: string) => void;
  onBack: () => void;
}

const ClubMembers: React.FC<ClubMembersProps> = ({ club, currentUser, onUpdateRoles, onRemoveMember, onAddMember, onUpdateMember, onDeleteClub, onBack }) => {
  const [isAddingMember, setIsAddingMember] = useState(false);
  const [editingMember, setEditingMember] = useState<User | null>(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [addMemberError, setAddMemberError] = useState<string | null>(null);
  const [editMemberError, setEditMemberError] = useState<string | null>(null);
  const [isAddingMemberLoading, setIsAddingMemberLoading] = useState(false);
  const [isEditingMemberLoading, setIsEditingMemberLoading] = useState(false);
  const [newName, setNewName] = useState('');
  const [newRole, setNewRole] = useState<UserRole>('PLAYER');
  const [newAvatar, setNewAvatar] = useState(`https://picsum.photos/seed/${Math.random()}/200/200`);
  const [newSquadNumber, setNewSquadNumber] = useState('');
  const [newPreferredPosition, setNewPreferredPosition] = useState<PlayerPosition | ''>('');
  const [newSecondaryPosition, setNewSecondaryPosition] = useState<PlayerPosition | ''>('');
  const [newPhone, setNewPhone] = useState('');
  const [newEmergencyContact, setNewEmergencyContact] = useState('');
  const [newDateOfBirth, setNewDateOfBirth] = useState('');
  const [newMedicalNotes, setNewMedicalNotes] = useState('');
  const [editName, setEditName] = useState('');
  const [editAvatar, setEditAvatar] = useState('');
  const [editSquadNumber, setEditSquadNumber] = useState('');
  const [editPreferredPosition, setEditPreferredPosition] = useState<PlayerPosition | ''>('');
  const [editSecondaryPosition, setEditSecondaryPosition] = useState<PlayerPosition | ''>('');
  const [editPhone, setEditPhone] = useState('');
  const [editEmergencyContact, setEditEmergencyContact] = useState('');
  const [editDateOfBirth, setEditDateOfBirth] = useState('');
  const [editMedicalNotes, setEditMedicalNotes] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const editFileInputRef = useRef<HTMLInputElement>(null);

  const POSITIONS: PlayerPosition[] = ['GK','RB','CB','LB','RWB','LWB','CDM','CM','CAM','RM','LM','RW','LW','CF','ST'];

  const isCurrentUserAdmin = club.members.find(m => m.id === currentUser.id)?.roles.includes('ADMIN');
  const isOwner = currentUser.id === club.ownerId;
  const isTeam = club.type === 'TEAM';

  const handleAddSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;
    setAddMemberError(null);
    setIsAddingMemberLoading(true);
    try {
      await onAddMember(newName.trim(), newRole, newAvatar, {
        squadNumber: newSquadNumber ? parseInt(newSquadNumber) : undefined,
        preferredPosition: newPreferredPosition || undefined,
        secondaryPosition: newSecondaryPosition || undefined,
        phone: newPhone.trim() || undefined,
        emergencyContact: newEmergencyContact.trim() || undefined,
        dateOfBirth: newDateOfBirth || undefined,
        medicalNotes: newMedicalNotes.trim() || undefined,
      });
      setNewName('');
      setNewSquadNumber('');
      setNewPreferredPosition('');
      setNewSecondaryPosition('');
      setNewPhone('');
      setNewEmergencyContact('');
      setNewDateOfBirth('');
      setNewMedicalNotes('');
      setNewAvatar(`https://picsum.photos/seed/${Math.random()}/200/200`);
      setIsAddingMember(false);
    } catch (err: any) {
      setAddMemberError(err?.message || 'Failed to add member. Check Supabase RLS and that profiles/club_members tables exist.');
    } finally {
      setIsAddingMemberLoading(false);
    }
  };

  const openEditMember = (member: User) => {
    setEditingMember(member);
    setEditName(member.name);
    setEditAvatar(member.avatar);
    setEditSquadNumber(member.squadNumber != null ? String(member.squadNumber) : '');
    setEditPreferredPosition(member.preferredPosition || '');
    setEditSecondaryPosition(member.secondaryPosition || '');
    setEditPhone(member.phone || '');
    setEditEmergencyContact(member.emergencyContact || '');
    setEditDateOfBirth(member.dateOfBirth || '');
    setEditMedicalNotes(member.medicalNotes || '');
    setEditMemberError(null);
  };

  const closeEditMember = () => {
    setEditingMember(null);
    setEditMemberError(null);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingMember || !editName.trim()) return;
    setEditMemberError(null);
    setIsEditingMemberLoading(true);
    try {
      await onUpdateMember(editingMember.id, {
        name: editName.trim(),
        avatar: editAvatar,
        squadNumber: editSquadNumber ? parseInt(editSquadNumber) : undefined,
        preferredPosition: editPreferredPosition || undefined,
        secondaryPosition: editSecondaryPosition || undefined,
        phone: editPhone.trim() || undefined,
        emergencyContact: editEmergencyContact.trim() || undefined,
        dateOfBirth: editDateOfBirth || undefined,
        medicalNotes: editMedicalNotes.trim() || undefined,
      });
      closeEditMember();
    } catch (err: any) {
      setEditMemberError(err?.message || 'Failed to update member. Run supabase_update_member.sql in Supabase if needed.');
    } finally {
      setIsEditingMemberLoading(false);
    }
  };

  const handleConfirmDelete = async () => {
    if (!onDeleteClub || isDeleting) return;
    setIsDeleting(true);
    await onDeleteClub(club.id);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>, target: 'add' | 'edit' = 'add') => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        if (target === 'edit') setEditAvatar(reader.result as string);
        else setNewAvatar(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const shuffleAvatar = (target: 'add' | 'edit' = 'add') => {
    const url = `https://picsum.photos/seed/${Math.random()}/200/200`;
    if (target === 'edit') setEditAvatar(url);
    else setNewAvatar(url);
  };

  const getRoleIcon = (role: UserRole) => {
    switch (role) {
      case 'ADMIN': return <Shield className="w-4 h-4 text-blue-600" />;
      case 'PLAYER': return <UserIcon className="w-4 h-4 text-green-600" />;
      case 'COACH': return <Shield className="w-4 h-4 text-purple-600" />;
      case 'SPECTATOR': return <Eye className="w-4 h-4 text-slate-400" />;
    }
  };

  const getRoleBadgeColor = (role: UserRole) => {
    switch (role) {
      case 'ADMIN': return 'bg-blue-50 text-blue-700 border-blue-100';
      case 'PLAYER': return 'bg-green-50 text-green-700 border-green-100';
      case 'COACH': return 'bg-purple-50 text-purple-700 border-purple-100';
      case 'SPECTATOR': return 'bg-slate-50 text-slate-600 border-slate-100';
    }
  };

  const handleToggleAdmin = (member: User) => {
    if (!isCurrentUserAdmin) return;
    const hasAdmin = member.roles.includes('ADMIN');
    const newRoles = hasAdmin 
      ? member.roles.filter(r => r !== 'ADMIN')
      : [...member.roles, 'ADMIN' as UserRole];
    onUpdateRoles(member.id, newRoles);
  };

  const handleSetBaseRole = (member: User, baseRole: 'PLAYER' | 'COACH' | 'SPECTATOR') => {
    if (!isCurrentUserAdmin && member.id !== currentUser.id) return;
    const otherRoles = member.roles.filter(r => r !== 'PLAYER' && r !== 'COACH' && r !== 'SPECTATOR');
    onUpdateRoles(member.id, [...otherRoles, baseRole]);
  };

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-left-4 duration-500 pb-20">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <button 
            onClick={onBack}
            className="p-2 hover:bg-slate-200 rounded-full transition-colors bg-white border border-slate-200 shadow-sm"
          >
            <ArrowLeft className="w-5 h-5 text-slate-600" />
          </button>
          <div className="flex items-center gap-4">
            <img src={club.logo} className="w-12 h-12 rounded-xl object-cover shadow-sm border border-slate-200" alt="" />
            <div>
              <h2 className="text-2xl font-black text-slate-900 tracking-tight">
                {club.name}
              </h2>
              <p className="text-sm text-slate-500 font-medium">
                {isTeam ? 'Team Roster' : 'Mates List'} • Invite Code: <span className="font-bold text-blue-600">{club.inviteCode}</span>
              </p>
            </div>
          </div>
        </div>

        <div className="flex gap-2">
          {isOwner && (
            <button 
              onClick={() => setShowDeleteConfirm(true)}
              className="bg-white border border-red-100 text-red-500 px-6 py-2.5 rounded-xl font-black text-xs uppercase tracking-widest flex items-center gap-2 hover:bg-red-50 transition-all"
            >
              <Trash2 className="w-4 h-4" />
              Delete Club
            </button>
          )}
          {isCurrentUserAdmin && (
            <button 
              onClick={() => setIsAddingMember(true)}
              className="bg-blue-600 text-white px-6 py-2.5 rounded-xl font-black text-xs uppercase tracking-widest flex items-center gap-2 shadow-lg shadow-blue-100 hover:bg-blue-700 transition-all"
            >
              <Plus className="w-4 h-4" />
              Add Member
            </button>
          )}
        </div>
      </div>

      <div className="bg-white rounded-[2rem] border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-100">
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">
                  {isTeam ? 'Athlete' : 'Member'}
                </th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Roles</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Access</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {club.members.map((member) => (
                <tr key={member.id} className="hover:bg-slate-50/50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="relative">
                        <img src={member.avatar} className="w-12 h-12 rounded-2xl object-cover border-2 border-white shadow-sm" alt={member.name} />
                        {member.id === club.ownerId && (
                          <div className="absolute -top-1 -right-1 bg-amber-400 text-white p-1 rounded-lg ring-2 ring-white shadow-sm">
                            <Star className="w-3 h-3 fill-current" />
                          </div>
                        )}
                      </div>
                      <div>
                        <p className="font-black text-slate-900 tracking-tight">
                          {member.squadNumber ? <span className="text-blue-600 mr-1.5">#{member.squadNumber}</span> : null}
                          {member.name}
                        </p>
                        <p className="text-[9px] text-slate-400 font-black uppercase tracking-widest">
                          {member.id === club.ownerId ? (isTeam ? 'Manager' : 'Organizer') : 'Active Member'}
                          {member.preferredPosition ? ` · ${member.preferredPosition}` : ''}
                          {member.secondaryPosition ? ` / ${member.secondaryPosition}` : ''}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-wrap gap-2">
                      {member.roles.map(role => (
                        <span key={role} className={`px-3 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest border ${getRoleBadgeColor(role)} flex items-center gap-1.5`}>
                          {getRoleIcon(role)}
                          {role}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    {isCurrentUserAdmin && member.id !== club.ownerId ? (
                      <button 
                        onClick={() => handleToggleAdmin(member)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all border ${
                          member.roles.includes('ADMIN') 
                            ? 'bg-blue-600 text-white border-blue-700 shadow-lg shadow-blue-100' 
                            : 'bg-white text-slate-400 border-slate-200 hover:border-blue-200 hover:text-blue-600'
                        }`}
                      >
                        {member.roles.includes('ADMIN') ? <ToggleRight className="w-4 h-4" /> : <ToggleLeft className="w-4 h-4" />}
                        {member.roles.includes('ADMIN') ? 'Full Access' : 'Grant Admin'}
                      </button>
                    ) : (
                      <div className="flex items-center gap-1.5 text-xs font-bold text-slate-400">
                        {member.roles.includes('ADMIN') ? (
                          <span className="text-blue-600 flex items-center gap-2 bg-blue-50 px-4 py-2 rounded-xl border border-blue-100 text-[10px] font-black uppercase tracking-widest">
                            <Shield className="w-3.5 h-3.5" />
                            Hub Admin
                          </span>
                        ) : (
                          <span className="px-4 py-2 text-[10px] font-black uppercase tracking-widest opacity-50">Standard User</span>
                        )}
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex justify-end items-center gap-3">
                      {(isCurrentUserAdmin || member.id === currentUser.id) && (
                        <>
                          {isCurrentUserAdmin && (
                            <button
                              type="button"
                              onClick={() => openEditMember(member)}
                              className="p-3 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all border border-transparent hover:border-blue-100"
                              title="Edit Member"
                            >
                              <Pencil className="w-5 h-5" />
                            </button>
                          )}
                          <div className="relative">
                            <select 
                              className="appearance-none bg-slate-50 border border-slate-200 rounded-xl text-[10px] font-black uppercase tracking-widest pl-4 pr-10 py-2.5 outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all cursor-pointer"
                              value={member.roles.includes('PLAYER') ? 'PLAYER' : member.roles.includes('COACH') ? 'COACH' : 'SPECTATOR'}
                              onChange={(e) => handleSetBaseRole(member, e.target.value as 'PLAYER' | 'COACH' | 'SPECTATOR')}
                            >
                              <option value="PLAYER">{isTeam ? 'PLAYER' : 'BALLER'}</option>
                              <option value="COACH">COACH</option>
                              <option value="SPECTATOR">WATCHER</option>
                            </select>
                            <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                            </div>
                          </div>
                          {isCurrentUserAdmin && member.id !== club.ownerId && member.id !== currentUser.id && (
                            <button 
                              onClick={() => onRemoveMember(member.id)}
                              className="p-3 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-xl transition-all border border-transparent hover:border-red-100"
                              title="Remove Member"
                            >
                              <Trash2 className="w-5 h-5" />
                            </button>
                          )}
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Member Modal */}
      {isAddingMember && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300 overflow-y-auto">
          <div className="bg-white rounded-[2rem] shadow-2xl w-full max-w-sm my-auto animate-in zoom-in-95 duration-300 max-h-[90vh] flex flex-col">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between shrink-0">
              <h3 className="text-xl font-bold text-slate-900">Add New Member</h3>
              <button type="button" onClick={() => { setIsAddingMember(false); setAddMemberError(null); }} className="p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-400">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <form onSubmit={handleAddSubmit} className="p-6 space-y-5 overflow-y-auto flex-1">
              {addMemberError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 shrink-0" />
                  {addMemberError}
                </div>
              )}
              <div className="flex flex-col items-center gap-4">
                <div className="relative group cursor-pointer" onClick={() => fileInputRef.current?.click()}>
                  <img 
                    src={newAvatar} 
                    className="w-20 h-20 rounded-full object-cover ring-4 ring-slate-50 shadow-md transition-transform group-hover:scale-105" 
                    alt="Avatar Preview" 
                  />
                  <div className="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <Camera className="w-5 h-5 text-white" />
                  </div>
                  <input 
                    type="file" 
                    ref={fileInputRef} 
                    className="hidden" 
                    accept="image/*" 
                    onChange={(e) => handleFileChange(e, 'add')} 
                  />
                </div>
                <button 
                  type="button" 
                  onClick={() => shuffleAvatar('add')}
                  className="flex items-center gap-1.5 text-[10px] font-black text-blue-600 uppercase tracking-widest"
                >
                  <RefreshCw className="w-3 h-3" /> Shuffle
                </button>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">Full Name</label>
                <input 
                  autoFocus
                  type="text" 
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. John Doe"
                  className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-5 py-4 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all"
                  required
                />
              </div>

              <div className="space-y-3">
                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">Base Role</label>
                <div className="grid grid-cols-3 gap-3">
                  <button
                    type="button"
                    onClick={() => setNewRole('PLAYER')}
                    className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${
                      newRole === 'PLAYER' 
                        ? 'border-green-600 bg-green-50 text-green-600' 
                        : 'border-slate-100 bg-white text-slate-400 hover:border-slate-200'
                    }`}
                  >
                    <UserIcon className="w-5 h-5" />
                    <span className="text-[9px] font-black uppercase tracking-widest">Player</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setNewRole('COACH')}
                    className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${
                      newRole === 'COACH' 
                        ? 'border-purple-600 bg-purple-50 text-purple-600' 
                        : 'border-slate-100 bg-white text-slate-400 hover:border-slate-200'
                    }`}
                  >
                    <Shield className="w-5 h-5" />
                    <span className="text-[9px] font-black uppercase tracking-widest">Coach</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setNewRole('SPECTATOR')}
                    className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${
                      newRole === 'SPECTATOR' 
                        ? 'border-amber-600 bg-amber-50 text-amber-600' 
                        : 'border-slate-100 bg-white text-slate-400 hover:border-slate-200'
                    }`}
                  >
                    <Eye className="w-5 h-5" />
                    <span className="text-[9px] font-black uppercase tracking-widest">Spectator</span>
                  </button>
                </div>
              </div>

              {(newRole === 'PLAYER' || newRole === 'COACH') && (
                <div className="space-y-4 border-t border-slate-100 pt-4">
                  <p className="text-[10px] font-black text-blue-600 uppercase tracking-widest">Player / Staff Details</p>

                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Squad #</label>
                      <input
                        type="number"
                        min="1"
                        max="99"
                        value={newSquadNumber}
                        onChange={(e) => setNewSquadNumber(e.target.value)}
                        placeholder="e.g. 7"
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">DOB</label>
                      <input
                        type="date"
                        value={newDateOfBirth}
                        onChange={(e) => setNewDateOfBirth(e.target.value)}
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Preferred Pos</label>
                      <select
                        value={newPreferredPosition}
                        onChange={(e) => setNewPreferredPosition(e.target.value as PlayerPosition | '')}
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                      >
                        <option value="">Select</option>
                        {POSITIONS.map(pos => <option key={pos} value={pos}>{pos}</option>)}
                      </select>
                    </div>
                    <div className="space-y-1">
                      <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Secondary Pos</label>
                      <select
                        value={newSecondaryPosition}
                        onChange={(e) => setNewSecondaryPosition(e.target.value as PlayerPosition | '')}
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                      >
                        <option value="">Select</option>
                        {POSITIONS.map(pos => <option key={pos} value={pos}>{pos}</option>)}
                      </select>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Phone</label>
                    <input
                      type="tel"
                      value={newPhone}
                      onChange={(e) => setNewPhone(e.target.value)}
                      placeholder="e.g. 07700 900000"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Emergency Contact</label>
                    <input
                      type="text"
                      value={newEmergencyContact}
                      onChange={(e) => setNewEmergencyContact(e.target.value)}
                      placeholder="Name & number"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Medical Notes</label>
                    <textarea
                      rows={2}
                      value={newMedicalNotes}
                      onChange={(e) => setNewMedicalNotes(e.target.value)}
                      placeholder="Allergies, injuries, conditions…"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm resize-none"
                    />
                  </div>
                </div>
              )}

              <button 
                type="submit"
                disabled={isAddingMemberLoading}
                className="w-full bg-slate-900 text-white rounded-2xl py-4 font-bold shadow-lg hover:bg-slate-800 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {isAddingMemberLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Check className="w-5 h-5" />}
                {isAddingMemberLoading ? 'Adding…' : 'Add to Roster'}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Edit Member Modal */}
      {editingMember && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300 overflow-y-auto">
          <div className="bg-white rounded-[2rem] shadow-2xl w-full max-w-sm my-auto animate-in zoom-in-95 duration-300 max-h-[90vh] flex flex-col">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between shrink-0">
              <h3 className="text-xl font-bold text-slate-900">Edit Member</h3>
              <button type="button" onClick={closeEditMember} className="p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-400">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleEditSubmit} className="p-6 space-y-5 overflow-y-auto flex-1">
              {editMemberError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 shrink-0" />
                  {editMemberError}
                </div>
              )}
              <div className="flex flex-col items-center gap-4">
                <div className="relative group cursor-pointer" onClick={() => editFileInputRef.current?.click()}>
                  <img
                    src={editAvatar}
                    className="w-20 h-20 rounded-full object-cover ring-4 ring-slate-50 shadow-md transition-transform group-hover:scale-105"
                    alt="Avatar Preview"
                  />
                  <div className="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <Camera className="w-5 h-5 text-white" />
                  </div>
                  <input
                    type="file"
                    ref={editFileInputRef}
                    className="hidden"
                    accept="image/*"
                    onChange={(e) => handleFileChange(e, 'edit')}
                  />
                </div>
                <button
                  type="button"
                  onClick={() => shuffleAvatar('edit')}
                  className="flex items-center gap-1.5 text-[10px] font-black text-blue-600 uppercase tracking-widest"
                >
                  <RefreshCw className="w-3 h-3" /> Shuffle
                </button>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">Full Name</label>
                <input
                  autoFocus
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  placeholder="e.g. John Doe"
                  className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-5 py-4 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all"
                  required
                />
              </div>

              <div className="space-y-4 border-t border-slate-100 pt-4">
                <p className="text-[10px] font-black text-blue-600 uppercase tracking-widest">Player / Staff Details</p>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Squad #</label>
                    <input
                      type="number"
                      min="1"
                      max="99"
                      value={editSquadNumber}
                      onChange={(e) => setEditSquadNumber(e.target.value)}
                      placeholder="e.g. 7"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">DOB</label>
                    <input
                      type="date"
                      value={editDateOfBirth}
                      onChange={(e) => setEditDateOfBirth(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Preferred Pos</label>
                    <select
                      value={editPreferredPosition}
                      onChange={(e) => setEditPreferredPosition(e.target.value as PlayerPosition | '')}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                    >
                      <option value="">Select</option>
                      {POSITIONS.map(pos => <option key={pos} value={pos}>{pos}</option>)}
                    </select>
                  </div>
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Secondary Pos</label>
                    <select
                      value={editSecondaryPosition}
                      onChange={(e) => setEditSecondaryPosition(e.target.value as PlayerPosition | '')}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                    >
                      <option value="">Select</option>
                      {POSITIONS.map(pos => <option key={pos} value={pos}>{pos}</option>)}
                    </select>
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Phone</label>
                  <input
                    type="tel"
                    value={editPhone}
                    onChange={(e) => setEditPhone(e.target.value)}
                    placeholder="e.g. 07700 900000"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Emergency Contact</label>
                  <input
                    type="text"
                    value={editEmergencyContact}
                    onChange={(e) => setEditEmergencyContact(e.target.value)}
                    placeholder="Name & number"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm"
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Medical Notes</label>
                  <textarea
                    rows={2}
                    value={editMedicalNotes}
                    onChange={(e) => setEditMedicalNotes(e.target.value)}
                    placeholder="Allergies, injuries, conditions…"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 font-semibold text-slate-900 focus:outline-none focus:border-blue-500 transition-all text-sm resize-none"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={isEditingMemberLoading}
                className="w-full bg-slate-900 text-white rounded-2xl py-4 font-bold shadow-lg hover:bg-slate-800 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {isEditingMemberLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Check className="w-5 h-5" />}
                {isEditingMemberLoading ? 'Saving…' : 'Save Changes'}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Delete Club Confirmation */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-[120] flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md animate-in fade-in duration-300">
          <div className="bg-white rounded-[2.5rem] shadow-2xl w-full max-w-sm overflow-hidden animate-in zoom-in-95 duration-300">
            <div className="p-8 text-center space-y-6">
              <div className="w-20 h-20 bg-red-50 text-red-500 rounded-3xl flex items-center justify-center mx-auto">
                <AlertTriangle className="w-10 h-10" />
              </div>
              <div className="space-y-2">
                <h3 className="text-2xl font-black text-slate-900 tracking-tight">Delete {club.name}?</h3>
                <p className="text-sm text-slate-500 font-medium leading-relaxed">
                  This will permanently remove the club, all matches, and member records. This cannot be undone.
                </p>
              </div>
              <div className="flex flex-col gap-3">
                <button 
                  onClick={handleConfirmDelete}
                  disabled={isDeleting}
                  className="w-full py-4 bg-red-600 text-white rounded-2xl font-black text-xs uppercase tracking-widest shadow-xl shadow-red-100 hover:bg-red-700 transition-all disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {isDeleting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
                  Yes, Delete Forever
                </button>
                <button 
                  onClick={() => setShowDeleteConfirm(false)}
                  disabled={isDeleting}
                  className="w-full py-4 bg-slate-100 text-slate-500 rounded-2xl font-black text-xs uppercase tracking-widest hover:bg-slate-200 transition-all disabled:opacity-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ClubMembers;
