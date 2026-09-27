B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Lineup — half-pitch with round slots + size/formation pickers.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private btnTeamSize As Button
	Private btnFormation As Button
	Private pitch As Panel
	Private clvPick As CustomListView
	Private lblPick As Label
	Private match As Map
	Private club As Map
	Private tacticalLineup As Map
	Private teamSizeValues As List
	Private selectedTeamSize As Int
	Private selectedFormation As String
	Private pendingPosId As String
	Private holdPosId As String
	Private pitchTop As Int
	Private pitchH As Int
	Private SlotSize As Int
End Sub

Public Sub Initialize
	tacticalLineup.Initialize
	teamSizeValues.Initialize
	pendingPosId = ""
	holdPosId = ""
	selectedTeamSize = 11
	selectedFormation = "4-4-2"
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	SlotSize = 48dip
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
	RefreshPickers
	DrawPitch
	HidePicker
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Lineup", "btnBack", "btnSave", "✓", True)
	Dim top As Int = chrome.Get("ContentTop")
	
	Dim pad As Int = 12dip
	Dim gap As Int = 8dip
	Dim sizeW As Int = 100dip
	btnTeamSize.Initialize("btnTeamSize")
	StylePickerButton(btnTeamSize)
	Root.AddView(btnTeamSize, pad, top, sizeW, 44dip)
	
	btnFormation.Initialize("btnFormation")
	StylePickerButton(btnFormation)
	Root.AddView(btnFormation, pad + sizeW + gap, top, Root.Width - pad * 2 - sizeW - gap, 44dip)
	
	pitchTop = top + 56dip
	pitchH = Min(Root.Height * 0.50, Root.Width * 1.05)
	pitch.Initialize("")
	pitch.Color = 0xFF15803D
	Root.AddView(pitch, pad, pitchTop, Root.Width - pad * 2, pitchH)
	
	lblPick.Initialize("")
	lblPick.Text = LineupHint
	lblPick.TextSize = 11
	lblPick.TextColor = modConfig.COLOR_DARK_MUTED
	lblPick.SingleLine = False
	Root.AddView(lblPick, 16dip, pitchTop + pitchH + 6dip, Root.Width - 32dip, 40dip)
	
	Dim listTop As Int = pitchTop + pitchH + 50dip
	clvPick = modUI.AddCustomListViewThemed(Root, 0, listTop, Root.Width, Root.Height - listTop, Me, "clvPick", True)
	Try
		clvPick.AsView.Visible = False
	Catch
		Log(LastException.Message)
	End Try
End Sub

Private Sub StylePickerButton(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	b.TextColor = modConfig.COLOR_DARK_TEXT
	b.TextSize = 14
	b.Typeface = Typeface.DEFAULT_BOLD
	b.Gravity = Gravity.CENTER
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", modAppState.SelectedClubId))
	tacticalLineup = match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMap))
	If tacticalLineup.IsInitialized = False Then tacticalLineup.Initialize
	holdPosId = ""
	
	teamSizeValues.Clear
	Dim sizes As List = modFormations.TeamSizes
	Dim si As Int
	For si = 0 To sizes.Size - 1
		teamSizeValues.Add(sizes.Get(si))
	Next
	
	Dim ts As Int = match.GetDefault("teamSize", 0)
	Dim formation As String = match.GetDefault("formation", "")
	Dim clubTs As Int = club.GetDefault("preferredTeamSize", 0)
	Dim clubForm As String = club.GetDefault("preferredFormation", "")
	
	' Empty lineup → prefer club last-used over virgin match defaults (11 / 4-4-2)
	If tacticalLineup.Size = 0 Then
		If clubTs > 0 Then ts = clubTs
		If clubForm <> "" Then formation = clubForm
	Else
		If ts = 0 And clubTs > 0 Then ts = clubTs
		If formation = "" And clubForm <> "" Then formation = clubForm
	End If
	If ts = 0 Then ts = 11
	If formation = "" Or modFormations.FormationsForSize(ts).IndexOf(formation) < 0 Then
		formation = modFormations.DefaultFormationForSize(ts)
	End If
	selectedTeamSize = ts
	selectedFormation = formation
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub RefreshPickers
	btnTeamSize.Text = selectedTeamSize & "v" & selectedTeamSize
	btnFormation.Text = selectedFormation
End Sub

Private Sub btnTeamSize_Click
	Dim opts As List
	opts.Initialize
	Dim i As Int
	For i = 0 To teamSizeValues.Size - 1
		Dim sz As Int = teamSizeValues.Get(i)
		opts.Add(sz & "v" & sz)
	Next
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	tmpl.SelectedItem = selectedTeamSize & "v" & selectedTeamSize
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim sel As String = tmpl.SelectedItem
	Dim idx As Int = opts.IndexOf(sel)
	If idx < 0 Then Return
	Dim ts As Int = teamSizeValues.Get(idx)
	If ts = selectedTeamSize Then Return
	selectedTeamSize = ts
	selectedFormation = modFormations.DefaultFormationForSize(ts)
	If club.GetDefault("preferredFormation", "") <> "" Then
		Dim clubForm As String = club.Get("preferredFormation")
		If modFormations.FormationsForSize(ts).IndexOf(clubForm) > -1 Then selectedFormation = clubForm
	End If
	tacticalLineup.Initialize
	holdPosId = ""
	ClearPitchLayout
	RefreshPickers
	HidePicker
	DrawPitch
	RememberPrefs
End Sub

Private Sub btnFormation_Click
	Dim names As List = modFormations.FormationsForSize(selectedTeamSize)
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = names
	If names.IndexOf(selectedFormation) > -1 Then tmpl.SelectedItem = selectedFormation
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim sel As String = tmpl.SelectedItem
	If sel = "" Or sel = selectedFormation Then Return
	selectedFormation = sel
	tacticalLineup.Initialize
	holdPosId = ""
	ClearPitchLayout
	RefreshPickers
	HidePicker
	DrawPitch
	RememberPrefs
End Sub

Private Sub PitchLayout As Map
	Dim plan As Object = match.GetDefault("subPlan", Null)
	If Not(plan Is Map) Then Return EmptyMap
	Dim subPlan As Map = plan
	Dim layout As Object = subPlan.GetDefault("layout", Null)
	If Not(layout Is Map) Then Return EmptyMap
	Dim m As Map = layout
	If m.IsInitialized = False Then Return EmptyMap
	Return m
End Sub

Private Sub ClearPitchLayout
	Dim plan As Object = match.GetDefault("subPlan", Null)
	If Not(plan Is Map) Then Return
	Dim subPlan As Map = plan
	If subPlan.IsInitialized = False Then Return
	Dim layout As Map
	layout.Initialize
	subPlan.Put("layout", layout)
	match.Put("subPlan", subPlan)
End Sub

Private Sub RememberPrefs
	Dim clubId As String = club.GetDefault("id", match.GetDefault("clubId", ""))
	modDb.UpdateClubPreferences(clubId, selectedTeamSize, selectedFormation)
	club = modAppState.FindClub(clubId)
End Sub

Private Sub DrawPitch
	pitch.RemoveAllViews
	DrawPitchMarkings
	Dim positions As List = modFormations.GetPositions(selectedFormation)
	Dim nameById As Map = NameByIdMap
	Dim avatarById As Map = AvatarByIdMap
	Dim i As Int
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		Dim pid As String = p.Get("id")
		Dim spread As Map = modFormations.DisplaySlot(p, PitchLayout)
		Dim xPct As Float = spread.Get("x")
		Dim yPct As Float = spread.Get("y")
		Dim origin As Map = modUI.PitchSlotLeftTop(pitch.Width, pitch.Height, SlotSize, xPct, yPct)
		Dim left As Int = origin.Get("left")
		Dim top As Int = origin.Get("top")
		
		Dim playerId As String = tacticalLineup.GetDefault(pid, "")
		Dim slot As Panel = CreateRoundSlot(pid, p.Get("label"), playerId, nameById, avatarById)
		pitch.AddView(slot, left, top, SlotSize, SlotSize + 16dip)
	Next
End Sub

Private Sub DrawPitchMarkings
	Dim cd As ColorDrawable
	cd.Initialize2(0xFF15803D, 14dip, 3dip, Colors.ARGB(180, 22, 101, 52))
	pitch.Background = cd
	pitch.Color = 0xFF15803D
	modUI.PaintPitchMarkings(pitch)
End Sub

Private Sub CreateRoundSlot(posId As String, label As String, playerId As String, nameById As Map, avatarById As Map) As Panel
	Dim wrap As Panel
	wrap.Initialize("pos")
	wrap.Color = Colors.Transparent
	wrap.Tag = posId
	
	Dim circle As Panel
	circle.Initialize("")
	Dim filled As Boolean = playerId <> ""
	If filled Then
		circle.Background = modUI.RoundedBg(0xFF0F172A, SlotSize / 2)
	Else
		circle.Background = modUI.RoundedBg(Colors.ARGB(70, 0, 0, 0), SlotSize / 2)
	End If
	wrap.AddView(circle, 0, 0, SlotSize, SlotSize)
	modUI.ClipToOutline(circle)
	
	' Border ring
	Dim ring As Panel
	ring.Initialize("")
	Dim ringCd As ColorDrawable
	Dim ringCol As Int = Colors.White
	Dim ringW As Int = 2dip
	If posId = holdPosId And holdPosId <> "" Then
		ringCol = modConfig.COLOR_ACCENT
		ringW = 3dip
	Else If filled = False Then
		ringCol = Colors.ARGB(180, 255, 255, 255)
	End If
	ringCd.Initialize2(Colors.Transparent, SlotSize / 2, ringW, ringCol)
	ring.Background = ringCd
	wrap.AddView(ring, 0, 0, SlotSize, SlotSize)
	
	If filled Then
		Dim nm As String = nameById.GetDefault(playerId, "?")
		Dim initials As Label
		initials.Initialize("")
		initials.Text = modUI.PlayerInitials(nm)
		initials.TextSize = 13
		initials.TextColor = Colors.White
		initials.Typeface = Typeface.DEFAULT_BOLD
		initials.Gravity = Gravity.CENTER
		circle.AddView(initials, 0, 0, SlotSize, SlotSize)
		
		Dim avUrl As String = avatarById.GetDefault(playerId, "")
		If avUrl <> "" Then
			Dim iv As ImageView
			iv.Initialize("")
			iv.Gravity = Gravity.FILL
			circle.AddView(iv, 0, 0, SlotSize, SlotSize)
			LoadSlotAvatar(iv, avUrl)
		End If
		
		Dim lblName As Label
		lblName.Initialize("")
		lblName.Text = FirstName(nm)
		lblName.TextSize = 9
		lblName.TextColor = Colors.White
		lblName.Typeface = Typeface.DEFAULT_BOLD
		lblName.Gravity = Gravity.CENTER
		lblName.SingleLine = True
		wrap.AddView(lblName, -8dip, SlotSize + 1dip, SlotSize + 16dip, 14dip)
	Else
		Dim lblPos As Label
		lblPos.Initialize("")
		lblPos.Text = label
		lblPos.TextSize = 10
		lblPos.TextColor = Colors.ARGB(230, 255, 255, 255)
		lblPos.Typeface = Typeface.DEFAULT_BOLD
		lblPos.Gravity = Gravity.CENTER
		circle.AddView(lblPos, 0, 0, SlotSize, SlotSize)
	End If
	Return wrap
End Sub

Private Sub FirstName(full As String) As String
	Dim n As String = full.Trim
	If n = "" Then Return "?"
	Dim parts() As String = Regex.Split("\s+", n)
	Return parts(0)
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
				iv.Gravity = Gravity.FILL
			End If
		Catch
			Log(LastException.Message)
		End Try
	End If
	job.Release
End Sub

Private Sub NameByIdMap As Map
	Dim m As Map
	m.Initialize
	Dim members As List = ClubMembers
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		m.Put(mem.Get("id"), mem.GetDefault("name", "?"))
	Next
	Return m
End Sub

Private Sub AvatarByIdMap As Map
	Dim m As Map
	m.Initialize
	Dim members As List = ClubMembers
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		m.Put(mem.Get("id"), mem.GetDefault("avatar", ""))
	Next
	Return m
End Sub

Private Sub ClubMembers As List
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Return members
End Sub

Private Sub LineupHint As String
	Return "Long-press two spots to swap. Tap empty to assign, tap filled to clear."
End Sub

' Hold one spot, then another, to exchange them. Tap still assigns or clears.
Private Sub pos_LongClick As Boolean
	Dim wrap As Panel = Sender
	Dim posId As String = "" & wrap.Tag
	If posId = "" Then Return True
	If holdPosId = "" Then
		holdPosId = posId
		ToastMessageShow("Long-press another spot to swap", False)
		CallSubDelayed(Me, "DrawPitch")
		Return True
	End If
	If posId = holdPosId Then
		holdPosId = ""
		ToastMessageShow("Swap cancelled", False)
		CallSubDelayed(Me, "DrawPitch")
		Return True
	End If
	Dim idA As String = "" & tacticalLineup.GetDefault(holdPosId, "")
	Dim idB As String = "" & tacticalLineup.GetDefault(posId, "")
	If (idA = "" Or idA = "null") And (idB = "" Or idB = "null") Then
		ToastMessageShow("Nothing to swap", False)
		Return True
	End If
	modSubPlanner.ExchangeSlots(tacticalLineup, holdPosId, posId)
	match.Put("lineup", tacticalLineup)
	match.Put("tacticalLineup", tacticalLineup)
	holdPosId = ""
	HidePicker
	ToastMessageShow("Positions swapped", False)
	CallSubDelayed(Me, "DrawPitch")
	Return True
End Sub

Private Sub pos_Click
	Dim wrap As Panel = Sender
	Dim posId As String = wrap.Tag
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
	Dim members As List = ClubMembers
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
			Dim iv As ImageView = modUI.PlayerCardImageView(card)
			If iv.IsInitialized Then
				Dim url As String = ""
				If iv.Tag <> Null Then url = iv.Tag
				If url <> "" Then LoadAvatar(iv, url)
			End If
		End If
	Next
	If any = False Then
		Dim empty As Panel = modUI.CreateSimpleRow(cardW, "No free confirmed players. Update Squad first.", "")
		empty.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clvPick.Add(empty, "")
	End If
End Sub

Private Sub LoadAvatar(iv As ImageView, url As String)
	Dim j As HttpJob
	j.Initialize("", Me)
	j.Download(url)
	Wait For (j) JobDone (job As HttpJob)
	If job.Success Then
		Try
			Dim bmp As Bitmap = job.GetBitmap
			If bmp <> Null And bmp.IsInitialized Then
				iv.Bitmap = bmp
				iv.Gravity = Gravity.FILL
			End If
		Catch
			Log("Lineup LoadAvatar: " & LastException.Message)
		End Try
	End If
	job.Release
End Sub

Private Sub HidePicker
	pendingPosId = ""
	clvPick.Clear
	Try
		clvPick.AsView.Visible = False
	Catch
		Log("HidePicker: " & LastException.Message)
	End Try
	lblPick.Text = LineupHint
End Sub

Private Sub clvPick_ItemClick (Index As Int, Value As Object)
	If Value = "" Or pendingPosId = "" Then Return
	tacticalLineup.Put(pendingPosId, Value)
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
	Dim members As List = ClubMembers
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		Dim id As String = mem.Get("id")
		If availability.GetDefault(id, "") = "CONFIRMED" And starting.IndexOf(id) = -1 Then
			bench.Add(id)
		End If
	Next
	match.Put("teamSize", selectedTeamSize)
	match.Put("formation", selectedFormation)
	match.Put("tacticalLineup", tacticalLineup)
	match.Put("lineup", tacticalLineup)
	match.Put("startingLineupIds", starting)
	match.Put("benchIds", bench)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	RememberPrefs
End Sub

Private Sub btnBack_Click
	PersistLineup
	B4XPages.ShowPage("MatchHub")
End Sub
