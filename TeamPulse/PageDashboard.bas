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
End Sub

Public Sub Initialize
	pageVisible = False
	itemValues.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = modConfig.COLOR_SURFACE
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
	Dim bar As Panel
	bar.Initialize("")
	bar.Color = modConfig.COLOR_PRIMARY
	Root.AddView(bar, 0, 0, Root.Width, 96dip)
	
	lblHello.Initialize("")
	lblHello.TextColor = Colors.White
	lblHello.TextSize = 18
	lblHello.Typeface = Typeface.DEFAULT_BOLD
	bar.AddView(lblHello, 16dip, 40dip, Root.Width - 128dip, 40dip)
	
	Dim btnRefresh As Button
	btnRefresh.Initialize("btnRefresh")
	btnRefresh.Text = "Refresh"
	btnRefresh.Color = modConfig.COLOR_ACCENT
	btnRefresh.TextColor = Colors.White
	Root.AddView(btnRefresh, Root.Width - 112dip, 28dip, 96dip, 40dip)
	
	Dim nav As Panel
	nav.Initialize("")
	nav.Color = Colors.White
	Root.AddView(nav, 0, Root.Height - 64dip, Root.Width, 64dip)
	AddNavBtn(nav, 0, "Clubs", "btnClubs")
	AddNavBtn(nav, 1, "Matches", "btnMatches")
	AddNavBtn(nav, 2, "Stats", "btnStats")
	AddNavBtn(nav, 3, "Out", "btnOut")
	
	sv.Initialize(Root.Height)
	Root.AddView(sv, 0, 96dip, Root.Width, Root.Height - 96dip - 64dip)
	content = sv.Panel
	content.Color = modConfig.COLOR_SURFACE
End Sub

Private Sub AddNavBtn(parent As Panel, index As Int, text As String, event As String)
	Dim w As Int = parent.Width / 4
	Dim b As Button
	b.Initialize(event)
	b.Text = text
	b.TextSize = 12
	b.Color = Colors.White
	b.TextColor = modConfig.COLOR_PRIMARY
	parent.AddView(b, index * w, 8dip, w, 48dip)
End Sub

Public Sub Refresh
	Dim name As String = "Coach"
	If modAppState.IsAuthenticated Then name = modAppState.CurrentUser.GetDefault("name", "Coach")
	lblHello.Text = "Hi, " & name
	
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
	
	Dim hdr1 As Panel = modUI.CreateSectionHeader(cardW, "Live & upcoming matches")
	content.AddView(hdr1, 12dip, y, cardW, modUI.SectionHeaderHeight)
	y = y + modUI.SectionHeaderHeight + 4dip
	
	Dim any As Boolean = False
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		Dim st As String = m.GetDefault("status", "")
		If st = "LIVE" Or st = "UPCOMING" Then
			any = True
			Dim card As Panel = modUI.CreateMatchCard(cardW, m, "card")
			Dim idx As Int = itemValues.Size
			itemValues.Add(m.Get("id"))
			card.Tag = idx
			content.AddView(card, 12dip, y, cardW, modUI.MatchCardHeight)
			y = y + modUI.MatchCardHeight + gap
		End If
	Next
	If any = False Then
		Dim empty As Panel = modUI.CreateSimpleRow(cardW, "No upcoming matches. Create one under Matches.", "")
		content.AddView(empty, 12dip, y, cardW, modUI.SimpleRowHeight)
		y = y + modUI.SimpleRowHeight + gap
	End If
	
	Dim hdr2 As Panel = modUI.CreateSectionHeader(cardW, "Your clubs")
	content.AddView(hdr2, 12dip, y, cardW, modUI.SectionHeaderHeight)
	y = y + modUI.SectionHeaderHeight + 4dip
	
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	If myClubs.Size = 0 Then
		Dim emptyClub As Panel = modUI.CreateSimpleRow(cardW, "You are not in a club yet. Join or create one.", "")
		content.AddView(emptyClub, 12dip, y, cardW, modUI.SimpleRowHeight)
		y = y + modUI.SimpleRowHeight + gap
	Else
		For i = 0 To myClubs.Size - 1
			Dim c As Map = myClubs.Get(i)
			Dim row As Panel = modUI.CreateSimpleRow(cardW, c.GetDefault("name", "Club") & "  ·  " & c.GetDefault("type", ""), "card")
			Dim cIdx As Int = itemValues.Size
			itemValues.Add("club:" & c.Get("id"))
			row.Tag = cIdx
			content.AddView(row, 12dip, y, cardW, modUI.SimpleRowHeight)
			y = y + modUI.SimpleRowHeight + gap
		Next
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

Private Sub btnClubs_Click
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnMatches_Click
	B4XPages.ShowPage("Matches")
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
