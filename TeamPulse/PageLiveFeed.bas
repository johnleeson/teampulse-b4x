B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Live match feed: score, period events, goals, subs, cards.
Sub Class_Globals
	Private Root As B4XView
	Private lblScore As Label
	Private lblStatus As Label
	Private clv As CustomListView
	Private match As Map
	Private club As Map
	Private spnPlayer As Spinner
	Private spnAssist As Spinner
	Private playerIds As List
End Sub

Public Sub Initialize
	playerIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFF0F172A
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
	Refresh
End Sub

Private Sub BuildUI
	lblStatus.Initialize("")
	lblStatus.TextColor = 0xFF94A3B8
	lblStatus.Gravity = Gravity.CENTER
	Root.AddView(lblStatus, 0, 8dip, Root.Width, 24dip)
	
	lblScore.Initialize("")
	lblScore.TextColor = Colors.White
	lblScore.TextSize = 36
	lblScore.Typeface = Typeface.DEFAULT_BOLD
	lblScore.Gravity = Gravity.CENTER
	Root.AddView(lblScore, 0, 36dip, Root.Width, 56dip)
	
	Dim row As Int = 100dip
	AddAction("GOAL", "btnGoal", 8dip, row, modConfig.COLOR_SUCCESS)
	AddAction("SUB", "btnSub", Root.Width / 4 + 4dip, row, modConfig.COLOR_ACCENT)
	AddAction("YC", "btnYC", Root.Width / 2 + 4dip, row, 0xFFF59E0B)
	AddAction("RC", "btnRC", Root.Width * 3 / 4 + 4dip, row, modConfig.COLOR_DANGER)
	
	row = 156dip
	AddAction("HT", "btnHT", 8dip, row, 0xFFFB923C)
	AddAction("2H", "btn2H", Root.Width / 4 + 4dip, row, 0xFF38BDF8)
	AddAction("END", "btnEnd", Root.Width / 2 + 4dip, row, 0xFF64748B)
	AddAction("Back", "btnBack", Root.Width * 3 / 4 + 4dip, row, 0xFF334155)
	
	spnPlayer.Initialize("")
	Root.AddView(spnPlayer, 8dip, 220dip, Root.Width / 2 - 12dip, 40dip)
	spnAssist.Initialize("")
	Root.AddView(spnAssist, Root.Width / 2, 220dip, Root.Width / 2 - 8dip, 40dip)
	
	clv.Initialize(Me, "clv")
	Root.AddView(clv.AsView, 0, 272dip, Root.Width, Root.Height - 280dip)
End Sub

Private Sub AddAction(text As String, event As String, left As Int, top As Int, col As Int)
	Dim b As Button
	b.Initialize(event)
	b.Text = text
	b.TextSize = 11
	b.Color = col
	b.TextColor = Colors.White
	Root.AddView(b, left, top, Root.Width / 4 - 12dip, 44dip)
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", ""))
	playerIds.Initialize
	spnPlayer.Clear
	spnAssist.Clear
	spnAssist.Add("(assist none)")
	playerIds.Add("")
	Dim members As List = club.GetDefault("members", EmptyList)
	For Each mem As Map In members
		spnPlayer.Add(mem.GetDefault("name", ""))
		spnAssist.Add(mem.GetDefault("name", ""))
		playerIds.Add(mem.Get("id"))
	Next
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Public Sub Refresh
	lblStatus.Text = match.GetDefault("status", "") & " · " & match.GetDefault("title", "")
	lblScore.Text = match.GetDefault("scoreA", 0) & "  -  " & match.GetDefault("scoreB", 0)
	clv.Clear
	Dim events As List = modAppState.EventsForMatch(match.Get("id"))
	' newest first
	For i = events.Size - 1 To 0 Step -1
		Dim e As Map = events.Get(i)
		clv.AddTextItem(e.GetDefault("type", "") & " · " & e.GetDefault("content", ""), e.Get("id"))
	Next
	If events.Size = 0 Then clv.AddTextItem("No events yet.", "")
End Sub

Private Sub SelectedPlayerId As String
	Dim members As List = club.GetDefault("members", EmptyList)
	If spnPlayer.SelectedIndex < 0 Or spnPlayer.SelectedIndex >= members.Size Then Return ""
	Dim mem As Map = members.Get(spnPlayer.SelectedIndex)
	Return mem.GetDefault("id", "")
End Sub

Private Sub SelectedAssistId As String
	If spnAssist.SelectedIndex <= 0 Then Return ""
	Dim members As List = club.GetDefault("members", EmptyList)
	Dim idx As Int = spnAssist.SelectedIndex - 1
	If idx < 0 Or idx >= members.Size Then Return ""
	Dim mem As Map = members.Get(idx)
	Return mem.GetDefault("id", "")
End Sub

Private Sub AddEvent(etype As String, content As String, details As Map)
	Dim ev As Map
	ev.Initialize
	ev.Put("id", modAppState.NewId)
	ev.Put("matchId", match.Get("id"))
	ev.Put("userId", modAppState.CurrentUser.GetDefault("id", ""))
	ev.Put("userName", modAppState.CurrentUser.GetDefault("name", ""))
	ev.Put("type", etype)
	ev.Put("content", content)
	ev.Put("timestamp", DateTime.Now)
	ev.Put("details", details)
	modDb.SaveEvent(ev)
	modAppState.UpsertEvent(ev)
	Refresh
End Sub

Private Sub btnGoal_Click
	Dim pid As String = SelectedPlayerId
	Dim aid As String = SelectedAssistId
	Dim details As Map
	details.Initialize
	details.Put("scorer", pid)
	details.Put("assist", aid)
	details.Put("team", "A")
	Dim pname As String = spnPlayer.SelectedItem
	Dim content As String = "GOAL! " & pname
	If aid <> "" Then content = content & " (assist " & spnAssist.SelectedItem & ")"
	match.Put("scoreA", match.GetDefault("scoreA", 0) + 1)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	' bump playerStats goals
	BumpPlayerStat(pid, "goals", 1)
	If aid <> "" Then BumpPlayerStat(aid, "assists", 1)
	AddEvent("GOAL", content, details)
End Sub

Private Sub BumpPlayerStat(playerId As String, field As String, delta As Int)
	If playerId = "" Then Return
	Dim stats As Map = match.GetDefault("playerStats", EmptyMap2)
	If stats.IsInitialized = False Then stats.Initialize
	Dim ps As Map
	If stats.ContainsKey(playerId) Then
		ps = stats.Get(playerId)
	Else
		ps.Initialize
		ps.Put("goals", 0)
		ps.Put("assists", 0)
		ps.Put("yellowCards", 0)
		ps.Put("redCards", 0)
	End If
	ps.Put(field, ps.GetDefault(field, 0) + delta)
	stats.Put(playerId, ps)
	match.Put("playerStats", stats)
	modDb.SaveMatch(match)
End Sub

Private Sub EmptyMap2 As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub btnSub_Click
	Dim details As Map
	details.Initialize
	details.Put("playerOut", SelectedPlayerId)
	details.Put("playerIn", SelectedAssistId)
	AddEvent("SUB", "Substitution: " & spnPlayer.SelectedItem & " → " & spnAssist.SelectedItem, details)
End Sub

Private Sub btnYC_Click
	Dim details As Map
	details.Initialize
	details.Put("player", SelectedPlayerId)
	BumpPlayerStat(SelectedPlayerId, "yellowCards", 1)
	AddEvent("YELLOW_CARD", "Yellow card: " & spnPlayer.SelectedItem, details)
End Sub

Private Sub btnRC_Click
	Dim details As Map
	details.Initialize
	details.Put("player", SelectedPlayerId)
	BumpPlayerStat(SelectedPlayerId, "redCards", 1)
	AddEvent("RED_CARD", "Red card: " & spnPlayer.SelectedItem, details)
End Sub

Private Sub btnHT_Click
	Dim details As Map
	details.Initialize
	AddEvent("HALF_TIME", "Half Time", details)
End Sub

Private Sub btn2H_Click
	Dim details As Map
	details.Initialize
	AddEvent("SECOND_HALF", "Second half underway", details)
End Sub

Private Sub btnEnd_Click
	match.Put("status", "COMPLETED")
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	Dim details As Map
	details.Initialize
	AddEvent("END", "Full Time " & match.GetDefault("scoreA", 0) & "-" & match.GetDefault("scoreB", 0), details)
	ToastMessageShow("Match completed", False)
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Matches")
End Sub
