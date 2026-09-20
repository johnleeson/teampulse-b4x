B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Live match feed: score, period events, goals, subs, cards — editable event cards.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private lblScore As Label
	Private lblStatus As Label
	Private lblClock As Label
	Private clv As CustomListView
	Private match As Map
	Private club As Map
	Private pollTimer As Timer
	Private pageVisible As Boolean
	Private memberNames As List
	Private memberIds As List
	Private dialog As B4XDialog
End Sub

Public Sub Initialize
	pageVisible = False
	memberNames.Initialize
	memberIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFF0F172A
	dialog.Initialize(Root)
	StyleDarkDialog
	BuildUI
	pollTimer.Initialize("pollTimer", 10000)
	pollTimer.Enabled = False
End Sub

Private Sub B4XPage_Appear
	pageVisible = True
	pollTimer.Enabled = True
	Load
	Refresh
End Sub

Private Sub B4XPage_Disappear
	pageVisible = False
	pollTimer.Enabled = False
End Sub

Private Sub pollTimer_Tick
	If pageVisible = False Then Return
	modDb.FetchInitialData
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	Refresh
End Sub

Private Sub BuildUI
	lblStatus.Initialize("")
	lblStatus.TextColor = 0xFF94A3B8
	lblStatus.Gravity = Gravity.CENTER
	Root.AddView(lblStatus, 0, 8dip, Root.Width, 22dip)
	
	lblScore.Initialize("")
	lblScore.TextColor = Colors.White
	lblScore.TextSize = 36
	lblScore.Typeface = Typeface.DEFAULT_BOLD
	lblScore.Gravity = Gravity.CENTER
	Root.AddView(lblScore, 0, 32dip, Root.Width, 52dip)
	
	lblClock.Initialize("")
	lblClock.TextColor = modConfig.COLOR_ACCENT
	lblClock.TextSize = 14
	lblClock.Typeface = Typeface.DEFAULT_BOLD
	lblClock.Gravity = Gravity.CENTER
	Root.AddView(lblClock, 0, 84dip, Root.Width, 22dip)
	
	Dim row As Int = 116dip
	AddAction("GOAL", "btnGoal", 8dip, row, modConfig.COLOR_SUCCESS)
	AddAction("SUB", "btnSub", Root.Width / 4 + 4dip, row, modConfig.COLOR_ACCENT)
	AddAction("YC", "btnYC", Root.Width / 2 + 4dip, row, 0xFFF59E0B)
	AddAction("RC", "btnRC", Root.Width * 3 / 4 + 4dip, row, modConfig.COLOR_DANGER)
	
	row = 168dip
	AddAction("HT", "btnHT", 8dip, row, 0xFFFB923C)
	AddAction("2H", "btn2H", Root.Width / 4 + 4dip, row, 0xFF38BDF8)
	AddAction("END", "btnEnd", Root.Width / 2 + 4dip, row, 0xFF64748B)
	AddAction("RESET", "btnReset", Root.Width * 3 / 4 + 4dip, row, 0xFF334155)
	
	row = 220dip
	AddAction("NOTE", "btnComment", 8dip, row, 0xFF6366F1)
	AddAction("Back", "btnBack", Root.Width / 4 + 4dip, row, 0xFF475569)
	
	clv = modUI.AddCustomListViewThemed(Root, 0, 276dip, Root.Width, Root.Height - 284dip, Me, "clv", True)
End Sub

Private Sub AddAction(text As String, event As String, left As Int, top As Int, col As Int)
	Dim b As Button
	b.Initialize(event)
	b.Text = text
	b.TextSize = 11
	b.Color = col
	b.TextColor = Colors.White
	Root.AddView(b, left, top, Root.Width / 4 - 12dip, 44dip)
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", ""))
	BuildMemberLists
End Sub

Private Sub BuildMemberLists
	memberNames.Initialize
	memberIds.Initialize
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		memberNames.Add(mem.GetDefault("name", "?"))
		memberIds.Add(mem.GetDefault("id", ""))
	Next
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Public Sub Refresh
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	lblStatus.Text = match.GetDefault("status", "") & " - " & match.GetDefault("title", "")
	lblScore.Text = match.GetDefault("scoreA", 0) & "  -  " & match.GetDefault("scoreB", 0)
	Dim nowMs As Long = DateTime.Now
	lblClock.Text = modAppState.FormatHHMM(nowMs) & "   ·   " & modAppState.PlayingMinuteAt(match, nowMs) & "'"
	modUI.ApplyDarkListBackground(clv, 0xFF0F172A)
	clv.Clear
	Dim events As List = modAppState.EventsNewestFirst(match.Get("id"))
	Dim names As Map = NameByIdMap
	Dim cardW As Int = Root.Width - 16dip
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		Dim isFirst As Boolean = (i = 0)
		Dim isLast As Boolean = (i = events.Size - 1)
		Dim card As Panel = BuildTimelineRow(cardW, e, names, isFirst, isLast)
		Dim h As Int = modUI.TimelineItemHeight(e)
		card.SetLayout(0, 0, cardW, h)
		clv.Add(card, e.GetDefault("id", ""))
	Next
	If events.Size = 0 Then
		Dim empty As Panel
		empty.Initialize("")
		empty.Color = 0xFF0F172A
		Dim lbl As Label
		lbl.Initialize("")
		lbl.Text = "No events yet — tap GOAL to start the timeline."
		lbl.TextSize = 13
		lbl.TextColor = 0xFF64748B
		lbl.Gravity = Gravity.CENTER
		empty.AddView(lbl, 16dip, 0, cardW - 32dip, 48dip)
		empty.SetLayout(0, 0, cardW, 48dip)
		clv.Add(empty, "")
	End If
	modUI.ApplyDarkListBackground(clv, 0xFF0F172A)
End Sub

Private Sub NameByIdMap As Map
	Dim m As Map
	m.Initialize
	Dim i As Int
	For i = 0 To memberIds.Size - 1
		m.Put(memberIds.Get(i), memberNames.Get(i))
	Next
	Return m
End Sub

Private Sub BuildTimelineRow(Width As Int, ev As Map, names As Map, isFirst As Boolean, isLast As Boolean) As Panel
	Dim row As Panel = modUI.CreateTimelineItem(Width, ev, names, isFirst, isLast)
	Dim eid As String = ev.GetDefault("id", "")
	Dim h As Int = modUI.TimelineItemHeight(ev)
	Dim btnSize As Int = 34dip
	Dim top As Int = (h - btnSize) / 2
	Dim btnEdit As Button = modUI.CreateIconButton("btnEvEdit", "✎", 0xFF334155, eid)
	row.AddView(btnEdit, Width - 80dip, top, btnSize, btnSize)
	Dim btnDel As Button = modUI.CreateIconButton("btnEvDel", "✕", 0xFF7F1D1D, eid)
	row.AddView(btnDel, Width - 40dip, top, btnSize, btnSize)
	Return row
End Sub

Private Sub btnEvEdit_Click
	Dim b As Button = Sender
	Dim eid As String = b.Tag
	If eid = "" Then Return
	modAppState.SelectedEventId = eid
	B4XPages.ShowPage("EventEdit")
End Sub

Private Sub btnEvDel_Click
	Dim b As Button = Sender
	Dim eid As String = b.Tag
	If eid = "" Then Return
	Dim ev As Map = modAppState.FindEvent(eid)
	If ev.IsInitialized = False Or ev.ContainsKey("id") = False Then Return
	StyleDarkDialog
	Wait For (dialog.Show("Delete this event from the timeline?", "Delete", "Cancel", "")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	modDb.DeleteEvent(eid)
	modAppState.RemoveEvent(eid)
	RecomputeScoresAndStats
	Refresh
	ToastMessageShow("Event deleted", False)
End Sub

Private Sub StyleDarkDialog
	dialog.BackgroundColor = 0xFF1E293B
	dialog.BorderColor = 0xFF334155
	dialog.BorderWidth = 1dip
	dialog.BorderCornersRadius = 18dip
	dialog.OverlayColor = 0xCC020617
	dialog.TitleBarColor = 0xFF0F172A
	dialog.BodyTextColor = 0xFFE2E8F0
	dialog.ButtonsColor = 0xFF334155
	dialog.ButtonsTextColor = Colors.White
	Try
		dialog.TitleBarHeight = 52dip
		dialog.ButtonsHeight = 48dip
		dialog.TitleBarFont = xui.CreateDefaultBoldFont(18)
		dialog.ButtonsFont = xui.CreateDefaultBoldFont(15)
	Catch
		Log("StyleDarkDialog: " & LastException.Message)
	End Try
End Sub

Private Sub StampTimeDetails(details As Map)
	Dim nowMs As Long = DateTime.Now
	details.Put("clockTime", modAppState.FormatHHMM(nowMs))
	details.Put("minute", modAppState.PlayingMinuteAt(match, nowMs))
End Sub

Private Sub AddEvent(etype As String, content As String, details As Map)
	If details.ContainsKey("minute") = False Or details.ContainsKey("clockTime") = False Then
		StampTimeDetails(details)
	End If
	Dim ev As Map
	ev.Initialize
	ev.Put("id", modAppState.NewId)
	ev.Put("matchId", match.Get("id"))
	ev.Put("userId", modAppState.CurrentUser.GetDefault("id", ""))
	ev.Put("userName", modAppState.CurrentUser.GetDefault("name", ""))
	ev.Put("type", etype)
	ev.Put("content", content)
	ev.Put("timestamp", DateTime.Now)
	ev.Put("details", details)
	modDb.SaveEvent(ev)
	modAppState.UpsertEvent(ev)
	Refresh
End Sub

' Returns selected index, or -1 if cancelled.
Private Sub PickFromList(title As String, items As List) As ResumableSub
	If items.IsInitialized = False Or items.Size = 0 Then Return -1
	StyleDarkDialog
	Dim template As B4XListTemplate
	template.Initialize
	' Colours must be set before Options so text items pick them up.
	Try
		template.CustomListView1.DefaultTextColor = Colors.White
		template.CustomListView1.DefaultTextBackgroundColor = 0xFF1E293B
		template.CustomListView1.PressedColor = 0xFF3B82F6
	Catch
		Log("ListTemplate colors: " & LastException.Message)
	End Try
	template.Options = items
	template.AllowMultiSelection = False
	Try
		Dim listH As Int = Min(Root.Height * 0.55, 72dip + items.Size * 52dip)
		template.Resize(Root.Width - 48dip, Max(180dip, listH))
	Catch
		Log("ListTemplate resize: " & LastException.Message)
	End Try
	Try
		modUI.ApplyDarkListBackground(template.CustomListView1, 0xFF1E293B)
	Catch
		Log("ListTemplate dark bg: " & LastException.Message)
	End Try
	dialog.Title = title
	Wait For (dialog.ShowTemplate(template, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return -1
	Dim selected As String = template.SelectedItem
	If selected = "" Then Return -1
	Dim i As Int
	For i = 0 To items.Size - 1
		If items.Get(i) = selected Then Return i
	Next
	Return -1
End Sub

Private Sub btnGoal_Click
	Dim teamOpts As List
	teamOpts.Initialize
	teamOpts.Add("Our team")
	teamOpts.Add("Opponent")
	Wait For (PickFromList("Who scored?", teamOpts)) Complete (teamIdx As Int)
	If teamIdx < 0 Then Return
	
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	Dim content As String
	
	If teamIdx = 0 Then
		details.Put("team", "A")
		If memberNames.Size = 0 Then
			ToastMessageShow("No players in club", False)
			Return
		End If
		Wait For (PickFromList("Who scored?", memberNames)) Complete (scorerIdx As Int)
		If scorerIdx < 0 Then Return
		Dim scorerId As String = memberIds.Get(scorerIdx)
		Dim scorerName As String = memberNames.Get(scorerIdx)
		details.Put("scorer", scorerId)
		
		Dim assistOpts As List
		assistOpts.Initialize
		assistOpts.Add("(no assist)")
		Dim ai As Int
		For ai = 0 To memberNames.Size - 1
			assistOpts.Add(memberNames.Get(ai))
		Next
		Wait For (PickFromList("Who assisted?", assistOpts)) Complete (assistIdx As Int)
		If assistIdx < 0 Then Return
		Dim assistId As String = ""
		If assistIdx > 0 Then
			assistId = memberIds.Get(assistIdx - 1)
			If assistId = scorerId Then
				ToastMessageShow("Assist can't be the scorer", False)
				assistId = ""
			End If
		End If
		details.Put("assist", assistId)
		content = "GOAL! " & scorerName
	Else
		details.Put("team", "B")
		details.Put("scorer", "")
		details.Put("assist", "")
		content = "GOAL! Opponent"
	End If
	
	AddEvent("GOAL", content, details)
	RecomputeScoresAndStats
	Refresh
End Sub

Private Sub btnSub_Click
	If memberNames.Size < 2 Then
		ToastMessageShow("Need at least 2 players", False)
		Return
	End If
	Wait For (PickFromList("Player off", memberNames)) Complete (outIdx As Int)
	If outIdx < 0 Then Return
	Wait For (PickFromList("Player on", memberNames)) Complete (inIdx As Int)
	If inIdx < 0 Then Return
	If outIdx = inIdx Then
		ToastMessageShow("Pick different players", False)
		Return
	End If
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("playerOut", memberIds.Get(outIdx))
	details.Put("playerIn", memberIds.Get(inIdx))
	StampTimeDetails(details)
	AddEvent("SUB", memberNames.Get(outIdx) & " → " & memberNames.Get(inIdx), details)
End Sub

Private Sub btnYC_Click
	If memberNames.Size = 0 Then
		ToastMessageShow("No players", False)
		Return
	End If
	Wait For (PickFromList("Yellow card for", memberNames)) Complete (idx As Int)
	If idx < 0 Then Return
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("player", memberIds.Get(idx))
	StampTimeDetails(details)
	AddEvent("YELLOW_CARD", memberNames.Get(idx), details)
	RecomputeScoresAndStats
	Refresh
End Sub

Private Sub btnRC_Click
	If memberNames.Size = 0 Then
		ToastMessageShow("No players", False)
		Return
	End If
	Wait For (PickFromList("Red card for", memberNames)) Complete (idx As Int)
	If idx < 0 Then Return
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("player", memberIds.Get(idx))
	StampTimeDetails(details)
	AddEvent("RED_CARD", memberNames.Get(idx), details)
	RecomputeScoresAndStats
	Refresh
End Sub

Private Sub btnHT_Click
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	AddEvent("HALF_TIME", "Half Time", details)
End Sub

Private Sub btn2H_Click
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	AddEvent("SECOND_HALF", "Second half underway", details)
End Sub

Private Sub btnEnd_Click
	match.Put("status", "COMPLETED")
	ApplyProjectedMinutesToStats
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	AddEvent("END", "Full Time " & match.GetDefault("scoreA", 0) & "-" & match.GetDefault("scoreB", 0), details)
	ToastMessageShow("Match completed — add post-match summary", False)
	B4XPages.ShowPage("MatchSummary")
End Sub

Private Sub btnComment_Click
	StyleDarkDialog
	Dim input As B4XInputTemplate
	input.Initialize
	input.Text = ""
	dialog.Title = "General commentary"
	Wait For (dialog.ShowTemplate(input, "Save", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim note As String = input.Text.Trim
	If note = "" Then
		ToastMessageShow("Enter some commentary", False)
		Return
	End If
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	AddEvent("COMMENT", note, details)
End Sub
Private Sub ApplyProjectedMinutesToStats
	Dim calculated As Map = modAppState.CalculateMatchMinutes(match)
	If calculated.Size = 0 Then
		' Fall back to sub-plan projection when feed has no usable periods
		Dim lineup As Map = match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMap2))
		Dim plan As Map = match.GetDefault("subPlan", modSubPlanner.EmptyPlan(60))
		If lineup.IsInitialized = False Or lineup.Size = 0 Then Return
		Dim squadIds As List
		squadIds.Initialize
		Dim i As Int
		For i = 0 To memberIds.Size - 1
			squadIds.Add(memberIds.Get(i))
		Next
		calculated = modSubPlanner.ProjectMatchMinutes(lineup, plan, squadIds)
	End If
	Dim stats As Map = match.GetDefault("playerStats", EmptyMap2)
	If stats.IsInitialized = False Then stats.Initialize
	For Each pid As String In calculated.Keys
		Dim ps As Map
		If stats.ContainsKey(pid) Then
			ps = stats.Get(pid)
		Else
			ps.Initialize
			ps.Put("goals", 0)
			ps.Put("assists", 0)
			ps.Put("yellowCards", 0)
			ps.Put("redCards", 0)
		End If
		ps.Put("minutesPlayed", calculated.Get(pid))
		stats.Put(pid, ps)
	Next
	match.Put("playerStats", stats)
End Sub

Private Sub btnReset_Click
	If match.GetDefault("status", "") <> "LIVE" Then
		ToastMessageShow("Only live matches can be reset", False)
		Return
	End If
	match.Put("status", "UPCOMING")
	match.Put("scoreA", 0)
	match.Put("scoreB", 0)
	match.Put("liveStartedAt", 0)
	Dim emptyStats As Map
	emptyStats.Initialize
	match.Put("playerStats", emptyStats)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	AddEvent("COMMENT", "Match reset to upcoming (kick-off undone)", details)
	ToastMessageShow("Match reset to upcoming", False)
	B4XPages.ShowPage("MatchHub")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("MatchHub")
End Sub

Public Sub RecomputeScoresAndStats
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	Dim scoreA As Int = 0
	Dim scoreB As Int = 0
	Dim stats As Map
	stats.Initialize
	Dim events As List = modAppState.EventsForMatch(match.Get("id"))
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		Dim etype As String = e.GetDefault("type", "")
		Dim details As Map
		Dim dObj As Object = e.GetDefault("details", Null)
		If dObj <> Null And dObj Is Map Then
			details = dObj
		Else
			details.Initialize
		End If
		If etype = "GOAL" Then
			Dim team As String = details.GetDefault("team", "A")
			If team = "B" Then
				scoreB = scoreB + 1
			Else
				scoreA = scoreA + 1
				BumpStatMap(stats, details.GetDefault("scorer", ""), "goals", 1)
				BumpStatMap(stats, details.GetDefault("assist", ""), "assists", 1)
			End If
		Else If etype = "YELLOW_CARD" Then
			BumpStatMap(stats, details.GetDefault("player", ""), "yellowCards", 1)
		Else If etype = "RED_CARD" Then
			BumpStatMap(stats, details.GetDefault("player", ""), "redCards", 1)
		End If
	Next
	Dim oldStats As Map = match.GetDefault("playerStats", EmptyMap2)
	If oldStats.IsInitialized Then
		For Each pid As String In oldStats.Keys
			Dim oldPs As Map = oldStats.Get(pid)
			Dim mins As Int = oldPs.GetDefault("minutesPlayed", 0)
			If mins > 0 Then
				Dim ps As Map
				If stats.ContainsKey(pid) Then
					ps = stats.Get(pid)
				Else
					ps.Initialize
					ps.Put("goals", 0)
					ps.Put("assists", 0)
					ps.Put("yellowCards", 0)
					ps.Put("redCards", 0)
				End If
				ps.Put("minutesPlayed", mins)
				stats.Put(pid, ps)
			End If
		Next
	End If
	match.Put("scoreA", scoreA)
	match.Put("scoreB", scoreB)
	match.Put("playerStats", stats)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
End Sub

Private Sub BumpStatMap(stats As Map, playerId As String, field As String, delta As Int)
	If playerId = "" Then Return
	Dim ps As Map
	If stats.ContainsKey(playerId) Then
		ps = stats.Get(playerId)
	Else
		ps.Initialize
		ps.Put("goals", 0)
		ps.Put("assists", 0)
		ps.Put("yellowCards", 0)
		ps.Put("redCards", 0)
		ps.Put("minutesPlayed", 0)
	End If
	ps.Put(field, ps.GetDefault(field, 0) + delta)
	stats.Put(playerId, ps)
End Sub

Private Sub EmptyMap2 As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub
