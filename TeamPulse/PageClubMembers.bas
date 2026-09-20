B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
	Private lblTitle As Label
	Private edtPlayerName As EditText
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Refresh
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Roster", "btnBack", "", "", False)
	lblTitle = chrome.Get("TitleLabel")
	
	clv = modUI.AddCustomListView(Root, 0, 56dip, Root.Width, Root.Height - 180dip, Me, "clv")
	
	edtPlayerName.Initialize("")
	edtPlayerName.Hint = "Add player name"
	Root.AddView(edtPlayerName, 16dip, Root.Height - 110dip, Root.Width / 2, 44dip)
	
	Dim btnAdd As Button
	btnAdd.Initialize("btnAdd")
	btnAdd.Text = "Add player"
	btnAdd.Color = modConfig.COLOR_ACCENT
	btnAdd.TextColor = Colors.White
	Root.AddView(btnAdd, Root.Width / 2 + 8dip, Root.Height - 110dip, Root.Width / 2 - 24dip, 44dip)
	
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Long-press a member to remove (admins)."
	hint.TextSize = 12
	hint.TextColor = modConfig.COLOR_MUTED
	Root.AddView(hint, 16dip, Root.Height - 56dip, Root.Width - 32dip, 40dip)
End Sub

Public Sub Refresh
	Dim club As Map = modAppState.FindClub(modAppState.SelectedClubId)
	lblTitle.Text = club.GetDefault("name", "Club") & " roster"
	clv.Clear
	Dim members As List = club.GetDefault("members", EmptyList)
	If members.Size = 0 Then
		clv.AddTextItem("No members.", "")
		Return
	End If
	For Each m As Map In members
		Dim roles As List = m.GetDefault("roles", EmptyList)
		Dim roleStr As String = ""
		For Each r As String In roles
			If roleStr <> "" Then roleStr = roleStr & ","
			roleStr = roleStr & r
		Next
		Dim line As String = m.GetDefault("name", "Player") & CRLF & roleStr & _
			" · pos " & m.GetDefault("preferredPosition", m.GetDefault("favPosition", "-")) & _
			" · #" & m.GetDefault("squadNumber", "-")
		clv.AddTextItem(line, m.Get("id"))
	Next
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub btnAdd_Click
	Dim n As String = edtPlayerName.Text.Trim
	If n = "" Then Return
	Dim member As Map
	member.Initialize
	member.Put("id", "local_" & modAppState.NewId)
	member.Put("name", n)
	member.Put("avatar", "")
	Dim roles As List
	roles.Initialize
	roles.Add("PLAYER")
	member.Put("roles", roles)
	modDb.AddMember(modAppState.SelectedClubId, member)
	' Refresh from server after write
	modDb.FetchInitialData
	edtPlayerName.Text = ""
	Refresh
End Sub

Private Sub clv_ItemLongClick (Index As Int, Value As Object)
	If Value = "" Then Return
	modDb.RemoveMember(modAppState.SelectedClubId, Value)
	modDb.FetchInitialData
	Refresh
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Clubs")
End Sub
