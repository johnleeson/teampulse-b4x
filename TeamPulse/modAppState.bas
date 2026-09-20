B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' In-memory app state shared across B4XPages.
Sub Process_Globals
	Public CurrentUser As Map
	Public Clubs As List
	Public Matches As List
	Public FeedEvents As List
	Public SelectedClubId As String
	Public SelectedMatchId As String
	Public SelectedEventId As String
	Public IsAuthenticated As Boolean
End Sub

Public Sub Initialize
	CurrentUser.Initialize
	Clubs.Initialize
	Matches.Initialize
	FeedEvents.Initialize
	SelectedClubId = ""
	SelectedMatchId = ""
	SelectedEventId = ""
	IsAuthenticated = False
End Sub

Public Sub SetUser(u As Map)
	CurrentUser = u
	IsAuthenticated = u.IsInitialized And u.ContainsKey("id") And u.Get("id") <> ""
End Sub

Public Sub ClearUser
	CurrentUser.Initialize
	IsAuthenticated = False
End Sub

Public Sub FindClub(clubId As String) As Map
	Dim empty As Map
	empty.Initialize
	For Each c As Map In Clubs
		If c.GetDefault("id", "") = clubId Then Return c
	Next
	Return empty
End Sub

Public Sub FindMatch(matchId As String) As Map
	Dim empty As Map
	empty.Initialize
	For Each m As Map In Matches
		If m.GetDefault("id", "") = matchId Then Return m
	Next
	Return empty
End Sub

Public Sub ClubsForCurrentUser As List
	Dim result As List
	result.Initialize
	If IsAuthenticated = False Then Return result
	Dim uid As String = CurrentUser.GetDefault("id", "")
	For Each c As Map In Clubs
		Dim members As List = c.GetDefault("members", DummyList)
		For Each mem As Map In members
			If mem.GetDefault("id", "") = uid Then
				result.Add(c)
				Exit
			End If
		Next
	Next
	Return result
End Sub

Private Sub DummyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Public Sub EventsForMatch(matchId As String) As List
	Dim result As List
	result.Initialize
	For Each e As Map In FeedEvents
		If e.GetDefault("matchId", "") = matchId Then result.Add(e)
	Next
	Return result
End Sub

Public Sub UpsertClub(club As Map)
	Dim id As String = club.GetDefault("id", "")
	For i = 0 To Clubs.Size - 1
		Dim c As Map = Clubs.Get(i)
		If c.GetDefault("id", "") = id Then
			Clubs.Set(i, club)
			Return
		End If
	Next
	Clubs.Add(club)
End Sub

Public Sub UpsertMatch(match As Map)
	Dim id As String = match.GetDefault("id", "")
	For i = 0 To Matches.Size - 1
		Dim m As Map = Matches.Get(i)
		If m.GetDefault("id", "") = id Then
			Matches.Set(i, match)
			Return
		End If
	Next
	Matches.Add(match)
End Sub

Public Sub UpsertEvent(ev As Map)
	Dim id As String = ev.GetDefault("id", "")
	For i = 0 To FeedEvents.Size - 1
		Dim e As Map = FeedEvents.Get(i)
		If e.GetDefault("id", "") = id Then
			FeedEvents.Set(i, ev)
			Return
		End If
	Next
	FeedEvents.Add(ev)
End Sub

Public Sub FindEvent(eventId As String) As Map
	Dim empty As Map
	empty.Initialize
	For Each e As Map In FeedEvents
		If e.GetDefault("id", "") = eventId Then Return e
	Next
	Return empty
End Sub

Public Sub RemoveEvent(eventId As String)
	For i = FeedEvents.Size - 1 To 0 Step -1
		Dim e As Map = FeedEvents.Get(i)
		If e.GetDefault("id", "") = eventId Then FeedEvents.RemoveAt(i)
	Next
End Sub

Public Sub RemoveMatch(matchId As String)
	For i = Matches.Size - 1 To 0 Step -1
		Dim m As Map = Matches.Get(i)
		If m.GetDefault("id", "") = matchId Then Matches.RemoveAt(i)
	Next
End Sub

Public Sub RemoveEventsForMatch(matchId As String)
	For i = FeedEvents.Size - 1 To 0 Step -1
		Dim e As Map = FeedEvents.Get(i)
		If e.GetDefault("matchId", "") = matchId Then FeedEvents.RemoveAt(i)
	Next
End Sub

Public Sub NewId As String
	Try
		Dim uuid As JavaObject
		uuid.InitializeStatic("java.util.UUID")
		Return uuid.RunMethodJO("randomUUID", Null).RunMethod("toString", Null)
	Catch
		Return "local-" & DateTime.Now & "-" & Rnd(1000, 9999)
	End Try
End Sub

' --- Match clock helpers (wall time ↔ playing minutes, HT break aware) ---

Public Sub KickOffMillis(match As Map) As Long
	Dim started As Long = 0
	Try
		started = match.GetDefault("liveStartedAt", 0)
	Catch
		started = 0
	End Try
	If started > 0 Then Return started
	Dim mid As String = match.GetDefault("id", "")
	Dim events As List = EventsForMatch(mid)
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") = "START" Then
			Return e.GetDefault("timestamp", DateTime.Now)
		End If
	Next
	Return DateTime.Now
End Sub

' Returns Map: htMs, htMin, shMs (0 if missing).
Public Sub HalfMarkers(matchId As String) As Map
	Dim out As Map
	out.Initialize
	out.Put("htMs", 0)
	out.Put("htMin", 0)
	out.Put("shMs", 0)
	Dim events As List = EventsForMatch(matchId)
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		Dim t As String = e.GetDefault("type", "")
		Dim details As Map
		Dim dObj As Object = e.GetDefault("details", Null)
		If dObj <> Null And dObj Is Map Then
			details = dObj
		Else
			details.Initialize
		End If
		If t = "HALF_TIME" Then
			out.Put("htMs", e.GetDefault("timestamp", 0))
			out.Put("htMin", details.GetDefault("minute", 0))
		Else If t = "SECOND_HALF" Then
			out.Put("shMs", e.GetDefault("timestamp", 0))
		End If
	Next
	Return out
End Sub

' Playing minutes at a wall-clock instant (HT break freezes the match clock).
Public Sub PlayingMinuteAt(match As Map, wallMs As Long) As Int
	Dim kick As Long = KickOffMillis(match)
	Dim marks As Map = HalfMarkers(match.GetDefault("id", ""))
	Dim htMs As Long = marks.GetDefault("htMs", 0)
	Dim htMin As Int = marks.GetDefault("htMin", 0)
	Dim shMs As Long = marks.GetDefault("shMs", 0)
	Dim mins As Int
	If htMs <= 0 Or wallMs <= htMs Then
		mins = (wallMs - kick) / DateTime.TicksPerMinute
	Else If shMs <= 0 Or wallMs < shMs Then
		mins = htMin
	Else
		mins = htMin + ((wallMs - shMs) / DateTime.TicksPerMinute)
	End If
	If mins < 0 Then mins = 0
	Return mins
End Sub

' Wall-clock millis for a playing minute (uses match date for calendar day).
Public Sub WallClockForMinute(match As Map, minute As Int) As Long
	If minute < 0 Then minute = 0
	Dim kick As Long = KickOffMillis(match)
	Dim marks As Map = HalfMarkers(match.GetDefault("id", ""))
	Dim htMs As Long = marks.GetDefault("htMs", 0)
	Dim htMin As Int = marks.GetDefault("htMin", 0)
	Dim shMs As Long = marks.GetDefault("shMs", 0)
	If htMs <= 0 Or minute <= htMin Then
		Return kick + minute * DateTime.TicksPerMinute
	End If
	If shMs > 0 Then
		Return shMs + (minute - htMin) * DateTime.TicksPerMinute
	End If
	' HT logged but no 2H yet — place beyond-HT minutes at HT whistle.
	Return htMs
End Sub

Public Sub FormatHHMM(ms As Long) As String
	DateTime.TimeFormat = "HH:mm"
	Return DateTime.Time(ms)
End Sub

' Parse "HH:mm" on the match's calendar day (falls back to today).
Public Sub ParseHHMMOnMatchDay(match As Map, hhmm As String) As Long
	Dim s As String = hhmm.Trim
	If s.Length < 4 Then Return DateTime.Now
	Dim colon As Int = s.IndexOf(":")
	If colon < 1 Then Return DateTime.Now
	Dim hh As Int = 0
	Dim mm As Int = 0
	Try
		hh = s.SubString2(0, colon)
		mm = s.SubString(colon + 1)
	Catch
		Return DateTime.Now
	End Try
	If hh < 0 Or hh > 23 Or mm < 0 Or mm > 59 Then Return DateTime.Now
	Dim dayMs As Long = DateTime.Now
	Dim d As String = match.GetDefault("date", "")
	If d.Length >= 10 Then
		Try
			DateTime.DateFormat = "yyyy-MM-dd"
			dayMs = DateTime.DateParse(d.SubString2(0, 10))
		Catch
			dayMs = DateTime.Now
		End Try
	End If
	Return dayMs + hh * DateTime.TicksPerHour + mm * DateTime.TicksPerMinute
End Sub

' Pitch minutes from live feed (START/HT/2H/END + SUBs), HT break excluded.
' Prefers wall-clock event timestamps — works even when details.minute was not stored.
Public Sub CalculateMatchMinutes(match As Map) As Map
	Dim result As Map
	result.Initialize
	Dim mid As String = match.GetDefault("id", "")
	Dim events As List = EventsForMatch(mid)
	Dim windows As List = MatchPlayWindows(match, events)
	If windows.Size = 0 Then Return result
	
	Dim matchStartMs As Long = 0
	Dim matchEndMs As Long = 0
	Dim w0 As Map = windows.Get(0)
	matchStartMs = w0.Get("startMs")
	Dim wLast As Map = windows.Get(windows.Size - 1)
	matchEndMs = wLast.Get("endMs")
	
	Dim subs As List = TeamASubs(events)
	Dim starters As List = ReconstructStarters(match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMapSafe)), subs)
	
	' stints: playerId -> List of Maps {onMs, offMs}  (offMs=-1 means open)
	Dim stints As Map
	stints.Initialize
	Dim i As Int
	For i = 0 To starters.Size - 1
		OpenStint(stints, starters.Get(i), matchStartMs)
	Next
	
	Dim timeline As List
	timeline.Initialize
	For i = 0 To subs.Size - 1
		Dim s As Map = subs.Get(i)
		Dim item As Map
		item.Initialize
		item.Put("atMs", s.Get("atMs"))
		item.Put("kind", "SUB")
		item.Put("playerOut", s.Get("playerOut"))
		item.Put("playerIn", s.Get("playerIn"))
		timeline.Add(item)
	Next
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "RED_CARD" Then Continue
		Dim d As Map = EventDetailsMap(e)
		If d.GetDefault("team", "A") = "B" Then Continue
		Dim rp As String = d.GetDefault("player", d.GetDefault("scorer", ""))
		If rp = "" Then Continue
		Dim red As Map
		red.Initialize
		red.Put("atMs", e.GetDefault("timestamp", 0))
		red.Put("kind", "RED")
		red.Put("playerOut", rp)
		red.Put("playerIn", "")
		timeline.Add(red)
	Next
	' Sort timeline ascending by atMs
	Dim a, b As Int
	For a = 0 To timeline.Size - 2
		For b = a + 1 To timeline.Size - 1
			Dim ia As Map = timeline.Get(a)
			Dim ib As Map = timeline.Get(b)
			If ib.GetDefault("atMs", 0) < ia.GetDefault("atMs", 0) Then
				timeline.Set(a, ib)
				timeline.Set(b, ia)
			End If
		Next
	Next
	
	For i = 0 To timeline.Size - 1
		Dim t As Map = timeline.Get(i)
		Dim atMs As Long = t.GetDefault("atMs", 0)
		If atMs < matchStartMs Or atMs > matchEndMs Then Continue
		If t.GetDefault("kind", "") = "SUB" Then
			CloseStint(stints, t.GetDefault("playerOut", ""), atMs)
			OpenStint(stints, t.GetDefault("playerIn", ""), atMs)
		Else
			CloseStint(stints, t.GetDefault("playerOut", ""), atMs)
		End If
	Next
	
	For Each pid As String In stints.Keys
		Dim list As List = stints.Get(pid)
		Dim si As Int
		For si = 0 To list.Size - 1
			Dim st As Map = list.Get(si)
			If st.GetDefault("offMs", -1) < 0 Then st.Put("offMs", matchEndMs)
		Next
	Next
	
	For Each pid2 As String In stints.Keys
		Dim list2 As List = stints.Get(pid2)
		Dim totalMs As Long = 0
		Dim sj As Int
		For sj = 0 To list2.Size - 1
			Dim st2 As Map = list2.Get(sj)
			Dim onMs As Long = st2.GetDefault("onMs", 0)
			Dim offMs As Long = st2.GetDefault("offMs", matchEndMs)
			Dim wi As Int
			For wi = 0 To windows.Size - 1
				Dim win As Map = windows.Get(wi)
				totalMs = totalMs + OverlapMs(onMs, offMs, win.Get("startMs"), win.Get("endMs"))
			Next
		Next
		Dim mins As Int = Round(totalMs / DateTime.TicksPerMinute)
		If mins > 0 Then result.Put(pid2, mins)
	Next
	Return result
End Sub

Private Sub MatchPlayWindows(match As Map, events As List) As List
	Dim windows As List
	windows.Initialize
	Dim startMs As Long = FindEventMs(events, "START")
	If startMs <= 0 Then startMs = KickOffMillis(match)
	Dim htMs As Long = FindEventMs(events, "HALF_TIME")
	Dim shMs As Long = FindEventMs(events, "SECOND_HALF")
	Dim endMs As Long = FindEventMs(events, "END")
	Dim planned As Int = 60
	Try
		Dim plan As Map = match.GetDefault("subPlan", Null)
		If plan <> Null And plan Is Map Then planned = plan.GetDefault("matchMinutes", 60)
	Catch
		planned = 60
	End Try
	If planned <= 0 Then planned = 60
	Dim halfMin As Int = Max(1, planned / 2)
	If endMs <= 0 Then
		If shMs > 0 Then
			endMs = shMs + halfMin * DateTime.TicksPerMinute
		Else If startMs > 0 Then
			endMs = startMs + planned * DateTime.TicksPerMinute
		End If
	End If
	If startMs > 0 And htMs > startMs Then
		Dim w1 As Map
		w1.Initialize
		w1.Put("startMs", startMs)
		w1.Put("endMs", htMs)
		windows.Add(w1)
	End If
	If shMs > 0 And endMs > shMs Then
		Dim w2 As Map
		w2.Initialize
		w2.Put("startMs", shMs)
		w2.Put("endMs", endMs)
		windows.Add(w2)
	End If
	' Incomplete periods (e.g. HT without 2H): use continuous start→end so SUBs still count
	If (windows.Size = 0 Or (htMs > 0 And shMs <= 0)) And startMs > 0 And endMs > startMs Then
		windows.Initialize
		Dim w0 As Map
		w0.Initialize
		w0.Put("startMs", startMs)
		w0.Put("endMs", endMs)
		windows.Add(w0)
	End If
	Return windows
End Sub

Private Sub FindEventMs(events As List, etype As String) As Long
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") = etype Then Return e.GetDefault("timestamp", 0)
	Next
	Return 0
End Sub

Private Sub TeamASubs(events As List) As List
	Dim out As List
	out.Initialize
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "SUB" Then Continue
		Dim d As Map = EventDetailsMap(e)
		If d.GetDefault("team", "A") = "B" Then Continue
		Dim pout As String = d.GetDefault("playerOut", "")
		Dim pin As String = d.GetDefault("playerIn", "")
		If pout = "" Or pin = "" Then Continue
		Dim s As Map
		s.Initialize
		s.Put("atMs", e.GetDefault("timestamp", 0))
		s.Put("playerOut", pout)
		s.Put("playerIn", pin)
		out.Add(s)
	Next
	Return out
End Sub

Private Sub ReconstructStarters(lineup As Map, subs As List) As List
	Dim slots As Map
	slots.Initialize
	If lineup.IsInitialized Then
		For Each k As String In lineup.Keys
			Dim v As String = lineup.Get(k)
			If v <> "" Then slots.Put(k, v)
		Next
	End If
	Dim i As Int
	For i = subs.Size - 1 To 0 Step -1
		Dim s As Map = subs.Get(i)
		Dim pin As String = s.GetDefault("playerIn", "")
		Dim pout As String = s.GetDefault("playerOut", "")
		Dim slot As String = ""
		For Each sk As String In slots.Keys
			If slots.Get(sk) = pin Then
				slot = sk
				Exit
			End If
		Next
		If slot <> "" Then slots.Put(slot, pout)
	Next
	Dim starters As List
	starters.Initialize
	Dim seen As Map
	seen.Initialize
	For Each sk2 As String In slots.Keys
		Dim pid As String = slots.Get(sk2)
		If pid <> "" And seen.ContainsKey(pid) = False Then
			seen.Put(pid, True)
			starters.Add(pid)
		End If
	Next
	Return starters
End Sub

Private Sub OpenStint(stints As Map, playerId As String, onMs As Long)
	If playerId = "" Then Return
	Dim list As List
	If stints.ContainsKey(playerId) Then
		list = stints.Get(playerId)
	Else
		list.Initialize
		stints.Put(playerId, list)
	End If
	Dim i As Int
	For i = 0 To list.Size - 1
		Dim st As Map = list.Get(i)
		If st.GetDefault("offMs", -1) < 0 Then Return
	Next
	Dim neu As Map
	neu.Initialize
	neu.Put("onMs", onMs)
	neu.Put("offMs", -1)
	list.Add(neu)
End Sub

Private Sub CloseStint(stints As Map, playerId As String, offMs As Long)
	If playerId = "" Or stints.ContainsKey(playerId) = False Then Return
	Dim list As List = stints.Get(playerId)
	Dim i As Int
	For i = list.Size - 1 To 0 Step -1
		Dim st As Map = list.Get(i)
		If st.GetDefault("offMs", -1) < 0 Then
			Dim onMs As Long = st.GetDefault("onMs", offMs)
			If offMs < onMs Then offMs = onMs
			st.Put("offMs", offMs)
			Return
		End If
	Next
End Sub

Private Sub OverlapMs(aStart As Long, aEnd As Long, bStart As Long, bEnd As Long) As Long
	Dim start As Long = Max(aStart, bStart)
	Dim endt As Long = Min(aEnd, bEnd)
	If endt > start Then Return endt - start
	Return 0
End Sub

Private Sub EmptyMapSafe As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

' Newest first by timestamp, then by playing minute.
Public Sub EventsNewestFirst(matchId As String) As List
	Dim src As List = EventsForMatch(matchId)
	Dim out As List
	out.Initialize
	Dim i As Int
	For i = 0 To src.Size - 1
		out.Add(src.Get(i))
	Next
	Dim a, b As Int
	For a = 0 To out.Size - 2
		For b = a + 1 To out.Size - 1
			Dim ea As Map = out.Get(a)
			Dim eb As Map = out.Get(b)
			Dim ta As Long = ea.GetDefault("timestamp", 0)
			Dim tb As Long = eb.GetDefault("timestamp", 0)
			Dim swap As Boolean = False
			If tb > ta Then
				swap = True
			Else If tb = ta Then
				Dim da As Map = EventDetailsMap(ea)
				Dim db As Map = EventDetailsMap(eb)
				If db.GetDefault("minute", 0) > da.GetDefault("minute", 0) Then swap = True
			End If
			If swap Then
				out.Set(a, eb)
				out.Set(b, ea)
			End If
		Next
	Next
	Return out
End Sub

Private Sub EventDetailsMap(e As Map) As Map
	Dim details As Map
	Dim dObj As Object = e.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then
		details = dObj
	Else
		details.Initialize
	End If
	Return details
End Sub
