B4A=true
B4i=true
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
	Public TrainingSessions As List
	Public SelectedClubId As String
	Public SelectedMatchId As String
	Public SelectedTrainingId As String
	' True when the training editor should load SelectedTrainingId.
	Public EditingExistingTraining As Boolean
	Public SelectedEventId As String
	Public SelectedPlayerId As String
	Public PlayerEditReturnPage As String
	Public IsAuthenticated As Boolean
	' True when ScheduleMatch should load SelectedMatchId for editing.
	Public EditingExistingMatch As Boolean
End Sub

Public Sub Initialize
	modLocal.Initialize
	CurrentUser.Initialize
	Clubs.Initialize
	Matches.Initialize
	FeedEvents.Initialize
	TrainingSessions.Initialize
	SelectedClubId = ""
	SelectedMatchId = ""
	SelectedTrainingId = ""
	EditingExistingTraining = False
	SelectedEventId = ""
	SelectedPlayerId = ""
	PlayerEditReturnPage = ""
	IsAuthenticated = False
	EditingExistingMatch = False
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

Public Sub FindTraining(sessionId As String) As Map
	Dim empty As Map
	empty.Initialize
	For Each s As Map In TrainingSessions
		If s.GetDefault("id", "") = sessionId Then Return s
	Next
	Return empty
End Sub

Public Sub TrainingsForCurrentUser As List
	Dim result As List
	result.Initialize
	Dim allowed As Map
	allowed.Initialize
	Dim mine As List = ClubsForCurrentUser
	For Each c As Map In mine
		Dim cid As String = c.GetDefault("id", "")
		If cid <> "" Then allowed.Put(cid, True)
	Next
	For Each s As Map In TrainingSessions
		Dim sid As String = s.GetDefault("clubId", "")
		If allowed.ContainsKey(sid) Then result.Add(s)
	Next
	Return result
End Sub

Public Sub UpsertTraining(session As Map)
	Dim id As String = session.GetDefault("id", "")
	For i = 0 To TrainingSessions.Size - 1
		Dim s As Map = TrainingSessions.Get(i)
		If s.GetDefault("id", "") = id Then
			TrainingSessions.Set(i, session)
			Return
		End If
	Next
	TrainingSessions.InsertAt(0, session)
End Sub

Public Sub RemoveTraining(sessionId As String)
	For i = TrainingSessions.Size - 1 To 0 Step -1
		Dim s As Map = TrainingSessions.Get(i)
		If s.GetDefault("id", "") = sessionId Then TrainingSessions.RemoveAt(i)
	Next
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
	Return modPlatform.NewUuid
End Sub

' --- Match clock helpers (wall time ↔ playing minutes, HT break aware) ---

' Actual whistle: edited START, else go-live instant, else the scheduled kick-off.
' Returns 0 when none of those exist (callers must not treat "now" as kick-off).
Public Sub KickOffMillis(match As Map) As Long
	If match.IsInitialized = False Then Return 0
	Dim mid As String = match.GetDefault("id", "")
	Dim events As List = EventsForMatch(mid)
	Dim startMs As Long = FirstPeriodAfter(events, "START", 0)
	If startMs > 0 Then Return startMs
	Dim started As Long = ToLong(match.GetDefault("liveStartedAt", 0))
	If started > 0 Then Return started
	Dim ko As String = "" & match.GetDefault("kickOffTime", "")
	ko = ko.Trim
	If ko.Length >= 4 And ko.IndexOf(":") > 0 Then
		Return ParseHHMMOnMatchDay(match, ko)
	End If
	Return 0
End Sub

' Returns Map: htMs, htMin, shMs (0 if missing).
' htMin is playing time from kick-off to the HT whistle (the break is not included).
Public Sub HalfMarkers(matchId As String) As Map
	Dim out As Map
	out.Initialize
	out.Put("htMs", 0)
	out.Put("htMin", 0)
	out.Put("shMs", 0)
	Dim events As List = EventsForMatch(matchId)
	Dim htRaw As Long = FirstPeriodAfter(events, "HALF_TIME", 0)
	Dim shRaw As Long = 0
	If htRaw > 0 Then shRaw = FirstPeriodAfter(events, "SECOND_HALF", htRaw)
	If shRaw <= 0 Then shRaw = FirstPeriodAfter(events, "SECOND_HALF", 0)
	Dim kick As Long = 0
	Dim match As Map = FindMatch(matchId)
	If match.IsInitialized And match.ContainsKey("id") Then kick = KickOffMillis(match)
	Dim htMs As Long = AlignToKickDay(kick, htRaw)
	Dim shMs As Long = AlignToKickDay(kick, shRaw)
	out.Put("htMs", htMs)
	out.Put("shMs", shMs)
	Dim htMin As Int = 0
	If kick > 0 And htMs > kick Then
		htMin = (htMs - kick) / modPlatform.MinuteTicks
	End If
	out.Put("htMin", htMin)
	Return out
End Sub

' Playing minutes at a wall-clock instant (HT break freezes the match clock).
Public Sub PlayingMinuteAt(match As Map, wallMs As Long) As Int
	Dim kick As Long = KickOffMillis(match)
	If kick <= 0 Or wallMs <= 0 Then Return 0
	Dim marks As Map = HalfMarkers(match.GetDefault("id", ""))
	Dim htMs As Long = marks.GetDefault("htMs", 0)
	Dim htMin As Int = marks.GetDefault("htMin", 0)
	Dim shMs As Long = marks.GetDefault("shMs", 0)
	Dim mins As Int
	If htMs <= 0 Or wallMs <= htMs Then
		mins = (wallMs - kick) / modPlatform.MinuteTicks
	Else If shMs <= 0 Or wallMs < shMs Then
		mins = htMin
	Else
		mins = htMin + ((wallMs - shMs) / modPlatform.MinuteTicks)
	End If
	If mins < 0 Then mins = 0
	Return mins
End Sub

' Wall-clock millis for a playing minute (uses match date for calendar day).
Public Sub WallClockForMinute(match As Map, minute As Int) As Long
	If minute < 0 Then minute = 0
	Dim kick As Long = KickOffMillis(match)
	If kick <= 0 Then kick = DateTime.Now
	Dim marks As Map = HalfMarkers(match.GetDefault("id", ""))
	Dim htMs As Long = marks.GetDefault("htMs", 0)
	Dim htMin As Int = marks.GetDefault("htMin", 0)
	Dim shMs As Long = marks.GetDefault("shMs", 0)
	If htMs <= 0 Or minute <= htMin Then
		Return kick + minute * modPlatform.MinuteTicks
	End If
	If shMs > 0 Then
		Return shMs + (minute - htMin) * modPlatform.MinuteTicks
	End If
	' HT logged but no 2H yet — place beyond-HT minutes at HT whistle.
	Return htMs
End Sub

Public Sub FormatHHMM(ms As Long) As String
	DateTime.TimeFormat = "HH:mm"
	Return DateTime.Time(ms)
End Sub

' Parse "HH:mm" onto the kick-off event's calendar day once START is logged.
' Before kick-off, use the fixture date. A whistle at 21:58 stays on the same evening as 21:55.
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
	Dim anchorMs As Long = 0
	If match.IsInitialized And match.ContainsKey("id") Then
		anchorMs = FirstPeriodAfter(EventsForMatch(match.Get("id")), "START", 0)
	End If
	Dim dayMs As Long = DateTime.Now
	If anchorMs > 0 Then
		dayMs = LocalMidnight(anchorMs)
	Else
		Dim d As String = match.GetDefault("date", "")
		If d.Length >= 10 Then
			Try
				DateTime.DateFormat = "yyyy-MM-dd"
				dayMs = DateTime.DateParse(d.SubString2(0, 10))
			Catch
				dayMs = DateTime.Now
			End Try
		End If
	End If
	Dim atMs As Long = dayMs + hh * DateTime.TicksPerHour + mm * modPlatform.MinuteTicks
	' Clock is before kick-off on that calendar day — the match crossed midnight.
	If anchorMs > 0 And atMs + 12 * DateTime.TicksPerHour < anchorMs Then
		atMs = atMs + DateTime.TicksPerDay
	End If
	Return atMs
End Sub

' Playing minutes per player. Only time inside a half counts:
' [kick-off, half-time whistle] and [second-half start, full time].
' Starters are the kick-off lineup. A player whose first sub is coming on starts at that sub.
' A player can leave and return any number of times; each spell is summed.
' Anyone still on at the final whistle is taken off then. The HT break is not counted.
Public Sub CalculateMatchMinutes(match As Map) As Map
	Return CalculateMatchMinutesFrom(match, FeedEvents)
End Sub

' Same calculation as CalculateMatchMinutes, using this event list.
' The in-memory feed keeps only the latest 100 events; export passes the full list.
Public Sub CalculateMatchMinutesFrom(match As Map, allEvents As List) As Map
	Dim result As Map
	result.Initialize
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then Return result
	Dim events As List
	events.Initialize
	Dim matchId As String = match.GetDefault("id", "")
	If allEvents.IsInitialized Then
		Dim ei As Int
		For ei = 0 To allEvents.Size - 1
			Dim ev As Map = allEvents.Get(ei)
			If ev.GetDefault("matchId", "") = matchId Then events.Add(ev)
		Next
	End If
	' Prefer the playing minute stored on each whistle and sub. That clock already
	' freezes through half time, so a break, a bench start, and a full-time whistle
	' do not depend on iOS timestamp units.
	Dim clocked As Map = MinutesFromPlayingClock(match, events)
	If clocked.Size > 0 Then Return clocked
	Dim windows As List = PlayWindows(match, events)
	If windows.Size = 0 Then Return result

	Dim firstW As Map = windows.Get(0)
	Dim lastW As Map = windows.Get(windows.Size - 1)
	Dim matchStartMs As Long = ToLong(firstW.Get("startMs"))
	Dim matchEndMs As Long = ToLong(lastW.Get("endMs"))

	Dim subs As List = TeamASubEvents(match, events)
	Dim starters As List = StarterIds(match, subs)
	Dim stints As Map
	stints.Initialize
	Dim s As Int
	For s = 0 To starters.Size - 1
		OpenStintAt(stints, starters.Get(s), matchStartMs)
	Next

	Dim timeline As List = PlayTimeline(match, events, subs)
	Dim i As Int
	For i = 0 To timeline.Size - 1
		Dim item As Map = timeline.Get(i)
		Dim atMs As Long = ToLong(item.Get("atMs"))
		If atMs < matchStartMs Or atMs > matchEndMs Then Continue
		If item.GetDefault("kind", "") = "SUB" Then
			' A tap during the half-time break is a HT sub: off at the whistle, on at the restart.
			Dim offAt As Long = atMs
			Dim onAt As Long = atMs
			Dim gap As Map = BreakGapContaining(atMs, windows)
			If gap.IsInitialized And gap.ContainsKey("offMs") Then
				offAt = ToLong(gap.Get("offMs"))
				onAt = ToLong(gap.Get("onMs"))
			End If
			CloseStintAt(stints, item.GetDefault("playerOut", ""), offAt)
			OpenStintAt(stints, item.GetDefault("playerIn", ""), onAt)
		Else
			CloseStintAt(stints, item.GetDefault("playerId", ""), atMs)
		End If
	Next

	Dim capMs As Long = 0
	For i = 0 To windows.Size - 1
		Dim w As Map = windows.Get(i)
		Dim w0 As Long = ToLong(w.Get("startMs"))
		Dim w1 As Long = ToLong(w.Get("endMs"))
		If w1 > w0 Then capMs = capMs + (w1 - w0)
	Next
	Dim capMin As Int = Round(capMs / modPlatform.MinuteTicks)
	If capMin < 1 Then capMin = 1

	For Each pid As String In stints.Keys
		Dim spells As List = stints.Get(pid)
		Dim totalMs As Long = 0
		Dim j As Int
		For j = 0 To spells.Size - 1
			Dim stint As Map = spells.Get(j)
			Dim onMs As Long = ToLong(stint.Get("onMs"))
			Dim offMs As Long = ToLong(stint.GetDefault("offMs", 0))
			If offMs <= 0 Then offMs = matchEndMs
			Dim wj As Int
			For wj = 0 To windows.Size - 1
				Dim win As Map = windows.Get(wj)
				totalMs = totalMs + OverlapMs(onMs, offMs, ToLong(win.Get("startMs")), ToLong(win.Get("endMs")))
			Next
		Next
		Dim mins As Int = Round(totalMs / modPlatform.MinuteTicks)
		If mins < 0 Then mins = 0
		If mins > capMin Then mins = capMin
		If mins > 0 Then result.Put(pid, mins)
	Next
	Return result
End Sub

Private Sub EventDetailsMap(e As Map) As Map
	Dim details As Map
	Dim dObj As Object = e.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then
		Return dObj
	End If
	If dObj <> Null And dObj Is String Then
		Dim raw As String = dObj
		raw = raw.Trim
		If raw.StartsWith("{") Then
			Try
				Dim jp As JSONParser
				jp.Initialize(raw)
				Dim parsed As Map = jp.NextObject
				Return parsed
			Catch
				Log("EventDetailsMap: " & LastException)
			End Try
		End If
	End If
	details.Initialize
	Return details
End Sub

Public Sub EventsNewestFirst(matchId As String) As List
	Dim raw As List = EventsForMatch(matchId)
	Dim sorted As List
	sorted.Initialize
	Dim i As Int
	For i = 0 To raw.Size - 1
		sorted.Add(raw.Get(i))
	Next
	' Newest first — live feed displays the latest event at the top.
	Dim a As Int, b As Int
	For a = 0 To sorted.Size - 2
		For b = a + 1 To sorted.Size - 1
			Dim ea As Map = sorted.Get(a)
			Dim eb As Map = sorted.Get(b)
			' Later in the match first. The minute and clock on the card win over the stored timestamp.
			If EarlierMoment(ea, eb) Then
				sorted.Set(a, eb)
				sorted.Set(b, ea)
			End If
		Next
	Next
	Return sorted
End Sub

' Minutes from details.minute on START / HALF_TIME / SECOND_HALF / END / SUB / RED_CARD.
' Empty when full time has no playing minute (caller falls back to the wall clock).
Private Sub MinutesFromPlayingClock(match As Map, events As List) As Map
	Dim result As Map
	result.Initialize
	Dim endMin As Int = TypedPlayingMinute(events, "END", match, True)
	If endMin <= 0 Then
		Dim htMark As Int = TypedPlayingMinute(events, "HALF_TIME", match, False)
		Dim shMark As Int = TypedPlayingMinute(events, "SECOND_HALF", match, False)
		If htMark > 0 And shMark >= 0 Then
			endMin = htMark + htMark
		Else If htMark <= 0 Then
			endMin = PlannedMatchMinutes(match)
		End If
	End If
	If endMin <= 0 Then Return result
	Dim subs As List = TeamASubEvents(match, events)
	Dim starters As List = StarterIds(match, subs)
	Dim stints As Map
	stints.Initialize
	Dim s As Int
	For s = 0 To starters.Size - 1
		OpenMinute(stints, starters.Get(s), 0)
	Next
	Dim i As Int
	For i = 0 To subs.Size - 1
		Dim subEv As Map = subs.Get(i)
		Dim minute As Int = MapInt(subEv.GetDefault("minute", -1), -1)
		If minute < 0 Then Continue
		If minute > endMin Then minute = endMin
		CloseMinute(stints, subEv.GetDefault("playerOut", ""), minute)
		OpenMinute(stints, subEv.GetDefault("playerIn", ""), minute)
	Next
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "RED_CARD" Then Continue
		Dim d As Map = EventDetailsMap(e)
		If d.GetDefault("team", "A") = "B" Then Continue
		Dim pid As String = d.GetDefault("player", "")
		If pid = "" Then pid = d.GetDefault("playerId", "")
		If pid = "" Then pid = d.GetDefault("scorer", "")
		If pid = "" Then Continue
		Dim redMin As Int = EventPlayingMinute(match, e, d)
		If redMin < 0 Then Continue
		If redMin > endMin Then redMin = endMin
		CloseMinute(stints, pid, redMin)
	Next
	For Each pid2 As String In stints.Keys
		Dim spells As List = stints.Get(pid2)
		Dim total As Int = 0
		Dim j As Int
		For j = 0 To spells.Size - 1
			Dim stint As Map = spells.Get(j)
			Dim onMin As Int = MapInt(stint.GetDefault("onMin", 0), 0)
			Dim offMin As Int = MapInt(stint.GetDefault("offMin", -1), -1)
			If offMin < 0 Then offMin = endMin
			If offMin > endMin Then offMin = endMin
			If offMin > onMin Then total = total + (offMin - onMin)
		Next
		If total > endMin Then total = endMin
		If total > 0 Then result.Put(pid2, total)
	Next
	Return result
End Sub

Private Sub TypedPlayingMinute(events As List, eventType As String, match As Map, lastOne As Boolean) As Int
	Dim found As Int = -1
	Dim foundTs As Long = 0
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> eventType Then Continue
		Dim d As Map = EventDetailsMap(e)
		Dim minute As Int = EventPlayingMinute(match, e, d)
		If minute < 0 Then Continue
		Dim ts As Long = ToLong(e.GetDefault("timestamp", 0))
		Dim take As Boolean = False
		If found = -1 Then
			take = True
		Else If lastOne And minute > found Then
			take = True
		Else If lastOne = False And minute < found Then
			take = True
		Else If minute = found And ((lastOne And ts >= foundTs) Or (lastOne = False And ts <= foundTs)) Then
			take = True
		End If
		If take Then
			found = minute
			foundTs = ts
		End If
	Next
	Return found
End Sub

' details.minute is the match clock logged with the event (half time already frozen).
Private Sub EventPlayingMinute(match As Map, e As Map, details As Map) As Int
	If details.IsInitialized And details.ContainsKey("minute") Then
		Dim minute As Int = MapInt(details.Get("minute"), -1)
		If minute >= 0 Then Return minute
	End If
	Dim atMs As Long = ToLong(e.GetDefault("timestamp", 0))
	If atMs <= 0 Then Return -1
	Return PlayingMinuteAt(match, atMs)
End Sub

Private Sub MapInt(v As Object, defaultValue As Int) As Int
	If v = Null Then Return defaultValue
	Try
		Dim n As Int = v
		Return n
	Catch
		Try
			Dim d As Double = v
			Return Round(d)
		Catch
			Return defaultValue
		End Try
	End Try
End Sub

Private Sub OpenMinute(stints As Map, playerId As String, onMin As Int)
	If playerId = "" Or onMin < 0 Then Return
	Dim list As List = StintList(stints, playerId)
	Dim i As Int
	For i = 0 To list.Size - 1
		Dim stint As Map = list.Get(i)
		If MapInt(stint.GetDefault("offMin", -1), -1) < 0 Then Return
	Next
	Dim s As Map
	s.Initialize
	s.Put("onMin", onMin)
	s.Put("offMin", -1)
	list.Add(s)
End Sub

Private Sub CloseMinute(stints As Map, playerId As String, offMin As Int)
	If playerId = "" Or stints.ContainsKey(playerId) = False Then Return
	Dim list As List = stints.Get(playerId)
	Dim i As Int = list.Size - 1
	Do While i >= 0
		Dim stint As Map = list.Get(i)
		If MapInt(stint.GetDefault("offMin", -1), -1) < 0 Then
			Dim onMin As Int = MapInt(stint.GetDefault("onMin", 0), 0)
			If offMin < onMin Then offMin = onMin
			stint.Put("offMin", offMin)
			Return
		End If
		i = i - 1
	Loop
End Sub

' Playing windows only. The half-time break is the gap between them.
Private Sub PlayWindows(match As Map, events As List) As List
	Dim windows As List
	windows.Initialize
	Dim startMs As Long = KickOffMillis(match)
	Dim htRaw As Long = FirstPeriodAfter(events, "HALF_TIME", 0)
	Dim shRaw As Long = 0
	If htRaw > 0 Then shRaw = FirstPeriodAfter(events, "SECOND_HALF", htRaw)
	If shRaw <= 0 Then shRaw = FirstPeriodAfter(events, "SECOND_HALF", 0)
	Dim htMs As Long = AlignToKickDay(startMs, htRaw)
	Dim shMs As Long = AlignToKickDay(startMs, shRaw)
	Dim endMs As Long = AlignToKickDay(startMs, LastPeriodAfter(events, "END", 0))
	If endMs <= 0 Then
		Dim status As String = match.GetDefault("status", "")
		If status = "LIVE" Then
			endMs = DateTime.Now
			' Still in the HT break — don't let the clock run through it.
			If htMs > 0 And shMs <= 0 And endMs > htMs Then endMs = htMs
		Else If shMs > 0 And htMs > startMs And startMs > 0 Then
			' Second half assumed the same length as the first when full time was not logged.
			endMs = shMs + (htMs - startMs)
		Else If startMs > 0 Then
			Dim planned As Int = PlannedMatchMinutes(match)
			endMs = startMs + planned * modPlatform.MinuteTicks
		End If
	End If

	If startMs > 0 And htMs > startMs Then
		windows.Add(WindowMap(startMs, htMs))
	End If
	If shMs > 0 And endMs > shMs Then
		windows.Add(WindowMap(shMs, endMs))
	End If
	' No half markers — one window from kick-off to full time.
	If windows.Size = 0 And startMs > 0 And endMs > startMs Then
		windows.Add(WindowMap(startMs, endMs))
	End If
	Return windows
End Sub

Private Sub PlannedMatchMinutes(match As Map) As Int
	Dim planned As Int = 60
	Dim planObj As Object = match.GetDefault("subPlan", Null)
	If planObj <> Null And planObj Is Map Then
		Dim plan As Map = planObj
		planned = plan.GetDefault("matchMinutes", 60)
	End If
	If planned < 1 Then planned = 60
	Return planned
End Sub

' The half-time break is the gap between two play windows. A sub in that gap
' takes the outgoing player off at the whistle and brings the next player on at the restart.
Private Sub BreakGapContaining(atMs As Long, windows As List) As Map
	Dim none As Map
	none.Initialize
	If windows.IsInitialized = False Or windows.Size < 2 Then Return none
	Dim i As Int
	For i = 0 To windows.Size - 2
		Dim w0 As Map = windows.Get(i)
		Dim w1 As Map = windows.Get(i + 1)
		Dim gapStart As Long = ToLong(w0.Get("endMs"))
		Dim gapEnd As Long = ToLong(w1.Get("startMs"))
		If gapEnd > gapStart And atMs >= gapStart And atMs <= gapEnd Then
			Dim hit As Map
			hit.Initialize
			hit.Put("offMs", gapStart)
			hit.Put("onMs", gapEnd)
			Return hit
		End If
	Next
	Return none
End Sub

Private Sub WindowMap(startMs As Long, endMs As Long) As Map
	Dim w As Map
	w.Initialize
	w.Put("startMs", startMs)
	w.Put("endMs", endMs)
	Return w
End Sub

' Local midnight of the calendar day that contains atMs.
Private Sub LocalMidnight(atMs As Long) As Long
	DateTime.DateFormat = "yyyy-MM-dd"
	Return DateTime.DateParse(DateTime.Date(atMs))
End Sub

' A whistle saved on the fixture date, about a day away from kick-off, is moved onto
' the kick-off evening while keeping its clock. A real gap under 18 hours is left as logged.
Private Sub AlignToKickDay(startMs As Long, atMs As Long) As Long
	If startMs <= 0 Or atMs <= 0 Then Return atMs
	Dim gap As Long = atMs - startMs
	If gap < 0 Then gap = -gap
	If gap < 18 * DateTime.TicksPerHour Then Return atMs
	DateTime.TimeFormat = "HH:mm"
	Dim clock As String = DateTime.Time(atMs)
	Dim colon As Int = clock.IndexOf(":")
	If colon < 1 Then Return atMs
	Dim hh As Int = clock.SubString2(0, colon)
	Dim mm As Int = clock.SubString(colon + 1)
	Dim placed As Long = LocalMidnight(startMs) + hh * DateTime.TicksPerHour + mm * modPlatform.MinuteTicks
	If placed + 12 * DateTime.TicksPerHour < startMs Then placed = placed + DateTime.TicksPerDay
	Return placed
End Sub

Private Sub FirstPeriodAfter(events As List, eventType As String, afterMs As Long) As Long
	Dim found As Long = 0
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> eventType Then Continue
		Dim ts As Long = ToLong(e.GetDefault("timestamp", 0))
		If ts <= 0 Then Continue
		If afterMs > 0 And ts <= afterMs Then Continue
		If found = 0 Or ts < found Then found = ts
	Next
	Return found
End Sub

Private Sub LastPeriodAfter(events As List, eventType As String, afterMs As Long) As Long
	Dim found As Long = 0
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> eventType Then Continue
		Dim ts As Long = ToLong(e.GetDefault("timestamp", 0))
		If ts <= 0 Then Continue
		If afterMs > 0 And ts <= afterMs Then Continue
		If ts > found Then found = ts
	Next
	Return found
End Sub

' Our-team substitutions, oldest first. Opponent subs are ignored.
Private Sub TeamASubEvents(match As Map, events As List) As List
	Dim subs As List
	subs.Initialize
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "SUB" Then Continue
		Dim d As Map = EventDetailsMap(e)
		If d.GetDefault("team", "A") = "B" Then Continue
		Dim pout As String = d.GetDefault("playerOut", "")
		Dim pin As String = d.GetDefault("playerIn", "")
		If pout = "" And pin = "" Then Continue
		Dim row As Map
		row.Initialize
		row.Put("atMs", EventAtMs(match, e, d))
		row.Put("minute", EventPlayingMinute(match, e, d))
		row.Put("playerOut", pout)
		row.Put("playerIn", pin)
		subs.Add(row)
	Next
	SortByAtMs(subs)
	Return subs
End Sub

Private Sub PlayTimeline(match As Map, events As List, subs As List) As List
	Dim timeline As List
	timeline.Initialize
	Dim i As Int
	For i = 0 To subs.Size - 1
		Dim s As Map = subs.Get(i)
		Dim row As Map
		row.Initialize
		row.Put("kind", "SUB")
		row.Put("atMs", s.Get("atMs"))
		row.Put("playerOut", s.GetDefault("playerOut", ""))
		row.Put("playerIn", s.GetDefault("playerIn", ""))
		timeline.Add(row)
	Next
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "RED_CARD" Then Continue
		Dim d As Map = EventDetailsMap(e)
		If d.GetDefault("team", "A") = "B" Then Continue
		Dim pid As String = d.GetDefault("player", "")
		If pid = "" Then pid = d.GetDefault("playerId", "")
		If pid = "" Then pid = d.GetDefault("scorer", "")
		If pid = "" Then Continue
		Dim red As Map
		red.Initialize
		red.Put("kind", "RED")
		red.Put("atMs", EventAtMs(match, e, d))
		red.Put("playerId", pid)
		timeline.Add(red)
	Next
	SortByAtMs(timeline)
	Return timeline
End Sub

Private Sub EventAtMs(match As Map, e As Map, details As Map) As Long
	Dim atMs As Long = ToLong(e.GetDefault("timestamp", 0))
	If atMs > 0 Then Return atMs
	Dim minute As Int = -1
	Try
		minute = details.GetDefault("minute", -1)
	Catch
		minute = -1
	End Try
	If minute >= 0 Then Return WallClockForMinute(match, minute)
	Return 0
End Sub

' Kick-off XI is the saved lineup, except anyone whose first sub is coming on.
' Those players did not start: minutes run from that sub until the full-time whistle.
' Someone missing from the lineup still started when their first sub is an off.
Private Sub StarterIds(match As Map, subs As List) As List
	Dim starters As List
	starters.Initialize
	Dim seen As Map
	seen.Initialize
	Dim firstAction As Map
	firstAction.Initialize
	Dim i As Int
	For i = 0 To subs.Size - 1
		Dim subEv As Map = subs.Get(i)
		Dim pout As String = subEv.GetDefault("playerOut", "")
		Dim pin As String = subEv.GetDefault("playerIn", "")
		If pout <> "" And firstAction.ContainsKey(pout) = False Then firstAction.Put(pout, "off")
		If pin <> "" And firstAction.ContainsKey(pin) = False Then firstAction.Put(pin, "on")
	Next
	Dim slots As Map = CopyLineup(match)
	For Each slotId As String In slots.Keys
		If FormationSlotAllowed(match, slotId) Then
			Dim pid As String = "" & slots.Get(slotId)
			If pid <> "" And pid <> "null" And seen.ContainsKey(pid) = False Then
				If firstAction.GetDefault(pid, "") <> "on" Then
					seen.Put(pid, True)
					starters.Add(pid)
				End If
			End If
		End If
	Next
	' Anyone already stored on a lineup slot was considered above. Stale slots stay off the clock.
	Dim rawIds As Map
	rawIds.Initialize
	Dim raw As Map = CopyLineup(match)
	For Each rawPid As Object In raw.Values
		Dim rawText As String = "" & rawPid
		If rawText <> "" And rawText <> "null" Then rawIds.Put(rawText, True)
	Next
	For Each oid As String In firstAction.Keys
		If seen.ContainsKey(oid) = False And rawIds.ContainsKey(oid) = False Then
			Dim action As String = firstAction.Get(oid)
			If action = "off" Then
				seen.Put(oid, True)
				starters.Add(oid)
			End If
		End If
	Next
	Return starters
End Sub

' Current XI: kick-off slots in this formation, then each local SUB and POSITION in time order.
' Includes events that have not reached Supabase yet.
Public Sub LineupAfterSubs(match As Map) As Map
	Dim filtered As Map
	filtered.Initialize
	If match.IsInitialized = False Then Return filtered
	Dim slots As Map = CopyLineup(match)
	For Each slotId As String In slots.Keys
		If FormationSlotAllowed(match, slotId) = False Then Continue
		filtered.Put(slotId, "" & slots.Get(slotId))
	Next
	Dim changes As List
	changes.Initialize
	Dim events As List = EventsForMatch(match.GetDefault("id", ""))
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		Dim etype As String = e.GetDefault("type", "")
		If etype <> "SUB" And etype <> "POSITION" Then Continue
		Dim d As Map = EventDetailsMap(e)
		If d.GetDefault("team", "A") = "B" Then Continue
		Dim row As Map
		row.Initialize
		row.Put("atMs", ToLong(e.GetDefault("timestamp", 0)))
		row.Put("kind", etype)
		If etype = "SUB" Then
			row.Put("playerOut", d.GetDefault("playerOut", ""))
			row.Put("playerIn", d.GetDefault("playerIn", ""))
		Else
			row.Put("slotA", "" & d.GetDefault("slotA", ""))
			row.Put("slotB", "" & d.GetDefault("slotB", ""))
		End If
		changes.Add(row)
	Next
	SortByAtMs(changes)
	For i = 0 To changes.Size - 1
		Dim change As Map = changes.Get(i)
		If change.GetDefault("kind", "") = "POSITION" Then
			modSubPlanner.ExchangeSlots(filtered, change.GetDefault("slotA", ""), change.GetDefault("slotB", ""))
			Continue
		End If
		Dim pout As String = change.GetDefault("playerOut", "")
		Dim pin As String = change.GetDefault("playerIn", "")
		If pout = "" Or pin = "" Then Continue
		Dim foundSlot As String = ""
		For Each slotKey As String In filtered.Keys
			If ("" & filtered.Get(slotKey)) = pout Then
				foundSlot = slotKey
				Exit
			End If
		Next
		If foundSlot <> "" Then filtered.Put(foundSlot, pin)
	Next
	Return filtered
End Sub

' Empty formation keeps every lineup key. A set formation ignores leftover slots from an older shape.
Private Sub FormationSlotAllowed(match As Map, slotId As String) As Boolean
	Dim formName As String = match.GetDefault("formation", "")
	If formName = "" Then Return True
	Dim positions As List = modFormations.GetPositions(formName)
	Dim i As Int
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		If p.GetDefault("id", "") = slotId Then Return True
	Next
	Return False
End Sub

Private Sub CopyLineup(match As Map) As Map
	Dim lineup As Map
	lineup.Initialize
	Dim obj As Object = match.GetDefault("lineup", Null)
	If obj = Null Or (obj Is Map) = False Then obj = match.GetDefault("tacticalLineup", Null)
	If obj <> Null And obj Is Map Then
		Dim src As Map = obj
		For Each key As Object In src.Keys
			lineup.Put(key, src.Get(key))
		Next
	End If
	Return lineup
End Sub

Private Sub OpenStintAt(stints As Map, playerId As String, onMs As Long)
	If playerId = "" Or onMs <= 0 Then Return
	Dim list As List = StintList(stints, playerId)
	Dim i As Int
	For i = 0 To list.Size - 1
		Dim stint As Map = list.Get(i)
		If ToLong(stint.GetDefault("offMs", 0)) <= 0 Then Return
	Next
	Dim s As Map
	s.Initialize
	s.Put("onMs", onMs)
	s.Put("offMs", 0)
	list.Add(s)
End Sub

Private Sub CloseStintAt(stints As Map, playerId As String, offMs As Long)
	If playerId = "" Or stints.ContainsKey(playerId) = False Then Return
	Dim list As List = stints.Get(playerId)
	Dim i As Int = list.Size - 1
	Do While i >= 0
		Dim stint As Map = list.Get(i)
		If ToLong(stint.GetDefault("offMs", 0)) <= 0 Then
			Dim onMs As Long = ToLong(stint.Get("onMs"))
			If offMs < onMs Then offMs = onMs
			stint.Put("offMs", offMs)
			Return
		End If
		i = i - 1
	Loop
End Sub

Private Sub StintList(stints As Map, playerId As String) As List
	If stints.ContainsKey(playerId) Then Return stints.Get(playerId)
	Dim list As List
	list.Initialize
	stints.Put(playerId, list)
	Return list
End Sub

Private Sub OverlapMs(a0 As Long, a1 As Long, b0 As Long, b1 As Long) As Long
	Dim s As Long = a0
	If b0 > s Then s = b0
	Dim e As Long = a1
	If b1 < e Then e = b1
	If e <= s Then Return 0
	Return e - s
End Sub

Private Sub SortByAtMs(items As List)
	Dim a As Int, b As Int
	For a = 0 To items.Size - 2
		For b = a + 1 To items.Size - 1
			Dim ra As Map = items.Get(a)
			Dim rb As Map = items.Get(b)
			If EarlierMoment(rb, ra) Then
				items.Set(a, rb)
				items.Set(b, ra)
			End If
		Next
	Next
End Sub

' True when a is earlier in the match than b.
' The minute and clock written on the event come first. The stored timestamp is only a tie-break.
Private Sub EarlierMoment(a As Map, b As Map) As Boolean
	Dim ma As Int = RowMinute(a)
	Dim mb As Int = RowMinute(b)
	If ma >= 0 And mb >= 0 And ma <> mb Then Return ma < mb
	Dim ca As Int = ShownClockMinute(a)
	Dim cb As Int = ShownClockMinute(b)
	If ca >= 0 And cb >= 0 And ca <> cb Then Return ca < cb
	Dim ta As Long = RowMillis(a)
	Dim tb As Long = RowMillis(b)
	Return ta < tb
End Sub

Private Sub RowMinute(ev As Map) As Int
	If ev.ContainsKey("minute") Then
		Dim direct As Int = MapInt(ev.Get("minute"), -1)
		If direct >= 0 Then Return direct
	End If
	Dim d As Map = EventDetailsMap(ev)
	If d.ContainsKey("minute") Then Return MapInt(d.Get("minute"), -1)
	Return -1
End Sub

Private Sub ShownClockMinute(ev As Map) As Int
	Dim d As Map = EventDetailsMap(ev)
	Dim clock As String = "" & d.GetDefault("clockTime", "")
	clock = clock.Trim
	Dim colon As Int = clock.IndexOf(":")
	If colon < 1 Then Return -1
	Try
		Dim hh As Int = clock.SubString2(0, colon)
		Dim mm As Int = clock.SubString(colon + 1)
		If hh < 0 Or hh > 23 Or mm < 0 Or mm > 59 Then Return -1
		Return hh * 60 + mm
	Catch
		Return -1
	End Try
End Sub

Private Sub RowMillis(ev As Map) As Long
	If ev.ContainsKey("atMs") Then
		Dim at As Long = ToLong(ev.Get("atMs"))
		If at > 0 Then Return at
	End If
	Return ToLong(ev.GetDefault("timestamp", 0))
End Sub

Private Sub ToLong(v As Object) As Long
	If v = Null Then Return 0
	Try
		' A JSON number arrives as a Double. Casting that straight to Long throws.
		If v Is Double Then
			Dim d As Double = v
			If d <= 0 Then Return 0
			Return modPlatform.NormalizeTicks(d)
		End If
		Dim n As Long = v
		If n <> 0 Then Return modPlatform.NormalizeTicks(n)
	Catch
		Log(LastException.Message)
	End Try
	Try
		Dim s As String = "" & v
		s = s.Trim
		If s = "" Or s = "0" Then Return 0
		If s.Contains("T") Then
			Dim ms As Long = modPlatform.ParseIsoMillis(s)
			If ms < 0 Then Return 0
			Return ms
		End If
		Return modPlatform.NormalizeTicks(s)
	Catch
		Return 0
	End Try
End Sub
