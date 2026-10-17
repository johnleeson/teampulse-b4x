B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private lblHello As Label
	Private btnRefresh As Button
	Private nav As Panel
	Private sv As ScrollView
	Private content As Panel
	Private itemValues As List
	Private pageW As Int
	Private pageH As Int
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
	LayoutChrome
	Refresh
End Sub

Private Sub B4XPage_Disappear
	pageVisible = False
	pollTimer.Enabled = False
End Sub

Private Sub pollTimer_Tick
	If pageVisible = False Then Return
	CallSubDelayed(B4XPages.MainPage, "KickSyncAndPull")
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	If Width < 80dip Or Height < 80dip Then Return
	pageW = Width
	pageH = Height
	LayoutChrome
	Refresh
End Sub

Private Sub BuildUI
	Root.Color = modConfig.COLOR_DARK_BG
	Dim w As Int = modUI.ViewWidth(Root)
	Dim h As Int = modUI.ViewHeight(Root)
	
	lblHello.Initialize("lblHello")
	lblHello.TextColor = modConfig.COLOR_DARK_TEXT
	modUI.SetTextSize(lblHello, 18)
	modUI.SetSingleLine(lblHello, True)
	modUI.SetBold(lblHello, True)
	modUI.SetAlign(lblHello, "CENTER", "LEFT")
	Root.AddView(lblHello, 16dip, 10dip, w - 72dip, 44dip)
	
	btnRefresh = modUI.CreateChromeIconButton(Me, "btnRefresh", "↻", Colors.Transparent, Colors.White)
	modUI.SetTextSize(btnRefresh, 24)
	Root.AddView(btnRefresh, w - 52dip, 10dip, 44dip, 44dip)
	
	nav.Initialize("")
	nav.Color = modConfig.COLOR_DARK_CARD
	Root.AddView(nav, 0, h - 64dip, w, 64dip)
	AddNavBtn(nav, 0, "Clubs", "btnClubs")
	AddNavBtn(nav, 1, "Matches", "btnMatches")
	AddNavBtn(nav, 2, "Training", "btnTraining")
	AddNavBtn(nav, 3, "Stats", "btnStats")
	AddNavBtn(nav, 4, "Out", "btnOut")
	
	modUI.InitScroll(sv, h)
	Root.AddView(sv, 0, 56dip, w, h - 56dip - 64dip)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
	content.Width = w
End Sub

Private Sub LayoutChrome
	If content.IsInitialized = False Then Return
	Dim w As Int = LayoutWidth
	Dim h As Int = LayoutHeight
	modUI.PlaceView(lblHello, 16dip, 10dip, w - 72dip, 44dip)
	modUI.PlaceView(btnRefresh, w - 52dip, 10dip, 44dip, 44dip)
	modUI.PlaceView(nav, 0, h - 64dip, w, 64dip)
	modUI.PlaceView(sv, 0, 56dip, w, h - 56dip - 64dip)
	Dim btnW As Int = w / 5
	Dim i As Int
	For i = 0 To nav.NumberOfViews - 1
		modUI.PlaceView(nav.GetView(i), i * btnW, 8dip, btnW, 48dip)
	Next
	content.Width = w
End Sub

Private Sub LayoutWidth As Int
	Dim w As Int = 0
	If pageW >= 80dip Then w = pageW
	If Root.Width >= 80dip And (w = 0 Or Root.Width < w) Then w = Root.Width
	If w < 80dip Then w = modUI.ViewWidth(Root)
	Return w
End Sub

Private Sub LayoutHeight As Int
	Dim h As Int = 0
	If pageH >= 80dip Then h = pageH
	If Root.Height >= 80dip And (h = 0 Or Root.Height < h) Then h = Root.Height
	If h < 80dip Then h = modUI.ViewHeight(Root)
	Return h
End Sub

Private Sub AddNavBtn(parent As Panel, index As Int, text As String, event As String)
	Dim w As Int = parent.Width / 5
	Dim b As Button
	modUI.InitButton(Me, b, event)
	b.Text = text
	modUI.SetTextSize(b, 11)
	modUI.RoundView(b, Colors.Transparent, 0)
	modUI.SetButtonTextColor(b, modConfig.COLOR_DARK_TEXT)
	parent.AddView(b, index * w, 8dip, w, 48dip)
End Sub

Public Sub Refresh
	modUI.SetClickTarget(Me)
	Dim who As String = "Coach"
	If modAppState.IsAuthenticated Then who = "" & modAppState.CurrentUser.GetDefault("name", "Coach")
	Dim suffix As String = RoleSuffix
	lblHello.Text = "Hi, " & who & suffix
	
	content.RemoveAllViews
	itemValues.Clear
	Dim y As Int = 8dip
	Dim cardW As Int = LayoutWidth - 24dip
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
		modUI.InitButton(Me, btnExport, "btnExport")
		btnExport.Text = "Export spreadsheet"
		modUI.SetButtonTextColor(btnExport, Colors.White)
		modUI.SetTextSize(btnExport, 15)
		modUI.RoundView(btnExport, modConfig.COLOR_ACCENT, 8dip)
		content.AddView(btnExport, 12dip, y, cardW, 48dip)
		y = y + 48dip + 4dip
		Dim exportHint As Label
		exportHint.Initialize("")
		exportHint.Text = "Players, matches, events, and season stats. Nothing is changed."
		exportHint.TextColor = modConfig.COLOR_DARK_MUTED
		modUI.SetTextSize(exportHint, 12)
		modUI.SetAlign(exportHint, "CENTER", "CENTER")
		content.AddView(exportHint, 12dip, y, cardW, 28dip)
		y = y + 28dip + gap
	End If
	content.Height = Max(y + 16dip, sv.Height)
End Sub

Private Sub card_Click
	Dim p As Panel = modUI.ClickedPanel(Sender)
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
		modPlatform.Toast("Join a club before changing your role", False)
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
	modPlatform.ProgressShow("Refreshing...")
	CallSubDelayed(B4XPages.MainPage, "RequestDashboardRefresh")
End Sub

Private Sub btnExport_Click
	If exporting Then Return
	exporting = True
	modPlatform.ProgressShow2("Building spreadsheet...", False)
	Dim built As Map = modExport.BuildFile
	modPlatform.ProgressHide
	If built.GetDefault("ok", False) = False Then
		exporting = False
		xui.MsgboxAsync(built.GetDefault("message", "Could not create the spreadsheet. Nothing was changed."), "Export")
		Return
	End If
	Dim shareErr As String = modExport.ShareFile(built.GetDefault("dir", ""), built.GetDefault("file", ""))
	exporting = False
	If shareErr <> "" Then xui.MsgboxAsync(shareErr, "Export")
End Sub
