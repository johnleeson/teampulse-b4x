B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Squad availability — dark player cards with avatars + edit.
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
	Private lblCount As Label
	Private match As Map
	Private club As Map
	Private memberCount As Int
	Private avatarLoaded As Map
End Sub

Public Sub Initialize
	avatarLoaded.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
	avatarLoaded.Initialize
	Refresh
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Me, Root, "Squad", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	
	lblCount.Initialize("")
	modUI.SetTextSize(lblCount, 13)
	lblCount.TextColor = modConfig.COLOR_DARK_TEXT
	modUI.SetBold(lblCount, True)
	Root.AddView(lblCount, 16dip, top, modUI.ViewWidth(Root) - 32dip, 22dip)
	
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Tap to cycle Maybe → In → Out · ✎ to edit"
	modUI.SetTextSize(hint, 11)
	hint.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(hint, 16dip, top + 24dip, modUI.ViewWidth(Root) - 32dip, 18dip)
	
	Dim listTop As Int = top + 50dip
	clv = modUI.AddCustomListViewThemed(Root, 0, listTop, modUI.ViewWidth(Root), modUI.ViewHeight(Root) - listTop, Me, "clv", True)
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", modAppState.SelectedClubId))
End Sub

Public Sub Refresh
	clv.Clear
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	memberCount = members.Size
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	If availability.IsInitialized = False Then availability.Initialize
	Dim cardW As Int = modUI.ViewWidth(Root) - 24dip
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		Dim id As String = mem.GetDefault("id", "")
		Dim av As String = availability.GetDefault(id, "UNKNOWN")
		Dim card As Panel = modUI.CreatePlayerCard(cardW, mem, av, False)
		Dim h As Int = modUI.PlayerCardHeight + 8dip
		modUI.PlaceView(card, 0, 0, cardW, h)
		
		Dim editLeft As Int = cardW - 12dip - 56dip - 10dip - 40dip
		Dim editTop As Int = (modUI.PlayerCardHeight - 40dip) / 2
		If card.Tag Is Map Then
			Dim meta As Map = card.Tag
			editLeft = meta.GetDefault("editLeft", editLeft)
			editTop = meta.GetDefault("editTop", editTop)
		End If
		
		Dim btnEdit As Button
		modUI.InitButton(Me, btnEdit, "btnEditPlayer")
		btnEdit.Text = "✎"
		btnEdit.Tag = id
		btnEdit.Color = Colors.Transparent
		modUI.SetButtonTextColor(btnEdit, modConfig.COLOR_ACCENT)
		modUI.SetTextSize(btnEdit, 18)
		modUI.SetAlign(btnEdit, "CENTER", "CENTER")
		modUI.SetBold(btnEdit, True)
		card.AddView(btnEdit, editLeft, editTop, 40dip, 40dip)
		
		clv.Add(card, id)
		Dim iv As ImageView = modUI.PlayerCardImageView(card)
		If iv.IsInitialized Then
			Dim url As String = ""
			If iv.Tag <> Null Then url = iv.Tag
			If url <> "" And avatarLoaded.ContainsKey(id) = False Then
				avatarLoaded.Put(id, True)
				LoadAvatar(iv, url)
			End If
		End If
	Next
	RefreshCount
End Sub

Private Sub RefreshCount
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	If availability.IsInitialized = False Then availability.Initialize
	Dim confirmed As Int = 0
	For Each k As String In availability.Keys
		If availability.Get(k) = "CONFIRMED" Then confirmed = confirmed + 1
	Next
	lblCount.Text = confirmed & " confirmed · " & memberCount & " in club"
End Sub

Private Sub CardAtIndex(Index As Int) As Panel
	Dim p As B4XView = clv.GetPanel(Index)
	Dim card As Panel
	If p Is Panel Then
		card = p
		Return card
	End If
	Return card
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
				modUI.SetImageFill(iv)
			End If
		Catch
			Log("LoadAvatar: " & LastException.Message)
		End Try
	End If
	job.Release
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	Dim id As String = Value
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	If availability.IsInitialized = False Then availability.Initialize
	Dim cur As String = availability.GetDefault(id, "UNKNOWN")
	Dim nextAv As String = modUI.NextAvailability(cur)
	availability.Put(id, nextAv)
	match.Put("availability", availability)
	PersistSignedUp(availability)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	
	Dim card As Panel = CardAtIndex(Index)
	If card.IsInitialized Then modUI.UpdatePlayerCardAvailability(card, nextAv)
	RefreshCount
End Sub

Private Sub btnEditPlayer_Click
	Dim b As Button = modUI.ClickedButton(Sender)
	Dim id As String = ""
	If b.Tag <> Null Then id = b.Tag
	If id = "" Then Return
	modAppState.SelectedPlayerId = id
	modAppState.SelectedClubId = club.GetDefault("id", modAppState.SelectedClubId)
	modAppState.PlayerEditReturnPage = "MatchSquad"
	B4XPages.ShowPage("PlayerEdit")
End Sub

Private Sub PersistSignedUp(availability As Map)
	Dim confirmedIds As List
	confirmedIds.Initialize
	For Each k As String In availability.Keys
		If availability.Get(k) = "CONFIRMED" Then confirmedIds.Add(k)
	Next
	match.Put("signedUpPlayerIds", confirmedIds)
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("MatchHub")
End Sub
