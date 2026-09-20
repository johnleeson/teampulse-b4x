B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Sub plan — manual players on/off each quarter + projected & season minutes.
Sub Class_Globals
	Private Root As B4XView
	Private edtDuration As EditText
	Private clv As CustomListView
	Private match As Map
	Private club As Map
	Private currentSubPlan As Map
	Private spnQuarter As Spinner
	Private spnOff As Spinner
	Private spnOn As Spinner
	Private offIds As List
	Private onIds As List
End Sub

Public Sub Initialize
	currentSubPlan.Initialize
	offIds.Initialize
	onIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
	FillSwapSpinners
	ShowPlan
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Sub plan", "btnBack", "btnSave", "✓", True)
	Dim top As Int = chrome.Get("ContentTop")
	
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = "Match minutes"
	lbl.TextSize = 12
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(lbl, 16dip, top, 120dip, 18dip)
	
	edtDuration.Initialize("")
	modUI.StyleEditText(edtDuration, "60")
	edtDuration.InputType = edtDuration.INPUT_TYPE_NUMBERS
	Root.AddView(edtDuration, 16dip, top + 20dip, 72dip, 40dip)
	
	Dim btnFair As Button
	btnFair.Initialize("btnFair")
	btnFair.Text = "Auto fair"
	btnFair.TextSize = 11
	btnFair.Color = 0xFF64748B
	btnFair.TextColor = Colors.White
	Root.AddView(btnFair, 96dip, top + 20dip, 88dip, 40dip)
	
	Dim btnClear As Button
	btnClear.Initialize("btnClear")
	btnClear.Text = "Clear"
	btnClear.TextSize = 11
	btnClear.Color = 0xFF475569
	btnClear.TextColor = Colors.White
	Root.AddView(btnClear, 192dip, top + 20dip, 72dip, 40dip)
	
	Dim lblQ As Label
	lblQ.Initialize("")
	lblQ.Text = "After quarter — player off — player on"
	lblQ.TextSize = 11
	lblQ.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(lblQ, 16dip, top + 68dip, Root.Width - 32dip, 18dip)
	
	spnQuarter.Initialize("spnQuarter")
	Root.AddView(spnQuarter, 16dip, top + 90dip, 72dip, 40dip)
	
	spnOff.Initialize("")
	Root.AddView(spnOff, 96dip, top + 90dip, (Root.Width - 200dip) / 2, 40dip)
	
	spnOn.Initialize("")
	Root.AddView(spnOn, 104dip + (Root.Width - 200dip) / 2, top + 90dip, (Root.Width - 200dip) / 2, 40dip)
	
	Dim btnAdd As Button
	btnAdd.Initialize("btnAddSwap")
	btnAdd.Text = "Add"
	btnAdd.TextSize = 12
	btnAdd.Color = modConfig.COLOR_ACCENT
	btnAdd.TextColor = Colors.White
	Root.AddView(btnAdd, Root.Width - 80dip, top + 90dip, 64dip, 40dip)
	
	Dim listTop As Int = top + 144dip
	clv = modUI.AddCustomListViewThemed(Root, 0, listTop, Root.Width, Root.Height - listTop, Me, "clv", True)
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
	edtDuration.Text = "" & currentSubPlan.GetDefault("matchMinutes", 60)
	spnQuarter.Clear
	spnQuarter.Add("Q1")
	spnQuarter.Add("Q2")
	spnQuarter.Add("Q3")
	spnQuarter.SelectedIndex = 0
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
		' Fall back to full club if nothing confirmed yet
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
		m.Put(mem.Get("id"), mem.GetDefault("name", "?"))
	Next
	Return m
End Sub

Private Sub CurrentLineup As Map
	Dim lineup As Map = match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMap))
	If lineup.IsInitialized = False Then lineup.Initialize
	Return lineup
End Sub

Private Sub SelectedAfterQuarter As Int
	Return spnQuarter.SelectedIndex + 1
End Sub

Private Sub LineupAfterQuarter(afterQ As Int) As Map
	Dim lineup As Map = CurrentLineup
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	Dim q As Int
	Dim current As Map = CopyMapLocal(lineup)
	For q = 1 To afterQ
		current = modSubPlanner.ApplySwapsToLineup(current, swaps, q)
	Next
	Return current
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

Private Sub FillSwapSpinners
	Dim afterQ As Int = SelectedAfterQuarter
	' Pitch before this break = lineup after previous swaps (through afterQ-1 applied... 
	' At break after quarter N, current pitch is lineup for quarter N = after applying swaps 1..N-1
	Dim pitch As Map
	If afterQ <= 1 Then
		pitch = CurrentLineup
	Else
		pitch = LineupAfterQuarter(afterQ - 1)
	End If
	
	offIds.Initialize
	onIds.Initialize
	spnOff.Clear
	spnOn.Clear
	
	Dim onPitch As List
	onPitch.Initialize
	For Each pid As String In pitch.Values
		If pid <> "" Then onPitch.Add(pid)
	Next
	
	Dim names As Map = NameByIdMap
	Dim i As Int
	For i = 0 To onPitch.Size - 1
		Dim idOff As String = onPitch.Get(i)
		spnOff.Add(names.GetDefault(idOff, "?"))
		offIds.Add(idOff)
	Next
	
	Dim squad As List = ConfirmedSquad
	For i = 0 To squad.Size - 1
		Dim mem As Map = squad.Get(i)
		Dim sid As String = mem.Get("id")
		If onPitch.IndexOf(sid) = -1 Then
			spnOn.Add(mem.GetDefault("name", "?"))
			onIds.Add(sid)
		End If
	Next
End Sub

Private Sub spnQuarter_ItemClick (Position As Int, Value As Object)
	FillSwapSpinners
End Sub

Private Sub ShowPlan
	clv.Clear
	Dim cardW As Int = Root.Width - 24dip
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	currentSubPlan.Put("matchMinutes", duration)
	
	Dim hdr As Panel = modUI.CreateSimpleRow(cardW, "Match " & duration & " mins · 4 quarters · " & _
		Round(duration / 4) & "' each", "")
	hdr.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
	clv.Add(hdr, "")
	
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	If swaps.Size = 0 Then
		Dim none As Panel = modUI.CreateSimpleRow(cardW, "No swaps yet — choose quarter, off, on, then Add.", "")
		none.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(none, "")
	End If
	Dim si As Int
	For si = 0 To swaps.Size - 1
		Dim s As Map = swaps.Get(si)
		Dim names As Map = NameByIdMap
		Dim label As String = "After Q" & s.GetDefault("afterQuarter", 0) & ": " & _
			s.GetDefault("outName", names.GetDefault(s.GetDefault("playerOut", ""), "?")) & " off → " & _
			s.GetDefault("inName", names.GetDefault(s.GetDefault("playerIn", ""), "?")) & " on"
		Dim row As Panel = BuildDeletableSwapRow(cardW, label, si)
		row.SetLayout(0, 0, cardW, 44dip)
		clv.Add(row, "del:" & si)
	Next
	
	Dim minsHdr As Panel = modUI.CreateSimpleRow(cardW, "Playing time (this game + season)", "")
	minsHdr.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
	clv.Add(minsHdr, "")
	
	Dim lineup As Map = CurrentLineup
	If lineup.Size = 0 Then
		Dim need As Panel = modUI.CreateSimpleRow(cardW, "Set a lineup to see minutes.", "")
		need.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(need, "")
		Return
	End If
	
	Dim squad As List = ConfirmedSquad
	Dim squadIds As List
	squadIds.Initialize
	Dim names2 As Map = NameByIdMap
	Dim j As Int
	For j = 0 To squad.Size - 1
		Dim m As Map = squad.Get(j)
		squadIds.Add(m.Get("id"))
	Next
	Dim projected As Map = modSubPlanner.ProjectMatchMinutes(lineup, currentSubPlan, squadIds)
	currentSubPlan.Put("projectedMinutes", projected)
	Dim clubId As String = match.GetDefault("clubId", "")
	For j = 0 To squadIds.Size - 1
		Dim pid As String = squadIds.Get(j)
		Dim matchMins As Int = projected.GetDefault(pid, 0)
		Dim seasonMins As Int = modSubPlanner.SeasonMinutesForPlayer(clubId, pid, modAppState.Matches)
		Dim rowM As Panel = modUI.CreateMinutesRow(cardW, names2.GetDefault(pid, "?"), matchMins, seasonMins)
		rowM.SetLayout(0, 0, cardW, modUI.MinutesRowHeight)
		clv.Add(rowM, "")
	Next
End Sub

Private Sub BuildDeletableSwapRow(Width As Int, text As String, swapIndex As Int) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Background = modUI.RoundedBg(modConfig.COLOR_CARD, 10dip)
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 12
	lbl.TextColor = modConfig.COLOR_PRIMARY
	lbl.SingleLine = True
	p.AddView(lbl, 10dip, 10dip, Width - 70dip, 24dip)
	Dim btn As Button
	btn.Initialize("btnDelSwap")
	btn.Text = "Del"
	btn.TextSize = 10
	btn.Color = modConfig.COLOR_DANGER
	btn.TextColor = Colors.White
	btn.Tag = swapIndex
	p.AddView(btn, Width - 56dip, 6dip, 44dip, 32dip)
	Return p
End Sub

Private Sub btnDelSwap_Click
	Dim b As Button = Sender
	Dim idx As Int = b.Tag
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	If idx < 0 Or idx >= swaps.Size Then Return
	swaps.RemoveAt(idx)
	currentSubPlan.Put("swaps", swaps)
	currentSubPlan.Put("autoGenerated", False)
	FillSwapSpinners
	ShowPlan
End Sub

Private Sub btnAddSwap_Click
	If offIds.Size = 0 Or onIds.Size = 0 Then
		ToastMessageShow("Need a player off and a player on", False)
		Return
	End If
	If spnOff.SelectedIndex < 0 Or spnOn.SelectedIndex < 0 Then
		ToastMessageShow("Select players off and on", False)
		Return
	End If
	Dim pOut As String = offIds.Get(spnOff.SelectedIndex)
	Dim pIn As String = onIds.Get(spnOn.SelectedIndex)
	If pOut = pIn Then
		ToastMessageShow("Pick different players", False)
		Return
	End If
	Dim names As Map = NameByIdMap
	Dim swap As Map
	swap.Initialize
	swap.Put("afterQuarter", SelectedAfterQuarter)
	swap.Put("playerOut", pOut)
	swap.Put("playerIn", pIn)
	swap.Put("outName", names.GetDefault(pOut, "?"))
	swap.Put("inName", names.GetDefault(pIn, "?"))
	Dim swaps As List = currentSubPlan.GetDefault("swaps", EmptyList)
	swaps.Add(swap)
	currentSubPlan.Put("swaps", swaps)
	currentSubPlan.Put("autoGenerated", False)
	FillSwapSpinners
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
	currentSubPlan = modSubPlanner.BuildFairQuarterPlan(ConfirmedSquad, lineup, NameByIdMap, duration, 2)
	FillSwapSpinners
	ShowPlan
End Sub

Private Sub btnClear_Click
	Dim duration As Int = edtDuration.Text
	If duration <= 0 Then duration = 60
	currentSubPlan = modSubPlanner.EmptyPlan(duration)
	FillSwapSpinners
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
	Dim lineup As Map = CurrentLineup
	If lineup.Size > 0 Then
		Dim squadIds As List
		squadIds.Initialize
		Dim squad As List = ConfirmedSquad
		Dim j As Int
		For j = 0 To squad.Size - 1
			Dim m As Map = squad.Get(j)
			squadIds.Add(m.Get("id"))
		Next
		currentSubPlan.Put("projectedMinutes", modSubPlanner.ProjectMatchMinutes(lineup, currentSubPlan, squadIds))
	End If
	match.Put("subPlan", currentSubPlan)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	ToastMessageShow("Sub plan saved", False)
End Sub

Private Sub btnBack_Click
	btnSave_Click
	B4XPages.ShowPage("MatchHub")
End Sub
