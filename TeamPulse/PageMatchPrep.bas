B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Pre-match: availability, formation, tactical lineup, sub plan.
Sub Class_Globals
	Private Root As B4XView
	Private lblTitle As Label
	Private spnFormation As Spinner
	Private clvSquad As CustomListView
	Private clvPlan As CustomListView
	Private pitch As Panel
	Private match As Map
	Private club As Map
	Private tacticalLineup As Map
	Private starIds As List
	Private weakerIds As List
	Private edtDuration As EditText
	Private edtInterval As EditText
End Sub

Public Sub Initialize
	tacticalLineup.Initialize
	starIds.Initialize
	weakerIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFFF8FAFC
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadMatch
	Refresh
End Sub

Private Sub BuildUI
	lblTitle.Initialize("")
	lblTitle.TextSize = 18
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.TextColor = modConfig.COLOR_PRIMARY
	Root.AddView(lblTitle, 8dip, 8dip, Root.Width - 160dip, 36dip)
	
	Dim btnLive As Button
	btnLive.Initialize("btnGoLive")
	btnLive.Text = "Go Live"
	btnLive.Color = modConfig.COLOR_DANGER
	btnLive.TextColor = Colors.White
	Root.AddView(btnLive, Root.Width - 148dip, 8dip, 72dip, 36dip)
	
	Dim btnBack As Button
	btnBack.Initialize("btnBack")
	btnBack.Text = "Back"
	Root.AddView(btnBack, Root.Width - 72dip, 8dip, 64dip, 36dip)
	
	spnFormation.Initialize("spnFormation")
	For Each n As String In modFormations.FormationNames
		spnFormation.Add(n)
	Next
	Root.AddView(spnFormation, 8dip, 48dip, Root.Width - 16dip, 40dip)
	
	pitch.Initialize("pitch")
	pitch.Color = modConfig.COLOR_PITCH
	Root.AddView(pitch, 8dip, 96dip, Root.Width - 16dip, 220dip)
	
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = "Tap player to toggle CONFIRMED · long-press = star"
	lblS.TextSize = 11
	lblS.TextColor = modConfig.COLOR_MUTED
	Root.AddView(lblS, 8dip, 320dip, Root.Width - 16dip, 24dip)
	
	clvSquad.Initialize(Me, "clvSquad")
	Root.AddView(clvSquad.AsView, 0, 344dip, Root.Width, 140dip)
	
	edtDuration.Initialize("")
	edtDuration.Text = "60"
	edtDuration.Hint = "Mins"
	Root.AddView(edtDuration, 8dip, 492dip, 80dip, 40dip)
	
	edtInterval.Initialize("")
	edtInterval.Text = "15"
	edtInterval.Hint = "Sub every"
	Root.AddView(edtInterval, 96dip, 492dip, 80dip, 40dip)
	
	Dim btnPlan As Button
	btnPlan.Initialize("btnPlan")
	btnPlan.Text = "Build sub plan"
	btnPlan.Color = modConfig.COLOR_ACCENT
	btnPlan.TextColor = Colors.White
	Root.AddView(btnPlan, 184dip, 492dip, Root.Width - 192dip, 40dip)
	
	Dim btnSave As Button
	btnSave.Initialize("btnSave")
	btnSave.Text = "Save lineup"
	btnSave.Color = modConfig.COLOR_SUCCESS
	btnSave.TextColor = Colors.White
	Root.AddView(btnSave, 8dip, 540dip, Root.Width - 16dip, 44dip)
	
	clvPlan.Initialize(Me, "clvPlan")
	Root.AddView(clvPlan.AsView, 0, 592dip, Root.Width, Root.Height - 600dip)
End Sub

Private Sub LoadMatch
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", modAppState.SelectedClubId))
	lblTitle.Text = match.GetDefault("title", "Match prep")
	tacticalLineup = match.GetDefault("tacticalLineup", EmptyMap)
	If tacticalLineup.IsInitialized = False Then tacticalLineup.Initialize
	starIds = CopyStrList(match.GetDefault("starPlayerIds", EmptyList))
	weakerIds = CopyStrList(match.GetDefault("weakerPlayerIds", EmptyList))
	Dim formation As String = match.GetDefault("formation", modFormations.DefaultFormationForClubType(club.GetDefault("type", "TEAM")))
	Dim names As List = modFormations.FormationNames
	Dim idx As Int = names.IndexOf(formation)
	If idx < 0 Then idx = 0
	spnFormation.SelectedIndex = idx
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

Private Sub CopyStrList(src As Object) As List
	Dim out As List
	out.Initialize
	If src Is List Then
		For Each o As Object In src
			out.Add(o)
		Next
	End If
	Return out
End Sub

Public Sub Refresh
	DrawPitch
	clvSquad.Clear
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	For Each mem As Map In members
		Dim id As String = mem.GetDefault("id", "")
		Dim av As String = availability.GetDefault(id, "UNKNOWN")
		Dim tags As String = ""
		If starIds.IndexOf(id) > -1 Then tags = tags & " ★"
		If weakerIds.IndexOf(id) > -1 Then tags = tags & " ☆"
		clvSquad.AddTextItem(mem.GetDefault("name", "") & " [" & av & "]" & tags, id)
	Next
End Sub

Private Sub DrawPitch
	pitch.RemoveAllViews
	Dim formation As String = spnFormation.SelectedItem
	Dim positions As List = modFormations.GetPositions(formation)
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim nameById As Map
	nameById.Initialize
	For Each mem As Map In members
		nameById.Put(mem.Get("id"), mem.GetDefault("name", "?"))
	Next
	For Each p As Map In positions
		Dim pid As String = p.Get("id")
		Dim xPct As Float = p.Get("x")
		Dim yPct As Float = p.Get("y")
		Dim w As Int = 56dip
		Dim h As Int = 40dip
		Dim left As Int = (pitch.Width - w) * xPct / 100
		Dim top As Int = (pitch.Height - h) * yPct / 100
		Dim b As Button
		b.Initialize("pos")
		Dim playerId As String = tacticalLineup.GetDefault(pid, "")
		If playerId = "" Then
			b.Text = p.Get("label")
			b.Color = 0x66FFFFFF
		Else
			b.Text = nameById.GetDefault(playerId, p.Get("label"))
			b.Color = Colors.White
		End If
		b.TextSize = 9
		b.Tag = pid
		b.TextColor = modConfig.COLOR_PRIMARY
		pitch.AddView(b, left, top, w, h)
	Next
End Sub

Private Sub pos_Click
	Dim b As Button = Sender
	Dim posId As String = b.Tag
	' Cycle: assign next confirmed player not already on pitch
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim used As Map
	used.Initialize
	For Each k As String In tacticalLineup.Keys
		used.Put(tacticalLineup.Get(k), True)
	Next
	Dim current As String = tacticalLineup.GetDefault(posId, "")
	If current <> "" Then
		tacticalLineup.Remove(posId)
		DrawPitch
		Return
	End If
	For Each mem As Map In members
		Dim id As String = mem.Get("id")
		If availability.GetDefault(id, "") <> "CONFIRMED" Then Continue
		If used.ContainsKey(id) Then Continue
		tacticalLineup.Put(posId, id)
		DrawPitch
		Return
	Next
	ToastMessageShow("Confirm players in squad first", False)
End Sub

Private Sub clvSquad_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	Dim id As String = Value
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	If availability.IsInitialized = False Then availability.Initialize
	Dim cur As String = availability.GetDefault(id, "UNKNOWN")
	If cur = "CONFIRMED" Then
		availability.Put(id, "UNAVAILABLE")
	Else
		availability.Put(id, "CONFIRMED")
	End If
	match.Put("availability", availability)
	' Keep signedUp in sync
	Dim signed As List
	signed.Initialize
	For Each k As String In availability.Keys
		If availability.Get(k) = "CONFIRMED" Then signed.Add(k)
	Next
	match.Put("signedUpPlayerIds", signed)
	Refresh
End Sub

Private Sub clvSquad_ItemLongClick (Index As Int, Value As Object)
	If Value = "" Then Return
	Dim id As String = Value
	Dim idx As Int = starIds.IndexOf(id)
	If idx > -1 Then
		starIds.RemoveAt(idx)
	Else
		starIds.Add(id)
	End If
	Refresh
End Sub

Private Sub spnFormation_ItemClick (Position As Int, Value As Object)
	DrawPitch
End Sub

Private Sub ConfirmedSquad As List
	Dim out As List
	out.Initialize
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	Dim members As List = club.GetDefault("members", EmptyList)
	For Each mem As Map In members
		If availability.GetDefault(mem.Get("id"), "") = "CONFIRMED" Then out.Add(mem)
	Next
	Return out
End Sub

Private Sub btnPlan_Click
	clvPlan.Clear
	Dim duration As Int = edtDuration.Text
	Dim interval As Int = edtInterval.Text
	Dim plan As Map = modSubPlanner.BuildPlan(ConfirmedSquad, tacticalLineup, spnFormation.SelectedItem, _
		starIds, weakerIds, duration, interval, 2)
	If plan.ContainsKey("error") Then
		clvPlan.AddTextItem(plan.Get("error"), "")
		Return
	End If
	Dim events As List = plan.Get("events")
	If events.Size = 0 Then
		clvPlan.AddTextItem("No substitution events needed.", "")
		Return
	End If
	For Each evt As Map In events
		Dim line As String = "Min " & evt.Get("minute") & ": "
		Dim subs As List = evt.Get("subs")
		For Each s As Map In subs
			line = line & "↓" & s.Get("outName") & " ↑" & s.Get("inName") & "  "
		Next
		clvPlan.AddTextItem(line, "")
	Next
End Sub

Private Sub btnSave_Click
	Dim starting As List
	starting.Initialize
	For Each k As String In tacticalLineup.Keys
		Dim pid As String = tacticalLineup.Get(k)
		If pid <> "" Then starting.Add(pid)
	Next
	Dim bench As List
	bench.Initialize
	For Each mem As Map In ConfirmedSquad
		Dim id As String = mem.Get("id")
		If starting.IndexOf(id) = -1 Then bench.Add(id)
	Next
	match.Put("formation", spnFormation.SelectedItem)
	match.Put("tacticalLineup", tacticalLineup)
	match.Put("startingLineupIds", starting)
	match.Put("benchIds", bench)
	match.Put("starPlayerIds", starIds)
	match.Put("weakerPlayerIds", weakerIds)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	ToastMessageShow("Lineup saved", False)
End Sub

Private Sub btnGoLive_Click
	btnSave_Click
	match.Put("status", "LIVE")
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	' Add START event
	Dim ev As Map
	ev.Initialize
	ev.Put("id", modAppState.NewId)
	ev.Put("matchId", match.Get("id"))
	ev.Put("userId", modAppState.CurrentUser.GetDefault("id", ""))
	ev.Put("userName", modAppState.CurrentUser.GetDefault("name", ""))
	ev.Put("type", "START")
	ev.Put("content", "Kick-off!")
	ev.Put("timestamp", DateTime.Now)
	Dim details As Map
	details.Initialize
	ev.Put("details", details)
	modDb.SaveEvent(ev)
	modAppState.UpsertEvent(ev)
	B4XPages.ShowPage("LiveFeed")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Matches")
End Sub
