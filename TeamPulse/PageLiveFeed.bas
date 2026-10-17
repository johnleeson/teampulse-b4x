B4A=true
B4i=true
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
	Private memberAvatars As Map
	Private dialog As B4XDialog
	Private shareHost As B4XView
	Private subSheet As Panel
	Private subPitch As Panel
	Private chipHost As Panel
	Private benchScroll As ScrollView
	Private benchHost As Panel
	Private subHint As Label
	Private subOffSlot As String
	Private subOffPlayer As String
	Private subSheetOpen As Boolean
	Private sheetMode As String
	Private sheetChips As List
	Private sheetIncludePlayers As Boolean
	Private pickExclude As String
	Private pickOpen As Boolean
	Private showPitch As Boolean
	Private sheetTitle As String
	Private holdSlot As String
	Private actionsLocked As Boolean
	Private sharingTimeline As Boolean
End Sub

Public Sub Initialize
	pageVisible = False
	memberNames.Initialize
	memberIds.Initialize
	memberAvatars.Initialize
	sheetChips.Initialize
	sheetMode = ""
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFF0F172A
	dialog.Initialize(Root)
	StyleDarkDialog
	BuildUI
	pollTimer.Initialize("pollTimer", 20000)
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
	CloseSubSheet
End Sub

Private Sub pollTimer_Tick
	If pageVisible = False Then Return
	CallSubDelayed(B4XPages.MainPage, "KickSyncAndPull")
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Me, Root, "Live", "btnBack", "btnShare", "↗", True)
	Dim top As Int = chrome.Get("ContentTop")
	lblStatus.Initialize("")
	lblStatus.TextColor = 0xFF94A3B8
	modUI.SetAlign(lblStatus, "CENTER", "CENTER")
	Root.AddView(lblStatus, 0, top, modUI.ViewWidth(Root), 22dip)
	
	lblScore.Initialize("")
	lblScore.TextColor = Colors.White
	modUI.SetTextSize(lblScore, 36)
	modUI.SetBold(lblScore, True)
	modUI.SetAlign(lblScore, "CENTER", "CENTER")
	Root.AddView(lblScore, 0, top + 24dip, modUI.ViewWidth(Root), 52dip)
	
	lblClock.Initialize("")
	lblClock.TextColor = modConfig.COLOR_ACCENT
	modUI.SetTextSize(lblClock, 14)
	modUI.SetBold(lblClock, True)
	modUI.SetAlign(lblClock, "CENTER", "CENTER")
	Root.AddView(lblClock, 0, top + 76dip, modUI.ViewWidth(Root), 22dip)
	
	Dim row As Int = top + 106dip
	AddAction("GOAL", "btnGoal", 8dip, row, modConfig.COLOR_SUCCESS)
	AddAction("SUB", "btnSub", modUI.ViewWidth(Root) / 4 + 4dip, row, modConfig.COLOR_ACCENT)
	AddAction("YC", "btnYC", modUI.ViewWidth(Root) / 2 + 4dip, row, 0xFFF59E0B)
	AddAction("RC", "btnRC", modUI.ViewWidth(Root) * 3 / 4 + 4dip, row, modConfig.COLOR_DANGER)
	
	row = top + 158dip
	AddAction("HT", "btnHT", 8dip, row, 0xFFFB923C)
	AddAction("2H", "btn2H", modUI.ViewWidth(Root) / 4 + 4dip, row, 0xFF38BDF8)
	AddAction("Full time", "btnEnd", modUI.ViewWidth(Root) / 2 + 4dip, row, 0xFF64748B)
	AddAction("RESET", "btnReset", modUI.ViewWidth(Root) * 3 / 4 + 4dip, row, 0xFF334155)
	
	row = top + 210dip
	AddAction("Corner" & CRLF & "(us)", "btnCornerUs", 8dip, row, 0xFF0F766E)
	AddAction("Corner" & CRLF & "(them)", "btnCornerThem", modUI.ViewWidth(Root) / 4 + 4dip, row, 0xFF115E59)
	AddAction("Penalty" & CRLF & "(us)", "btnPenUs", modUI.ViewWidth(Root) / 2 + 4dip, row, 0xFF7C3AED)
	AddAction("Penalty" & CRLF & "(them)", "btnPenThem", modUI.ViewWidth(Root) * 3 / 4 + 4dip, row, 0xFF5B21B6)
	
	row = top + 262dip
	AddAction("NOTE", "btnComment", 8dip, row, 0xFF6366F1)
	AddAction("PENS", "btnPens", modUI.ViewWidth(Root) / 4 + 4dip, row, 0xFF7C3AED)
	
	Dim listTop As Int = top + 314dip
	clv = modUI.AddCustomListViewThemed(Root, 0, listTop, modUI.ViewWidth(Root), modUI.ViewHeight(Root) - listTop - 8dip, Me, "clv", True)
End Sub

Private Sub AddAction(text As String, event As String, left As Int, top As Int, col As Int)
	Dim b As Button
	modUI.InitButton(Me, b, event)
	b.Text = text
	modUI.SetTextSize(b, 11)
	If text.Length > 10 Then
		modUI.SetTextSize(b, 9)
	Else If text.Length > 6 Then
		modUI.SetTextSize(b, 10)
	End If
	modUI.SetSingleLine(b, False)
	b.Color = col
	modUI.SetButtonTextColor(b, Colors.White)
	modUI.SetAlign(b, "CENTER", "CENTER")
#if B4A
	b.Padding = Array As Int(2dip, 0, 2dip, 0)
#End If
	Root.AddView(b, left, top, modUI.ViewWidth(Root) / 4 - 12dip, 44dip)
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", ""))
	BuildMemberLists
End Sub

Private Sub BuildMemberLists
	memberNames.Initialize
	memberIds.Initialize
	memberAvatars.Initialize
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		Dim mid As String = mem.GetDefault("id", "")
		memberNames.Add(mem.GetDefault("name", "?"))
		memberIds.Add(mid)
		memberAvatars.Put(mid, mem.GetDefault("avatar", ""))
	Next
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Public Sub Refresh
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then Return
	If modLocal.ApplyLiveScore(match) Then modLocal.QueueMatch(match)
	' Sync can finish before this page is opened. Score is already saved; skip the views.
	If lblStatus.IsInitialized = False Then Return
	lblStatus.Text = match.GetDefault("status", "") & "  ·  " & modLocal.SyncWord(match.Get("id"))
	lblScore.Text = match.GetDefault("scoreA", 0) & "  -  " & match.GetDefault("scoreB", 0)
	Dim nowMs As Long = DateTime.Now
	Dim pensLine As String = modLocal.PensStatusLine(match.Get("id"))
	If pensLine <> "" Then
		lblClock.Text = pensLine
	Else
		lblClock.Text = modAppState.FormatHHMM(nowMs) & "   ·   " & modAppState.PlayingMinuteAt(match, nowMs) & "'"
	End If
	modLocal.SyncShootoutFlags(match.Get("id"))
	modUI.ApplyDarkListBackground(clv, 0xFF0F172A)
	clv.Clear
	Dim events As List = modAppState.EventsNewestFirst(match.Get("id"))
	Dim names As Map = NameByIdMap
	Dim sides As Map = SideNames
	Dim planned As List = OpenPlannedSwaps
	Dim cardW As Int = modUI.ViewWidth(Root) - 16dip
	Dim i As Int
	For i = 0 To planned.Size - 1
		Dim swap As Map = planned.Get(i)
		Dim plannedEv As Map = PlannedSubEvent(swap)
		Dim planFirst As Boolean = (i = 0)
		Dim planLast As Boolean = (i = planned.Size - 1 And events.Size = 0)
		Dim planCard As Panel = BuildPlannedRow(cardW, plannedEv, names, sides, planFirst, planLast)
		Dim planH As Int = modUI.TimelineItemHeight(plannedEv)
		modUI.PlaceView(planCard, 0, 0, cardW, planH)
		clv.Add(planCard, "plan:" & swap.GetDefault("index", i))
	Next
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		Dim isFirst As Boolean = (planned.Size = 0 And i = 0)
		Dim isLast As Boolean = (i = events.Size - 1)
		Dim card As Panel = BuildTimelineRow(cardW, e, names, sides, isFirst, isLast)
		Dim h As Int = modUI.TimelineItemHeight(e)
		modUI.PlaceView(card, 0, 0, cardW, h)
		clv.Add(card, e.GetDefault("id", ""))
	Next
	If planned.Size = 0 And events.Size = 0 Then
		Dim empty As Panel
		empty.Initialize("")
		empty.Color = 0xFF0F172A
		Dim lbl As Label
		lbl.Initialize("")
		lbl.Text = "No events yet — tap GOAL to start the timeline."
		modUI.SetTextSize(lbl, 13)
		lbl.TextColor = 0xFF64748B
		modUI.SetAlign(lbl, "CENTER", "CENTER")
		empty.AddView(lbl, 16dip, 0, cardW - 32dip, 48dip)
		modUI.PlaceView(empty, 0, 0, cardW, 48dip)
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

Private Sub SideNames As Map
	Dim m As Map
	m.Initialize
	Dim ours As String = ""
	Dim clubId As String = ""
	If match.IsInitialized Then clubId = match.GetDefault("clubId", "")
	Dim c As Map = modAppState.FindClub(clubId)
	If c.IsInitialized Then ours = ("" & c.GetDefault("name", "")).Trim
	If ours = "" Or ours = "null" Then ours = "Our team"
	Dim opp As String = ""
	If match.IsInitialized Then opp = ("" & match.GetDefault("opponentName", "")).Trim
	If opp = "" Or opp = "null" Then opp = "Opposition"
	m.Put("A", ours)
	m.Put("B", opp)
	Return m
End Sub

Private Sub OpenPlannedSwaps As List
	Dim none As List
	none.Initialize
	If match.IsInitialized = False Then Return none
	If match.GetDefault("status", "") <> "LIVE" Then Return none
	Dim planObj As Object = match.GetDefault("subPlan", Null)
	If planObj = Null Or Not(planObj Is Map) Then Return none
	Dim plan As Map = planObj
	Dim playing As Int = modAppState.PlayingMinuteAt(match, DateTime.Now)
	Dim open As List = modSubPlanner.NextOpenSwaps(plan, LoggedTeamSubs, modAppState.LineupAfterSubs(match))
	Dim i As Int
	For i = 0 To open.Size - 1
		Dim row As Map = open.Get(i)
		Dim target As Int = row.GetDefault("minute", 0)
		row.Put("due", playing >= target)
	Next
	Return open
End Sub

Private Sub LoggedTeamSubs As List
	Dim out As List
	out.Initialize
	Dim events As List = modAppState.EventsForMatch(match.GetDefault("id", ""))
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("type", "") <> "SUB" Then Continue
		Dim details As Map
		Dim dObj As Object = e.GetDefault("details", Null)
		If dObj <> Null And dObj Is Map Then
			details = dObj
		Else
			Continue
		End If
		If details.GetDefault("team", "A") = "B" Then Continue
		Dim row As Map
		row.Initialize
		row.Put("playerOut", "" & details.GetDefault("playerOut", ""))
		row.Put("playerIn", "" & details.GetDefault("playerIn", ""))
		out.Add(row)
	Next
	Return out
End Sub

Private Sub PlannedSubEvent(swap As Map) As Map
	Dim outName As String = swap.GetDefault("outName", "")
	Dim inName As String = swap.GetDefault("inName", "")
	If outName = "" Then outName = NameForId(swap.GetDefault("playerOut", ""))
	If inName = "" Then inName = NameForId(swap.GetDefault("playerIn", ""))
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("playerOut", swap.GetDefault("playerOut", ""))
	details.Put("playerIn", swap.GetDefault("playerIn", ""))
	details.Put("minute", swap.GetDefault("minute", 0))
	details.Put("clockTime", "Q" & (swap.GetDefault("afterQuarter", 0) + 1))
	details.Put("due", swap.GetDefault("due", False))
	details.Put("swapIndex", swap.GetDefault("index", 0))
	Dim ev As Map
	ev.Initialize
	ev.Put("type", "PLANNED_SUB")
	ev.Put("content", outName & " → " & inName)
	ev.Put("details", details)
	Return ev
End Sub

Private Sub BuildPlannedRow(Width As Int, ev As Map, names As Map, sides As Map, isFirst As Boolean, isLast As Boolean) As Panel
	Dim row As Panel = modUI.CreateTimelineItem(Width, ev, names, sides, isFirst, isLast)
	Dim details As Map = ev.Get("details")
	Dim idx As Int = details.GetDefault("swapIndex", 0)
	Dim h As Int = modUI.TimelineItemHeight(ev)
	Dim btnW As Int = 72dip
	Dim btnH As Int = 28dip
	Dim left As Int = Width - btnW - 10dip
	Dim btnConfirm As Button
	modUI.InitButton(Me, btnConfirm, "btnPlanConfirm")
	btnConfirm.Text = "Confirm"
	modUI.SetTextSize(btnConfirm, 11)
	modUI.SetBold(btnConfirm, True)
	btnConfirm.Color = modConfig.COLOR_SUCCESS
	modUI.SetButtonTextColor(btnConfirm, Colors.White)
	btnConfirm.Tag = idx
	row.AddView(btnConfirm, left, 16dip, btnW, btnH)
	Dim btnSkip As Button
	modUI.InitButton(Me, btnSkip, "btnPlanSkip")
	btnSkip.Text = "Skip"
	modUI.SetTextSize(btnSkip, 11)
	modUI.SetBold(btnSkip, True)
	btnSkip.Color = 0xFF334155
	modUI.SetButtonTextColor(btnSkip, Colors.White)
	btnSkip.Tag = idx
	row.AddView(btnSkip, left, h - btnH - 16dip, btnW, btnH)
	Return row
End Sub

Private Sub btnPlanConfirm_Click
	If actionsLocked Then Return
	Dim b As Button = modUI.ClickedButton(Sender)
	Dim swap As Map = SwapAtIndex(b.Tag)
	If swap.ContainsKey("playerOut") = False Then Return
	Dim pout As String = swap.GetDefault("playerOut", "")
	Dim pin As String = swap.GetDefault("playerIn", "")
	If pout = "" Or pin = "" Then Return
	LogSub(pout, pin, NameForId(pout), NameForId(pin))
End Sub

Private Sub btnPlanSkip_Click
	If actionsLocked Then Return
	Dim b As Button = modUI.ClickedButton(Sender)
	Dim swap As Map = SwapAtIndex(b.Tag)
	If swap.ContainsKey("playerOut") = False Then Return
	swap.Put("skipped", True)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	Refresh
End Sub

Private Sub SwapAtIndex(rawIndex As Object) As Map
	Dim empty As Map
	empty.Initialize
	Dim idx As Int = rawIndex
	If match.IsInitialized = False Then Return empty
	Dim planObj As Object = match.GetDefault("subPlan", Null)
	If planObj = Null Or Not(planObj Is Map) Then Return empty
	Dim plan As Map = planObj
	Dim swaps As List = plan.GetDefault("swaps", EmptyList)
	If idx < 0 Or idx >= swaps.Size Then Return empty
	Dim raw As Object = swaps.Get(idx)
	If Not(raw Is Map) Then Return empty
	Return raw
End Sub

Private Sub BuildTimelineRow(Width As Int, ev As Map, names As Map, sides As Map, isFirst As Boolean, isLast As Boolean) As Panel
	Dim row As Panel = modUI.CreateTimelineItem(Width, ev, names, sides, isFirst, isLast)
	Dim eid As String = ev.GetDefault("id", "")
	Dim h As Int = modUI.TimelineItemHeight(ev)
	Dim btnSize As Int = 34dip
	Dim top As Int = (h - btnSize) / 2
	Dim btnEdit As Button = modUI.CreateIconButton(Me, "btnEvEdit", "✎", 0xFF334155, eid)
	row.AddView(btnEdit, Width - 80dip, top, btnSize, btnSize)
	Dim btnDel As Button = modUI.CreateIconButton(Me, "btnEvDel", "✕", 0xFF7F1D1D, eid)
	row.AddView(btnDel, Width - 40dip, top, btnSize, btnSize)
	Return row
End Sub

Private Sub btnEvEdit_Click
	Dim b As Button = modUI.ClickedButton(Sender)
	Dim eid As String = b.Tag
	If eid = "" Then Return
	modAppState.SelectedEventId = eid
	B4XPages.ShowPage("EventEdit")
End Sub

Private Sub btnEvDel_Click
	Dim b As Button = modUI.ClickedButton(Sender)
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
	modPlatform.Toast("Event deleted", False)
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

Private Sub AddEvent(etype As String, content As String, details As Map) As String
	If details.ContainsKey("minute") = False Or details.ContainsKey("clockTime") = False Then
		StampTimeDetails(details)
	End If
	Dim eid As String = modAppState.NewId
	Dim ev As Map
	ev.Initialize
	ev.Put("id", eid)
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
	Return eid
End Sub

Private Sub btnGoal_Click
	If actionsLocked Then Return
	Dim teamChips As List = ChipList(Array As String("our", "Our team", "opp", "Opponent"))
	Wait For (ShowPick("Who scored?", teamChips, False, "")) Complete (team As String)
	If team = "" Then Return
	
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	Dim content As String
	
	If team = "opp" Then
		Dim oppChips As List = ChipList(Array As String("owngoal", "Own goal", "oppgoal", "Opposition goal"))
		Wait For (ShowPick("Goal type", oppChips, False, "")) Complete (kind As String)
		If kind = "" Then Return
		details.Put("team", "B")
		details.Put("scorer", "")
		details.Put("assist", "")
		details.Put("assistUnknown", False)
		If kind = "owngoal" Then
			details.Put("ownGoal", True)
			content = "Own goal"
		Else
			details.Put("ownGoal", False)
			content = "Opposition goal"
		End If
	Else
		If memberNames.Size = 0 Then
			modPlatform.Toast("No players in club", False)
			Return
		End If
		Dim scorerChips As List = ChipList(Array As String("owngoal", "Own goal"))
		Wait For (ShowPick("Who scored?", scorerChips, True, "")) Complete (scorerId As String)
		If scorerId = "" Then Return
		details.Put("team", "A")
		If scorerId = "owngoal" Then
			details.Put("ownGoal", True)
			details.Put("scorer", "")
			details.Put("assist", "")
			details.Put("assistUnknown", False)
			content = "Own goal"
		Else
			Dim assistChips As List = ChipList(Array As String("none", "No assist", "unknown", "Unknown"))
			Wait For (ShowPick("Who assisted?", assistChips, True, scorerId)) Complete (assistId As String)
			If assistId = "" Then Return
			details.Put("ownGoal", False)
			details.Put("scorer", scorerId)
			details.Put("assist", "")
			details.Put("assistUnknown", False)
			If assistId = "unknown" Then
				details.Put("assistUnknown", True)
			Else If assistId <> "none" Then
				details.Put("assist", assistId)
			End If
			content = "GOAL! " & NameForId(scorerId)
		End If
	End If
	
	AddEvent("GOAL", content, details)
	RecomputeScoresAndStats
	Refresh
End Sub

Private Sub btnSub_Click
	If actionsLocked Or subSheetOpen Then Return
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	If memberIds.Size < 2 Then
		modPlatform.Toast("Need at least 2 players", False)
		Return
	End If
	sheetMode = "sub"
	sheetChips.Initialize
	sheetIncludePlayers = True
	subOffSlot = ""
	subOffPlayer = ""
	holdSlot = ""
	OpenSubSheet
End Sub

Private Sub OccupiedSlots(pitch As Map) As Int
	Dim n As Int = 0
	If pitch.IsInitialized = False Then Return 0
	For Each rawPid As Object In pitch.Values
		Dim pid As String = "" & rawPid
		If pid <> "" And pid <> "null" Then n = n + 1
	Next
	Return n
End Sub

Private Sub LogSub(playerOut As String, playerIn As String, outName As String, inName As String)
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("playerOut", playerOut)
	details.Put("playerIn", playerIn)
	StampTimeDetails(details)
	AddEvent("SUB", outName & " → " & inName, details)
End Sub

Private Sub btnYC_Click
	If actionsLocked Then Return
	Wait For (ShowPick("Yellow card", EmptyChipList, True, "")) Complete (pid As String)
	If pid = "" Then Return
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("player", pid)
	StampTimeDetails(details)
	AddEvent("YELLOW_CARD", NameForId(pid), details)
	RecomputeScoresAndStats
	Refresh
End Sub

Private Sub btnRC_Click
	If actionsLocked Then Return
	Wait For (ShowPick("Red card", EmptyChipList, True, "")) Complete (pid As String)
	If pid = "" Then Return
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("player", pid)
	StampTimeDetails(details)
	AddEvent("RED_CARD", NameForId(pid), details)
	RecomputeScoresAndStats
	Refresh
End Sub

Private Sub btnCornerUs_Click
	LogSetPiece("CORNER", "A", "Corner (us)")
End Sub

Private Sub btnCornerThem_Click
	LogSetPiece("CORNER", "B", "Corner (them)")
End Sub

Private Sub btnPenUs_Click
	LogSetPiece("PENALTY", "A", "Penalty (us)")
End Sub

Private Sub btnPenThem_Click
	LogSetPiece("PENALTY", "B", "Penalty (them)")
End Sub

Private Sub LogSetPiece(etype As String, team As String, content As String)
	If actionsLocked Then Return
	Dim details As Map
	details.Initialize
	details.Put("team", team)
	StampTimeDetails(details)
	AddEvent(etype, content, details)
End Sub

Private Sub btnHT_Click
	If actionsLocked Then Return
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	AddEvent("HALF_TIME", "Half Time", details)
End Sub

Private Sub btn2H_Click
	If actionsLocked Then Return
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	AddEvent("SECOND_HALF", "Second half underway", details)
End Sub

Private Sub btnEnd_Click
	If actionsLocked Then Return
	modLocal.ApplyLiveScore(match)
	match.Put("status", "COMPLETED")
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	' Full-time has to be on the feed before minutes are measured, otherwise
	' the whistle is missing and everyone is capped short of the match.
	AddEvent("END", "Full Time " & match.GetDefault("scoreA", 0) & "-" & match.GetDefault("scoreB", 0), details)
	ApplyProjectedMinutesToStats
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	modPlatform.Toast("Full time. Add the summary later from the match page.", False)
	Refresh
End Sub

Private Sub btnPens_Click
	If actionsLocked Then Return
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then Return
	If modLocal.HasFullTime(match.Get("id")) = False Then
		modPlatform.Toast("End the match before a shootout", False)
		Return
	End If
	Dim st As Map = modLocal.ShootoutState(match.Get("id"))
	If modLocal.IsFlag(st, "active") = False Then
		Wait For (SetupShootout) Complete (ok As Boolean)
		If ok Then modPlatform.Toast("Shootout ready. Tap Pens for each kick.", False)
		Return
	End If
	If modLocal.IsFlag(st, "decided") Then
		modPlatform.Toast("Shootout is already decided", False)
		Return
	End If
	Wait For (LogShootoutKick(st)) Complete (logged As Boolean)
	If logged = False Then Return
	Dim after As Map = modLocal.ShootoutState(match.Get("id"))
	If modLocal.IsFlag(after, "decided") Then
		modPlatform.Toast(modLocal.PensStatusLine(match.Get("id")), False)
	End If
	Refresh
End Sub

Private Sub SetupShootout As ResumableSub
	Dim countChips As List = ChipList(Array As String("5", "5 each", "3", "3 each", "other", "Other"))
	Wait For (ShowPick("Kicks each side", countChips, False, "")) Complete (countChoice As String)
	If countChoice = "" Then Return False
	Dim kicksEach As Int = 5
	If countChoice = "3" Then
		kicksEach = 3
	Else If countChoice = "other" Then
		Wait For (AskPositiveInt("How many kicks each?")) Complete (typed As Int)
		If typed < 1 Then Return False
		kicksEach = typed
	End If
	Dim startChips As List = ChipList(Array As String("A", "We start", "B", "Opposition starts"))
	Wait For (ShowPick("Who takes the first kick?", startChips, False, "")) Complete (firstTeam As String)
	If firstTeam <> "A" And firstTeam <> "B" Then Return False
	Dim details As Map
	details.Initialize
	details.Put("kind", "setup")
	details.Put("kicksEach", kicksEach)
	details.Put("firstTeam", firstTeam)
	details.Put("seq", DateTime.Now)
	StampTimeDetails(details)
	AddEvent("SHOOTOUT", modLocal.ShootoutSetupContent(kicksEach, firstTeam), details)
	Return True
End Sub

Private Sub LogShootoutKick(st As Map) As ResumableSub
	Dim team As String = st.GetDefault("nextTeam", "A")
	Dim playerId As String = ""
	Dim playerName As String = ""
	If team <> "B" Then
		team = "A"
		If memberNames.Size = 0 Then
			modPlatform.Toast("No players in club", False)
			Return False
		End If
		Wait For (ShowPick("Who's taking it?", EmptyChipList, True, "")) Complete (pickedId As String)
		playerId = pickedId
		If playerId = "" Then Return False
		playerName = NameForId(playerId)
	End If
	Dim resultChips As List = ChipList(Array As String("scored", "Scored", "missed", "Missed"))
	Wait For (ShowPick("Penalty", resultChips, False, "")) Complete (result As String)
	If result <> "scored" And result <> "missed" Then Return False
	Dim scored As Boolean = (result = "scored")
	Dim details As Map
	details.Initialize
	details.Put("kind", "kick")
	details.Put("team", team)
	details.Put("scored", scored)
	details.Put("player", playerId)
	details.Put("suddenDeath", modLocal.IsFlag(st, "inSuddenDeath"))
	details.Put("seq", DateTime.Now)
	StampTimeDetails(details)
	AddEvent("SHOOTOUT", modLocal.ShootoutKickContent(team, scored, playerName), details)
	modLocal.SyncShootoutFlags(match.Get("id"))
	Return True
End Sub

Private Sub AskPositiveInt(title As String) As ResumableSub
	StyleDarkDialog
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, 320dip, 80dip)
	pnl.Color = modConfig.COLOR_DARK_CARD
#if B4A
	Dim edt As EditText
#else if B4i
	Dim edt As TextField
#End If
	edt.Initialize("")
	modUI.StyleEditTextDark(edt, "5")
	modUI.SetKeyboard(edt, "numbers")
	pnl.AddView(edt, 12dip, 16dip, 296dip, 48dip)
	dialog.Title = title
	Wait For (dialog.ShowCustom(pnl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return 0
	Dim n As Int
	Try
		n = edt.Text.Trim
	Catch
		modPlatform.Toast("Enter a number", False)
		Return 0
	End Try
	If n < 1 Then
		modPlatform.Toast("Enter at least 1", False)
		Return 0
	End If
	Return n
End Sub

Private Sub btnComment_Click
	If actionsLocked Then Return
	' Custom note dialog — avoids B4XInputTemplate "Explanation" label.
	StyleDarkDialog
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, 320dip, 180dip)
	pnl.Color = modConfig.COLOR_DARK_CARD
#if B4A
	Dim edt As EditText
#else if B4i
	Dim edt As TextView
#End If
	edt.Initialize("")
	modUI.StyleEditTextDark(edt, "Write a note…")
	modUI.SetSingleLine(edt, False)
	modUI.SetAlign(edt, "TOP", "LEFT")
	pnl.AddView(edt, 12dip, 12dip, 296dip, 150dip)
	dialog.Title = "Match note"
	Wait For (dialog.ShowCustom(pnl, "Save", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim note As String = edt.Text.Trim
	If note = "" Then
		modPlatform.Toast("Enter some text", False)
		Return
	End If
	Dim details As Map
	details.Initialize
	StampTimeDetails(details)
	Dim eid As String = AddEvent("COMMENT", note, details)
	modAppState.SelectedEventId = eid
	B4XPages.ShowPage("EventEdit")
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
	If actionsLocked Then Return
	If match.GetDefault("status", "") <> "LIVE" Then
		modPlatform.Toast("Only live matches can be reset", False)
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
	modPlatform.Toast("Match reset to upcoming", False)
	B4XPages.ShowPage("MatchHub")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("MatchHub")
End Sub

Public Sub RecomputeScoresAndStats
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	If match.IsInitialized And match.ContainsKey("id") Then modLocal.SyncShootoutFlags(match.Get("id"))
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
				If modLocal.IsOwnGoal(details) = False Then
					BumpStatMap(stats, details.GetDefault("scorer", ""), "goals", 1)
					BumpStatMap(stats, details.GetDefault("assist", ""), "assists", 1)
				End If
			End If
		Else If etype = "YELLOW_CARD" Then
			BumpStatMap(stats, details.GetDefault("player", ""), "yellowCards", 1)
		Else If etype = "RED_CARD" Then
			BumpStatMap(stats, details.GetDefault("player", ""), "redCards", 1)
		End If
	Next
	Dim calculated As Map = modAppState.CalculateMatchMinutes(match)
	If calculated.IsInitialized And calculated.Size > 0 Then
		For Each pid As String In calculated.Keys
			Dim mins As Int = 0
			Try
				mins = calculated.Get(pid)
			Catch
				mins = 0
			End Try
			If mins <= 0 Then Continue
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
		Next
	Else
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

Private Sub ShowPick(title As String, chips As List, includePlayers As Boolean, excludeId As String) As ResumableSub
	sheetMode = "pick"
	sheetTitle = title
	sheetChips = chips
	sheetIncludePlayers = includePlayers
	pickExclude = excludeId
	subOffSlot = ""
	subOffPlayer = ""
	holdSlot = ""
	OpenSubSheet
	Wait For PlayerPicked (choice As String)
	Return choice
End Sub

Private Sub ChipList(pairs() As String) As List
	Dim chips As List
	chips.Initialize
	Dim i As Int = 0
	Do While i < pairs.Length - 1
		Dim c As Map
		c.Initialize
		c.Put("id", pairs(i))
		c.Put("label", pairs(i + 1))
		chips.Add(c)
		i = i + 2
	Loop
	Return chips
End Sub

Private Sub EmptyChipList As List
	Dim chips As List
	chips.Initialize
	Return chips
End Sub

Private Sub OpenSubSheet
	actionsLocked = True
	If subSheet.IsInitialized = False Then BuildSubSheet
#if B4A
	subSheet.Elevation = 24dip
#End If
	subSheet.Visible = True
	subSheet.BringToFront
	subSheetOpen = True
	If sheetMode = "pick" Then pickOpen = True
	DrawSheet
End Sub

Private Sub CloseSubSheet
	If pickOpen Then
		FinishPick("")
		Return
	End If
	HideSubSheet
End Sub

Private Sub FinishPick(choice As String)
	If pickOpen = False Then Return
	pickOpen = False
	HideSubSheet
	CallSubDelayed2(Me, "PlayerPicked", choice)
End Sub

Private Sub HideSubSheet
	subSheetOpen = False
	subOffSlot = ""
	subOffPlayer = ""
	holdSlot = ""
	sheetMode = ""
	If subSheet.IsInitialized Then subSheet.Visible = False
	CallSubDelayed(Me, "UnlockActions")
End Sub

Private Sub UnlockActions
	If subSheetOpen Then Return
	actionsLocked = False
End Sub

Private Sub BuildSubSheet
	subSheet.Initialize("subSheetBlock")
	subSheet.Color = 0xFF0F172A
#if B4A
	subSheet.Elevation = 24dip
#End If
	Root.AddView(subSheet, 0, 0, modUI.ViewWidth(Root), modUI.ViewHeight(Root))
	Dim btnBack As Button = modUI.CreateChromeIconButton(Me, "btnSubCancel", "←", Colors.Transparent, Colors.White)
	modUI.SetTextSize(btnBack, 26)
	subSheet.AddView(btnBack, 4dip, 6dip, 44dip, 44dip)
	subHint.Initialize("")
	subHint.TextColor = Colors.White
	modUI.SetTextSize(subHint, 15)
	modUI.SetBold(subHint, True)
	modUI.SetAlign(subHint, "CENTER", "LEFT")
	modUI.SetSingleLine(subHint, False)
	subSheet.AddView(subHint, 52dip, 6dip, modUI.ViewWidth(Root) - 64dip, 48dip)
	chipHost.Initialize("subSheetBlock")
	chipHost.Color = 0xFF0F172A
	subSheet.AddView(chipHost, 0, 64dip, modUI.ViewWidth(Root), 0)
	subPitch.Initialize("subSheetBlock")
	subPitch.Color = 0xFF15803D
	modUI.RoundBorder(subPitch, 0xFF15803D, 12dip, 2dip, Colors.ARGB(180, 22, 101, 52))
	subSheet.AddView(subPitch, 8dip, 64dip, modUI.ViewWidth(Root) - 16dip, 0)
	modUI.InitScroll(benchScroll, 200dip)
	benchScroll.Color = 0xFF0F172A
	subSheet.AddView(benchScroll, 0, 64dip, modUI.ViewWidth(Root), 80dip)
	benchScroll.Panel.Color = 0xFF0F172A
	benchHost.Initialize("subSheetBlock")
	benchHost.Color = 0xFF0F172A
	benchScroll.Panel.AddView(benchHost, 0, 0, modUI.ViewWidth(Root), 200dip)
End Sub

Private Sub subSheetBlock_Click
End Sub

Private Sub DrawSheet
	Dim lineup As Map
	lineup.Initialize
	If match.IsInitialized Then lineup = modAppState.LineupAfterSubs(match)
	showPitch = False
	If sheetMode = "sub" Or sheetIncludePlayers Then
		If OccupiedSlots(lineup) > 0 Then showPitch = True
	End If
	If sheetMode = "pick" Then
		subHint.Text = sheetTitle
	Else If showPitch And holdSlot <> "" Then
		subHint.Text = "Hold another spot to switch"
	Else If showPitch And subOffSlot = "" Then
		subHint.Text = "Tap a player to sub. Hold two spots to switch."
	Else If showPitch Then
		subHint.Text = "Tap who is coming on"
	Else If subOffPlayer = "" Then
		subHint.Text = "Tap the player coming off"
	Else
		subHint.Text = "Tap who is coming on"
	End If
	Dim y As Int = 64dip
	Dim chipH As Int = 0
	If sheetChips.IsInitialized And sheetChips.Size > 0 Then chipH = 88dip
	modUI.PlaceView(chipHost, 0, y, modUI.ViewWidth(Root), chipH)
	chipHost.Visible = chipH > 0
	y = y + chipH
	Dim pitchH As Int = 0
	If showPitch Then
		pitchH = modUI.ViewHeight(Root) * 0.40
		If pitchH < 220dip Then pitchH = 220dip
	End If
	modUI.PlaceView(subPitch, 8dip, y, modUI.ViewWidth(Root) - 16dip, pitchH)
	subPitch.Visible = pitchH > 0
	y = y + pitchH
	Dim showBench As Boolean = sheetMode = "sub" Or sheetIncludePlayers
	Dim benchH As Int = modUI.ViewHeight(Root) - y
	If benchH < 4dip Then benchH = 4dip
	modUI.PlaceView(benchScroll, 0, y, modUI.ViewWidth(Root), benchH)
	benchScroll.Visible = showBench
	DrawChips
	If showPitch Then
		If subPitch.Width > 2dip And subPitch.Height > 2dip Then DrawPitch(lineup)
	End If
	If showBench Then DrawBenchGrid
End Sub

Private Sub DrawChips
	chipHost.RemoveAllViews
	If sheetChips.IsInitialized = False Then Return
	Dim size As Int = 64dip
	Dim i As Int
	For i = 0 To sheetChips.Size - 1
		Dim c As Map = sheetChips.Get(i)
		Dim left As Int = 8dip + i * (size + 12dip)
		AddRoundSpot(chipHost, left, 8dip, size, "chip", c.GetDefault("id", ""), "", c.GetDefault("label", ""), False)
	Next
End Sub

Private Sub DrawPitch(lineup As Map)
	subPitch.RemoveAllViews
	If subPitch.Width < 2dip Or subPitch.Height < 2dip Then Return
	subPitch.Color = 0xFF15803D
	modUI.RoundBorder(subPitch, 0xFF15803D, 12dip, 2dip, Colors.ARGB(180, 22, 101, 52))
	modUI.PaintPitchMarkings(subPitch)
	Dim formName As String = ""
	If match.IsInitialized Then formName = match.GetDefault("formation", "")
	If formName = "" And club.IsInitialized Then formName = club.GetDefault("preferredFormation", "")
	Dim positions As List = modFormations.GetPositions(formName)
	Dim layout As Map
	layout.Initialize
	Dim planObj As Object = match.GetDefault("subPlan", Null)
	If planObj <> Null And planObj Is Map Then
		Dim plan As Map = planObj
		Dim lay As Object = plan.GetDefault("layout", Null)
		If lay <> Null And lay Is Map Then layout = lay
	End If
	Dim slotSize As Int = 52dip
	Dim i As Int
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		Dim posId As String = p.GetDefault("id", "")
		Dim spread As Map = modFormations.DisplaySlot(p, layout)
		Dim xPct As Float = spread.Get("x")
		Dim yPct As Float = spread.Get("y")
		Dim origin As Map = modUI.PitchSlotLeftTop(subPitch.Width, subPitch.Height, slotSize, xPct, yPct)
		Dim pid As String = "" & lineup.GetDefault(posId, "")
		Dim displayName As String = ""
		If pid <> "" And pid <> "null" Then displayName = NameForId(pid)
		Dim held As Boolean = posId = subOffSlot Or posId = holdSlot
		AddRoundSpot(subPitch, origin.Get("left"), origin.Get("top"), slotSize, "slot", posId, displayName, p.GetDefault("label", ""), held)
	Next
End Sub

Private Sub DrawBenchGrid
	benchHost.RemoveAllViews
	benchHost.Color = 0xFF0F172A
	Dim ids As List = GridPlayerIds
	If ids.Size = 0 Then
		Dim lbl As Label
		lbl.Initialize("")
		lbl.Text = "No one else to pick"
		lbl.TextColor = 0xFF94A3B8
		modUI.SetTextSize(lbl, 14)
		modUI.SetAlign(lbl, "CENTER", "CENTER")
		benchHost.AddView(lbl, 12dip, 8dip, benchScroll.Width - 24dip, 36dip)
		SizeBench(52dip)
		Return
	End If
	Dim cols As Int = 4
	Dim size As Int = 56dip
	Dim cellW As Int = benchScroll.Width / cols
	If cellW < size + 8dip Then cellW = size + 8dip
	Dim rowH As Int = size + 22dip
	Dim col As Int = 0
	Dim row As Int = 0
	Dim i As Int
	For i = 0 To ids.Size - 1
		Dim pid As String = ids.Get(i)
		AddRoundSpot(benchHost, col * cellW + 4dip, row * rowH + 4dip, size, "player", pid, NameForId(pid), "", pid = subOffPlayer)
		col = col + 1
		If col >= cols Then
			col = 0
			row = row + 1
		End If
	Next
	Dim rows As Int = row
	If col > 0 Then rows = rows + 1
	SizeBench(rows * rowH + 12dip)
End Sub

' The scroll view's own panel uses Android frame params, so SetLayout on it crashes.
Private Sub SizeBench(contentH As Int)
	Dim w As Int = benchScroll.Width
	If w < 2dip Then w = modUI.ViewWidth(Root)
	modUI.PlaceView(benchHost, 0, 0, w, contentH)
	modUI.SetScrollContentHeight(benchScroll, contentH)
End Sub

Private Sub GridPlayerIds As List
	Dim ids As List
	ids.Initialize
	Dim onPitch As Map
	onPitch.Initialize
	If showPitch And match.IsInitialized Then
		Dim lineup As Map = modAppState.LineupAfterSubs(match)
		For Each onRaw As Object In lineup.Values
			Dim onId As String = "" & onRaw
			If onId <> "" And onId <> "null" Then onPitch.Put(onId, True)
		Next
	End If
	Dim availability As Map
	availability.Initialize
	If match.IsInitialized Then
		Dim avObj As Object = match.GetDefault("availability", Null)
		If avObj <> Null And avObj Is Map Then availability = avObj
	End If
	Dim confirmed As Int = 0
	Dim i As Int
	If sheetMode = "sub" And showPitch Then
		For i = 0 To memberIds.Size - 1
			If availability.GetDefault(memberIds.Get(i), "") = "CONFIRMED" Then confirmed = confirmed + 1
		Next
	End If
	For i = 0 To memberIds.Size - 1
		Dim id As String = memberIds.Get(i)
		Dim skip As Boolean = False
		If sheetMode = "pick" And id = pickExclude Then skip = True
		If sheetMode = "sub" And showPitch = False And subOffPlayer <> "" And id = subOffPlayer Then skip = True
		If onPitch.ContainsKey(id) Then skip = True
		If confirmed > 0 And availability.GetDefault(id, "") <> "CONFIRMED" Then skip = True
		If skip = False Then ids.Add(id)
	Next
	Return ids
End Sub

Private Sub AddRoundSpot(parent As Panel, left As Int, top As Int, size As Int, kind As String, id As String, displayName As String, emptyLabel As String, selected As Boolean)
	Dim tag As Map
	tag.Initialize
	tag.Put("kind", kind)
	tag.Put("id", id)
	Dim avatar As String = ""
	If displayName <> "" Then avatar = memberAvatars.GetDefault(id, "")
	Dim slot As Map = modUI.CreateRoundPlayerSlot(Me, "pickSpot", tag, size, displayName, avatar, emptyLabel, selected)
	Dim pnl As Panel = slot.Get("panel")
	parent.AddView(pnl, left, top, size + 16dip, size + 18dip)
	If slot.ContainsKey("imageView") = False Then Return
	Dim iv As ImageView = slot.Get("imageView")
	If iv.IsInitialized = False Or avatar = "" Then Return
	' Start after this click handler returns. A photo download cannot start while the goal step is still running.
	CallSubDelayed3(Me, "LoadSlotAvatar", iv, avatar)
End Sub

Private Sub LoadSlotAvatar(iv As ImageView, url As String)
	Dim j As HttpJob
	j.Initialize("", Me)
	j.Download(url)
	Wait For (j) JobDone (job As HttpJob)
	If job.Success Then
		Try
			Dim bmp As Bitmap = job.GetBitmap
			If bmp <> Null And bmp.IsInitialized Then
				iv.Bitmap = bmp
				modUI.SetImageFill(iv)
			End If
		Catch
			Log("LiveFeed avatar: " & LastException.Message)
		End Try
	End If
	job.Release
End Sub

Private Sub pickSpot_LongClick As Boolean
	If sheetMode <> "sub" Or showPitch = False Then Return False
	Dim pnl As Panel = modUI.LongClickPanel(Sender)
	If pnl.IsInitialized = False Then Return True
	If Not(pnl.Tag Is Map) Then Return True
	Dim tag As Map = pnl.Tag
	If tag.GetDefault("kind", "") <> "slot" Then Return True
	Dim slotId As String = tag.GetDefault("id", "")
	If slotId = "" Then Return True
	If holdSlot = "" Then
		holdSlot = slotId
		modPlatform.Toast("Hold another spot to switch", False)
		CallSubDelayed(Me, "DrawSheet")
		Return True
	End If
	If slotId = holdSlot Then
		holdSlot = ""
		modPlatform.Toast("Switch cancelled", False)
		CallSubDelayed(Me, "DrawSheet")
		Return True
	End If
	If LogPositionSwitch(holdSlot, slotId) = False Then
		modPlatform.Toast("Nothing to switch", False)
		Return True
	End If
	holdSlot = ""
	subOffSlot = ""
	subOffPlayer = ""
	modPlatform.Toast("Positions switched", False)
	CallSubDelayed(Me, "DrawSheet")
	Return True
End Sub

Private Sub LogPositionSwitch(slotA As String, slotB As String) As Boolean
	Dim lineup As Map = modAppState.LineupAfterSubs(match)
	Dim idA As String = CleanPlayerId(lineup.GetDefault(slotA, ""))
	Dim idB As String = CleanPlayerId(lineup.GetDefault(slotB, ""))
	If idA = "" And idB = "" Then Return False
	Dim details As Map
	details.Initialize
	details.Put("team", "A")
	details.Put("slotA", slotA)
	details.Put("slotB", slotB)
	details.Put("playerA", idA)
	details.Put("playerB", idB)
	StampTimeDetails(details)
	AddEvent("POSITION", SpotCaption(lineup, slotA) & " ↔ " & SpotCaption(lineup, slotB), details)
	Return True
End Sub

Private Sub SpotCaption(lineup As Map, slotId As String) As String
	Dim label As String = SlotLabel(slotId)
	Dim pid As String = CleanPlayerId(lineup.GetDefault(slotId, ""))
	If pid = "" Then Return label
	Return NameForId(pid) & " (" & label & ")"
End Sub

Private Sub SlotLabel(slotId As String) As String
	Dim formName As String = ""
	If match.IsInitialized Then formName = match.GetDefault("formation", "")
	If formName = "" And club.IsInitialized Then formName = club.GetDefault("preferredFormation", "")
	Dim positions As List = modFormations.GetPositions(formName)
	Dim i As Int
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		If ("" & p.GetDefault("id", "")) = slotId Then Return "" & p.GetDefault("label", slotId)
	Next
	Return slotId
End Sub

Private Sub CleanPlayerId(raw As Object) As String
	Dim pid As String = "" & raw
	If pid = "null" Then Return ""
	Return pid
End Sub

Private Sub pickSpot_Click
	Dim raw As Object = Sender
	If Not(raw Is Panel) Then Return
	Dim pnl As Panel = raw
	If Not(pnl.Tag Is Map) Then Return
	Dim tag As Map = pnl.Tag
	Dim kind As String = tag.GetDefault("kind", "")
	Dim id As String = tag.GetDefault("id", "")
	If sheetMode = "pick" Then
		If kind = "chip" Then
			FinishPick(id)
			Return
		End If
		If kind = "slot" Then
			Dim lineup As Map = modAppState.LineupAfterSubs(match)
			Dim pid As String = "" & lineup.GetDefault(id, "")
			If pid = "" Or pid = "null" Then
				modPlatform.Toast("Nobody in that spot", False)
				Return
			End If
			If pid = pickExclude Then
				modPlatform.Toast("That's the scorer", False)
				Return
			End If
			FinishPick(pid)
			Return
		End If
		If id = "" Or id = pickExclude Then Return
		FinishPick(id)
		Return
	End If
	If kind = "slot" Then
		Dim lineup2 As Map = modAppState.LineupAfterSubs(match)
		Dim pid2 As String = "" & lineup2.GetDefault(id, "")
		If pid2 = "" Or pid2 = "null" Then
			modPlatform.Toast("Nobody in that spot", False)
			Return
		End If
		If subOffSlot = id Then
			subOffSlot = ""
		Else
			subOffSlot = id
		End If
		DrawSheet
		Return
	End If
	If showPitch And subOffSlot = "" Then
		modPlatform.Toast("Tap a player on the pitch first", False)
		Return
	End If
	If showPitch = False And subOffPlayer = "" Then
		subOffPlayer = id
		DrawSheet
		Return
	End If
	Dim playerOut As String = subOffPlayer
	If showPitch Then playerOut = "" & modAppState.LineupAfterSubs(match).GetDefault(subOffSlot, "")
	If playerOut = "" Or playerOut = "null" Or playerOut = id Then Return
	LogSub(playerOut, id, NameForId(playerOut), NameForId(id))
	CloseSubSheet
	Refresh
End Sub

Private Sub btnSubCancel_Click
	CloseSubSheet
End Sub

Private Sub NameForId(pid As String) As String
	If pid = "" Or pid = "null" Then Return ""
	Dim i As Int
	For i = 0 To memberIds.Size - 1
		If memberIds.Get(i) = pid Then Return memberNames.Get(i)
	Next
	Return "?"
End Sub

Private Sub btnShare_Click
	If sharingTimeline Then Return
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then
		modPlatform.Toast("Open a match first", False)
		Return
	End If
	sharingTimeline = True
	Dim err As String = ""
	Try
		err = WriteAndShareTimeline
	Catch
		Log("ShareTimeline: " & LastException)
		err = "Could not create the timeline image."
	End Try
	sharingTimeline = False
	If err <> "" Then modPlatform.Toast(err, True)
End Sub

Private Sub WriteAndShareTimeline As String
	Dim newest As List = modAppState.EventsNewestFirst(match.Get("id"))
	Dim oldest As List
	oldest.Initialize
	Dim i As Int
	For i = newest.Size - 1 To 0 Step -1
		oldest.Add(newest.Get(i))
	Next
	Dim names As Map = NameByIdMap
	Dim scale As Float = modPlatform.TextScale
	Dim width As Int = 1080
	Dim pad As Int = 56
	Dim maxW As Float = width - pad * 2
	Dim measureCvs As B4XCanvas = OpenShareCanvas(16, 16)
	Dim drawn As List
	drawn.Initialize
	AddWrappedShareLines(drawn, measureCvs, scale, "title", match.GetDefault("title", "Match"), maxW)
	AddWrappedShareLines(drawn, measureCvs, scale, "score", modLocal.ScoreLine(match), maxW)
	AddShareLine(drawn, "gap", "")
	If oldest.Size = 0 Then
		AddWrappedShareLines(drawn, measureCvs, scale, "body", "No events yet", maxW)
	Else
		For i = 0 To oldest.Size - 1
			Dim ev As Map = oldest.Get(i)
			Dim lines As Map = modUI.TimelineLines(ev, names, SideNames)
			AddWrappedShareLines(drawn, measureCvs, scale, "meta", lines.Get("minute") & "   " & lines.Get("clock") & "   " & lines.Get("typeLabel"), maxW)
			Dim mainText As String = lines.Get("main")
			If mainText <> "" Then AddWrappedShareLines(drawn, measureCvs, scale, "body", mainText, maxW)
			Dim line2 As String = lines.Get("line2")
			If line2 <> "" Then AddWrappedShareLines(drawn, measureCvs, scale, "sub", line2, maxW)
			AddShareLine(drawn, "gap", "")
		Next
	End If
	Dim height As Int = pad
	For i = 0 To drawn.Size - 1
		height = height + ShareRowHeight(measureCvs, scale, drawn.Get(i))
	Next
	height = height + pad
	If height < 480 Then height = 480
	If height > 12000 Then height = 12000
	measureCvs.Release
	Dim cvs As B4XCanvas = OpenShareCanvas(width, height)
	Dim bg As B4XRect
	bg.Initialize(0, 0, width, height)
	cvs.DrawRect(bg, 0xFF0F172A, True, 0)
	Dim y As Int = pad
	For i = 0 To drawn.Size - 1
		Dim row As Map = drawn.Get(i)
		Dim rowH As Int = ShareRowHeight(cvs, scale, row)
		If y + rowH > height - pad Then Exit
		Dim kind As String = row.Get("kind")
		If kind = "gap" Then
			y = y + rowH
			Continue
		End If
		Dim fnt As B4XFont = ShareFont(kind, scale)
		Dim textH As Float = cvs.MeasureText("Ag", fnt).Height
		cvs.DrawText(row.Get("text"), pad, y + textH, fnt, ShareColor(kind), "LEFT")
		y = y + rowH
	Next
	Dim bmp As Bitmap = cvs.CreateBitmap
	cvs.Release
	File.MakeDir(modPlatform.AppDir, "shared")
	Dim dir As String = File.Combine(modPlatform.AppDir, "shared")
	Dim existing As List = File.ListFiles(dir)
	If existing.IsInitialized Then
		For i = 0 To existing.Size - 1
			Dim name As String = existing.Get(i)
			If name.StartsWith("timeline-") And name.EndsWith(".jpg") Then File.Delete(dir, name)
		Next
	End If
	Dim fileName As String = "timeline-" & ShareStamp & ".jpg"
	Dim out As OutputStream = File.OpenOutput(dir, fileName, False)
	bmp.WriteToStream(out, 90, "JPEG")
	out.Close
	Return modExport.ShareDocument(dir, fileName, "image/jpeg", "Share timeline")
End Sub

Private Sub OpenShareCanvas(width As Int, height As Int) As B4XCanvas
	shareHost = xui.CreatePanel("")
	shareHost.SetLayoutAnimated(0, 0, 0, width, height)
	Dim cvs As B4XCanvas
	cvs.Initialize(shareHost)
	Return cvs
End Sub

Private Sub SharePx(kind As String) As Float
	If kind = "title" Then Return 44
	If kind = "score" Then Return 60
	If kind = "meta" Then Return 28
	If kind = "sub" Then Return 30
	Return 32
End Sub

Private Sub ShareFont(kind As String, scale As Float) As B4XFont
	Dim size As Float = SharePx(kind) / scale
	If kind = "title" Or kind = "score" Or kind = "meta" Then Return xui.CreateDefaultBoldFont(size)
	Return xui.CreateDefaultFont(size)
End Sub

Private Sub ShareColor(kind As String) As Int
	If kind = "title" Or kind = "score" Then Return Colors.White
	If kind = "meta" Then Return 0xFF38BDF8
	If kind = "sub" Then Return 0xFF94A3B8
	Return 0xFFE2E8F0
End Sub

Private Sub ShareRowHeight(cvs As B4XCanvas, scale As Float, row As Map) As Int
	Dim kind As String = row.Get("kind")
	If kind = "gap" Then Return 20
	Dim h As Float = cvs.MeasureText("Ag", ShareFont(kind, scale)).Height
	Return h + 14
End Sub

Private Sub AddWrappedShareLines(lines As List, cvs As B4XCanvas, scale As Float, kind As String, text As String, maxW As Float)
	Dim parts As List = WrapShareToWidth(cvs, text, ShareFont(kind, scale), maxW)
	Dim i As Int
	For i = 0 To parts.Size - 1
		AddShareLine(lines, kind, parts.Get(i))
	Next
End Sub

Private Sub AddShareLine(lines As List, kind As String, text As String)
	Dim row As Map
	row.Initialize
	row.Put("kind", kind)
	row.Put("text", text)
	lines.Add(row)
End Sub

Private Sub WrapShareToWidth(cvs As B4XCanvas, text As String, fnt As B4XFont, maxW As Float) As List
	Dim lines As List
	lines.Initialize
	Dim rest As String = text.Trim
	If rest = "" Then
		lines.Add("")
		Return lines
	End If
	Do While rest <> ""
		If cvs.MeasureText(rest, fnt).Width <= maxW Then
			lines.Add(rest)
			Exit
		End If
		Dim cut As Int = FitShareCut(cvs, rest, fnt, maxW)
		If cut < 1 Then cut = 1
		Dim piece As String = rest.SubString2(0, cut).Trim
		If piece = "" Then piece = rest.SubString2(0, cut)
		lines.Add(piece)
		rest = rest.SubString(cut).Trim
	Loop
	Return lines
End Sub

' Last character index that still fits, preferring a space.
Private Sub FitShareCut(cvs As B4XCanvas, text As String, fnt As B4XFont, maxW As Float) As Int
	Dim lo As Int = 1
	Dim hi As Int = text.Length - 1
	Dim best As Int = 1
	Do While lo <= hi
		Dim mid As Int = (lo + hi) / 2
		If cvs.MeasureText(text.SubString2(0, mid), fnt).Width <= maxW Then
			best = mid
			lo = mid + 1
		Else
			hi = mid - 1
		End If
	Loop
	Dim space As Int = text.LastIndexOf2(" ", best)
	If space > 8 Then Return space
	Return best
End Sub

Private Sub ShareStamp As String
	Dim oldDate As String = DateTime.DateFormat
	Dim oldTime As String = DateTime.TimeFormat
	DateTime.DateFormat = "yyyyMMdd"
	DateTime.TimeFormat = "HHmmss"
	Dim s As String = DateTime.Date(DateTime.Now) & "-" & DateTime.Time(DateTime.Now)
	DateTime.DateFormat = oldDate
	DateTime.TimeFormat = oldTime
	Return s
End Sub
