B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Match hub — entry for squad / lineup / subs / live / stats / post-match.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private lblTitle As Label
	Private lblStatus As Label
	Private match As Map
	Private btnLive As Button
	Private btnDelete As Button
	Private sv As ScrollView
	Private content As Panel
	Private dialog As B4XDialog
	Private contentTop As Int
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Match", "btnBack", "", "", True)
	contentTop = chrome.Get("ContentTop")
	lblTitle = chrome.Get("TitleLabel")
	
	lblStatus.Initialize("")
	lblStatus.TextSize = 12
	lblStatus.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(lblStatus, 16dip, contentTop, Root.Width - 32dip, 20dip)
	
	Dim listTop As Int = contentTop + 28dip
	sv.Initialize(1400dip)
	Root.AddView(sv, 0, listTop, Root.Width, Root.Height - listTop)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
	
	Dim y As Int = 8dip
	Dim w As Int = Root.Width - 32dip
	Dim h As Int = modUI.HubNavCardHeight
	Dim gap As Int = 12dip
	
	Dim c1 As Panel = CreateDarkHubCard(w, "Squad", "Confirm who is available", "btnSquad")
	content.AddView(c1, 16dip, y, w, h)
	y = y + h + gap
	
	Dim c2 As Panel = CreateDarkHubCard(w, "Lineup", "Formation and starting XI", "btnLineup")
	content.AddView(c2, 16dip, y, w, h)
	y = y + h + gap
	
	Dim c3 As Panel = CreateDarkHubCard(w, "Sub plan", "Fair 4-quarter rotations", "btnSubs")
	content.AddView(c3, 16dip, y, w, h)
	y = y + h + gap
	
	Dim c4 As Panel = CreateDarkHubCard(w, "Live feed", "Score, goals, cards, events", "btnLiveFeed")
	content.AddView(c4, 16dip, y, w, h)
	y = y + h + gap
	
	Dim c5 As Panel = CreateDarkHubCard(w, "Match stats", "Goals, assists, awards, minutes", "btnStats")
	content.AddView(c5, 16dip, y, w, h)
	y = y + h + gap
	
	Dim c6 As Panel = CreateDarkHubCard(w, "Post-match", "Summary, POTM, fan votes", "btnSummary")
	content.AddView(c6, 16dip, y, w, h)
	y = y + h + 24dip
	
	btnLive.Initialize("btnGoLive")
	btnLive.Text = "Go Live"
	btnLive.Color = modConfig.COLOR_DANGER
	btnLive.TextColor = Colors.White
	content.AddView(btnLive, 16dip, y, w, 52dip)
	y = y + 64dip
	
	btnDelete.Initialize("btnDelete")
	btnDelete.Text = "Delete match"
	btnDelete.Color = 0xFF7F1D1D
	btnDelete.TextColor = Colors.White
	content.AddView(btnDelete, 16dip, y, w, 48dip)
	y = y + 64dip
	
	content.Height = Max(y, Root.Height)
	sv.Panel.Height = content.Height
End Sub

Private Sub CreateDarkHubCard(Width As Int, title As String, subtitle As String, EventName As String) As Panel
	Dim card As Panel
	card.Initialize(EventName)
	card.Background = modUI.RoundedBg(modConfig.COLOR_DARK_CARD, 14dip)
	
	Dim lblT As Label
	lblT.Initialize("")
	lblT.Text = title
	lblT.TextSize = 16
	lblT.TextColor = modConfig.COLOR_DARK_TEXT
	lblT.Typeface = Typeface.DEFAULT_BOLD
	lblT.SingleLine = True
	card.AddView(lblT, 16dip, 14dip, Width - 48dip, 24dip)
	
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = subtitle
	lblS.TextSize = 12
	lblS.TextColor = modConfig.COLOR_DARK_MUTED
	lblS.SingleLine = True
	card.AddView(lblS, 16dip, 40dip, Width - 48dip, 20dip)
	
	Dim chev As Label
	chev.Initialize("")
	chev.Text = ">"
	chev.TextSize = 18
	chev.TextColor = modConfig.COLOR_ACCENT
	chev.Gravity = Gravity.CENTER
	card.AddView(chev, Width - 36dip, 18dip, 28dip, 36dip)
	Return card
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	Dim t As String = match.GetDefault("title", "Match")
	lblTitle.Text = t
	Dim st As String = match.GetDefault("status", "UPCOMING")
	Dim loc As String = match.GetDefault("location", "")
	Dim when As String = match.GetDefault("date", "") & "  " & match.GetDefault("kickOffTime", "")
	lblStatus.Text = st & "  ·  " & when.Trim
	If loc <> "" Then lblStatus.Text = lblStatus.Text & "  ·  " & loc
	btnLive.Visible = (st = "UPCOMING")
End Sub

Private Sub btnSquad_Click
	B4XPages.ShowPage("MatchSquad")
End Sub

Private Sub btnLineup_Click
	B4XPages.ShowPage("MatchLineup")
End Sub

Private Sub btnSubs_Click
	B4XPages.ShowPage("MatchSubs")
End Sub

Private Sub btnLiveFeed_Click
	B4XPages.ShowPage("LiveFeed")
End Sub

Private Sub btnStats_Click
	B4XPages.ShowPage("MatchStats")
End Sub

Private Sub btnSummary_Click
	B4XPages.ShowPage("MatchSummary")
End Sub

Private Sub btnGoLive_Click
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	match.Put("status", "LIVE")
	Dim kickMs As Long = DateTime.Now
	match.Put("liveStartedAt", kickMs)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	Dim ev As Map
	ev.Initialize
	ev.Put("id", modAppState.NewId)
	ev.Put("matchId", match.Get("id"))
	ev.Put("userId", modAppState.CurrentUser.GetDefault("id", ""))
	ev.Put("userName", modAppState.CurrentUser.GetDefault("name", ""))
	ev.Put("type", "START")
	ev.Put("content", "Kick-off!")
	ev.Put("timestamp", kickMs)
	Dim details As Map
	details.Initialize
	details.Put("minute", 0)
	DateTime.TimeFormat = "HH:mm"
	details.Put("clockTime", DateTime.Time(kickMs))
	ev.Put("details", details)
	modDb.SaveEvent(ev)
	modAppState.UpsertEvent(ev)
	B4XPages.ShowPage("LiveFeed")
End Sub

Private Sub btnDelete_Click
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	Dim title As String = match.GetDefault("title", "this match")
	dialog.Title = "Delete match"
	Wait For (dialog.Show("Delete """ & title & """ and all its events, stats, and post-match data? This cannot be undone.", "Delete", "Cancel", "")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim mid As String = match.GetDefault("id", "")
	If mid = "" Then
		ToastMessageShow("Match not found", False)
		Return
	End If
	If modDb.DeleteMatch(mid) = False Then
		Dim err As String = modSupabase.LastError
		If err = "" Then err = "Delete failed"
		ToastMessageShow(err, True)
		Return
	End If
	ToastMessageShow("Match deleted", False)
	B4XPages.ShowPage("Matches")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Matches")
End Sub
