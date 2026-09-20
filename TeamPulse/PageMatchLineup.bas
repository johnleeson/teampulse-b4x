B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Lineup — formation pitch + pick confirmed players for slots.
Sub Class_Globals
	Private Root As B4XView
	Private spnTeamSize As Spinner
	Private spnFormation As Spinner
	Private pitch As Panel
	Private clvPick As CustomListView
	Private lblPick As Label
	Private match As Map
	Private club As Map
	Private tacticalLineup As Map
	Private teamSizeValues As List
	Private pendingPosId As String
End Sub

Public Sub Initialize
	tacticalLineup.Initialize
	teamSizeValues.Initialize
	pendingPosId = ""
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
	DrawPitch
	HidePicker
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Lineup", "btnBack", "btnSave", "✓", True)
	Dim top As Int = chrome.Get("ContentTop")
	
	spnTeamSize.Initialize("spnTeamSize")
	Root.AddView(spnTeamSize, 16dip, top, 100dip, 40dip)
	
	spnFormation.Initialize("spnFormation")
	Root.AddView(spnFormation, 124dip, top, Root.Width - 140dip, 40dip)
	
	Dim pitchTop As Int = top + 52dip
	Dim pitchH As Int = Root.Height * 0.48
	pitch.Initialize("")
	pitch.Color = modConfig.COLOR_PITCH
	Root.AddView(pitch, 12dip, pitchTop, Root.Width - 24dip, pitchH)
	
	lblPick.Initialize("")
	lblPick.Text = "Tap an empty slot to assign a confirmed player. Tap a filled slot to clear."
	lblPick.TextSize = 11
	lblPick.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(lblPick, 16dip, pitchTop + pitchH + 8dip, Root.Width - 32dip, 36dip)
	
	Dim listTop As Int = pitchTop + pitchH + 48dip
	clvPick = modUI.AddCustomListViewThemed(Root, 0, listTop, Root.Width, Root.Height - listTop, Me, "clvPick", True)
	Try
		clvPick.AsView.Visible = False
	Catch
		Log(LastException.Message)
	End Try
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", modAppState.SelectedClubId))
	tacticalLineup = match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMap))
	If tacticalLineup.IsInitialized = False Then tacticalLineup.Initialize
	
	teamSizeValues.Clear
	spnTeamSize.Clear
	Dim sizes As List = modFormations.TeamSizes
	Dim si As Int
	For si = 0 To sizes.Size - 1
		Dim sz As Int = sizes.Get(si)
		teamSizeValues.Add(sz)
		spnTeamSize.Add(sz & "v" & sz)
	Next
	
	Dim ts As Int = match.GetDefault("teamSize", 0)
	If ts = 0 Then ts = club.GetDefault("preferredTeamSize", 11)
	If ts = 0 Then ts = 11
	Dim formation As String = match.GetDefault("formation", "")
	If formation = "" Then formation = club.GetDefault("preferredFormation", "")
	If formation = "" Then formation = modFormations.DefaultFormationForSize(ts)
	
	Dim sizeIdx As Int = teamSizeValues.IndexOf(ts)
	If sizeIdx < 0 Then sizeIdx = 0
	spnTeamSize.SelectedIndex = sizeIdx
	ReloadFormationSpinner(ts, formation)
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub ReloadFormationSpinner(teamSize As Int, selectedName As String)
	spnFormation.Clear
	Dim names As List = modFormations.FormationsForSize(teamSize)
	Dim i As Int
	For i = 0 To names.Size - 1
		spnFormation.Add(names.Get(i))
	Next
	Dim idx As Int = names.IndexOf(selectedName)
	If idx < 0 Then idx = 0
	spnFormation.SelectedIndex = idx
End Sub

Private Sub CurrentTeamSize As Int
	Dim idx As Int = spnTeamSize.SelectedIndex
	If idx < 0 Or idx >= teamSizeValues.Size Then Return 11
	Return teamSizeValues.Get(idx)
End Sub

Private Sub DrawPitch
	pitch.RemoveAllViews
	Dim formation As String = spnFormation.SelectedItem
	If formation = "" Then Return
	Dim positions As List = modFormations.GetPositions(formation)
	Dim nameById As Map = NameByIdMap
	Dim i As Int
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		Dim pid As String = p.Get("id")
		Dim xPct As Float = p.Get("x")
		Dim yPct As Float = p.Get("y")
		Dim w As Int = 64dip
		Dim h As Int = 40dip
		Dim left As Int = (pitch.Width - w) * xPct / 100
		Dim top As Int = (pitch.Height - h) * yPct / 100
		Dim b As Button
		b.Initialize("pos")
		Dim playerId As String = tacticalLineup.GetDefault(pid, "")
		If playerId = "" Then
			b.Text = p.Get("label")
			b.Color = 0xAAFFFFFF
		Else
			b.Text = nameById.GetDefault(playerId, "?")
			b.Color = Colors.White
		End If
		b.TextSize = 10
		b.Typeface = Typeface.DEFAULT_BOLD
		b.Tag = pid
		b.TextColor = modConfig.COLOR_PRIMARY
		pitch.AddView(b, left, top, w, h)
	Next
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

Private Sub pos_Click
	Dim b As Button = Sender
	Dim posId As String = b.Tag
	Dim current As String = tacticalLineup.GetDefault(posId, "")
	If current <> "" Then
		tacticalLineup.Remove(posId)
		HidePicker
		DrawPitch
		Return
	End If
	pendingPosId = posId
	ShowPicker
End Sub

Private Sub ShowPicker
	lblPick.Text = "Choose a confirmed player for this slot"
	Try
		clvPick.AsView.Visible = True
	Catch
		Log(LastException.Message)
	End Try
	clvPick.Clear
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Dim used As Map
	used.Initialize
	For Each k As String In tacticalLineup.Keys
		used.Put(tacticalLineup.Get(k), True)
	Next
	Dim cardW As Int = Root.Width - 24dip
	Dim any As Boolean = False
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		Dim id As String = mem.GetDefault("id", "")
		If availability.GetDefault(id, "") = "CONFIRMED" And used.ContainsKey(id) = False Then
			any = True
			Dim card As Panel = modUI.CreatePlayerCard(cardW, mem, "CONFIRMED", False)
			Dim h As Int = modUI.PlayerCardHeight + 8dip
			card.SetLayout(0, 0, cardW, h)
			clvPick.Add(card, id)
		End If
	Next
	If any = False Then
		Dim empty As Panel = modUI.CreateSimpleRow(cardW, "No free confirmed players. Update Squad first.", "")
		empty.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clvPick.Add(empty, "")
	End If
End Sub

Private Sub HidePicker
	pendingPosId = ""
	clvPick.Clear
	Try
		clvPick.AsView.Visible = False
	Catch
		Log("HidePicker: " & LastException.Message)
	End Try
	lblPick.Text = "Tap an empty slot to assign a confirmed player. Tap a filled slot to clear."
End Sub

Private Sub clvPick_ItemClick (Index As Int, Value As Object)
	If Value = "" Or pendingPosId = "" Then Return
	tacticalLineup.Put(pendingPosId, Value)
	HidePicker
	DrawPitch
End Sub

Private Sub spnTeamSize_ItemClick (Position As Int, Value As Object)
	Dim ts As Int = CurrentTeamSize
	ReloadFormationSpinner(ts, modFormations.DefaultFormationForSize(ts))
	tacticalLineup.Initialize
	HidePicker
	DrawPitch
End Sub

Private Sub spnFormation_ItemClick (Position As Int, Value As Object)
	HidePicker
	DrawPitch
End Sub

Private Sub btnSave_Click
	PersistLineup
	ToastMessageShow("Lineup saved", False)
End Sub

Private Sub PersistLineup
	Dim starting As List
	starting.Initialize
	For Each k As String In tacticalLineup.Keys
		Dim pid As String = tacticalLineup.Get(k)
		If pid <> "" Then starting.Add(pid)
	Next
	Dim bench As List
	bench.Initialize
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
		Dim id As String = mem.Get("id")
		If availability.GetDefault(id, "") = "CONFIRMED" And starting.IndexOf(id) = -1 Then
			bench.Add(id)
		End If
	Next
	match.Put("teamSize", CurrentTeamSize)
	match.Put("formation", spnFormation.SelectedItem)
	match.Put("tacticalLineup", tacticalLineup)
	match.Put("lineup", tacticalLineup)
	match.Put("startingLineupIds", starting)
	match.Put("benchIds", bench)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
End Sub

Private Sub btnBack_Click
	PersistLineup
	B4XPages.ShowPage("MatchHub")
End Sub
