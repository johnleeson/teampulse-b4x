B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private lblHello As Label
	Private sv As ScrollView
	Private content As Panel
	Private itemValues As List
	Private pollTimer As Timer
	Private pageVisible As Boolean
	Private exporting As Boolean
End Sub

Public Sub Initialize
	pageVisible = False
	itemValues.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
	pollTimer.Initialize("pollTimer", 15000)
	pollTimer.Enabled = False
End Sub

Private Sub B4XPage_Appear
	pageVisible = True
	pollTimer.Enabled = True
	Refresh
End Sub

Private Sub B4XPage_Disappear
	pageVisible = False
	pollTimer.Enabled = False
End Sub

Private Sub pollTimer_Tick
	If pageVisible = False Then Return
	modDb.FetchInitialData
	Refresh
End Sub

Private Sub BuildUI
	Root.Color = modConfig.COLOR_DARK_BG
	
	lblHello.Initialize("lblHello")
	lblHello.TextColor = modConfig.COLOR_DARK_TEXT
	lblHello.TextSize = 18
	lblHello.SingleLine = True
	lblHello.Typeface = Typeface.DEFAULT_BOLD
	lblHello.Gravity = Gravity.CENTER_VERTICAL
	Root.AddView(lblHello, 16dip, 10dip, Root.Width - 72dip, 44dip)
	
	Dim btnRefresh As Button = modUI.CreateChromeIconButton("btnRefresh", "↻", Colors.Transparent, Colors.White)
	btnRefresh.TextSize = 24
	Root.AddView(btnRefresh, Root.Width - 52dip, 10dip, 44dip, 44dip)
	
	Dim nav As Panel
	nav.Initialize("")
	nav.Color = modConfig.COLOR_DARK_CARD
	Root.AddView(nav, 0, Root.Height - 64dip, Root.Width, 64dip)
	AddNavBtn(nav, 0, "Clubs", "btnClubs")
	AddNavBtn(nav, 1, "Matches", "btnMatches")
	AddNavBtn(nav, 2, "Training", "btnTraining")
	AddNavBtn(nav, 3, "Stats", "btnStats")
	AddNavBtn(nav, 4, "Out", "btnOut")
	
	sv.Initialize(Root.Height)
	Root.AddView(sv, 0, 56dip, Root.Width, Root.Height - 56dip - 64dip)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
End Sub

Private Sub AddNavBtn(parent As Panel, index As Int, text As String, event As String)
	Dim w As Int = parent.Width / 5
	Dim b As Button
	b.Initialize(event)
	b.Text = text
	b.TextSize = 11
	Dim cd As ColorDrawable
	cd.Initialize(Colors.Transparent, 0)
	b.Background = cd
	b.TextColor = modConfig.COLOR_DARK_TEXT
	parent.AddView(b, index * w, 8dip, w, 48dip)
End Sub

Public Sub Refresh
	Dim name As String = "Coach"
	If modAppState.IsAuthenticated Then name = modAppState.CurrentUser.GetDefault("name", "Coach")
	lblHello.Text = "Hi, " & name & RoleSuffix()
	
	content.RemoveAllViews
	itemValues.Clear
	Dim y As Int = 8dip
	Dim cardW As Int = Root.Width - 24dip
	Dim gap As Int = 10dip
	
	Dim liveMatch As Map
	liveMatch.Initialize
	Dim matches As List = modAppState.Matches
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim probe As Map = matches.Get(i)
		If probe.GetDefault("status", "") = "LIVE" Then
			liveMatch = probe
			Exit
		End If
	Next
	If liveMatch.ContainsKey("id") And liveMatch.Get("id") <> "" Then
		Dim banner As Panel = modUI.CreateLiveBanner(cardW, liveMatch, "card")
		Dim bIdx As Int = itemValues.Size
		itemValues.Add(liveMatch.Get("id"))
		banner.Tag = bIdx
		content.AddView(banner, 12dip, y, cardW, modUI.LiveBannerHeight)
		y = y + modUI.LiveBannerHeight + gap
	End If
	
	Dim hdr1 As Panel = modUI.CreateSectionHeaderThemed(cardW, "Live & upcoming matches", True)
	content.AddView(hdr1, 12dip, y, cardW, modUI.SectionHeaderHeight)
	y = y + modUI.SectionHeaderHeight + 4dip
	
	Dim any As Boolean = False
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		Dim st As String = m.GetDefault("status", "")
		If st = "LIVE" Or st = "UPCOMING" Then
			any = True
			Dim card As Panel = modUI.CreateMatchCardThemed(cardW, m, "card", True)
			Dim idx As Int = itemValues.Size
			itemValues.Add(m.Get("id"))
			card.Tag = idx
			content.AddView(card, 12dip, y, cardW, modUI.MatchCardHeight)
			y = y + modUI.MatchCardHeight + gap
		End If
	Next
	If any = False Then
		Dim empty As Panel = modUI.CreateSimpleRowThemed(cardW, "No upcoming matches. Create one under Matches.", "", True)
		content.AddView(empty, 12dip, y, cardW, modUI.SimpleRowHeight)
		y = y + modUI.SimpleRowHeight + gap
	End If
	
	Dim hdr2 As Panel = modUI.CreateSectionHeaderThemed(cardW, "Your clubs", True)
	content.AddView(hdr2, 12dip, y, cardW, modUI.SectionHeaderHeight)
	y = y + modUI.SectionHeaderHeight + 4dip
	
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	If myClubs.Size = 0 Then
		Dim emptyClub As Panel = modUI.CreateSimpleRowThemed(cardW, "You are not in a club yet. Join or create one.", "", True)
		content.AddView(emptyClub, 12dip, y, cardW, modUI.SimpleRowHeight)
		y = y + modUI.SimpleRowHeight + gap
	Else
		For i = 0 To myClubs.Size - 1
			Dim c As Map = myClubs.Get(i)
			Dim row As Panel = modUI.CreateSimpleRowThemed(cardW, c.GetDefault("name", "Club") & "  ·  " & c.GetDefault("type", ""), "card", True)
			Dim cIdx As Int = itemValues.Size
			itemValues.Add("club:" & c.Get("id"))
			row.Tag = cIdx
			content.AddView(row, 12dip, y, cardW, modUI.SimpleRowHeight)
			y = y + modUI.SimpleRowHeight + gap
		Next
	End If
	If modExport.UserCanExport Then
		Dim btnExport As Button
		btnExport.Initialize("btnExport")
		btnExport.Text = "Export spreadsheet"
		btnExport.TextColor = Colors.White
		btnExport.TextSize = 15
		Dim exportBg As ColorDrawable
		exportBg.Initialize(modConfig.COLOR_ACCENT, 8dip)
		btnExport.Background = exportBg
		content.AddView(btnExport, 12dip, y, cardW, 48dip)
		y = y + 48dip + 4dip
		Dim exportHint As Label
		exportHint.Initialize("")
		exportHint.Text = "Players, matches, events, and season stats. Nothing is changed."
		exportHint.TextColor = modConfig.COLOR_DARK_MUTED
		exportHint.TextSize = 12
		exportHint.Gravity = Gravity.CENTER
		content.AddView(exportHint, 12dip, y, cardW, 28dip)
		y = y + 28dip + gap
	End If
	content.Height = Max(y + 16dip, sv.Height)
End Sub

Private Sub card_Click
	Dim p As Panel = Sender
	If p.Tag = Null Then Return
	Dim idx As Int = p.Tag
	If idx < 0 Or idx >= itemValues.Size Then Return
	Dim v As String = itemValues.Get(idx)
	If v = "" Then Return
	If v.StartsWith("club:") Then
		modAppState.SelectedClubId = v.SubString(5)
		B4XPages.ShowPage("ClubMembers")
	Else
		modAppState.SelectedMatchId = v
		Dim m As Map = modAppState.FindMatch(v)
		If m.GetDefault("status", "") = "LIVE" Then
			B4XPages.ShowPage("LiveFeed")
		Else
			B4XPages.ShowPage("MatchHub")
		End If
	End If
End Sub

Private Sub RoleSuffix As String
	If modAppState.IsAuthenticated = False Then Return ""
	Dim roles As Object = modAppState.CurrentUser.GetDefault("roles", Null)
	Dim hasPlayer As Boolean = modDb.RoleListHas(roles, "PLAYER")
	Dim hasCoach As Boolean = modDb.RoleListHas(roles, "COACH")
	Dim clubs As List = modAppState.ClubsForCurrentUser
	Dim uid As String = modAppState.CurrentUser.GetDefault("id", "")
	Dim ci As Int
	For ci = 0 To clubs.Size - 1
		Dim c As Map = clubs.Get(ci)
		Dim memObj As Object = c.GetDefault("members", Null)
		If (memObj Is List) = False Then Continue
		Dim members As List = memObj
		Dim mi As Int
		For mi = 0 To members.Size - 1
			Dim m As Map = members.Get(mi)
			If m.GetDefault("id", "") <> uid Then Continue
			If modDb.RoleListHas(m.GetDefault("roles", Null), "PLAYER") Then hasPlayer = True
			If modDb.RoleListHas(m.GetDefault("roles", Null), "COACH") Then hasCoach = True
		Next
	Next
	If hasCoach And hasPlayer Then Return "  ·  Coach, Player"
	If hasCoach Then Return "  ·  Coach"
	If hasPlayer Then Return "  ·  Player"
	Return ""
End Sub

Private Sub lblHello_Click
	If modAppState.IsAuthenticated = False Then Return
	Dim clubs As List = modAppState.ClubsForCurrentUser
	If clubs.Size = 0 Then
		ToastMessageShow("Join a club before changing your role", False)
		Return
	End If
	Dim club As Map = clubs.Get(0)
	Dim i As Int
	For i = 0 To clubs.Size - 1
		Dim c As Map = clubs.Get(i)
		If c.GetDefault("id", "") = modAppState.SelectedClubId Then
			club = c
			Exit
		End If
	Next
	modAppState.SelectedClubId = club.Get("id")
	modAppState.SelectedPlayerId = modAppState.CurrentUser.GetDefault("id", "")
	modAppState.PlayerEditReturnPage = "Dashboard"
	B4XPages.ShowPage("PlayerEdit")
End Sub

Private Sub btnClubs_Click
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnMatches_Click
	B4XPages.ShowPage("Matches")
End Sub

Private Sub btnTraining_Click
	B4XPages.ShowPage("Training")
End Sub

Private Sub btnStats_Click
	B4XPages.ShowPage("Stats")
End Sub

Private Sub btnOut_Click
	modSupabase.SignOut
	B4XPages.ShowPageAndRemovePreviousPages("Login")
End Sub

Private Sub btnRefresh_Click
	ProgressDialogShow("Refreshing...")
	modDb.FetchInitialData
	ProgressDialogHide
	Refresh
End Sub

Private Sub btnExport_Click
	If exporting Then Return
	exporting = True
	ProgressDialogShow2("Building spreadsheet...", False)
	Dim built As Map = modExport.BuildFile
	ProgressDialogHide
	If built.GetDefault("ok", False) = False Then
		exporting = False
		xui.MsgboxAsync(built.GetDefault("message", "Could not create the spreadsheet. Nothing was changed."), "Export")
		Return
	End If
	Dim shareErr As String = modExport.ShareFile(built.GetDefault("dir", ""), built.GetDefault("file", ""))
	exporting = False
	If shareErr <> "" Then xui.MsgboxAsync(shareErr, "Export")
End Sub
