B4A=true
B4i=true
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
#if B4A
	Private edtName As EditText
#else if B4i
	Private edtName As TextField
#End If
#if B4A
	Private edtDesc As EditText
#else if B4i
	Private edtDesc As TextField
#End If
	Private btnType As Button
	Private btnMyRole As Button
	Private btnJoinRole As Button
#if B4A
	Private edtInvite As EditText
#else if B4i
	Private edtInvite As TextField
#End If
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
	Dim chrome As Map = modUI.AddPageChrome(Me, Root, "New club", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	modUI.InitScroll(sv, 900dip)
	Root.AddView(sv, 0, top, modUI.ViewWidth(Root), modUI.ViewHeight(Root) - top)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
	Dim y As Int = 8dip
	Dim w As Int = modUI.ViewWidth(Root) - 32dip
	
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
	modUI.InitButton(Me, btnType, "btnType")
	btnType.Color = modConfig.COLOR_DARK_CARD
	modUI.SetButtonTextColor(btnType, modConfig.COLOR_DARK_TEXT)
	modUI.SetTextSize(btnType, 15)
	modUI.SetBold(btnType, True)
	modUI.SetAlign(btnType, "CENTER", "LEFT")
#if B4A
	btnType.Padding = Array As Int(14dip, 0, 14dip, 0)
#End If
	content.AddView(btnType, 16dip, y, w, 48dip)
	y = y + 64dip
	
	y = AddLabel(y, w, "YOUR ROLE")
	modUI.InitButton(Me, btnMyRole, "btnMyRole")
	StyleChoiceButton(btnMyRole)
	content.AddView(btnMyRole, 16dip, y, w, 48dip)
	y = y + 64dip
	
	Dim btnCreate As Button
	modUI.InitButton(Me, btnCreate, "btnCreate")
	btnCreate.Text = "Create club"
	btnCreate.Color = modConfig.COLOR_ACCENT
	modUI.SetButtonTextColor(btnCreate, Colors.White)
	modUI.SetBold(btnCreate, True)
	content.AddView(btnCreate, 16dip, y, w, 52dip)
	y = y + 72dip
	
	Dim lblJoin As Label
	lblJoin.Initialize("")
	lblJoin.Text = "OR JOIN WITH CODE"
	modUI.SetTextSize(lblJoin, 11)
	lblJoin.TextColor = modConfig.COLOR_DARK_MUTED
	modUI.SetBold(lblJoin, True)
	content.AddView(lblJoin, 16dip, y, w, 20dip)
	y = y + 28dip
	
	modUI.InitButton(Me, btnJoinRole, "btnJoinRole")
	StyleChoiceButton(btnJoinRole)
	content.AddView(btnJoinRole, 16dip, y, w, 48dip)
	y = y + 56dip
	
	edtInvite.Initialize("")
	modUI.StyleEditTextDark(edtInvite, "Invite code")
	content.AddView(edtInvite, 16dip, y, modUI.ViewWidth(Root) / 2 - 24dip, 48dip)
	
	Dim btnJoin As Button
	modUI.InitButton(Me, btnJoin, "btnJoin")
	btnJoin.Text = "Join"
	btnJoin.Color = modConfig.COLOR_SUCCESS
	modUI.SetButtonTextColor(btnJoin, Colors.White)
	modUI.SetBold(btnJoin, True)
	content.AddView(btnJoin, modUI.ViewWidth(Root) / 2, y, modUI.ViewWidth(Root) / 2 - 16dip, 48dip)
	y = y + 64dip
	content.Height = Max(y, sv.Height + 1)
	modUI.SetScrollContentHeight(sv, content.Height)
End Sub

Private Sub AddLabel(y As Int, w As Int, text As String) As Int
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	modUI.SetTextSize(lbl, 11)
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	modUI.SetBold(lbl, True)
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
	modUI.SetButtonTextColor(b, modConfig.COLOR_DARK_TEXT)
	modUI.SetTextSize(b, 15)
	modUI.SetBold(b, True)
	modUI.SetAlign(b, "CENTER", "LEFT")
#if B4A
	b.Padding = Array As Int(14dip, 0, 14dip, 0)
#End If
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
		modPlatform.Toast("Enter a club name", False)
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
	modPlatform.Toast("Club created. Invite: " & club.Get("inviteCode"), True)
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnJoin_Click
	Dim code As String = edtInvite.Text.Trim.ToUpperCase
	If code = "" Then
		modPlatform.Toast("Enter an invite code", False)
		Return
	End If
	Dim club As Map = modDb.FindClubByInviteCode(code)
	If club.ContainsKey("id") = False Or club.Get("id") = "" Then
		modPlatform.Toast("No club for that code", False)
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
	modPlatform.Toast("Joined " & club.GetDefault("name", "club"), False)
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Clubs")
End Sub
