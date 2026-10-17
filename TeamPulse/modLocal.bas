B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' On-phone copy of clubs, matches, and feed events, plus the unsynced queue.
' The live screen reads this copy. Supabase is updated from it when there is a signal.
' The file lives in the app's private storage. Closing the app does not delete it.

Sub Process_Globals
	Private Const CACHE_FILE As String = "live_cache.json"
	Private ready As Boolean
	Private dirtyEvents As Map
	Private dirtyMatches As Map
	Private ackedEvents As Map
End Sub

Public Sub Initialize
	If ready Then Return
	dirtyEvents.Initialize
	dirtyMatches.Initialize
	ackedEvents.Initialize
	ready = True
End Sub

Public Sub AsInt(v As Object) As Int
	If v = Null Then Return 0
	Try
		Dim n As Int = v
		Return n
	Catch
		Try
			Dim d As Double = v
			Return d
		Catch
			Return 0
		End Try
	End Try
End Sub

Public Sub IsOwnGoal(details As Map) As Boolean
	If details.IsInitialized = False Then Return False
	Dim s As String = "" & details.GetDefault("ownGoal", False)
	s = s.ToLowerCase
	Return s = "true" Or s = "1"
End Sub

Public Sub SyncWord(matchId As String) As String
	If HasPending(matchId) Then Return "Saved on phone"
	Return "Synced"
End Sub

Public Sub HasPending(matchId As String) As Boolean
	Initialize
	If matchId = "" Then Return dirtyEvents.Size > 0 Or dirtyMatches.Size > 0
	If dirtyMatches.ContainsKey(matchId) Then Return True
	For Each rowObj As Object In dirtyEvents.Values
		Dim row As Map = rowObj
		If row.GetDefault("matchId", "") = matchId Then Return True
	Next
	Return False
End Sub

' Score is the count of GOAL events on the phone, including own goals, for any status.
' An END whistle marks the match completed. Returns True when the match map changed.
' No loaded events means the feed has not arrived — leave a saved score alone.
Public Sub ApplyLiveScore(match As Map) As Boolean
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then Return False
	Dim events As List = modAppState.EventsForMatch(match.Get("id"))
	If events.Size = 0 Then Return False
	Dim counted As Map = CountScores(match.Get("id"))
	Dim a As Int = counted.Get("scoreA")
	Dim b As Int = counted.Get("scoreB")
	Dim goals As Int = a + b
	Dim changed As Boolean = False
	Dim status As String = match.GetDefault("status", "")
	' Goals on the timeline win for every status. A live match with no goals yet is 0-0.
	' A finished match with events but no goals keeps a non-zero saved score.
	If goals > 0 Or status = "LIVE" Then
		If AsInt(match.GetDefault("scoreA", 0)) <> a Or AsInt(match.GetDefault("scoreB", 0)) <> b Then
			match.Put("scoreA", a)
			match.Put("scoreB", b)
			changed = True
		End If
	End If
	Dim endEv As Map
	endEv.Initialize
	Dim hasEnd As Boolean = False
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") = "END" Then
			hasEnd = True
			endEv = e
		End If
	Next
	If hasEnd And status <> "COMPLETED" And status <> "CANCELLED" Then
		match.Put("status", "COMPLETED")
		changed = True
	End If
	If hasEnd And goals > 0 Then
		Dim want As String = "Full Time " & a & "-" & b
		Dim content As String = endEv.GetDefault("content", "")
		If content.StartsWith("Full Time ") And content <> want Then
			endEv.Put("content", want)
			QueueEventUpsert(endEv)
		End If
	End If
	Return changed
End Sub

' After events are loaded, correct every match score from its goals and queue a save.
Public Sub RecountLoadedScores
	Initialize
	If modAppState.Matches.IsInitialized = False Then Return
	Dim i As Int
	For i = 0 To modAppState.Matches.Size - 1
		Dim match As Map = modAppState.Matches.Get(i)
		If ApplyLiveScore(match) Then QueueMatch(match)
	Next
End Sub

Public Sub CountScores(matchId As String) As Map
	Dim scoreA As Int = 0
	Dim scoreB As Int = 0
	Dim events As List = modAppState.EventsForMatch(matchId)
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "GOAL" Then Continue
		Dim details As Map = DetailsOf(e)
		If details.GetDefault("team", "A") = "B" Then
			scoreB = scoreB + 1
		Else
			scoreA = scoreA + 1
		End If
	Next
	Dim m As Map
	m.Initialize
	m.Put("scoreA", scoreA)
	m.Put("scoreB", scoreB)
	Return m
End Sub

Public Sub AsLong(v As Object) As Long
	If v = Null Then Return 0
	Try
		Dim n As Long = v
		Return n
	Catch
		Try
			Dim d As Double = v
			Return d
		Catch
			Return 0
		End Try
	End Try
End Sub

Public Sub IsFlag(details As Map, key As String) As Boolean
	If details.IsInitialized = False Then Return False
	Dim s As String = "" & details.GetDefault(key, False)
	s = s.ToLowerCase
	Return s = "true" Or s = "1"
End Sub

Public Sub HasFullTime(matchId As String) As Boolean
	Dim events As List = modAppState.EventsForMatch(matchId)
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") = "END" Then Return True
	Next
	Return False
End Sub

Public Sub ShootoutKickContent(team As String, scored As Boolean, playerName As String) As String
	If team = "B" Then
		If scored Then Return "Opposition scored"
		Return "Opposition missed"
	End If
	Dim verb As String = "Missed"
	If scored Then verb = "Scored"
	If playerName = "" Then playerName = "?"
	Return verb & " · " & playerName
End Sub

Public Sub ShootoutSetupContent(kicksEach As Int, firstTeam As String) As String
	Dim who As String = "We start"
	If firstTeam = "B" Then who = "Opposition start"
	Return kicksEach & " each · " & who
End Sub

' Regulation score, plus pens when a shootout has been set up.
' Won and Lost are from our side (team A), and only once the shootout is decided.
Public Sub ScoreLine(match As Map) As String
	Dim a As Int = AsInt(match.GetDefault("scoreA", 0))
	Dim b As Int = AsInt(match.GetDefault("scoreB", 0))
	Dim base As String = a & " - " & b
	Dim st As Map = ShootoutState(match.GetDefault("id", ""))
	If IsFlag(st, "active") = False Then Return base
	Dim line As String = base & " (" & AsInt(st.GetDefault("pensA", 0)) & "-" & AsInt(st.GetDefault("pensB", 0)) & " pens)"
	If IsFlag(st, "decided") Then
		If st.GetDefault("winner", "") = "A" Then
			line = line & " · Won"
		Else
			line = line & " · Lost"
		End If
	End If
	Return line
End Sub

' Clock-line text once a shootout exists. Empty when there is no setup.
Public Sub PensStatusLine(matchId As String) As String
	Dim st As Map = ShootoutState(matchId)
	If IsFlag(st, "active") = False Then Return ""
	Dim line As String = "Pens " & AsInt(st.GetDefault("pensA", 0)) & "-" & AsInt(st.GetDefault("pensB", 0))
	If IsFlag(st, "decided") Then
		If st.GetDefault("winner", "") = "A" Then
			line = line & " · Won"
		Else
			line = line & " · Lost"
		End If
	Else If IsFlag(st, "inSuddenDeath") Then
		line = line & " · Sudden death"
	End If
	Return line
End Sub

' active, decided, winner (A/B), pensA, pensB, kicksEach, firstTeam, nextTeam, inSuddenDeath.
' Kicks do not change scoreA/scoreB. A winner exists only when the other side cannot catch up,
' or a sudden-death pair has finished with the scores different.
Public Sub ShootoutState(matchId As String) As Map
	Dim out As Map
	out.Initialize
	out.Put("active", False)
	out.Put("decided", False)
	out.Put("winner", "")
	out.Put("pensA", 0)
	out.Put("pensB", 0)
	out.Put("kicksEach", 0)
	out.Put("firstTeam", "A")
	out.Put("nextTeam", "")
	out.Put("inSuddenDeath", False)
	out.Put("takenA", 0)
	out.Put("takenB", 0)
	If matchId = "" Then Return out
	
	Dim events As List = modAppState.EventsForMatch(matchId)
	Dim setup As Map
	setup.Initialize
	Dim haveSetup As Boolean
	Dim kicks As List
	kicks.Initialize
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "SHOOTOUT" Then Continue
		Dim details As Map = DetailsOf(e)
		If details.GetDefault("kind", "") = "setup" Then
			If haveSetup = False Or EventSeq(e) >= EventSeq(setup) Then
				setup = e
				haveSetup = True
			End If
		Else
			kicks.Add(e)
		End If
	Next
	If haveSetup = False Then Return out
	
	Dim setupDetails As Map = DetailsOf(setup)
	Dim n As Int = AsInt(setupDetails.GetDefault("kicksEach", 5))
	If n < 1 Then n = 1
	Dim firstTeam As String = "" & setupDetails.GetDefault("firstTeam", "A")
	If firstTeam <> "B" Then firstTeam = "A"
	SortShootoutKicks(kicks)
	
	Dim takenA As Int
	Dim takenB As Int
	Dim scoredA As Int
	Dim scoredB As Int
	For i = 0 To kicks.Size - 1
		Dim kick As Map = kicks.Get(i)
		Dim kd As Map = DetailsOf(kick)
		If kd.GetDefault("team", "A") = "B" Then
			takenB = takenB + 1
			If IsFlag(kd, "scored") Then scoredB = scoredB + 1
		Else
			takenA = takenA + 1
			If IsFlag(kd, "scored") Then scoredA = scoredA + 1
		End If
	Next
	
	Dim outcome As Map = ShootoutOutcome(n, takenA, takenB, scoredA, scoredB)
	Dim decided As Boolean = outcome.Get("decided")
	Dim winner As String = outcome.Get("winner")
	Dim inSuddenDeath As Boolean = outcome.Get("inSuddenDeath")
	
	out.Put("active", True)
	out.Put("decided", decided)
	out.Put("winner", winner)
	out.Put("pensA", scoredA)
	out.Put("pensB", scoredB)
	out.Put("kicksEach", n)
	out.Put("firstTeam", firstTeam)
	out.Put("inSuddenDeath", inSuddenDeath)
	out.Put("takenA", takenA)
	out.Put("takenB", takenB)
	If decided = False Then
		Dim nextTeam As String = firstTeam
		If takenA < takenB Then
			nextTeam = "A"
		Else If takenB < takenA Then
			nextTeam = "B"
		End If
		out.Put("nextTeam", nextTeam)
	End If
	Return out
End Sub

' Rewrites suddenDeath on logged kicks so a deleted kick does not leave later cards wrong.
' Returns True when an event was updated.
Public Sub SyncShootoutFlags(matchId As String) As Boolean
	Dim st As Map = ShootoutState(matchId)
	If IsFlag(st, "active") = False Then Return False
	Dim n As Int = AsInt(st.GetDefault("kicksEach", 0))
	Dim events As List = modAppState.EventsForMatch(matchId)
	Dim kicks As List
	kicks.Initialize
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "SHOOTOUT" Then Continue
		Dim details As Map = DetailsOf(e)
		If details.GetDefault("kind", "") = "setup" Then Continue
		kicks.Add(e)
	Next
	SortShootoutKicks(kicks)
	Dim takenA As Int
	Dim takenB As Int
	Dim changed As Boolean
	For i = 0 To kicks.Size - 1
		Dim kick As Map = kicks.Get(i)
		Dim kd As Map = DetailsOf(kick)
		Dim sd As Boolean = (takenA >= n And takenB >= n)
		If IsFlag(kd, "suddenDeath") <> sd Then
			kd.Put("suddenDeath", sd)
			kick.Put("details", kd)
			QueueEventUpsert(kick)
			changed = True
		End If
		If kd.GetDefault("team", "A") = "B" Then
			takenB = takenB + 1
		Else
			takenA = takenA + 1
		End If
	Next
	Return changed
End Sub

Private Sub ShootoutOutcome(kicksEach As Int, takenA As Int, takenB As Int, scoredA As Int, scoredB As Int) As Map
	Dim decided As Boolean
	Dim winner As String
	Dim inSuddenDeath As Boolean
	If takenA < kicksEach Or takenB < kicksEach Then
		Dim remA As Int = kicksEach - takenA
		If remA < 0 Then remA = 0
		Dim remB As Int = kicksEach - takenB
		If remB < 0 Then remB = 0
		If scoredA > scoredB + remB Then
			decided = True
			winner = "A"
		Else If scoredB > scoredA + remA Then
			decided = True
			winner = "B"
		End If
	Else If takenA = takenB Then
		If scoredA > scoredB Then
			decided = True
			winner = "A"
		Else If scoredB > scoredA Then
			decided = True
			winner = "B"
		Else
			inSuddenDeath = True
		End If
	Else
		inSuddenDeath = True
	End If
	Dim m As Map
	m.Initialize
	m.Put("decided", decided)
	m.Put("winner", winner)
	m.Put("inSuddenDeath", inSuddenDeath)
	Return m
End Sub

Private Sub SortShootoutKicks(kicks As List)
	Dim a As Int
	For a = 0 To kicks.Size - 2
		Dim b As Int
		For b = a + 1 To kicks.Size - 1
			Dim ea As Map = kicks.Get(a)
			Dim eb As Map = kicks.Get(b)
			If EventSeq(ea) > EventSeq(eb) Then
				kicks.Set(a, eb)
				kicks.Set(b, ea)
			End If
		Next
	Next
End Sub

Private Sub EventSeq(ev As Map) As Long
	Dim details As Map = DetailsOf(ev)
	If details.ContainsKey("seq") Then Return AsLong(details.Get("seq"))
	Return AsLong(ev.GetDefault("timestamp", 0))
End Sub

Public Sub QueueEventUpsert(ev As Map)
	Initialize
	If ev.IsInitialized = False Or ev.ContainsKey("id") = False Then Return
	modAppState.UpsertEvent(ev)
	Dim eventId As String = ev.Get("id")
	Dim rev As Int = 1
	If dirtyEvents.ContainsKey(eventId) Then
		Dim prev As Map = dirtyEvents.Get(eventId)
		rev = AsInt(prev.GetDefault("rev", 0)) + 1
	End If
	Dim row As Map
	row.Initialize
	row.Put("op", "upsert")
	row.Put("rev", rev)
	row.Put("matchId", ev.GetDefault("matchId", ""))
	dirtyEvents.Put(eventId, row)
	PersistSnapshot
	Kick
End Sub

Public Sub QueueEventDelete(eventId As String)
	Initialize
	If eventId = "" Then Return
	Dim ev As Map = modAppState.FindEvent(eventId)
	Dim matchId As String = ""
	If ev.IsInitialized And ev.ContainsKey("id") Then matchId = ev.GetDefault("matchId", "")
	Dim wasAcked As Boolean = ackedEvents.ContainsKey(eventId)
	modAppState.RemoveEvent(eventId)
	If wasAcked = False Then
		dirtyEvents.Remove(eventId)
	Else
		Dim rev As Int = 1
		If dirtyEvents.ContainsKey(eventId) Then
			Dim prev As Map = dirtyEvents.Get(eventId)
			rev = AsInt(prev.GetDefault("rev", 0)) + 1
		End If
		Dim row As Map
		row.Initialize
		row.Put("op", "delete")
		row.Put("rev", rev)
		row.Put("matchId", matchId)
		dirtyEvents.Put(eventId, row)
	End If
	PersistSnapshot
	Kick
End Sub

Public Sub QueueMatch(match As Map)
	Initialize
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then Return
	ApplyLiveScore(match)
	modAppState.UpsertMatch(match)
	Dim matchId As String = match.Get("id")
	Dim rev As Int = 1
	If dirtyMatches.ContainsKey(matchId) Then rev = AsInt(dirtyMatches.Get(matchId)) + 1
	dirtyMatches.Put(matchId, rev)
	PersistSnapshot
	Kick
End Sub

Public Sub ForgetMatch(matchId As String)
	Initialize
	If matchId = "" Then Return
	dirtyMatches.Remove(matchId)
	Dim drop As List
	drop.Initialize
	For Each eventId As String In dirtyEvents.Keys
		Dim row As Map = dirtyEvents.Get(eventId)
		If row.GetDefault("matchId", "") = matchId Then drop.Add(eventId)
	Next
	Dim i As Int
	For i = 0 To drop.Size - 1
		Dim id As String = drop.Get(i)
		dirtyEvents.Remove(id)
		ackedEvents.Remove(id)
	Next
	PersistSnapshot
End Sub

' One pending event. Body is read from memory at send time by the caller.
Public Sub NextEventSend As Map
	Initialize
	Dim empty As Map
	empty.Initialize
	Dim ids As List
	ids.Initialize
	For Each eventId As String In dirtyEvents.Keys
		ids.Add(eventId)
	Next
	Dim dropped As Boolean = False
	Dim i As Int
	For i = 0 To ids.Size - 1
		Dim eventId As String = ids.Get(i)
		If dirtyEvents.ContainsKey(eventId) Then
			Dim row As Map = dirtyEvents.Get(eventId)
			Dim op As String = row.GetDefault("op", "upsert")
			Dim missing As Boolean = False
			If op = "upsert" Then
				Dim ev As Map = modAppState.FindEvent(eventId)
				If ev.IsInitialized = False Or ev.ContainsKey("id") = False Then missing = True
			End If
			If missing Then
				dirtyEvents.Remove(eventId)
				dropped = True
			Else
				Dim job As Map
				job.Initialize
				job.Put("id", eventId)
				job.Put("op", op)
				job.Put("rev", AsInt(row.GetDefault("rev", 1)))
				If dropped Then PersistSnapshot
				Return job
			End If
		End If
	Next
	If dropped Then PersistSnapshot
	Return empty
End Sub

' One pending match. Score is counted from the phone's events just before send.
Public Sub NextMatchSend As Map
	Initialize
	Dim empty As Map
	empty.Initialize
	If dirtyMatches.Size = 0 Then Return empty
	Dim matchId As String = ""
	For Each matchKey As String In dirtyMatches.Keys
		matchId = matchKey
		Exit
	Next
	If matchId = "" Then Return empty
	Dim rev As Int = AsInt(dirtyMatches.Get(matchId))
	Dim match As Map = modAppState.FindMatch(matchId)
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then
		dirtyMatches.Remove(matchId)
		PersistSnapshot
		Return NextMatchSend
	End If
	ApplyLiveScore(match)
	Dim job As Map
	job.Initialize
	job.Put("id", matchId)
	job.Put("rev", rev)
	Return job
End Sub

Public Sub NoteEventSend(eventId As String, sentRev As Int, sentOp As String, ok As Boolean)
	Initialize
	If ok = False Then Return
	If sentOp = "upsert" Then ackedEvents.Put(eventId, True)
	If dirtyEvents.ContainsKey(eventId) Then
		Dim row As Map = dirtyEvents.Get(eventId)
		Dim curOp As String = row.GetDefault("op", "")
		Dim curRev As Int = AsInt(row.GetDefault("rev", 0))
		If curOp = sentOp And curRev = sentRev Then
			dirtyEvents.Remove(eventId)
			If sentOp = "delete" Then ackedEvents.Remove(eventId)
		End If
	End If
	PersistSnapshot
End Sub

Public Sub NoteMatchSend(matchId As String, sentRev As Int, ok As Boolean)
	Initialize
	If ok = False Then Return
	If dirtyMatches.ContainsKey(matchId) Then
		If AsInt(dirtyMatches.Get(matchId)) = sentRev Then dirtyMatches.Remove(matchId)
	End If
	PersistSnapshot
End Sub

Public Sub PreferDirtyMatches(serverMatches As List) As List
	Initialize
	Dim local As Map
	local.Initialize
	Dim i As Int
	For i = 0 To modAppState.Matches.Size - 1
		Dim m As Map = modAppState.Matches.Get(i)
		Dim id As String = m.GetDefault("id", "")
		If id <> "" Then local.Put(id, m)
	Next
	Dim out As List
	out.Initialize
	Dim seen As Map
	seen.Initialize
	If serverMatches.IsInitialized Then
		For i = 0 To serverMatches.Size - 1
			Dim sm As Map = serverMatches.Get(i)
			Dim sid As String = sm.GetDefault("id", "")
			If sid = "" Then Continue
			seen.Put(sid, True)
			If dirtyMatches.ContainsKey(sid) And local.ContainsKey(sid) Then
				out.Add(local.Get(sid))
			Else
				out.Add(sm)
			End If
		Next
	End If
	For Each did As String In dirtyMatches.Keys
		If seen.ContainsKey(did) Then Continue
		If local.ContainsKey(did) Then out.Add(local.Get(did))
	Next
	Return out
End Sub

Public Sub PreferDirtyEvents(serverEvents As List) As List
	Initialize
	Dim local As Map
	local.Initialize
	Dim i As Int
	For i = 0 To modAppState.FeedEvents.Size - 1
		Dim e As Map = modAppState.FeedEvents.Get(i)
		Dim id As String = e.GetDefault("id", "")
		If id <> "" Then local.Put(id, e)
	Next
	Dim out As List
	out.Initialize
	Dim seen As Map
	seen.Initialize
	If serverEvents.IsInitialized Then
		For i = 0 To serverEvents.Size - 1
			Dim se As Map = serverEvents.Get(i)
			Dim sid As String = se.GetDefault("id", "")
			If sid = "" Then Continue
			seen.Put(sid, True)
			If dirtyEvents.ContainsKey(sid) Then
				Dim row As Map = dirtyEvents.Get(sid)
				If row.GetDefault("op", "") = "delete" Then Continue
				If local.ContainsKey(sid) Then
					out.Add(local.Get(sid))
				Else
					out.Add(se)
				End If
			Else
				out.Add(se)
			End If
		Next
	End If
	For Each did As String In dirtyEvents.Keys
		If seen.ContainsKey(did) Then Continue
		Dim drow As Map = dirtyEvents.Get(did)
		If drow.GetDefault("op", "") = "delete" Then Continue
		If local.ContainsKey(did) Then out.Add(local.Get(did))
	Next
	' Keep events for a live match even when they fall outside the server's latest 100.
	For i = 0 To modAppState.FeedEvents.Size - 1
		Dim kept As Map = modAppState.FeedEvents.Get(i)
		Dim keptId As String = kept.GetDefault("id", "")
		If keptId = "" Or seen.ContainsKey(keptId) Then Continue
		If dirtyEvents.ContainsKey(keptId) Then Continue
		Dim host As Map = modAppState.FindMatch(kept.GetDefault("matchId", ""))
		If host.GetDefault("status", "") = "LIVE" Then out.Add(kept)
	Next
	Return out
End Sub

Public Sub LoadSnapshot
	Initialize
	Try
		If File.Exists(modPlatform.AppDir, CACHE_FILE) = False Then Return
		Dim raw As String = File.ReadString(modPlatform.AppDir, CACHE_FILE)
		If raw.Length = 0 Then Return
		Dim jp As JSONParser
		jp.Initialize(raw)
		Dim root As Map = jp.NextObject
		If root.ContainsKey("clubs") And root.Get("clubs") Is List Then modAppState.Clubs = root.Get("clubs")
		If root.ContainsKey("matches") And root.Get("matches") Is List Then modAppState.Matches = root.Get("matches")
		If root.ContainsKey("events") And root.Get("events") Is List Then modAppState.FeedEvents = root.Get("events")
		If root.ContainsKey("training") And root.Get("training") Is List Then modAppState.TrainingSessions = root.Get("training")
		If root.ContainsKey("dirtyEvents") And root.Get("dirtyEvents") Is Map Then dirtyEvents = root.Get("dirtyEvents")
		If root.ContainsKey("dirtyMatches") And root.Get("dirtyMatches") Is Map Then dirtyMatches = root.Get("dirtyMatches")
		If root.ContainsKey("ackedEvents") And root.Get("ackedEvents") Is Map Then ackedEvents = root.Get("ackedEvents")
		If root.ContainsKey("selectedMatchId") Then modAppState.SelectedMatchId = "" & root.GetDefault("selectedMatchId", "")
		If root.ContainsKey("selectedClubId") Then modAppState.SelectedClubId = "" & root.GetDefault("selectedClubId", "")
		RecountLoadedScores
	Catch
		Log("LoadSnapshot: " & LastException)
	End Try
End Sub

Public Sub PersistSnapshot
	Initialize
	Try
		Dim root As Map
		root.Initialize
		root.Put("clubs", modAppState.Clubs)
		root.Put("matches", modAppState.Matches)
		root.Put("events", modAppState.FeedEvents)
		root.Put("training", modAppState.TrainingSessions)
		root.Put("dirtyEvents", dirtyEvents)
		root.Put("dirtyMatches", dirtyMatches)
		root.Put("ackedEvents", ackedEvents)
		root.Put("selectedMatchId", modAppState.SelectedMatchId)
		root.Put("selectedClubId", modAppState.SelectedClubId)
		Dim json As String = modPlatform.JsonString(root)
		Dim dir As String = modPlatform.AppDir
		Dim tmp As String = CACHE_FILE & ".tmp"
		File.WriteString(dir, tmp, json)
		modPlatform.ReplaceFile(dir, tmp, CACHE_FILE)
	Catch
		Log("PersistSnapshot: " & LastException)
	End Try
End Sub

Private Sub DetailsOf(e As Map) As Map
	Dim details As Map
	Dim dObj As Object = e.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then Return dObj
	details.Initialize
	Return details
End Sub

Private Sub Kick
	Try
		CallSubDelayed(B4XPages.MainPage, "KickSync")
	Catch
		Log("KickSync: " & LastException)
	End Try
End Sub
