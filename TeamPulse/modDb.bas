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
	Dim bucket As Map
	bucket.Initialize
	If playerId <> "" Then bucket.Put("club", playerId)
	potm.Put(category, bucket)
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
	payload.Put("squad_number", user.GetDefault("squadNumber", Null))
	payload.Put("preferred_position", NullIfEmpty(user.GetDefault("preferredPosition", user.GetDefault("favPosition", ""))))
	payload.Put("secondary_position", NullIfEmpty(user.GetDefault("secondaryPosition", "")))
	payload.Put("phone", NullIfEmpty(user.GetDefault("phone", "")))
	payload.Put("emergency_contact", NullIfEmpty(user.GetDefault("emergencyContact", "")))
	payload.Put("date_of_birth", NullIfEmpty(user.GetDefault("dateOfBirth", "")))
	payload.Put("medical_notes", NullIfEmpty(user.GetDefault("medicalNotes", "")))
	modSupabase.RestPost(TBL_PROFILES & "?on_conflict=id", payload, "resolution=merge-duplicates,return=minimal")
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

Public Sub DeleteClub(clubId As String)
	modSupabase.RestDelete(TBL_CLUBS & "?id=eq." & modSupabase.UrlEncode(clubId))
End Sub

Public Sub SaveMatch(match As Map)
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
	modSupabase.RestPost(TBL_MATCHES & "?on_conflict=id", payload, "resolution=merge-duplicates,return=minimal")
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
	Return True
End Sub

Public Sub SaveEvent(ev As Map)
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
	modSupabase.RestPost(TBL_EVENTS & "?on_conflict=id", payload, "resolution=merge-duplicates,return=minimal")
End Sub

Public Sub DeleteEvent(eventId As String)
	modSupabase.RestDelete(TBL_EVENTS & "?id=eq." & modSupabase.UrlEncode(eventId))
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

Public Sub RemoveMember(clubId As String, userId As String)
	modSupabase.RestDelete(TBL_MEMBERS & "?club_id=eq." & modSupabase.UrlEncode(clubId) & _
		"&user_id=eq." & modSupabase.UrlEncode(userId))
End Sub

Public Sub AddMember(clubId As String, member As Map)
	' Prefer RPC when available (dummy members without auth accounts)
	Dim args As Map
	args.Initialize
	args.Put("p_club_id", clubId)
	args.Put("p_name", member.GetDefault("name", "Player"))
	args.Put("p_avatar", member.GetDefault("avatar", ""))
	Dim roles As List = member.GetDefault("roles", NewListFromStrings(Array As String("PLAYER")))
	Dim role As String = "PLAYER"
	If roles.Size > 0 Then role = roles.Get(0)
	args.Put("p_role", role)
	args.Put("p_squad_number", member.GetDefault("squadNumber", Null))
	args.Put("p_preferred_position", NullIfEmpty(member.GetDefault("preferredPosition", member.GetDefault("favPosition", ""))))
	args.Put("p_secondary_position", NullIfEmpty(member.GetDefault("secondaryPosition", "")))
	args.Put("p_phone", NullIfEmpty(member.GetDefault("phone", "")))
	args.Put("p_emergency_contact", NullIfEmpty(member.GetDefault("emergencyContact", "")))
	args.Put("p_date_of_birth", NullIfEmpty(member.GetDefault("dateOfBirth", "")))
	args.Put("p_medical_notes", NullIfEmpty(member.GetDefault("medicalNotes", "")))
	modSupabase.Rpc("add_dummy_member", args)
	If modSupabase.LastError <> "" Then
		' Fallback: profile upsert + membership
		Log("add_dummy_member RPC failed, fallback: " & modSupabase.LastError)
		If member.GetDefault("id", "") = "" Then
			member.Put("id", GenerateUuid)
		End If
		SaveProfile(member)
		JoinClub(clubId, member.Get("id"), roles)
	End If
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
		modAppState.Clubs = clubs
		
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
		End If
		modAppState.Matches = matches
		
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
		End If
		modAppState.FeedEvents = events
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
