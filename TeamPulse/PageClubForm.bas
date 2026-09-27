B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Create a club or join with invite code.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private edtName As EditText
	Private edtDesc As EditText
	Private btnType As Button
	Private btnMyRole As Button
	Private btnJoinRole As Button
	Private edtInvite As EditText
	Private sv As ScrollView
	Private content As Panel
	Private selectedType As String
	Private selectedMyRole As String
	Private selectedJoinRole As String
End Sub

Public Sub Initialize
	selectedType = "TEAM"
	selectedMyRole = "PLAYER"
	selectedJoinRole = "PLAYER"
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildUI
End Sub

Private Sub B4XPage_Appear
	If modAppState.IsAuthenticated Then
		Dim base As String = modDb.ResolveBaseRole(modAppState.CurrentUser.GetDefault("roles", Null))
		selectedMyRole = base
		selectedJoinRole = base
	End If
	RefreshTypeButton
	RefreshRoleButtons
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "New club", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	sv.Initialize(900dip)
	Root.AddView(sv, 0, top, Root.Width, Root.Height - top)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
	Dim y As Int = 8dip
	Dim w As Int = Root.Width - 32dip
	
	y = AddLabel(y, w, "CLUB NAME")
	edtName.Initialize("")
	modUI.StyleEditTextDark(edtName, "Club name")
	content.AddView(edtName, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddLabel(y, w, "DESCRIPTION")
	edtDesc.Initialize("")
	modUI.StyleEditTextDark(edtDesc, "Optional description")
	content.AddView(edtDesc, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddLabel(y, w, "TYPE")
	btnType.Initialize("btnType")
	btnType.Color = modConfig.COLOR_DARK_CARD
	btnType.TextColor = modConfig.COLOR_DARK_TEXT
	btnType.TextSize = 15
	btnType.Typeface = Typeface.DEFAULT_BOLD
	btnType.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
	btnType.Padding = Array As Int(14dip, 0, 14dip, 0)
	content.AddView(btnType, 16dip, y, w, 48dip)
	y = y + 64dip
	
	y = AddLabel(y, w, "YOUR ROLE")
	btnMyRole.Initialize("btnMyRole")
	StyleChoiceButton(btnMyRole)
	content.AddView(btnMyRole, 16dip, y, w, 48dip)
	y = y + 64dip
	
	Dim btnCreate As Button
	btnCreate.Initialize("btnCreate")
	btnCreate.Text = "Create club"
	btnCreate.Color = modConfig.COLOR_ACCENT
	btnCreate.TextColor = Colors.White
	btnCreate.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(btnCreate, 16dip, y, w, 52dip)
	y = y + 72dip
	
	Dim lblJoin As Label
	lblJoin.Initialize("")
	lblJoin.Text = "OR JOIN WITH CODE"
	lblJoin.TextSize = 11
	lblJoin.TextColor = modConfig.COLOR_DARK_MUTED
	lblJoin.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblJoin, 16dip, y, w, 20dip)
	y = y + 28dip
	
	btnJoinRole.Initialize("btnJoinRole")
	StyleChoiceButton(btnJoinRole)
	content.AddView(btnJoinRole, 16dip, y, w, 48dip)
	y = y + 56dip
	
	edtInvite.Initialize("")
	modUI.StyleEditTextDark(edtInvite, "Invite code")
	content.AddView(edtInvite, 16dip, y, Root.Width / 2 - 24dip, 48dip)
	
	Dim btnJoin As Button
	btnJoin.Initialize("btnJoin")
	btnJoin.Text = "Join"
	btnJoin.Color = modConfig.COLOR_SUCCESS
	btnJoin.TextColor = Colors.White
	btnJoin.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(btnJoin, Root.Width / 2, y, Root.Width / 2 - 16dip, 48dip)
	y = y + 64dip
	content.Height = Max(y, sv.Height + 1)
	sv.Panel.Height = content.Height
End Sub

Private Sub AddLabel(y As Int, w As Int, text As String) As Int
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 11
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	lbl.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lbl, 16dip, y, w, 18dip)
	Return y + 22dip
End Sub

Private Sub RefreshTypeButton
	btnType.Text = selectedType
End Sub

Private Sub RefreshRoleButtons
	btnMyRole.Text = selectedMyRole
	btnJoinRole.Text = "Join as " & selectedJoinRole
End Sub

Private Sub StyleChoiceButton(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	b.TextColor = modConfig.COLOR_DARK_TEXT
	b.TextSize = 15
	b.Typeface = Typeface.DEFAULT_BOLD
	b.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
	b.Padding = Array As Int(14dip, 0, 14dip, 0)
End Sub

Private Sub PickBaseRole(current As String) As ResumableSub
	Dim opts As List
	opts.Initialize
	opts.AddAll(Array As String("PLAYER", "COACH", "SPECTATOR"))
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	tmpl.SelectedItem = current
	dialog.Title = "Your role"
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return current
	Return tmpl.SelectedItem
End Sub

Private Sub btnMyRole_Click
	Wait For (PickBaseRole(selectedMyRole)) Complete (sel As String)
	selectedMyRole = sel
	RefreshRoleButtons
End Sub

Private Sub btnJoinRole_Click
	Wait For (PickBaseRole(selectedJoinRole)) Complete (sel As String)
	selectedJoinRole = sel
	RefreshRoleButtons
End Sub

Private Sub btnType_Click
	Dim opts As List
	opts.Initialize
	opts.AddAll(Array As String("TEAM", "SOCIAL"))
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	tmpl.SelectedItem = selectedType
	dialog.Title = "Club type"
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	selectedType = tmpl.SelectedItem
	RefreshTypeButton
End Sub

Private Sub btnCreate_Click
	If modAppState.IsAuthenticated = False Then Return
	Dim name As String = edtName.Text.Trim
	If name = "" Then
		ToastMessageShow("Enter a club name", False)
		Return
	End If
	Dim club As Map
	club.Initialize
	club.Put("id", modAppState.NewId)
	club.Put("name", name)
	club.Put("description", edtDesc.Text.Trim)
	club.Put("type", selectedType)
	club.Put("logo", "")
	club.Put("inviteCode", modDb.GenerateInviteCode)
	Dim members As List
	members.Initialize
	Dim owner As Map = modAppState.CurrentUser
	Dim om As Map
	om.Initialize
	om.Put("id", owner.Get("id"))
	om.Put("name", owner.GetDefault("name", ""))
	om.Put("avatar", owner.GetDefault("avatar", ""))
	Dim roles As List
	roles.Initialize
	roles.Add("ADMIN")
	If selectedMyRole = "" Then selectedMyRole = "PLAYER"
	roles.Add(selectedMyRole)
	om.Put("roles", roles)
	members.Add(om)
	club.Put("members", members)
	club.Put("ownerId", owner.Get("id"))
	Dim profileRoles As List = modDb.BuildRolesKeepingAdmin(owner.GetDefault("roles", Null), selectedMyRole)
	owner.Put("roles", profileRoles)
	modDb.SaveClub(club, owner)
	modAppState.UpsertClub(club)
	modAppState.SelectedClubId = club.Get("id")
	ToastMessageShow("Club created. Invite: " & club.Get("inviteCode"), True)
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnJoin_Click
	Dim code As String = edtInvite.Text.Trim.ToUpperCase
	If code = "" Then
		ToastMessageShow("Enter an invite code", False)
		Return
	End If
	Dim club As Map = modDb.FindClubByInviteCode(code)
	If club.ContainsKey("id") = False Or club.Get("id") = "" Then
		ToastMessageShow("No club for that code", False)
		Return
	End If
	Dim roles As List
	roles.Initialize
	If selectedJoinRole = "" Then selectedJoinRole = "PLAYER"
	roles.Add(selectedJoinRole)
	modDb.JoinClub(club.Get("id"), modAppState.CurrentUser.Get("id"), roles)
	If modAppState.CurrentUser.IsInitialized Then
		Dim profileRoles As List = modDb.BuildRolesKeepingAdmin(modAppState.CurrentUser.GetDefault("roles", Null), selectedJoinRole)
		modAppState.CurrentUser.Put("roles", profileRoles)
		modDb.SaveProfile(modAppState.CurrentUser)
	End If
	modDb.FetchInitialData
	ToastMessageShow("Joined " & club.GetDefault("name", "club"), False)
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Clubs")
End Sub
