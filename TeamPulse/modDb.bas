B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Port of reference/services/dbService.ts — Supabase REST CRUD for TeamPulse.
' DB columns are snake_case; app Maps use camelCase (with lineup aliased as tacticalLineup for UI).

Sub Process_Globals
	Public Const TBL_PROFILES As String = "profiles"
	Public Const TBL_CLUBS As String = "clubs"
	Public Const TBL_MEMBERS As String = "club_members"
	Public Const TBL_MATCHES As String = "matches"
	Public Const TBL_EVENTS As String = "feed_events"
	Public Const TBL_TRAINING As String = "training_sessions"
End Sub

Public Sub MapProfile(row As Map) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", row.GetDefault("id", ""))
	m.Put("name", row.GetDefault("name", "User"))
	m.Put("avatar", row.GetDefault("avatar", ""))
	m.Put("roles", row.GetDefault("roles", NewListFromStrings(Array As String("SPECTATOR"))))
	m.Put("squadNumber", row.GetDefault("squad_number", 0))
	m.Put("preferredPosition", row.GetDefault("preferred_position", ""))
	m.Put("secondaryPosition", row.GetDefault("secondary_position", ""))
	m.Put("phone", row.GetDefault("phone", ""))
	m.Put("emergencyContact", row.GetDefault("emergency_contact", ""))
	m.Put("dateOfBirth", row.GetDefault("date_of_birth", ""))
	m.Put("medicalNotes", row.GetDefault("medical_notes", ""))
	' UI alias used by older member list label
	m.Put("favPosition", m.Get("preferredPosition"))
	Return m
End Sub

Public Sub MapMatch(row As Map) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", row.GetDefault("id", ""))
	m.Put("clubId", row.GetDefault("club_id", ""))
	m.Put("title", row.GetDefault("title", ""))
	m.Put("date", row.GetDefault("date", ""))
	m.Put("meetTime", row.GetDefault("meet_time", ""))
	m.Put("kickOffTime", row.GetDefault("kick_off_time", ""))
	m.Put("location", row.GetDefault("location", ""))
	m.Put("status", row.GetDefault("status", "UPCOMING"))
	m.Put("competition", row.GetDefault("competition", "FRIENDLY"))
	m.Put("scoreA", row.GetDefault("score_a", 0))
	m.Put("scoreB", row.GetDefault("score_b", 0))
	m.Put("signedUpPlayerIds", row.GetDefault("signed_up_player_ids", EmptyList))
	m.Put("availability", row.GetDefault("availability", EmptyMap))
	m.Put("opponentName", row.GetDefault("opponent_name", ""))
	m.Put("isHome", row.GetDefault("is_home", True))
	m.Put("potmVotes", NormalizePotmVotes(row.GetDefault("potm_votes", EmptyMap)))
	m.Put("photoUrls", row.GetDefault("photo_urls", EmptyList))
	m.Put("formation", row.GetDefault("formation", "4-4-2"))
	m.Put("teamSize", row.GetDefault("team_size", 11))
	m.Put("subPlan", row.GetDefault("sub_plan", EmptyMap))
	m.Put("aiSummary", row.GetDefault("ai_summary", ""))
	m.Put("playerStats", row.GetDefault("player_stats", EmptyMap))
	Dim lineup As Object = row.GetDefault("lineup", EmptyMap)
	m.Put("lineup", lineup)
	' Alias for existing MatchPrep UI
	m.Put("tacticalLineup", lineup)
	m.Put("startingLineupIds", LineupToIds(lineup))
	m.Put("benchIds", EmptyList)
	m.Put("starPlayerIds", EmptyList)
	m.Put("weakerPlayerIds", EmptyList)
	m.Put("teamA", EmptyList)
	m.Put("teamB", EmptyList)
	Return m
End Sub

' potm_votes shape: { coach: {voterId: playerId}, fans: {...}, opposition: {...}, fanCounts: {playerId: n} }
Public Sub NormalizePotmVotes(raw As Object) As Map
	Dim out As Map
	out.Initialize
	Dim coach As Map
	coach.Initialize
	Dim fans As Map
	fans.Initialize
	Dim opposition As Map
	opposition.Initialize
	Dim fanCounts As Map
	fanCounts.Initialize
	out.Put("coach", coach)
	out.Put("fans", fans)
	out.Put("opposition", opposition)
	out.Put("fanCounts", fanCounts)
	If raw = Null Or (raw Is Map) = False Then Return out
	Dim obj As Map = raw
	If obj.ContainsKey("coach") Or obj.ContainsKey("fans") Or obj.ContainsKey("opposition") Or obj.ContainsKey("fanCounts") Then
		Dim cObj As Object = obj.GetDefault("coach", Null)
		If cObj <> Null And cObj Is Map Then out.Put("coach", cObj)
		Dim fObj As Object = obj.GetDefault("fans", Null)
		If fObj <> Null And fObj Is Map Then out.Put("fans", fObj)
		Dim oObj As Object = obj.GetDefault("opposition", Null)
		If oObj <> Null And oObj Is Map Then out.Put("opposition", oObj)
		Dim fcObj As Object = obj.GetDefault("fanCounts", Null)
		If fcObj <> Null And fcObj Is Map Then
			Dim fc As Map = fcObj
			Dim fcOut As Map
			fcOut.Initialize
			For Each pid As String In fc.Keys
		Try
			Dim n As Int = fc.Get(pid)
			If n > 0 Then fcOut.Put(pid, n)
		Catch
			Log("fanCounts parse: " & LastException.Message)
		End Try
			Next
			out.Put("fanCounts", fcOut)
		End If
		Return out
	End If
	' Legacy flat voterId -> playerId as fans
	out.Put("fans", obj)
	Return out
End Sub

Public Sub EmptyPotmVotes As Map
	Return NormalizePotmVotes(Null)
End Sub

Public Sub GetCategoryPotmPlayerId(potm As Map, category As String) As String
	Dim bucket As Map
	Dim bObj As Object = potm.GetDefault(category, Null)
	If bObj = Null Or (bObj Is Map) = False Then Return ""
	bucket = bObj
	For Each k As String In bucket.Keys
		Dim v As String = bucket.Get(k)
		If v <> "" Then Return v
	Next
	Return ""
End Sub

Public Sub SetCategoryPotmPlayerId(potm As Map, category As String, playerId As String)
	Dim ids As List
	ids.Initialize
	If playerId <> "" Then ids.Add(playerId)
	SetCategoryPotmPlayerIds(potm, category, ids)
End Sub

Public Sub GetCategoryPotmPlayerIds(potm As Map, category As String) As List
	Dim out As List
	out.Initialize
	Dim bObj As Object = potm.GetDefault(category, Null)
	If bObj = Null Or (bObj Is Map) = False Then Return out
	Dim bucket As Map = bObj
	Dim seen As Map
	seen.Initialize
	For Each k As String In bucket.Keys
		Dim v As String = "" & bucket.Get(k)
		If v <> "" And v <> "null" And seen.ContainsKey(v) = False Then
			seen.Put(v, True)
			out.Add(v)
		End If
	Next
	Return out
End Sub

Public Sub SetCategoryPotmPlayerIds(potm As Map, category As String, playerIds As List)
	Dim bucket As Map
	bucket.Initialize
	If playerIds.IsInitialized Then
		Dim i As Int
		For i = 0 To playerIds.Size - 1
			Dim pid As String = "" & playerIds.Get(i)
			If pid <> "" Then bucket.Put(pid, pid)
		Next
	End If
	potm.Put(category, bucket)
End Sub

Public Sub MapTraining(row As Map) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", row.GetDefault("id", ""))
	m.Put("clubId", row.GetDefault("club_id", ""))
	m.Put("date", NormalizeIsoDate(row.GetDefault("session_date", "")))
	Dim trainer As String = ""
	Dim trainerObj As Object = row.GetDefault("trainer_of_week_id", "")
	If trainerObj <> Null Then trainer = trainerObj
	If trainer = "null" Then trainer = ""
	m.Put("trainerOfWeekId", trainer)
	m.Put("presentIds", AsIdList(row.GetDefault("present_ids", Null)))
	m.Put("absentIds", AsIdList(row.GetDefault("absent_ids", Null)))
	m.Put("wellBehavedIds", AsIdList(row.GetDefault("well_behaved_ids", Null)))
	m.Put("poorlyBehavedIds", AsIdList(row.GetDefault("poorly_behaved_ids", Null)))
	Return m
End Sub

Public Sub MapEvent(row As Map) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", row.GetDefault("id", ""))
	m.Put("matchId", row.GetDefault("match_id", ""))
	m.Put("userId", row.GetDefault("user_id", ""))
	m.Put("userName", row.GetDefault("user_name", ""))
	m.Put("type", row.GetDefault("type", "COMMENT"))
	m.Put("content", row.GetDefault("content", ""))
	m.Put("details", row.GetDefault("details", EmptyMap))
	m.Put("timestamp", ParseTimestamp(row.GetDefault("timestamp", "")))
	Return m
End Sub

Private Sub LineupToIds(lineup As Object) As List
	Dim ids As List
	ids.Initialize
	If lineup Is Map Then
		Dim lm As Map = lineup
		For Each k As String In lm.Keys
			Dim pid As String = lm.Get(k)
			If pid <> "" Then ids.Add(pid)
		Next
	End If
	Return ids
End Sub

Private Sub ParseTimestamp(v As Object) As Long
	Try
		If v Is Long Then Return v
		If v Is Double Then Return v
		Dim s As String = v
		If s = "" Then Return DateTime.Now
		' ISO-8601 → millis via Java Instant when possible
		Dim jo As JavaObject
		jo.InitializeStatic("java.time.Instant")
		Dim inst As JavaObject = jo.RunMethod("parse", Array(s))
		Return inst.RunMethod("toEpochMilli", Null)
	Catch
		Return DateTime.Now
	End Try
End Sub

Private Sub IsoTimestamp(ms As Long) As String
	Try
		Dim inst As JavaObject
		inst.InitializeStatic("java.time.Instant")
		Return inst.RunMethodJO("ofEpochMilli", Array(ms)).RunMethod("toString", Null)
	Catch
		DateTime.DateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
		Return DateTime.Date(ms)
	End Try
End Sub

Private Sub NormalizeIsoDate(v As Object) As String
	Dim s As String = "" & v
	If s = "null" Then Return ""
	Dim ti As Int = s.IndexOf("T")
	If ti > 0 Then s = s.SubString2(0, ti)
	Dim si As Int = s.IndexOf(" ")
	If si > 0 Then s = s.SubString2(0, si)
	Return s
End Sub

Private Sub AsIdList(raw As Object) As List
	Dim out As List
	out.Initialize
	If raw = Null Or (raw Is List) = False Then Return out
	Dim src As List = raw
	Dim i As Int
	For i = 0 To src.Size - 1
		Dim id As String = "" & src.Get(i)
		If id <> "" And id <> "null" Then out.Add(id)
	Next
	Return out
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub NewListFromStrings(arr() As String) As List
	Dim l As List
	l.Initialize
	For Each s As String In arr
		l.Add(s)
	Next
	Return l
End Sub

Private Sub NullIfEmpty(s As String) As Object
	If s = "" Then
		Dim n As Object = Null
		Return n
	End If
	Return s
End Sub

' --- Writes ---

Public Sub SaveProfile(user As Map)
	Dim payload As Map
	payload.Initialize
	payload.Put("id", user.Get("id"))
	payload.Put("name", user.GetDefault("name", ""))
	payload.Put("avatar", user.GetDefault("avatar", ""))
	payload.Put("roles", user.GetDefault("roles", EmptyList))
	PutIfSet(payload, "squad_number", user.GetDefault("squadNumber", ""))
	PutIfSet(payload, "preferred_position", user.GetDefault("preferredPosition", user.GetDefault("favPosition", "")))
	PutIfSet(payload, "secondary_position", user.GetDefault("secondaryPosition", ""))
	PutIfSet(payload, "phone", user.GetDefault("phone", ""))
	PutIfSet(payload, "emergency_contact", user.GetDefault("emergencyContact", ""))
	PutIfSet(payload, "date_of_birth", user.GetDefault("dateOfBirth", ""))
	PutIfSet(payload, "medical_notes", user.GetDefault("medicalNotes", ""))
	modSupabase.RestPost(TBL_PROFILES & "?on_conflict=id", payload, "resolution=merge-duplicates,return=minimal")
End Sub

' Update profile fields and mirror into in-memory club member maps.
Public Sub UpdateMember(userId As String, updates As Map)
	Dim profile As Map
	profile.Initialize
	profile.Put("id", userId)
	profile.Put("name", updates.GetDefault("name", "Player"))
	profile.Put("avatar", updates.GetDefault("avatar", ""))
	profile.Put("squadNumber", updates.GetDefault("squadNumber", Null))
	profile.Put("preferredPosition", updates.GetDefault("preferredPosition", ""))
	profile.Put("favPosition", updates.GetDefault("preferredPosition", ""))
	profile.Put("secondaryPosition", updates.GetDefault("secondaryPosition", ""))
	profile.Put("phone", updates.GetDefault("phone", ""))
	profile.Put("emergencyContact", updates.GetDefault("emergencyContact", ""))
	profile.Put("dateOfBirth", updates.GetDefault("dateOfBirth", ""))
	profile.Put("medicalNotes", updates.GetDefault("medicalNotes", ""))
	Dim existing As Map = GetProfile(userId)
	If existing.IsInitialized And existing.ContainsKey("roles") Then
		profile.Put("roles", existing.Get("roles"))
	Else
		profile.Put("roles", NewListFromStrings(Array As String("PLAYER")))
	End If
	SaveProfile(profile)
	SyncMemberIntoClubs(profile)
End Sub

Private Sub SyncMemberIntoClubs(profile As Map)
	Dim uid As String = profile.GetDefault("id", "")
	If uid = "" Then Return
	Dim ci As Int
	For ci = 0 To modAppState.Clubs.Size - 1
		Dim club As Map = modAppState.Clubs.Get(ci)
		Dim memObj As Object = club.GetDefault("members", Null)
		If memObj = Null Or (memObj Is List) = False Then Continue
		Dim members As List = memObj
		Dim mi As Int
		For mi = 0 To members.Size - 1
			Dim mem As Map = members.Get(mi)
			If mem.GetDefault("id", "") <> uid Then Continue
			mem.Put("name", profile.GetDefault("name", mem.GetDefault("name", "Player")))
			mem.Put("avatar", profile.GetDefault("avatar", ""))
			mem.Put("squadNumber", profile.GetDefault("squadNumber", 0))
			mem.Put("preferredPosition", profile.GetDefault("preferredPosition", ""))
			mem.Put("favPosition", profile.GetDefault("preferredPosition", ""))
			mem.Put("secondaryPosition", profile.GetDefault("secondaryPosition", ""))
			mem.Put("phone", profile.GetDefault("phone", ""))
			mem.Put("emergencyContact", profile.GetDefault("emergencyContact", ""))
			mem.Put("dateOfBirth", profile.GetDefault("dateOfBirth", ""))
			mem.Put("medicalNotes", profile.GetDefault("medicalNotes", ""))
		Next
	Next
End Sub

Public Sub SaveClub(club As Map, owner As Map)
	SaveProfile(owner)
	Dim payload As Map
	payload.Initialize
	payload.Put("id", club.Get("id"))
	payload.Put("name", club.GetDefault("name", ""))
	payload.Put("logo", club.GetDefault("logo", ""))
	payload.Put("description", club.GetDefault("description", ""))
	payload.Put("type", club.GetDefault("type", "TEAM"))
	payload.Put("owner_id", owner.Get("id"))
	payload.Put("invite_code", club.GetDefault("inviteCode", ""))
	payload.Put("preferred_team_size", club.GetDefault("preferredTeamSize", Null))
	payload.Put("preferred_formation", NullIfEmpty(club.GetDefault("preferredFormation", "")))
	modSupabase.RestPost(TBL_CLUBS & "?on_conflict=id", payload, "resolution=merge-duplicates,return=minimal")
	
	Dim roles As List = NewListFromStrings(Array As String("ADMIN", "PLAYER"))
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim mi As Int
	For mi = 0 To members.Size - 1
		Dim mem As Map = members.Get(mi)
		If mem.GetDefault("id", "") = owner.Get("id") Then
			roles = mem.GetDefault("roles", roles)
			Exit
		End If
	Next
	Dim mp As Map
	mp.Initialize
	mp.Put("club_id", club.Get("id"))
	mp.Put("user_id", owner.Get("id"))
	mp.Put("roles", roles)
	modSupabase.RestPost(TBL_MEMBERS & "?on_conflict=club_id,user_id", mp, "resolution=merge-duplicates,return=minimal")
End Sub

' Persist last-used size/formation on the club so new matches remember it.
Public Sub UpdateClubPreferences(clubId As String, teamSize As Int, formation As String)
	If clubId = "" Then Return
	Dim payload As Map
	payload.Initialize
	If teamSize > 0 Then payload.Put("preferred_team_size", teamSize)
	If formation <> "" Then payload.Put("preferred_formation", formation)
	If payload.Size = 0 Then Return
	modSupabase.RestPatch(TBL_CLUBS & "?id=eq." & modSupabase.UrlEncode(clubId), payload, "return=minimal")
	Dim club As Map = modAppState.FindClub(clubId)
	If club.IsInitialized Then
		If teamSize > 0 Then club.Put("preferredTeamSize", teamSize)
		If formation <> "" Then club.Put("preferredFormation", formation)
		modAppState.UpsertClub(club)
	End If
End Sub

Public Sub DeleteClub(clubId As String)
	modSupabase.RestDelete(TBL_CLUBS & "?id=eq." & modSupabase.UrlEncode(clubId))
End Sub

' Writes the match on the phone and queues one Supabase upsert of the latest copy.
' player_stats is not a matches column, so it is kept in memory only.
Public Sub SaveMatch(match As Map)
	modLocal.QueueMatch(match)
End Sub

Public Sub BuildMatchPayload(match As Map) As Map
	Dim lineup As Object = match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMap))
	Dim payload As Map
	payload.Initialize
	payload.Put("id", match.Get("id"))
	payload.Put("club_id", match.GetDefault("clubId", ""))
	payload.Put("title", match.GetDefault("title", ""))
	payload.Put("date", match.GetDefault("date", ""))
	payload.Put("meet_time", NullIfEmpty(match.GetDefault("meetTime", "")))
	payload.Put("kick_off_time", match.GetDefault("kickOffTime", ""))
	payload.Put("location", match.GetDefault("location", ""))
	payload.Put("status", match.GetDefault("status", "UPCOMING"))
	payload.Put("competition", match.GetDefault("competition", "FRIENDLY"))
	payload.Put("score_a", match.GetDefault("scoreA", 0))
	payload.Put("score_b", match.GetDefault("scoreB", 0))
	payload.Put("signed_up_player_ids", match.GetDefault("signedUpPlayerIds", EmptyList))
	payload.Put("availability", match.GetDefault("availability", EmptyMap))
	payload.Put("opponent_name", NullIfEmpty(match.GetDefault("opponentName", "")))
	payload.Put("is_home", match.GetDefault("isHome", True))
	payload.Put("potm_votes", NormalizePotmVotes(match.GetDefault("potmVotes", EmptyMap)))
	payload.Put("photo_urls", match.GetDefault("photoUrls", EmptyList))
	payload.Put("formation", NullIfEmpty(match.GetDefault("formation", "")))
	payload.Put("lineup", lineup)
	payload.Put("team_size", match.GetDefault("teamSize", Null))
	payload.Put("sub_plan", match.GetDefault("subPlan", EmptyMap))
	payload.Put("ai_summary", match.GetDefault("aiSummary", ""))
	Return payload
End Sub

' Deletes feed events for the match, then the match row. Clears local cache.
' Returns True if both REST deletes reported no error.
Public Sub DeleteMatch(matchId As String) As Boolean
	If matchId = "" Then Return False
	modSupabase.RestDelete(TBL_EVENTS & "?match_id=eq." & modSupabase.UrlEncode(matchId))
	Dim eventsErr As String = modSupabase.LastError
	modSupabase.RestDelete(TBL_MATCHES & "?id=eq." & modSupabase.UrlEncode(matchId))
	Dim matchErr As String = modSupabase.LastError
	If eventsErr <> "" Then
		Log("DeleteMatch events: " & eventsErr)
		modSupabase.LastError = eventsErr
		Return False
	End If
	If matchErr <> "" Then
		Log("DeleteMatch match: " & matchErr)
		Return False
	End If
	modAppState.RemoveEventsForMatch(matchId)
	modAppState.RemoveMatch(matchId)
	If modAppState.SelectedMatchId = matchId Then modAppState.SelectedMatchId = ""
	modLocal.ForgetMatch(matchId)
	Return True
End Sub

Public Sub SaveEvent(ev As Map)
	modLocal.QueueEventUpsert(ev)
End Sub

Public Sub BuildEventPayload(ev As Map) As Map
	Dim payload As Map
	payload.Initialize
	payload.Put("id", ev.Get("id"))
	payload.Put("match_id", ev.GetDefault("matchId", ""))
	payload.Put("user_id", ev.GetDefault("userId", ""))
	payload.Put("user_name", ev.GetDefault("userName", ""))
	payload.Put("type", ev.GetDefault("type", "COMMENT"))
	payload.Put("content", ev.GetDefault("content", ""))
	payload.Put("details", ev.GetDefault("details", EmptyMap))
	payload.Put("timestamp", IsoTimestamp(ev.GetDefault("timestamp", DateTime.Now)))
	Return payload
End Sub

Public Sub DeleteEvent(eventId As String)
	modLocal.QueueEventDelete(eventId)
End Sub

Public Sub SaveTraining(session As Map)
	Dim payload As Map
	payload.Initialize
	payload.Put("id", session.Get("id"))
	payload.Put("club_id", session.GetDefault("clubId", ""))
	payload.Put("session_date", session.GetDefault("date", ""))
	payload.Put("trainer_of_week_id", NullIfEmpty(session.GetDefault("trainerOfWeekId", "")))
	payload.Put("present_ids", AsIdList(session.GetDefault("presentIds", Null)))
	payload.Put("absent_ids", AsIdList(session.GetDefault("absentIds", Null)))
	payload.Put("well_behaved_ids", AsIdList(session.GetDefault("wellBehavedIds", Null)))
	payload.Put("poorly_behaved_ids", AsIdList(session.GetDefault("poorlyBehavedIds", Null)))
	modSupabase.RestPost(TBL_TRAINING & "?on_conflict=id", payload, "resolution=merge-duplicates,return=minimal")
	If modSupabase.LastError = "" Then modAppState.UpsertTraining(session)
End Sub

Public Sub DeleteTraining(sessionId As String) As Boolean
	If sessionId = "" Then Return False
	modSupabase.RestDelete(TBL_TRAINING & "?id=eq." & modSupabase.UrlEncode(sessionId))
	If modSupabase.LastError <> "" Then
		Log("DeleteTraining: " & modSupabase.LastError)
		Return False
	End If
	modAppState.RemoveTraining(sessionId)
	If modAppState.SelectedTrainingId = sessionId Then modAppState.SelectedTrainingId = ""
	Return True
End Sub

Public Sub JoinClub(clubId As String, userId As String, roles As List)
	Dim mp As Map
	mp.Initialize
	mp.Put("club_id", clubId)
	mp.Put("user_id", userId)
	mp.Put("roles", roles)
	modSupabase.RestPost(TBL_MEMBERS & "?on_conflict=club_id,user_id", mp, "resolution=merge-duplicates,return=minimal")
End Sub

Public Sub UpdateMemberRoles(clubId As String, userId As String, roles As List)
	Dim mp As Map
	mp.Initialize
	mp.Put("roles", roles)
	modSupabase.RestPatch(TBL_MEMBERS & "?club_id=eq." & modSupabase.UrlEncode(clubId) & _
		"&user_id=eq." & modSupabase.UrlEncode(userId), mp, "return=minimal")
End Sub

Public Sub RoleListHas(roles As Object, role As String) As Boolean
	If roles = Null Then Return False
	Dim want As String = role.ToUpperCase
	If (roles Is List) = False Then Return ("" & roles).ToUpperCase = want
	Dim lst As List = roles
	Dim i As Int
	For i = 0 To lst.Size - 1
		If ("" & lst.Get(i)).ToUpperCase = want Then Return True
	Next
	Return False
End Sub

' Coach wins when the account is both coach and player, so a new club does not force Player back on.
Public Sub ResolveBaseRole(roles As Object) As String
	If RoleListHas(roles, "COACH") Then Return "COACH"
	If RoleListHas(roles, "PLAYER") Then Return "PLAYER"
	If RoleListHas(roles, "SPECTATOR") Then Return "SPECTATOR"
	Return "PLAYER"
End Sub

Public Sub BuildRolesKeepingAdmin(existing As Object, baseRole As String) As List
	Dim out As List
	out.Initialize
	If RoleListHas(existing, "ADMIN") Then out.Add("ADMIN")
	Dim base As String = baseRole.ToUpperCase
	If base <> "PLAYER" And base <> "COACH" And base <> "SPECTATOR" Then base = "PLAYER"
	out.Add(base)
	Return out
End Sub

' Sets the club membership and the profile to one base role (Player, Coach, or Spectator). Admin is kept.
Public Sub SetMemberBaseRole(clubId As String, userId As String, baseRole As String) As Boolean
	If clubId = "" Or userId = "" Then Return False
	Dim club As Map = modAppState.FindClub(clubId)
	Dim existingClubRoles As Object = Null
	Dim mem As Map
	mem.Initialize
	If club.IsInitialized Then
		Dim memObj As Object = club.GetDefault("members", Null)
		If memObj Is List Then
			Dim members As List = memObj
			Dim i As Int
			For i = 0 To members.Size - 1
				Dim m As Map = members.Get(i)
				If m.GetDefault("id", "") = userId Then
					mem = m
					existingClubRoles = m.GetDefault("roles", Null)
					Exit
				End If
			Next
		End If
	End If
	Dim clubRoles As List = BuildRolesKeepingAdmin(existingClubRoles, baseRole)
	UpdateMemberRoles(clubId, userId, clubRoles)
	If modSupabase.LastError <> "" Then
		Log("SetMemberBaseRole club: " & modSupabase.LastError)
		Return False
	End If
	If mem.IsInitialized And mem.ContainsKey("id") Then mem.Put("roles", clubRoles)
	
	Dim profile As Map = GetProfile(userId)
	If profile.IsInitialized And profile.GetDefault("id", "") <> "" Then
		Dim profileRoles As List = BuildRolesKeepingAdmin(profile.GetDefault("roles", Null), baseRole)
		profile.Put("roles", profileRoles)
		SaveProfile(profile)
		If modSupabase.LastError <> "" Then
			Log("SetMemberBaseRole profile: " & modSupabase.LastError)
			Return False
		End If
		If modAppState.IsAuthenticated And modAppState.CurrentUser.GetDefault("id", "") = userId Then
			modAppState.CurrentUser.Put("roles", profileRoles)
		End If
	End If
	Return True
End Sub

Public Sub RemoveMember(clubId As String, userId As String)
	modSupabase.RestDelete(TBL_MEMBERS & "?club_id=eq." & modSupabase.UrlEncode(clubId) & _
		"&user_id=eq." & modSupabase.UrlEncode(userId))
End Sub

Private Sub PutIfSet(payload As Map, key As String, value As Object)
	If value = Null Then Return
	Dim s As String = "" & value
	If s.Trim = "" Or s = "null" Then Return
	payload.Put(key, value)
End Sub

Public Sub AddMember(clubId As String, member As Map) As String
	Dim args As Map
	args.Initialize
	args.Put("p_club_id", clubId)
	args.Put("p_name", member.GetDefault("name", "Player"))
	args.Put("p_avatar", member.GetDefault("avatar", ""))
	Dim roles As List = member.GetDefault("roles", NewListFromStrings(Array As String("PLAYER")))
	Dim role As String = "PLAYER"
	If roles.Size > 0 Then role = roles.Get(0)
	args.Put("p_role", role)
	PutIfSet(args, "p_squad_number", member.GetDefault("squadNumber", ""))
	PutIfSet(args, "p_preferred_position", member.GetDefault("preferredPosition", member.GetDefault("favPosition", "")))
	PutIfSet(args, "p_secondary_position", member.GetDefault("secondaryPosition", ""))
	PutIfSet(args, "p_phone", member.GetDefault("phone", ""))
	PutIfSet(args, "p_emergency_contact", member.GetDefault("emergencyContact", ""))
	PutIfSet(args, "p_date_of_birth", member.GetDefault("dateOfBirth", ""))
	PutIfSet(args, "p_medical_notes", member.GetDefault("medicalNotes", ""))
	Dim raw As Object = modSupabase.Rpc("add_dummy_member", args)
	If modSupabase.LastError = "" And raw Is Map Then
		Dim created As Map = raw
		Dim newId As String = "" & created.GetDefault("id", "")
		If newId <> "" And newId <> "null" Then Return newId
	End If
	Log("add_dummy_member RPC failed, fallback: " & modSupabase.LastError)
	Dim mid As String = member.GetDefault("id", "")
	If mid = "" Or mid.StartsWith("local_") Then
		mid = GenerateUuid
		member.Put("id", mid)
	End If
	SaveProfile(member)
	If modSupabase.LastError <> "" Then Return ""
	JoinClub(clubId, mid, roles)
	If modSupabase.LastError <> "" Then Return ""
	Return mid
End Sub

Public Sub FetchInitialData
	Try
		Dim clubsRaw As Object = modSupabase.RestGet(TBL_CLUBS & "?select=*,members:club_members(user_id,roles)")
		Dim profileMap As Map
		profileMap.Initialize
		Dim userIds As List
		userIds.Initialize
		If clubsRaw Is List Then
			Dim clubsRows As List
			clubsRows = clubsRaw
			Dim ci As Int
			For ci = 0 To clubsRows.Size - 1
				Dim c As Map = clubsRows.Get(ci)
				Dim memsObj As Object = c.Get("members")
				If memsObj Is List Then
					Dim memsList As List
					memsList = memsObj
					Dim mi As Int
					For mi = 0 To memsList.Size - 1
						Dim mrow As Map = memsList.Get(mi)
						Dim uid As String = mrow.GetDefault("user_id", "")
						If uid <> "" And userIds.IndexOf(uid) = -1 Then userIds.Add(uid)
					Next
				End If
			Next
		End If
		If userIds.Size > 0 Then
			Dim inList As StringBuilder
			inList.Initialize
			inList.Append("(")
			For i = 0 To userIds.Size - 1
				If i > 0 Then inList.Append(",")
				inList.Append(userIds.Get(i))
			Next
			inList.Append(")")
			Dim prefsObj As Object = modSupabase.RestGet(TBL_PROFILES & "?select=id,name,avatar,squad_number,preferred_position,secondary_position,phone,emergency_contact,date_of_birth,medical_notes,roles&id=in." & inList.ToString)
			If prefsObj Is List Then
				Dim prefsList As List
				prefsList = prefsObj
				Dim pi As Int
				For pi = 0 To prefsList.Size - 1
					Dim prow As Map = prefsList.Get(pi)
					profileMap.Put(prow.Get("id"), MapProfile(prow))
				Next
			End If
		End If
		
		Dim clubs As List
		clubs.Initialize
		If clubsRaw Is List Then
			Dim clubsRows2 As List
			clubsRows2 = clubsRaw
			Dim cj As Int
			For cj = 0 To clubsRows2.Size - 1
				Dim crow As Map = clubsRows2.Get(cj)
				Dim club As Map
				club.Initialize
				club.Put("id", crow.GetDefault("id", ""))
				club.Put("name", crow.GetDefault("name", ""))
				club.Put("logo", crow.GetDefault("logo", ""))
				club.Put("description", crow.GetDefault("description", ""))
				club.Put("type", crow.GetDefault("type", "TEAM"))
				club.Put("ownerId", crow.GetDefault("owner_id", ""))
				club.Put("inviteCode", crow.GetDefault("invite_code", ""))
				club.Put("preferredTeamSize", crow.GetDefault("preferred_team_size", 11))
				club.Put("preferredFormation", crow.GetDefault("preferred_formation", ""))
				Dim members As List
				members.Initialize
				Dim mems2Obj As Object = crow.Get("members")
				If mems2Obj Is List Then
					Dim mems2List As List
					mems2List = mems2Obj
					Dim mj As Int
					For mj = 0 To mems2List.Size - 1
						Dim mrow2 As Map = mems2List.Get(mj)
						Dim uid2 As String = mrow2.GetDefault("user_id", "")
						Dim profile As Map
						If profileMap.ContainsKey(uid2) Then
							profile = profileMap.Get(uid2)
						Else
							profile.Initialize
							profile.Put("id", uid2)
							profile.Put("name", "Unknown")
							profile.Put("avatar", "")
						End If
						Dim mem As Map
						mem.Initialize
						mem.Put("id", uid2)
						mem.Put("name", profile.GetDefault("name", "Unknown"))
						mem.Put("avatar", profile.GetDefault("avatar", ""))
						mem.Put("roles", mrow2.GetDefault("roles", NewListFromStrings(Array As String("PLAYER"))))
						mem.Put("squadNumber", profile.GetDefault("squadNumber", 0))
						mem.Put("preferredPosition", profile.GetDefault("preferredPosition", ""))
						mem.Put("favPosition", profile.GetDefault("preferredPosition", ""))
						mem.Put("secondaryPosition", profile.GetDefault("secondaryPosition", ""))
						mem.Put("phone", profile.GetDefault("phone", ""))
						members.Add(mem)
					Next
				End If
				club.Put("members", members)
				clubs.Add(club)
			Next
		End If
		If clubsRaw Is List Then modAppState.Clubs = clubs
		
		Dim matchesRaw As Object = modSupabase.RestGet(TBL_MATCHES & "?select=*&order=date.asc")
		Dim matches As List
		matches.Initialize
		If matchesRaw Is List Then
			Dim matchesList As List
			matchesList = matchesRaw
			Dim mk As Int
			For mk = 0 To matchesList.Size - 1
				Dim matchRow As Map = matchesList.Get(mk)
				matches.Add(MapMatch(matchRow))
			Next
			modAppState.Matches = modLocal.PreferDirtyMatches(matches)
		Else
			Log("Fetch matches: " & modSupabase.LastError)
		End If
		
		' Missing table must not wipe clubs or matches. Run reference/supabase_training_sessions.sql once.
		Try
			Dim trainingRaw As Object = modSupabase.RestGet(TBL_TRAINING & "?select=*&order=session_date.desc,created_at.desc")
			If trainingRaw Is List Then
				Dim trainingRows As List = trainingRaw
				Dim sessions As List
				sessions.Initialize
				Dim ti As Int
				For ti = 0 To trainingRows.Size - 1
					sessions.Add(MapTraining(trainingRows.Get(ti)))
				Next
				modAppState.TrainingSessions = sessions
			Else
				Log("Fetch training: " & modSupabase.LastError)
			End If
		Catch
			Log("Fetch training: " & LastException)
		End Try
		
		' Latest 100 only. Coach export loads every event for the coach's clubs and does not use this list.
		Dim eventsRaw As Object = modSupabase.RestGet(TBL_EVENTS & "?select=*&order=timestamp.desc&limit=100")
		Dim events As List
		events.Initialize
		If eventsRaw Is List Then
			Dim eventsList As List
			eventsList = eventsRaw
			Dim ek As Int
			For ek = 0 To eventsList.Size - 1
				Dim erow As Map = eventsList.Get(ek)
				events.Add(MapEvent(erow))
			Next
			modAppState.FeedEvents = modLocal.PreferDirtyEvents(events)
			modLocal.RecountLoadedScores
		Else
			Log("Fetch events: " & modSupabase.LastError)
		End If
		modLocal.PersistSnapshot
	Catch
		Log("FetchInitialData: " & LastException)
	End Try
End Sub

Public Sub GetProfile(userId As String) As Map
	Dim empty As Map
	empty.Initialize
	Try
		Dim raw As Object = modSupabase.RestGet(TBL_PROFILES & "?id=eq." & modSupabase.UrlEncode(userId) & "&select=*")
		If raw Is List Then
			Dim rows As List = raw
			If rows.Size = 0 Then Return empty
			Return MapProfile(rows.Get(0))
		End If
	Catch
		Log("GetProfile: " & LastException)
	End Try
	Return empty
End Sub

Public Sub FindClubByInviteCode(code As String) As Map
	Dim empty As Map
	empty.Initialize
	Try
		Dim raw As Object = modSupabase.RestGet(TBL_CLUBS & "?invite_code=eq." & modSupabase.UrlEncode(code) & "&select=*&limit=1")
		If raw Is List Then
			Dim rows As List = raw
			If rows.Size = 0 Then Return empty
			Dim crow As Map = rows.Get(0)
			Dim club As Map
			club.Initialize
			club.Put("id", crow.GetDefault("id", ""))
			club.Put("name", crow.GetDefault("name", ""))
			club.Put("logo", crow.GetDefault("logo", ""))
			club.Put("description", crow.GetDefault("description", ""))
			club.Put("type", crow.GetDefault("type", "TEAM"))
			club.Put("ownerId", crow.GetDefault("owner_id", ""))
			club.Put("inviteCode", crow.GetDefault("invite_code", ""))
			club.Put("members", EmptyList)
			Return club
		End If
	Catch
		Log("FindClubByInviteCode: " & LastException)
	End Try
	Return empty
End Sub

Public Sub GenerateInviteCode As String
	Dim chars As String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	Dim sb As StringBuilder
	sb.Initialize
	For i = 1 To 6
		Dim idx As Int = Rnd(0, chars.Length)
		sb.Append(chars.CharAt(idx))
	Next
	Return sb.ToString
End Sub

Public Sub GenerateUuid As String
	Try
		Dim uuid As JavaObject
		uuid.InitializeStatic("java.util.UUID")
		Return uuid.RunMethodJO("randomUUID", Null).RunMethod("toString", Null)
	Catch
		Return "local-" & DateTime.Now & "-" & Rnd(1000, 9999)
	End Try
End Sub
