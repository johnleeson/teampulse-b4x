B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Create a club or join with invite code.
Sub Class_Globals
	Private Root As B4XView
	Private edtName As EditText
	Private edtDesc As EditText
	Private spnType As Spinner
	Private edtInvite As EditText
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = modConfig.COLOR_SURFACE
	BuildUI
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "New club", "btnBack", "", "", False)
	Dim y As Int = chrome.Get("ContentTop") + 8dip
	edtName.Initialize("")
	modUI.StyleEditText(edtName, "Club name")
	Root.AddView(edtName, 16dip, y, Root.Width - 32dip, 48dip)
	y = y + 56dip
	
	edtDesc.Initialize("")
	modUI.StyleEditText(edtDesc, "Description")
	Root.AddView(edtDesc, 16dip, y, Root.Width - 32dip, 48dip)
	y = y + 56dip
	
	spnType.Initialize("")
	spnType.AddAll(Array As String("TEAM", "SOCIAL"))
	spnType.TextSize = 15
	Root.AddView(spnType, 16dip, y, Root.Width - 32dip, 44dip)
	y = y + 56dip
	
	Dim btnCreate As Button
	btnCreate.Initialize("btnCreate")
	btnCreate.Text = "Create club"
	btnCreate.Color = modConfig.COLOR_ACCENT
	btnCreate.TextColor = Colors.White
	Root.AddView(btnCreate, 16dip, y, Root.Width - 32dip, 52dip)
	y = y + 72dip
	
	Dim lblJoin As Label
	lblJoin.Initialize("")
	lblJoin.Text = "OR JOIN WITH CODE"
	lblJoin.TextSize = 11
	lblJoin.TextColor = modConfig.COLOR_MUTED
	lblJoin.Typeface = Typeface.DEFAULT_BOLD
	Root.AddView(lblJoin, 16dip, y, Root.Width - 32dip, 20dip)
	y = y + 28dip
	
	edtInvite.Initialize("")
	modUI.StyleEditText(edtInvite, "Invite code")
	Root.AddView(edtInvite, 16dip, y, Root.Width / 2 - 24dip, 48dip)
	
	Dim btnJoin As Button
	btnJoin.Initialize("btnJoin")
	btnJoin.Text = "Join"
	btnJoin.Color = modConfig.COLOR_SUCCESS
	btnJoin.TextColor = Colors.White
	Root.AddView(btnJoin, Root.Width / 2, y, Root.Width / 2 - 16dip, 48dip)
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
	club.Put("type", spnType.SelectedItem)
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
	roles.AddAll(Array As String("ADMIN", "PLAYER"))
	om.Put("roles", roles)
	members.Add(om)
	club.Put("members", members)
	club.Put("ownerId", owner.Get("id"))
	modDb.SaveClub(club, owner)
	modAppState.UpsertClub(club)
	ToastMessageShow("Club created. Invite: " & club.Get("inviteCode"), True)
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnJoin_Click
	Dim code As String = edtInvite.Text.Trim.ToUpperCase
	If code = "" Then Return
	Dim club As Map = modDb.FindClubByInviteCode(code)
	If club.ContainsKey("id") = False Or club.Get("id") = "" Then
		ToastMessageShow("No club for that code", False)
		Return
	End If
	Dim roles As List
	roles.Initialize
	roles.Add("PLAYER")
	modDb.JoinClub(club.Get("id"), modAppState.CurrentUser.Get("id"), roles)
	modDb.FetchInitialData
	ToastMessageShow("Joined " & club.GetDefault("name", "club"), False)
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Clubs")
End Sub
