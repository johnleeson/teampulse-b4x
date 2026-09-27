B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Sub plan — live pitch/bench after each planned swap, minutes in pickers, lineup preview, play targets.
' Long-press two spots on a quarter pitch to swap those players.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private edtDuration As EditText
	Private clv As CustomListView
	Private match As Map
	Private club As Map
	Private currentSubPlan As Map
	Private btnQuarter As Button
	Private btnOff As Button
	Private btnOn As Button
	Private btnAdd As Button
	Private btnShare As Button
	Private sharing As Boolean
	Private selectedAfterQuarter As Int
	Private selectedOffId As String
	Private selectedOnId As String
	Private offIds As List
	Private onIds As List
	Private editingSwapIndex As Int
	Private projectedCache As Map
	Private pitchPanels As List
	Private holdSlotId As String
	Private holdQuarter As Int
End Sub

Public Sub Initialize
	currentSubPlan.Initialize
	offIds.Initialize
	onIds.Initialize
	projectedCache.Initialize
	pitchPanels.Initialize
	selectedAfterQuarter = 1
	selectedOffId = ""
	selectedOnId = ""
	editingSwapIndex = -1
	holdSlotId = ""
	holdQuarter = 0
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
	Dim clubId As String = ""
	If match.IsInitialized Then clubId = "" & match.GetDefault("clubId", "")
	btnShare.Visible = modExport.UserCanExportClub(clubId)
	PlaceList
	RefreshProjected
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Sub plan", "btnBack", "btnSave", "✓", True)
	Dim top As Int = chrome.Get("ContentTop")
	Dim w As Int = Root.Width - 32dip
	
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = "MATCH MINUTES"
	lbl.TextSize = 11
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	lbl.Typeface = Typeface.DEFAULT_BOLD
	Root.AddView(lbl, 16dip, top, 120dip, 16dip)
	
	edtDuration.Initialize("")
	modUI.StyleEditTextDark(edtDuration, "60")
	edtDuration.InputType = edtDuration.INPUT_TYPE_NUMBERS
	edtDuration.Gravity = Gravity.CENTER
	Root.AddView(edtDuration, 16dip, top + 18dip, 64dip, 44dip)
	
	Dim btnFair As Button
	btnFair.Initialize("btnFair")
	btnFair.Text = "Auto fair"
	btnFair.TextSize = 12
	btnFair.Typeface = Typeface.DEFAULT_BOLD
	btnFair.Color = modConfig.COLOR_ACCENT
	btnFair.TextColor = Colors.White
	Root.AddView(btnFair, 88dip, top + 18dip, 100dip, 44dip)
	
	Dim btnClear As Button
	btnClear.Initialize("btnClear")
	btnClear.Text = "Clear"
	btnClear.TextSize = 12
	btnClear.Typeface = Typeface.DEFAULT_BOLD
	btnClear.Color = modConfig.COLOR_DARK_CHIP
	btnClear.TextColor = modConfig.COLOR_DARK_TEXT
	Root.AddView(btnClear, 196dip, top + 18dip, 72dip, 44dip)
	
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Long-press two spots to swap them. Tap a pitch to plan that break. Tap a name for 1Q–4Q."
	hint.TextSize = 11
	hint.TextColor = modConfig.COLOR_DARK_MUTED
	hint.SingleLine = False
	Root.AddView(hint, 16dip, top + 68dip, w, 56dip)
	
	Dim lblQ As Label
	lblQ.Initialize("")
	lblQ.Text = "ADD / EDIT SWAP"
	lblQ.TextSize = 11
	lblQ.TextColor = modConfig.COLOR_DARK_MUTED
	lblQ.Typeface = Typeface.DEFAULT_BOLD
	Root.AddView(lblQ, 16dip, top + 128dip, w, 16dip)
	
	Dim rowY As Int = top + 148dip
	Dim qW As Int = 56dip
	Dim gap As Int = 6dip
	Dim midW As Int = (w - qW - 64dip - gap * 3) / 2
	
	btnQuarter.Initialize("btnQuarter")
	StylePickerButton(btnQuarter)
	Root.AddView(btnQuarter, 16dip, rowY, qW, 44dip)
	
	btnOff.Initialize("btnOff")
	StylePickerButton(btnOff)
	Root.AddView(btnOff, 16dip + qW + gap, rowY, midW, 44dip)
	
	btnOn.Initialize("btnOn")
	StylePickerButton(btnOn)
	Root.AddView(btnOn, 16dip + qW + gap * 2 + midW, rowY, midW, 44dip)
	
	btnAdd.Initialize("btnAddSwap")
	btnAdd.Text = "Add"
	btnAdd.TextSize = 12
	btnAdd.Typeface = Typeface.DEFAULT_BOLD
	btnAdd.Color = modConfig.COLOR_SUCCESS
	btnAdd.TextColor = Colors.White
	Root.AddView(btnAdd, Root.Width - 16dip - 64dip, rowY, 64dip, 44dip)
	
	btnShare.Initialize("btnShare")
	btnShare.Text = "Share sheet"
	btnShare.TextSize = 14
	btnShare.Typeface = Typeface.DEFAULT_BOLD
	btnShare.Color = modConfig.COLOR_ACCENT
	btnShare.TextColor = Colors.White
	btnShare.Visible = False
	Root.AddView(btnShare, 16dip, rowY + 52dip, w, 40dip)
	
	Dim listTop As Int = rowY + 100dip
	clv = modUI.AddCustomListViewThemed(Root, 0, listTop, Root.Width, Root.Height - listTop, Me, "clv", True)
	btnShare.BringToFront
End Sub

Private Sub PlaceList
	Dim rowY As Int = modUI.PageChromeHeight + 148dip
	Dim listTop As Int
	If btnShare.IsInitialized And btnShare.Visible Then
		listTop = rowY + 100dip
	Else
		listTop = rowY + 56dip
	End If
	clv.AsView.SetLayoutAnimated(0, 0, listTop, Root.Width, Root.Height - listTop)
	If btnShare.Visible Then btnShare.BringToFront
End Sub

Private Sub HasLineup As Boolean
	Dim lineup As Map = CurrentLineup
	If lineup.IsInitialized = False Or lineup.Size = 0 Then Return False
	Dim ids As List = modSubPlanner.MemberIdsInSlots(lineup, CurrentFormation, NameByIdMap)
	Return ids.Size > 0
End Sub

Private Sub btnShare_Click
	If sharing Then Return
	If HasLineup = False Then
		ToastMessageShow("Set a lineup to share the sheet.", False)
		Return
	End If
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	currentSubPlan.Put("matchMinutes", duration)
	sharing = True
	btnShare.Enabled = False
	ProgressDialogShow2("Building sub plan sheet...", False)
	Try
		Dim built As Map = modSubPlanExport.BuildFile(match, club, currentSubPlan, CurrentLineup, CurrentFormation, NameByIdMap, ConfirmedSquad, pitchPanels)
		ProgressDialogHide
		btnShare.Enabled = True
		sharing = False
		If built.IsInitialized = False Or built.GetDefault("ok", False) = False Then
			Dim fail As String = "Could not create the sub plan sheet. Nothing was changed."
			If built.IsInitialized Then fail = built.GetDefault("message", fail)
			xui.MsgboxAsync(fail, "Share")
			Return
		End If
		Dim shareErr As String = modExport.ShareDocument(built.GetDefault("dir", ""), built.GetDefault("file", ""), _
			"application/pdf", "Share sub plan")
		If shareErr <> "" Then xui.MsgboxAsync(shareErr, "Share")
	Catch
		Log("btnShare: " & LastException)
		ProgressDialogHide
		btnShare.Enabled = True
		sharing = False
		xui.MsgboxAsync("Could not create the sub plan sheet. Nothing was changed.", "Share")
	End Try
End Sub

Private Sub StylePickerButton(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	b.TextColor = modConfig.COLOR_DARK_TEXT
	b.TextSize = 12
	b.Typeface = Typeface.DEFAULT_BOLD
	b.Gravity = Gravity.CENTER
	b.SingleLine = True
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", modAppState.SelectedClubId))
	currentSubPlan = match.GetDefault("subPlan", modSubPlanner.EmptyPlan(60))
	If currentSubPlan.IsInitialized = False Then currentSubPlan = modSubPlanner.EmptyPlan(60)
	If currentSubPlan.ContainsKey("swaps") = False Then
		Dim swaps As List
		swaps.Initialize
		currentSubPlan.Put("swaps", swaps)
	End If
	If currentSubPlan.ContainsKey("playTargets") = False Then
		Dim targets As Map
		targets.Initialize
		currentSubPlan.Put("playTargets", targets)
	End If
	MovesList
	LayoutMap
	edtDuration.Text = "" & currentSubPlan.GetDefault("matchMinutes", 60)
	editingSwapIndex = -1
	selectedAfterQuarter = 1
	selectedOffId = ""
	selectedOnId = ""
	holdSlotId = ""
	holdQuarter = 0
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub ConfirmedSquad As List
	Dim out As List
	out.Initialize
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		If availability.GetDefault(mem.Get("id"), "") = "CONFIRMED" Then out.Add(mem)
	Next
	If out.Size = 0 Then
		For i = 0 To members.Size - 1
			out.Add(members.Get(i))
		Next
	End If
	Return out
End Sub

Private Sub NameByIdMap As Map
	Dim m As Map
	m.Initialize
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		Dim mid As String = "" & mem.Get("id")
		If mid <> "" And mid <> "null" Then m.Put(mid, mem.GetDefault("name", "?"))
	Next
	Return m
End Sub

Private Sub CurrentFormation As String
	Dim formation As String = match.GetDefault("formation", "")
	Dim teamSize As Int = 11
	Try
		teamSize = match.GetDefault("teamSize", 11)
	Catch
		teamSize = 11
	End Try
	If formation = "" Then formation = modFormations.DefaultFormationForSize(teamSize)
	Return formation
End Sub

Private Sub MemberIdList As List
	Dim ids As List
	ids.Initialize
	Dim names As Map = NameByIdMap
	For Each k As String In names.Keys
		ids.Add(k)
	Next
	Return ids
End Sub

Private Sub CurrentLineup As Map
	Dim lineup As Map = match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMap))
	If lineup.IsInitialized = False Then lineup.Initialize
	Return lineup
End Sub

Private Sub SquadIdsList As List
	Dim squadIds As List
	squadIds.Initialize
	Dim squad As List = ConfirmedSquad
	Dim j As Int
	For j = 0 To squad.Size - 1
		Dim m As Map = squad.Get(j)
		squadIds.Add(m.Get("id"))
	Next
	Return squadIds
End Sub

Private Sub RefreshProjected
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	currentSubPlan.Put("matchMinutes", duration)
	Dim lineup As Map = CurrentLineup
	If lineup.Size = 0 Then
		projectedCache.Initialize
		Return
	End If
	projectedCache = modSubPlanner.ProjectMatchMinutes(lineup, currentSubPlan, MemberIdList)
	currentSubPlan.Put("projectedMinutes", projectedCache)
End Sub

Private Sub CopyMapLocal(src As Map) As Map
	Dim m As Map
	m.Initialize
	If src.IsInitialized Then
		For Each k As String In src.Keys
			m.Put(k, src.Get(k))
		Next
	End If
	Return m
End Sub

' Lineup on the pitch when picking the next swap after quarter afterQ,
' including swaps already planned for earlier breaks AND this same break
' (except the swap currently being edited).
Private Sub PitchAtBreak(afterQ As Int) As Map
	Dim current As Map = CopyMapLocal(CurrentLineup)
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	Dim moves As List = MovesList
	Dim q As Int
	For q = 1 To afterQ - 1
		current = modSubPlanner.ApplySwapsToLineup(current, swaps, q)
		current = modSubPlanner.ApplyMovesToLineup(current, moves, q)
	Next
	Dim si As Int
	For si = 0 To swaps.Size - 1
		If editingSwapIndex >= 0 And si = editingSwapIndex Then Continue
		Dim swap As Map = swaps.Get(si)
		If afterQ <> swap.GetDefault("afterQuarter", 0) Then Continue
		Dim playerOut As String = swap.GetDefault("playerOut", "")
		Dim playerIn As String = swap.GetDefault("playerIn", "")
		Dim slot As String = ""
		For Each k As String In current.Keys
			If ("" & current.Get(k)) = playerOut Then
				slot = k
				Exit
			End If
		Next
		If slot = "" Then Continue
		Dim alreadyOn As Boolean = False
		For Each slotKey As String In current.Keys
			If ("" & current.Get(slotKey)) = playerIn Then
				alreadyOn = True
				Exit
			End If
		Next
		If alreadyOn = False Then current.Put(slot, playerIn)
	Next
	current = modSubPlanner.ApplyMovesToLineup(current, moves, afterQ)
	Return current
End Sub

Private Sub LineupForQuarter(q As Int) As Map
	Dim lineup As Map = CurrentLineup
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	Dim byQ As Map = modSubPlanner.LineupsByQuarter(lineup, swaps, MovesList)
	Dim key As String = "" & q
	If byQ.ContainsKey(key) Then Return byQ.Get(key)
	Return CopyMapLocal(lineup)
End Sub

Private Sub PlayTargetsMap As Map
	Dim t As Map = currentSubPlan.GetDefault("playTargets", EmptyMap)
	If t.IsInitialized = False Then
		t.Initialize
		currentSubPlan.Put("playTargets", t)
	End If
	Return t
End Sub

Private Sub TargetQuarters(pid As String) As Int
	Return modSubPlanner.TargetQuartersFor(PlayTargetsMap, pid)
End Sub

Private Sub FillSwapPickers
	Dim pitch As Map = PitchAtBreak(selectedAfterQuarter)
	Dim names As Map = NameByIdMap
	Dim onPitch As List = modSubPlanner.MemberIdsInSlots(pitch, CurrentFormation, names)
	onIds.Initialize
	Dim squad As List = ConfirmedSquad
	Dim i As Int
	For i = 0 To squad.Size - 1
		Dim mem As Map = squad.Get(i)
		Dim sid As String = "" & mem.Get("id")
		If sid <> "" And onPitch.IndexOf(sid) = -1 Then onIds.Add(sid)
	Next
	' Sort: off = most planned minutes first; on = fewest first
	offIds = SortIdsByProjected(onPitch, True)
	onIds = SortIdsByProjected(onIds, False)
	
	If selectedOffId = "" Or offIds.IndexOf(selectedOffId) < 0 Then
		If offIds.Size > 0 Then selectedOffId = offIds.Get(0) Else selectedOffId = ""
	End If
	If selectedOnId = "" Or onIds.IndexOf(selectedOnId) < 0 Then
		If onIds.Size > 0 Then selectedOnId = onIds.Get(0) Else selectedOnId = ""
	End If
End Sub

Private Sub SortIdsByProjected(ids As List, descending As Boolean) As List
	Dim out As List
	out.Initialize
	Dim i As Int
	For i = 0 To ids.Size - 1
		out.Add(ids.Get(i))
	Next
	Dim a, b As Int
	For a = 0 To out.Size - 2
		For b = a + 1 To out.Size - 1
			Dim idA As String = out.Get(a)
			Dim idB As String = out.Get(b)
			Dim mA As Int = projectedCache.GetDefault(idA, 0)
			Dim mB As Int = projectedCache.GetDefault(idB, 0)
			Dim swapThem As Boolean
			If descending Then
				swapThem = mB > mA
			Else
				swapThem = mB < mA
			End If
			If swapThem Then
				out.Set(a, idB)
				out.Set(b, idA)
			End If
		Next
	Next
	Return out
End Sub

Private Sub RefreshPickerButtons
	btnQuarter.Text = "Q" & selectedAfterQuarter
	Dim names As Map = NameByIdMap
	If selectedOffId = "" Then
		btnOff.Text = "Off…"
	Else
		btnOff.Text = PickerShortLabel(selectedOffId, names)
	End If
	If selectedOnId = "" Then
		btnOn.Text = "On…"
	Else
		btnOn.Text = PickerShortLabel(selectedOnId, names)
	End If
	If editingSwapIndex >= 0 Then
		btnAdd.Text = "Save"
		btnAdd.Color = modConfig.COLOR_ACCENT
	Else
		btnAdd.Text = "Add"
		btnAdd.Color = modConfig.COLOR_SUCCESS
	End If
End Sub

Private Sub PickerShortLabel(pid As String, names As Map) As String
	Dim mins As Int = projectedCache.GetDefault(pid, 0)
	Return FirstName(names.GetDefault(pid, "?")) & " " & mins & "'"
End Sub

Private Sub PickerFullLabel(pid As String, names As Map) As String
	Dim mins As Int = projectedCache.GetDefault(pid, 0)
	Dim tgt As Int = TargetQuarters(pid)
	Return names.GetDefault(pid, "?") & "  ·  " & mins & "' plan  ·  target " & tgt & "Q"
End Sub

Private Sub FirstName(full As String) As String
	Dim n As String = full.Trim
	If n = "" Then Return "?"
	Dim parts() As String = Regex.Split("\s+", n)
	Return parts(0)
End Sub

Private Sub btnQuarter_Click
	Dim opts As List
	opts.Initialize
	opts.AddAll(Array As String("After Q1", "After Q2", "After Q3"))
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	tmpl.SelectedItem = opts.Get(selectedAfterQuarter - 1)
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim idx As Int = opts.IndexOf(tmpl.SelectedItem)
	If idx < 0 Then Return
	selectedAfterQuarter = idx + 1
	selectedOffId = ""
	selectedOnId = ""
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub SelectBreak(breakQ As Int)
	If breakQ < 1 Or breakQ > 3 Then Return
	If selectedAfterQuarter = breakQ Then Return
	selectedAfterQuarter = breakQ
	selectedOffId = ""
	selectedOnId = ""
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
	ToastMessageShow("Planning after Q" & breakQ, False)
End Sub

Private Sub btnOff_Click
	If offIds.Size = 0 Then
		ToastMessageShow("No one on the pitch for this break", False)
		Return
	End If
	Wait For (PickPlayerId(offIds, selectedOffId, "Player off")) Complete (sel As String)
	If sel = "__cancel__" Then Return
	selectedOffId = sel
	RefreshPickerButtons
End Sub

Private Sub btnOn_Click
	If onIds.Size = 0 Then
		ToastMessageShow("No bench players available", False)
		Return
	End If
	Wait For (PickPlayerId(onIds, selectedOnId, "Player on")) Complete (sel As String)
	If sel = "__cancel__" Then Return
	selectedOnId = sel
	RefreshPickerButtons
End Sub

Private Sub PickPlayerId(ids As List, currentId As String, title As String) As ResumableSub
	Dim names As Map = NameByIdMap
	Dim opts As List
	opts.Initialize
	Dim i As Int
	For i = 0 To ids.Size - 1
		opts.Add(PickerFullLabel(ids.Get(i), names))
	Next
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	Dim curIdx As Int = ids.IndexOf(currentId)
	If curIdx >= 0 Then tmpl.SelectedItem = opts.Get(curIdx)
	dialog.Title = title
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return "__cancel__"
	Dim selIdx As Int = opts.IndexOf(tmpl.SelectedItem)
	If selIdx < 0 Then Return "__cancel__"
	Return ids.Get(selIdx)
End Sub

Private Sub ShowPlan
	clv.Clear
	pitchPanels.Clear
	Dim cardW As Int = Root.Width - 24dip
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	currentSubPlan.Put("matchMinutes", duration)
	RefreshProjected
	
	Dim qMins As Int = Round(duration / 4)
	Dim halfMins As Int = Round(duration / 2)
	Dim hdr As Panel = modUI.CreateSimpleRowThemed(cardW, _
		duration & " mins · 4 × " & qMins & "' · half ≈ " & halfMins & "'", "", True)
	hdr.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
	clv.Add(hdr, "")
	
	Dim lineup As Map = CurrentLineup
	Dim names As Map = NameByIdMap
	
	' --- Lineup by quarter (4 pitch diagrams) ---
	Dim xiHdr As Panel = modUI.CreateSectionHeaderThemed(cardW, "LINEUP BY QUARTER", True)
	xiHdr.SetLayout(0, 0, cardW, modUI.SectionHeaderHeight)
	clv.Add(xiHdr, "")
	If lineup.Size = 0 Then
		Dim needXi As Panel = modUI.CreateSimpleRowThemed(cardW, "Set a lineup to preview quarters.", "", True)
		needXi.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(needXi, "")
	Else
		Dim formation As String = CurrentFormation
		Dim pitchH As Int = modUI.CompactPitchHeight(cardW)
		Dim allSwaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
		Dim allMoves As List = MovesList
		Dim pitchLayout As Map = LayoutMap
		Dim q As Int
		For q = 1 To 4
			Dim title As String
			Dim breakQ As Int
			Dim selected As Boolean
			If q = 1 Then
				title = "Kick-off (Q1)"
				breakQ = 0
				selected = False
			Else
				breakQ = q - 1
				title = "After Q" & breakQ & "  ·  tap to plan this break"
				selected = (selectedAfterQuarter = breakQ)
			End If
			If selected Then title = "After Q" & breakQ & "  ·  planning this break"
			Dim titleRow As Panel = modUI.CreateSimpleRowThemed(cardW, title, "", True)
			titleRow.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
			If breakQ > 0 Then
				clv.Add(titleRow, "break:" & breakQ)
			Else
				clv.Add(titleRow, "")
			End If
			Dim xi As Map = LineupForQuarter(q)
			Dim holdId As String = ""
			If q = holdQuarter Then holdId = holdSlotId
			Dim pitchPanel As Panel = modUI.CreatePitchPanel(cardW, pitchH, formation, xi, names, projectedCache, selected, _
				pitchLayout, Me, "pitchSlot", q, holdId)
			pitchPanel.SetLayout(0, 0, cardW, pitchH)
			pitchPanels.Add(pitchPanel)
			If breakQ > 0 Then
				clv.Add(pitchPanel, "break:" & breakQ)
			Else
				clv.Add(pitchPanel, "")
			End If
			' Swaps that produce this XI (breaks after Q1/Q2/Q3 only)
			If breakQ > 0 Then
				Dim anySwap As Boolean = False
				Dim si As Int
				For si = 0 To allSwaps.Size - 1
					Dim s As Map = allSwaps.Get(si)
					If breakQ <> s.GetDefault("afterQuarter", 0) Then Continue
					anySwap = True
					Dim outN As String = s.GetDefault("outName", names.GetDefault(s.GetDefault("playerOut", ""), "?"))
					Dim inN As String = s.GetDefault("inName", names.GetDefault(s.GetDefault("playerIn", ""), "?"))
					Dim label2 As String = outN & " → " & inN
					Dim row As Panel = BuildSwapRow(cardW, label2, si)
					row.SetLayout(0, 0, cardW, 52dip)
					clv.Add(row, "swap:" & si)
				Next
				Dim anyMove As Boolean = False
				Dim mi As Int
				For mi = 0 To allMoves.Size - 1
					Dim rawMv As Object = allMoves.Get(mi)
					If Not(rawMv Is Map) Then Continue
					Dim mv As Map = rawMv
					If breakQ <> mv.GetDefault("afterQuarter", 0) Then Continue
					anyMove = True
					Dim moveRow As Panel = BuildMoveRow(cardW, MoveCaption(mv), mi)
					moveRow.SetLayout(0, 0, cardW, 52dip)
					clv.Add(moveRow, "move:" & mi)
				Next
				If anySwap = False And anyMove = False Then
					Dim noneAt As Panel = modUI.CreateSimpleRowThemed(cardW, "No swaps after Q" & breakQ & " yet", "", True)
					noneAt.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
					clv.Add(noneAt, "break:" & breakQ)
				End If
			End If
		Next
	End If
	
	Dim autoFlag As Boolean = currentSubPlan.GetDefault("autoGenerated", False)
	If autoFlag Then
		Dim autoNote As Panel = modUI.CreateSimpleRowThemed(cardW, "Auto fair plan — edit swaps under each pitch", "", True)
		autoNote.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(autoNote, "")
	End If
	
	Dim minsHdr As Panel = modUI.CreateSectionHeaderThemed(cardW, "PLAYING TIME (tap target)", True)
	minsHdr.SetLayout(0, 0, cardW, modUI.SectionHeaderHeight)
	clv.Add(minsHdr, "")
	
	If lineup.Size = 0 Then
		Dim need As Panel = modUI.CreateSimpleRowThemed(cardW, "Set a lineup to see minutes.", "", True)
		need.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(need, "")
		Return
	End If
	
	Dim squadIds As List = SquadIdsList
	Dim clubId As String = match.GetDefault("clubId", "")
	Dim status As String = match.GetDefault("status", "")
	Dim actualMins As Map
	actualMins.Initialize
	Dim showPlayed As Boolean = False
	If status = "LIVE" Or status = "COMPLETED" Then
		actualMins = modAppState.CalculateMatchMinutes(match)
		showPlayed = actualMins.IsInitialized And actualMins.Size > 0
	End If
	Dim j As Int
	For j = 0 To squadIds.Size - 1
		Dim pid2 As String = squadIds.Get(j)
		Dim matchMins As Int = projectedCache.GetDefault(pid2, 0)
		Dim gameWord As String = "plan"
		If showPlayed Then
			Try
				matchMins = actualMins.GetDefault(pid2, 0)
			Catch
				matchMins = 0
			End Try
			gameWord = "played"
		End If
		Dim seasonMins As Int = modSubPlanner.SeasonMinutesForPlayer(clubId, pid2, modAppState.Matches)
		Dim tgtQ As Int = TargetQuarters(pid2)
		Dim tgtMins As Int = Round(tgtQ * (duration / 4.0))
		Dim rowM As Panel = BuildMinutesTargetRow(cardW, names.GetDefault(pid2, "?"), matchMins, seasonMins, tgtQ, tgtMins, gameWord)
		rowM.SetLayout(0, 0, cardW, 48dip)
		clv.Add(rowM, "target:" & pid2)
	Next
End Sub

Private Sub BuildMinutesTargetRow(Width As Int, name As String, matchMins As Int, seasonMins As Int, tgtQ As Int, tgtMins As Int, gameWord As String) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Background = modUI.RoundedBg(modConfig.COLOR_DARK_CARD, 10dip)
	
	Dim below As Boolean = matchMins < tgtMins
	Dim nameCol As Int = modConfig.COLOR_DARK_TEXT
	If below Then nameCol = 0xFFFBBF24
	
	Dim lblN As Label
	lblN.Initialize("")
	lblN.Text = name
	lblN.TextSize = 13
	lblN.TextColor = nameCol
	lblN.Typeface = Typeface.DEFAULT_BOLD
	lblN.SingleLine = True
	p.AddView(lblN, 12dip, 6dip, Width * 0.40, 20dip)
	
	Dim lblT As Label
	lblT.Initialize("")
	lblT.Text = "target " & tgtQ & "Q (~" & tgtMins & "')"
	lblT.TextSize = 11
	lblT.TextColor = modConfig.COLOR_DARK_MUTED
	p.AddView(lblT, 12dip, 26dip, Width * 0.40, 16dip)
	
	Dim lblM As Label
	lblM.Initialize("")
	lblM.Text = matchMins & "' " & gameWord
	lblM.TextSize = 12
	lblM.TextColor = modConfig.COLOR_ACCENT
	lblM.Gravity = Gravity.CENTER
	p.AddView(lblM, Width * 0.42, 12dip, Width * 0.28, 24dip)
	
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = seasonMins & "' season"
	lblS.TextSize = 12
	lblS.TextColor = modConfig.COLOR_DARK_MUTED
	lblS.Gravity = Gravity.CENTER
	p.AddView(lblS, Width * 0.70, 12dip, Width * 0.28 - 8dip, 24dip)
	Return p
End Sub

Private Sub BuildSwapRow(Width As Int, text As String, swapIndex As Int) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Background = modUI.RoundedBg(modConfig.COLOR_DARK_CARD, 12dip)
	
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 13
	lbl.TextColor = modConfig.COLOR_DARK_TEXT
	lbl.SingleLine = True
	lbl.Gravity = Gravity.CENTER_VERTICAL
	p.AddView(lbl, 12dip, 0, Width - 120dip, 52dip)
	
	Dim btnEdit As Button
	btnEdit.Initialize("btnEditSwap")
	btnEdit.Text = "Edit"
	btnEdit.TextSize = 11
	btnEdit.Typeface = Typeface.DEFAULT_BOLD
	btnEdit.Color = modConfig.COLOR_DARK_CHIP
	btnEdit.TextColor = modConfig.COLOR_DARK_TEXT
	btnEdit.Tag = swapIndex
	p.AddView(btnEdit, Width - 108dip, 10dip, 48dip, 32dip)
	
	Dim btnDel As Button
	btnDel.Initialize("btnDelSwap")
	btnDel.Text = "Del"
	btnDel.TextSize = 11
	btnDel.Typeface = Typeface.DEFAULT_BOLD
	btnDel.Color = modConfig.COLOR_DANGER
	btnDel.TextColor = Colors.White
	btnDel.Tag = swapIndex
	p.AddView(btnDel, Width - 54dip, 10dip, 42dip, 32dip)
	Return p
End Sub

Private Sub BuildMoveRow(Width As Int, text As String, moveIndex As Int) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Background = modUI.RoundedBg(modConfig.COLOR_DARK_CARD, 12dip)
	
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 13
	lbl.TextColor = modConfig.COLOR_DARK_TEXT
	lbl.SingleLine = True
	lbl.Gravity = Gravity.CENTER_VERTICAL
	p.AddView(lbl, 12dip, 0, Width - 70dip, 52dip)
	
	Dim btnDel As Button
	btnDel.Initialize("btnDelMove")
	btnDel.Text = "Del"
	btnDel.TextSize = 11
	btnDel.Typeface = Typeface.DEFAULT_BOLD
	btnDel.Color = modConfig.COLOR_DANGER
	btnDel.TextColor = Colors.White
	btnDel.Tag = moveIndex
	p.AddView(btnDel, Width - 54dip, 10dip, 42dip, 32dip)
	Return p
End Sub

Private Sub btnDelMove_Click
	Dim b As Button = Sender
	Dim idx As Int = b.Tag
	Dim moves As List = MovesList
	If idx < 0 Or idx >= moves.Size Then Return
	moves.RemoveAt(idx)
	currentSubPlan.Put("moves", moves)
	currentSubPlan.Put("autoGenerated", False)
	RefreshProjected
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	Dim key As String = "" & Value
	If key.StartsWith("break:") Then
		Dim bq As Int = 0
		Try
			bq = key.SubString(6)
		Catch
			bq = 0
		End Try
		SelectBreak(bq)
		Return
	End If
	If key.StartsWith("target:") = False Then Return
	Dim pid As String = key.SubString(7)
	If pid = "" Then Return
	Dim targets As Map = PlayTargetsMap
	Dim cur As Int = TargetQuarters(pid)
	Dim nextQ As Int = cur + 1
	If nextQ > 4 Then nextQ = 1
	targets.Put(pid, nextQ)
	currentSubPlan.Put("playTargets", targets)
	currentSubPlan.Put("autoGenerated", False)
	Dim names As Map = NameByIdMap
	ToastMessageShow(FirstName(names.GetDefault(pid, "?")) & " → target " & nextQ & "Q", False)
	ShowPlan
End Sub

Private Sub btnEditSwap_Click
	Dim b As Button = Sender
	Dim idx As Int = b.Tag
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	If idx < 0 Or idx >= swaps.Size Then Return
	Dim s As Map = swaps.Get(idx)
	editingSwapIndex = idx
	selectedAfterQuarter = s.GetDefault("afterQuarter", 1)
	If selectedAfterQuarter < 1 Or selectedAfterQuarter > 3 Then selectedAfterQuarter = 1
	selectedOffId = s.GetDefault("playerOut", "")
	selectedOnId = s.GetDefault("playerIn", "")
	RefreshProjected
	FillSwapPickers
	If selectedOffId <> "" And offIds.IndexOf(selectedOffId) < 0 Then offIds.InsertAt(0, selectedOffId)
	If selectedOnId <> "" And onIds.IndexOf(selectedOnId) < 0 Then onIds.InsertAt(0, selectedOnId)
	RefreshPickerButtons
	ToastMessageShow("Editing swap — change pickers, then Save", False)
End Sub

Private Sub btnDelSwap_Click
	Dim b As Button = Sender
	Dim idx As Int = b.Tag
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	If idx < 0 Or idx >= swaps.Size Then Return
	swaps.RemoveAt(idx)
	currentSubPlan.Put("swaps", swaps)
	currentSubPlan.Put("autoGenerated", False)
	If editingSwapIndex = idx Then
		editingSwapIndex = -1
	Else If editingSwapIndex > idx Then
		editingSwapIndex = editingSwapIndex - 1
	End If
	selectedOffId = ""
	selectedOnId = ""
	RefreshProjected
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub btnAddSwap_Click
	If selectedOffId = "" Or selectedOnId = "" Then
		ToastMessageShow("Need a player off and a player on", False)
		Return
	End If
	If selectedOffId = selectedOnId Then
		ToastMessageShow("Pick different players", False)
		Return
	End If
	' Validate against live pitch at this break
	Dim pitch As Map = PitchAtBreak(selectedAfterQuarter)
	Dim onPitchIds As List = modSubPlanner.MemberIdsInSlots(pitch, CurrentFormation, NameByIdMap)
	Dim onPitch As Boolean = onPitchIds.IndexOf(selectedOffId) >= 0
	Dim inAlready As Boolean = onPitchIds.IndexOf(selectedOnId) >= 0
	If onPitch = False Then
		ToastMessageShow("That player is not on the pitch for this break", False)
		RefreshProjected
		FillSwapPickers
		RefreshPickerButtons
		Return
	End If
	If inAlready Then
		ToastMessageShow("That player is already on the pitch", False)
		RefreshProjected
		FillSwapPickers
		RefreshPickerButtons
		Return
	End If
	
	Dim names As Map = NameByIdMap
	Dim swap As Map
	swap.Initialize
	swap.Put("afterQuarter", selectedAfterQuarter)
	swap.Put("playerOut", selectedOffId)
	swap.Put("playerIn", selectedOnId)
	swap.Put("outName", names.GetDefault(selectedOffId, "?"))
	swap.Put("inName", names.GetDefault(selectedOnId, "?"))
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	If editingSwapIndex >= 0 And editingSwapIndex < swaps.Size Then
		swaps.Set(editingSwapIndex, swap)
		editingSwapIndex = -1
	Else
		swaps.Add(swap)
	End If
	currentSubPlan.Put("swaps", swaps)
	currentSubPlan.Put("autoGenerated", False)
	' Clear so next pick reflects updated pitch/bench immediately
	selectedOffId = ""
	selectedOnId = ""
	RefreshProjected
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub btnFair_Click
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	Dim lineup As Map = CurrentLineup
	If lineup.Size = 0 Then
		ToastMessageShow("Set a lineup first", False)
		Return
	End If
	If ConfirmedSquad.Size = 0 Then
		ToastMessageShow("Confirm squad players first", False)
		Return
	End If
	Dim targets As Map = PlayTargetsMap
	Dim keepLayout As Map = CopyMapLocal(LayoutMap)
	currentSubPlan = modSubPlanner.BuildFairQuarterPlanWithTargets(ConfirmedSquad, lineup, NameByIdMap, duration, 2, targets, CurrentFormation)
	currentSubPlan.Put("layout", keepLayout)
	editingSwapIndex = -1
	selectedOffId = ""
	selectedOnId = ""
	RefreshProjected
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub btnClear_Click
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	Dim keepTargets As Map = CopyMapLocal(PlayTargetsMap)
	Dim keepLayout As Map = CopyMapLocal(LayoutMap)
	currentSubPlan = modSubPlanner.EmptyPlan(duration)
	currentSubPlan.Put("playTargets", keepTargets)
	currentSubPlan.Put("layout", keepLayout)
	editingSwapIndex = -1
	selectedOffId = ""
	selectedOnId = ""
	RefreshProjected
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub btnSave_Click
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	If currentSubPlan.IsInitialized = False Then currentSubPlan = modSubPlanner.EmptyPlan(duration)
	currentSubPlan.Put("matchMinutes", duration)
	If currentSubPlan.ContainsKey("swaps") = False Then
		Dim swaps As List
		swaps.Initialize
		currentSubPlan.Put("swaps", swaps)
	End If
	If currentSubPlan.ContainsKey("playTargets") = False Then
		currentSubPlan.Put("playTargets", EmptyMap)
	End If
	currentSubPlan.Put("moves", MovesList)
	currentSubPlan.Put("layout", LayoutMap)
	RefreshProjected
	match.Put("lineup", CurrentLineup)
	match.Put("tacticalLineup", CurrentLineup)
	match.Put("subPlan", currentSubPlan)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	ToastMessageShow("Sub plan saved", False)
End Sub

Private Sub btnBack_Click
	btnSave_Click
	B4XPages.ShowPage("MatchHub")
End Sub

Private Sub MovesList As List
	Dim raw As Object = currentSubPlan.GetDefault("moves", Null)
	If raw Is List Then
		Dim existing As List = raw
		If existing.IsInitialized Then Return existing
	End If
	Dim moves As List
	moves.Initialize
	currentSubPlan.Put("moves", moves)
	Return moves
End Sub

Private Sub LayoutMap As Map
	Dim raw As Object = currentSubPlan.GetDefault("layout", Null)
	If raw Is Map Then
		Dim existing As Map = raw
		If existing.IsInitialized Then Return existing
	End If
	Dim layout As Map
	layout.Initialize
	currentSubPlan.Put("layout", layout)
	Return layout
End Sub

Private Sub MoveCaption(mv As Map) As String
	Dim a As String = "" & mv.GetDefault("nameA", mv.GetDefault("slotA", "?"))
	Dim b As String = "" & mv.GetDefault("nameB", mv.GetDefault("slotB", "?"))
	Return a & " ↔ " & b
End Sub

Private Sub SlotLabel(slotId As String) As String
	Dim positions As List = modFormations.GetPositions(CurrentFormation)
	Dim i As Int
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		If ("" & p.GetDefault("id", "")) = slotId Then Return "" & p.GetDefault("label", slotId)
	Next
	Return slotId
End Sub

Private Sub OccupantLabel(xi As Map, slotId As String, names As Map) As String
	Dim pid As String = ""
	If xi.IsInitialized Then pid = "" & xi.GetDefault(slotId, "")
	If pid <> "" And pid <> "null" Then
		Dim nm As String = "" & names.GetDefault(pid, "")
		If nm <> "" Then Return FirstName(nm)
	End If
	Return SlotLabel(slotId)
End Sub

' Hold one spot, then another, to exchange them. The marker's tag carries slotId and quarter.
Private Sub pitchSlot_LongClick As Boolean
	Dim hit As Panel = Sender
	If Not(hit.Tag Is Map) Then Return True
	Dim info As Map = hit.Tag
	Dim slotId As String = "" & info.GetDefault("slotId", "")
	Dim quarter As Int = info.GetDefault("quarter", 1)
	If slotId = "" Then Return True
	If holdSlotId = "" Or quarter <> holdQuarter Then
		holdSlotId = slotId
		holdQuarter = quarter
		ToastMessageShow("Long-press another spot to swap", False)
		CallSubDelayed(Me, "ShowPlan")
		Return True
	End If
	If slotId = holdSlotId Then
		holdSlotId = ""
		holdQuarter = 0
		ToastMessageShow("Swap cancelled", False)
		CallSubDelayed(Me, "ShowPlan")
		Return True
	End If
	If SwapSlots(holdSlotId, slotId, quarter) = False Then
		ToastMessageShow("Nothing to swap", False)
		Return True
	End If
	holdSlotId = ""
	holdQuarter = 0
	CallSubDelayed(Me, "RefreshAfterSwap")
	Return True
End Sub

Private Sub RefreshAfterSwap
	RefreshProjected
	FillSwapPickers
	RefreshPickerButtons
	ShowPlan
End Sub

Private Sub SwapSlots(slotA As String, slotB As String, quarter As Int) As Boolean
	Dim xi As Map = LineupForQuarter(quarter)
	Dim idA As String = "" & xi.GetDefault(slotA, "")
	Dim idB As String = "" & xi.GetDefault(slotB, "")
	If (idA = "" Or idA = "null") And (idB = "" Or idB = "null") Then Return False
	If quarter <= 1 Then
		Dim lineup As Map = CurrentLineup
		modSubPlanner.ExchangeSlots(lineup, slotA, slotB)
		match.Put("lineup", lineup)
		match.Put("tacticalLineup", lineup)
		ToastMessageShow("Positions swapped", False)
		Return True
	End If
	Dim names As Map = NameByIdMap
	Dim mv As Map
	mv.Initialize
	mv.Put("afterQuarter", quarter - 1)
	mv.Put("slotA", slotA)
	mv.Put("slotB", slotB)
	mv.Put("nameA", OccupantLabel(xi, slotA, names))
	mv.Put("nameB", OccupantLabel(xi, slotB, names))
	Dim moves As List = MovesList
	moves.Add(mv)
	currentSubPlan.Put("moves", moves)
	currentSubPlan.Put("autoGenerated", False)
	ToastMessageShow("Positions swapped", False)
	Return True
End Sub

