B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Club roster — dark player cards aligned with Match Squad.
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
	Private lblTitle As Label
	Private club As Map
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
	Dim chrome As Map = modUI.AddPageChrome(Root, "Roster", "btnBack", "btnAdd", "+", True)
	lblTitle = chrome.Get("TitleLabel")
	Dim top As Int = chrome.Get("ContentTop")
	clv = modUI.AddCustomListViewThemed(Root, 0, top, Root.Width, Root.Height - top - 48dip, Me, "clv", True)
	
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Tap a player to edit · long-press to remove"
	hint.TextSize = 12
	hint.TextColor = modConfig.COLOR_DARK_MUTED
	hint.Gravity = Gravity.CENTER
	Root.AddView(hint, 16dip, Root.Height - 40dip, Root.Width - 32dip, 32dip)
End Sub

Public Sub Refresh
	club = modAppState.FindClub(modAppState.SelectedClubId)
	lblTitle.Text = club.GetDefault("name", "Club")
	clv.Clear
	modUI.ApplyDarkListBackground(clv, modConfig.COLOR_DARK_BG)
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim cardW As Int = Root.Width - 24dip
	If members.Size = 0 Then
		Dim empty As Panel = modUI.CreateSimpleRowThemed(cardW, "No members yet. Tap + to add.", "", True)
		empty.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(empty, "")
		Return
	End If
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim m As Map = members.Get(i)
		Dim card As Panel = modUI.CreatePlayerCardThemed(cardW, m, "CONFIRMED", False, True)
		Dim h As Int = modUI.PlayerCardHeight + 8dip
		card.SetLayout(0, 0, cardW, h)
		clv.Add(card, m.GetDefault("id", ""))
		Dim iv As ImageView = modUI.PlayerCardImageView(card)
		If iv.IsInitialized Then
			Dim url As String = m.GetDefault("avatar", "")
			If url <> "" Then LoadAvatar(iv, url)
		End If
	Next
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
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
			Log("Roster LoadAvatar: " & LastException.Message)
		End Try
	End If
	job.Release
End Sub

Private Sub btnAdd_Click
	Dim member As Map
	member.Initialize
	member.Put("name", "New player")
	member.Put("avatar", "")
	Dim roles As List
	roles.Initialize
	roles.Add("PLAYER")
	member.Put("roles", roles)
	Dim newId As String = modDb.AddMember(modAppState.SelectedClubId, member)
	If newId = "" Then
		Dim err As String = modSupabase.LastError
		If err = "" Then err = "Could not add player"
		ToastMessageShow(err, True)
		Return
	End If
	modDb.FetchInitialData
	modAppState.SelectedPlayerId = newId
	modAppState.PlayerEditReturnPage = "ClubMembers"
	B4XPages.ShowPage("PlayerEdit")
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	modAppState.SelectedPlayerId = Value
	modAppState.PlayerEditReturnPage = "ClubMembers"
	B4XPages.ShowPage("PlayerEdit")
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
