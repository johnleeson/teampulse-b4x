B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
	Private edtName As EditText
	Private edtDesc As EditText
	Private spnType As Spinner
	Private edtInvite As EditText
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFFF8FAFC
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Refresh
End Sub

Private Sub BuildUI
	Dim title As Label
	title.Initialize("")
	title.Text = "My Clubs"
	title.TextSize = 22
	title.Typeface = Typeface.DEFAULT_BOLD
	title.TextColor = modConfig.COLOR_PRIMARY
	Root.AddView(title, 16dip, 24dip, Root.Width - 32dip, 40dip)
	
	Dim btnBack As Button
	btnBack.Initialize("btnBack")
	btnBack.Text = "Back"
	Root.AddView(btnBack, Root.Width - 88dip, 24dip, 72dip, 40dip)
	
	clv.Initialize(Me, "clv")
	Root.AddView(clv.AsView, 0, 72dip, Root.Width, 200dip)
	
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = "Create club"
	lbl.Typeface = Typeface.DEFAULT_BOLD
	lbl.TextColor = modConfig.COLOR_PRIMARY
	Root.AddView(lbl, 16dip, 284dip, Root.Width - 32dip, 28dip)
	
	edtName.Initialize("")
	edtName.Hint = "Club name"
	Root.AddView(edtName, 16dip, 320dip, Root.Width - 32dip, 44dip)
	
	edtDesc.Initialize("")
	edtDesc.Hint = "Description"
	Root.AddView(edtDesc, 16dip, 372dip, Root.Width - 32dip, 44dip)
	
	spnType.Initialize("")
	spnType.AddAll(Array As String("TEAM", "SOCIAL"))
	Root.AddView(spnType, 16dip, 424dip, Root.Width - 32dip, 44dip)
	
	Dim btnCreate As Button
	btnCreate.Initialize("btnCreate")
	btnCreate.Text = "Create club"
	btnCreate.Color = modConfig.COLOR_ACCENT
	btnCreate.TextColor = Colors.White
	Root.AddView(btnCreate, 16dip, 480dip, Root.Width - 32dip, 48dip)
	
	Dim lbl2 As Label
	lbl2.Initialize("")
	lbl2.Text = "Join with invite code"
	lbl2.Typeface = Typeface.DEFAULT_BOLD
	lbl2.TextColor = modConfig.COLOR_PRIMARY
	Root.AddView(lbl2, 16dip, 548dip, Root.Width - 32dip, 28dip)
	
	edtInvite.Initialize("")
	edtInvite.Hint = "Invite code"
	Root.AddView(edtInvite, 16dip, 584dip, Root.Width / 2 - 24dip, 44dip)
	
	Dim btnJoin As Button
	btnJoin.Initialize("btnJoin")
	btnJoin.Text = "Join"
	btnJoin.Color = modConfig.COLOR_SUCCESS
	btnJoin.TextColor = Colors.White
	Root.AddView(btnJoin, Root.Width / 2, 584dip, Root.Width / 2 - 16dip, 44dip)
End Sub

Public Sub Refresh
	clv.Clear
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	If myClubs.Size = 0 Then
		clv.AddTextItem("No clubs yet.", "")
	Else
		For Each c As Map In myClubs
			Dim members As List = c.GetDefault("members", EmptyList)
			clv.AddTextItem(c.GetDefault("name", "") & CRLF & c.GetDefault("type", "") & " · " & members.Size & " members · code " & c.GetDefault("inviteCode", ""), c.Get("id"))
		Next
	End If
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	modAppState.SelectedClubId = Value
	B4XPages.ShowPage("ClubMembers")
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
	edtName.Text = ""
	edtDesc.Text = ""
	ToastMessageShow("Club created. Invite: " & club.Get("inviteCode"), True)
	Refresh
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
	Refresh
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Dashboard")
End Sub
