B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Edit player / member profile (name, number, positions, contact).
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private sv As ScrollView
	Private content As Panel
#if B4A
	Private edtName As EditText
#else if B4i
	Private edtName As TextField
#End If
#if B4A
	Private edtSquadNumber As EditText
#else if B4i
	Private edtSquadNumber As TextField
#End If
#if B4A
	Private edtPhone As EditText
#else if B4i
	Private edtPhone As TextField
#End If
#if B4A
	Private edtEmergency As EditText
#else if B4i
	Private edtEmergency As TextField
#End If
#if B4A
	Private edtMedical As EditText
#else if B4i
	Private edtMedical As TextView
#End If
	Private btnPos As Button
	Private btnPos2 As Button
	Private btnShuffle As Button
	Private btnRolePlayer As Button
	Private btnRoleCoach As Button
	Private btnRoleSpectator As Button
	Private lblTitle As Label
	Private lblRoleHint As Label
	Private selectedBaseRole As String
	Private ivAvatar As ImageView
	Private lblInitials As Label
	Private avPanel As Panel
	Private member As Map
	Private club As Map
	Private avatarUrl As String
	Private preferredPos As String
	Private secondaryPos As String
	Private positions As List
End Sub

Public Sub Initialize
	positions.Initialize
	positions.AddAll(Array As String("GK", "RB", "CB", "LB", "RWB", "LWB", "CDM", "CM", "CAM", "RM", "LM", "RW", "LW", "CF", "ST"))
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadMember
	BindFields
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Me, Root, "Edit player", "btnBack", "btnSave", "Save", True)
	lblTitle = chrome.Get("TitleLabel")
	Dim top As Int = chrome.Get("ContentTop")
	modUI.InitScroll(sv, 2200dip)
	Root.AddView(sv, 0, top, modUI.ViewWidth(Root), modUI.ViewHeight(Root) - top)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
	
	Dim y As Int = 12dip
	Dim w As Int = modUI.ViewWidth(Root) - 32dip
	Dim avSize As Int = 72dip
	
	avPanel.Initialize("")
	modUI.RoundView(avPanel, modConfig.COLOR_ACCENT, avSize / 2)
	content.AddView(avPanel, (modUI.ViewWidth(Root) - avSize) / 2, y, avSize, avSize)
	modUI.ClipToOutline(avPanel)
	
	lblInitials.Initialize("")
	modUI.SetTextSize(lblInitials, 22)
	lblInitials.TextColor = Colors.White
	modUI.SetBold(lblInitials, True)
	modUI.SetAlign(lblInitials, "CENTER", "CENTER")
	avPanel.AddView(lblInitials, 0, 0, avSize, avSize)
	
	ivAvatar.Initialize("")
	modUI.SetImageFill(ivAvatar)
	avPanel.AddView(ivAvatar, 0, 0, avSize, avSize)
	y = y + avSize + 10dip
	
	modUI.InitButton(Me, btnShuffle, "btnShuffle")
	btnShuffle.Text = "Shuffle avatar"
	btnShuffle.Color = Colors.Transparent
	modUI.SetButtonTextColor(btnShuffle, modConfig.COLOR_ACCENT)
	modUI.SetTextSize(btnShuffle, 12)
	modUI.SetBold(btnShuffle, True)
	modUI.SetAlign(btnShuffle, "CENTER", "CENTER")
	content.AddView(btnShuffle, 16dip, y, w, 28dip)
	y = y + 40dip
	
	y = AddFieldLabel(y, w, "NAME")
	edtName.Initialize("")
	modUI.StyleEditTextDark(edtName, "Full name")
	content.AddView(edtName, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "ROLE")
	Dim gap As Int = 8dip
	Dim bw As Int = (w - gap * 2) / 3
	modUI.InitButton(Me, btnRolePlayer, "btnRolePlayer")
	modUI.InitButton(Me, btnRoleCoach, "btnRoleCoach")
	modUI.InitButton(Me, btnRoleSpectator, "btnRoleSpectator")
	btnRolePlayer.Text = "Player"
	btnRoleCoach.Text = "Coach"
	btnRoleSpectator.Text = "Spectator"
	content.AddView(btnRolePlayer, 16dip, y, bw, 44dip)
	content.AddView(btnRoleCoach, 16dip + bw + gap, y, bw, 44dip)
	content.AddView(btnRoleSpectator, 16dip + (bw + gap) * 2, y, bw, 44dip)
	y = y + 50dip
	lblRoleHint.Initialize("")
	modUI.SetTextSize(lblRoleHint, 12)
	lblRoleHint.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(lblRoleHint, 16dip, y, w, 40dip)
	y = y + 44dip
	
	y = AddFieldLabel(y, w, "SQUAD #")
	edtSquadNumber.Initialize("")
	modUI.StyleEditTextDark(edtSquadNumber, "e.g. 7")
	modUI.SetKeyboard(edtSquadNumber, "numbers")
	content.AddView(edtSquadNumber, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "PREFERRED POSITION")
	modUI.InitButton(Me, btnPos, "btnPos")
	StylePickerButton(btnPos)
	content.AddView(btnPos, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "SECONDARY POSITION")
	modUI.InitButton(Me, btnPos2, "btnPos2")
	StylePickerButton(btnPos2)
	content.AddView(btnPos2, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "PHONE")
	edtPhone.Initialize("")
	modUI.StyleEditTextDark(edtPhone, "Mobile")
	content.AddView(edtPhone, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "EMERGENCY CONTACT")
	edtEmergency.Initialize("")
	modUI.StyleEditTextDark(edtEmergency, "Name & number")
	content.AddView(edtEmergency, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "MEDICAL NOTES")
	edtMedical.Initialize("")
	modUI.StyleEditTextDark(edtMedical, "Allergies, injuries…")
	modUI.SetSingleLine(edtMedical, False)
	modUI.SetAlign(edtMedical, "TOP", "LEFT")
	content.AddView(edtMedical, 16dip, y, w, 96dip)
	y = y + 112dip
	
	content.Height = Max(y + 24dip, sv.Height + 1)
	modUI.SetScrollContentHeight(sv, content.Height)
End Sub

Private Sub AddFieldLabel(y As Int, w As Int, text As String) As Int
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	modUI.SetTextSize(lbl, 11)
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	modUI.SetBold(lbl, True)
	content.AddView(lbl, 16dip, y, w, 18dip)
	Return y + 22dip
End Sub

Private Sub StylePickerButton(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	modUI.SetButtonTextColor(b, modConfig.COLOR_DARK_TEXT)
	modUI.SetTextSize(b, 15)
	modUI.SetAlign(b, "CENTER", "LEFT")
#if B4A
	b.Padding = Array As Int(14dip, 0, 14dip, 0)
#End If
End Sub

Private Sub LoadMember
	club = modAppState.FindClub(modAppState.SelectedClubId)
	member.Initialize
	Dim uid As String = modAppState.SelectedPlayerId
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		Dim members As List = memObj
		Dim i As Int
		For i = 0 To members.Size - 1
			Dim m As Map = members.Get(i)
			If m.GetDefault("id", "") = uid Then
				member = m
				Exit
			End If
		Next
	End If
	If member.IsInitialized = False Or member.ContainsKey("id") = False Then
		member.Initialize
		member.Put("id", uid)
		member.Put("name", "Player")
	End If
End Sub

Private Sub BindFields
	edtName.Text = member.GetDefault("name", "")
	Dim numObj As Object = member.GetDefault("squadNumber", "")
	If numObj = Null Or 0 = numObj Or "0" = numObj Then
		edtSquadNumber.Text = ""
	Else
		edtSquadNumber.Text = numObj
	End If
	preferredPos = member.GetDefault("preferredPosition", member.GetDefault("favPosition", ""))
	secondaryPos = member.GetDefault("secondaryPosition", "")
	If preferredPos = "" Then btnPos.Text = "Select position" Else btnPos.Text = preferredPos
	If secondaryPos = "" Then btnPos2.Text = "Optional" Else btnPos2.Text = secondaryPos
	edtPhone.Text = member.GetDefault("phone", "")
	edtEmergency.Text = member.GetDefault("emergencyContact", "")
	edtMedical.Text = member.GetDefault("medicalNotes", "")
	avatarUrl = member.GetDefault("avatar", "")
	BindRole
	RefreshAvatar
End Sub

Private Sub BindRole
	Dim isSelf As Boolean = False
	If modAppState.IsAuthenticated Then
		isSelf = member.GetDefault("id", "") = modAppState.CurrentUser.GetDefault("id", "")
	End If
	If isSelf Then lblTitle.Text = "Your profile" Else lblTitle.Text = "Edit player"
	Dim clubRoles As Object = member.GetDefault("roles", Null)
	Dim profileRoles As Object = Null
	If isSelf Then profileRoles = modAppState.CurrentUser.GetDefault("roles", Null)
	Dim hasPlayer As Boolean = modDb.RoleListHas(clubRoles, "PLAYER") Or modDb.RoleListHas(profileRoles, "PLAYER")
	Dim hasCoach As Boolean = modDb.RoleListHas(clubRoles, "COACH") Or modDb.RoleListHas(profileRoles, "COACH")
	Dim hasSpectator As Boolean = modDb.RoleListHas(clubRoles, "SPECTATOR") Or modDb.RoleListHas(profileRoles, "SPECTATOR")
	If hasPlayer And hasCoach Then
		selectedBaseRole = "PLAYER"
		lblRoleHint.Text = "You are Coach and Player. Tap Coach, then Save, to remove Player."
	Else If hasCoach Then
		selectedBaseRole = "COACH"
		lblRoleHint.Text = "One role. Admin access stays if you already have it."
	Else If hasSpectator And hasPlayer = False Then
		selectedBaseRole = "SPECTATOR"
		lblRoleHint.Text = "One role. Admin access stays if you already have it."
	Else
		selectedBaseRole = "PLAYER"
		lblRoleHint.Text = "Pick Player, Coach, or Spectator."
	End If
	RefreshRoleButtons
End Sub

Private Sub RefreshRoleButtons
	StyleRoleButton(btnRolePlayer, selectedBaseRole = "PLAYER")
	StyleRoleButton(btnRoleCoach, selectedBaseRole = "COACH")
	StyleRoleButton(btnRoleSpectator, selectedBaseRole = "SPECTATOR")
End Sub

Private Sub StyleRoleButton(b As Button, selected As Boolean)
	modUI.SetTextSize(b, 12)
	modUI.SetBold(b, True)
	modUI.SetAlign(b, "CENTER", "CENTER")
#if B4A
	b.Padding = Array As Int(4dip, 0, 4dip, 0)
#End If
	If selected Then
		b.Color = modConfig.COLOR_ACCENT
		modUI.SetButtonTextColor(b, Colors.White)
	Else
		b.Color = modConfig.COLOR_DARK_CARD
		modUI.SetButtonTextColor(b, modConfig.COLOR_DARK_MUTED)
	End If
End Sub

Private Sub btnRolePlayer_Click
	selectedBaseRole = "PLAYER"
	RefreshRoleButtons
End Sub

Private Sub btnRoleCoach_Click
	selectedBaseRole = "COACH"
	RefreshRoleButtons
End Sub

Private Sub btnRoleSpectator_Click
	selectedBaseRole = "SPECTATOR"
	RefreshRoleButtons
End Sub

Private Sub RefreshAvatar
	Dim nm As String = edtName.Text.Trim
	If nm = "" Then nm = member.GetDefault("name", "Player")
	lblInitials.Text = modUI.PlayerInitials(nm)
	modUI.RoundView(avPanel, modUI.AvatarColorForName(nm), 36dip)
	If avatarUrl <> "" Then
		LoadAvatar(avatarUrl)
	End If
End Sub

Private Sub LoadAvatar(url As String)
	Dim j As HttpJob
	j.Initialize("", Me)
	j.Download(url)
	Wait For (j) JobDone (job As HttpJob)
	If job.Success And url = avatarUrl Then
		Try
			Dim bmp As Bitmap = job.GetBitmap
			If bmp <> Null And bmp.IsInitialized Then
				ivAvatar.Bitmap = bmp
				modUI.SetImageFill(ivAvatar)
			End If
		Catch
			Log("PlayerEdit avatar: " & LastException.Message)
		End Try
	End If
	job.Release
End Sub

Private Sub btnShuffle_Click
	Dim seed As String = modAppState.NewId
	avatarUrl = "https://i.pravatar.cc/150?u=" & seed
	RefreshAvatar
End Sub

Private Sub btnPos_Click
	Wait For (PickPosition(preferredPos)) Complete (sel As String)
	If sel = "__cancel__" Then Return
	preferredPos = sel
	If preferredPos = "" Then btnPos.Text = "Select position" Else btnPos.Text = preferredPos
End Sub

Private Sub btnPos2_Click
	Wait For (PickPosition(secondaryPos)) Complete (sel As String)
	If sel = "__cancel__" Then Return
	secondaryPos = sel
	If secondaryPos = "" Then btnPos2.Text = "Optional" Else btnPos2.Text = secondaryPos
End Sub

Private Sub PickPosition(current As String) As ResumableSub
	Dim opts As List
	opts.Initialize
	opts.Add("(none)")
	opts.AddAll(positions)
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	If current <> "" And opts.IndexOf(current) > -1 Then tmpl.SelectedItem = current
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return "__cancel__"
	Dim sel As String = tmpl.SelectedItem
	If sel = "(none)" Then Return ""
	Return sel
End Sub

Private Sub btnSave_Click
	Dim nm As String = edtName.Text.Trim
	If nm = "" Then
		xui.MsgboxAsync("Name is required.", "Edit player")
		Return
	End If
	Dim updates As Map
	updates.Initialize
	updates.Put("name", nm)
	updates.Put("avatar", avatarUrl)
	Dim numTxt As String = edtSquadNumber.Text.Trim
	If numTxt = "" Then
		updates.Put("squadNumber", Null)
	Else
		updates.Put("squadNumber", numTxt)
	End If
	updates.Put("preferredPosition", preferredPos)
	updates.Put("secondaryPosition", secondaryPos)
	updates.Put("phone", edtPhone.Text.Trim)
	updates.Put("emergencyContact", edtEmergency.Text.Trim)
	updates.Put("medicalNotes", edtMedical.Text.Trim)
	updates.Put("dateOfBirth", member.GetDefault("dateOfBirth", ""))
	modDb.UpdateMember(modAppState.SelectedPlayerId, updates)
	If modDb.SetMemberBaseRole(modAppState.SelectedClubId, modAppState.SelectedPlayerId, selectedBaseRole) = False Then
		xui.MsgboxAsync("Profile saved, but the role could not be updated.", "Role")
		Return
	End If
	GoBack
End Sub

Private Sub btnBack_Click
	GoBack
End Sub

Private Sub GoBack
	Dim ret As String = modAppState.PlayerEditReturnPage
	If ret = "" Then ret = "MatchSquad"
	B4XPages.ShowPage(ret)
End Sub
