B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Per-match stats: goals, assists, awards, minutes.
Sub Class_Globals
	Private Root As B4XView
	Private sv As ScrollView
	Private content As Panel
	Private match As Map
	Private club As Map
	Private nameById As Map
End Sub

Public Sub Initialize
	nameById.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildChrome
End Sub

Private Sub B4XPage_Appear
	Load
	BuildBody
End Sub

Private Sub BuildChrome
	Dim chrome As Map = modUI.AddPageChrome(Root, "Match stats", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	sv.Initialize(4000dip)
	Root.AddView(sv, 0, top, Root.Width, Root.Height - top)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", ""))
	nameById.Initialize
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		nameById.Put(mem.GetDefault("id", ""), mem.GetDefault("name", "?"))
	Next
End Sub

Private Sub PlayerName(pid As String) As String
	If pid = "" Then Return "?"
	Return nameById.GetDefault(pid, "Unknown")
End Sub

Private Sub BuildBody
	content.RemoveAllViews
	Dim y As Int = 12dip
	Dim w As Int = Root.Width - 32dip
	
	Dim hdr As Label
	hdr.Initialize("")
	hdr.Text = match.GetDefault("title", "Match") & "  ·  " & match.GetDefault("scoreA", 0) & "-" & match.GetDefault("scoreB", 0)
	hdr.TextSize = 14
	hdr.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(hdr, 16dip, y, w, 22dip)
	y = y + 32dip
	
	y = BuildGoalsSection(y, w)
	y = BuildAssistsSection(y, w)
	y = BuildAwardsSection(y, w)
	y = BuildMinutesSection(y, w)
	
	y = y + 24dip
	content.Height = Max(y, Root.Height)
	sv.Panel.Height = content.Height
End Sub

Private Sub AddSectionHeader(y As Int, text As String) As Int
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 11
	lbl.Typeface = Typeface.DEFAULT_BOLD
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(lbl, 16dip, y, Root.Width - 32dip, 18dip)
	Return y + 22dip
End Sub

Private Sub AddEmptyRow(y As Int, w As Int, msg As String) As Int
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = msg
	lbl.TextSize = 13
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(lbl, 16dip, y, w, 24dip)
	Return y + 32dip
End Sub

Private Sub AddStatRow(y As Int, w As Int, leftText As String, rightText As String) As Int
	Dim row As Panel
	row.Initialize("")
	row.Background = modUI.RoundedBg(modConfig.COLOR_DARK_CARD, 10dip)
	content.AddView(row, 16dip, y, w, 48dip)
	Dim l As Label
	l.Initialize("")
	l.Text = leftText
	l.TextSize = 14
	l.TextColor = modConfig.COLOR_DARK_TEXT
	l.Gravity = Gravity.CENTER_VERTICAL
	row.AddView(l, 12dip, 0, w - 100dip, 48dip)
	Dim r As Label
	r.Initialize("")
	r.Text = rightText
	r.TextSize = 13
	r.TextColor = modConfig.COLOR_DARK_MUTED
	r.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.RIGHT)
	row.AddView(r, w - 96dip, 0, 84dip, 48dip)
	Return y + 56dip
End Sub

Private Sub BuildGoalsSection(y As Int, w As Int) As Int
	y = AddSectionHeader(y, "GOALS")
	Dim events As List = modAppState.EventsForMatch(match.Get("id"))
	Dim any As Boolean = False
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim ev As Map = events.Get(i)
		If ev.GetDefault("type", "") <> "GOAL" Then Continue
		Dim details As Map = ev.GetDefault("details", EmptyMap)
		Dim team As String = details.GetDefault("team", "A")
		Dim minute As Object = details.GetDefault("minute", "")
		Dim clock As String = details.GetDefault("clockTime", "")
		Dim whenTxt As String = ""
		If minute <> "" Then whenTxt = minute & "'"
		If clock <> "" Then
			If whenTxt <> "" Then whenTxt = whenTxt & " · "
			whenTxt = whenTxt & clock
		End If
		If whenTxt = "" Then whenTxt = "—"
		Dim left As String
		If team = "B" Then
			left = "Opponent"
		Else
			left = PlayerName(details.GetDefault("scorer", ""))
		End If
		y = AddStatRow(y, w, left, whenTxt)
		any = True
	Next
	If any = False Then y = AddEmptyRow(y, w, "No goals recorded")
	Return y + 8dip
End Sub

Private Sub BuildAssistsSection(y As Int, w As Int) As Int
	y = AddSectionHeader(y, "ASSISTS")
	Dim events As List = modAppState.EventsForMatch(match.Get("id"))
	Dim counts As Map
	counts.Initialize
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim ev As Map = events.Get(i)
		If ev.GetDefault("type", "") <> "GOAL" Then Continue
		Dim details As Map = ev.GetDefault("details", EmptyMap)
		If details.GetDefault("team", "A") = "B" Then Continue
		Dim assistId As String = details.GetDefault("assist", "")
		If assistId = "" Then Continue
		counts.Put(assistId, counts.GetDefault(assistId, 0) + 1)
	Next
	If counts.Size = 0 Then
		Return AddEmptyRow(y, w, "No assists recorded") + 8dip
	End If
	For Each pid As String In counts.Keys
		Dim n As Int = counts.Get(pid)
		Dim suffix As String = " assist"
		If n <> 1 Then suffix = " assists"
		y = AddStatRow(y, w, PlayerName(pid), n & suffix)
	Next
	Return y + 8dip
End Sub

Private Sub BuildAwardsSection(y As Int, w As Int) As Int
	y = AddSectionHeader(y, "PLAYER AWARDS")
	Dim potm As Map = modDb.NormalizePotmVotes(match.GetDefault("potmVotes", Null))
	Dim coachId As String = modDb.GetCategoryPotmPlayerId(potm, "coach")
	Dim oppId As String = modDb.GetCategoryPotmPlayerId(potm, "opposition")
	Dim fanWinner As String = ""
	Dim fanBest As Int = -1
	Dim fanCounts As Map
	Dim fcObj As Object = potm.GetDefault("fanCounts", Null)
	If fcObj <> Null And fcObj Is Map Then
		fanCounts = fcObj
		For Each pid As String In fanCounts.Keys
			Dim c As Int = fanCounts.Get(pid)
			If c > fanBest Then
				fanBest = c
				fanWinner = pid
			End If
		Next
	End If
	
	Dim any As Boolean = False
	If coachId <> "" Then
		y = AddStatRow(y, w, "Coach's POTM", PlayerName(coachId))
		any = True
	End If
	If oppId <> "" Then
		y = AddStatRow(y, w, "Opposition POTM", PlayerName(oppId))
		any = True
	End If
	If fanWinner <> "" And fanBest > 0 Then
		y = AddStatRow(y, w, "Fans' POTM", PlayerName(fanWinner) & " (" & fanBest & " votes)")
		any = True
	End If
	If any = False Then y = AddEmptyRow(y, w, "No awards yet — fill in post-match")
	Return y + 8dip
End Sub

Private Sub BuildMinutesSection(y As Int, w As Int) As Int
	y = AddSectionHeader(y, "MINUTES PLAYED")
	' Always derive from live feed timestamps + SUBs (ignores stale all-60 projections)
	Dim minutes As Map = modAppState.CalculateMatchMinutes(match)
	Dim fromFeed As Boolean = minutes.Size > 0
	If fromFeed = False Then
		Dim lineup As Map = match.GetDefault("lineup", match.GetDefault("tacticalLineup", EmptyMap))
		Dim plan As Map = match.GetDefault("subPlan", modSubPlanner.EmptyPlan(60))
		If lineup.IsInitialized And lineup.Size > 0 Then
			Dim squadIds As List
			squadIds.Initialize
			For Each mid As String In nameById.Keys
				squadIds.Add(mid)
			Next
			minutes = modSubPlanner.ProjectMatchMinutes(lineup, plan, squadIds)
		End If
	End If
	If minutes.Size = 0 Then
		Return AddEmptyRow(y, w, "No minutes recorded") + 8dip
	End If
	If fromFeed Then PersistMinutes(minutes)
	' Sort descending by minutes
	Dim ids As List
	ids.Initialize
	For Each pid As String In minutes.Keys
		ids.Add(pid)
	Next
	Dim a As Int, b As Int
	For a = 0 To ids.Size - 2
		For b = a + 1 To ids.Size - 1
			Dim ma As Int = minutes.Get(ids.Get(a))
			Dim mb As Int = minutes.Get(ids.Get(b))
			If mb > ma Then
				Dim tmp As String = ids.Get(a)
				ids.Set(a, ids.Get(b))
				ids.Set(b, tmp)
			End If
		Next
	Next
	For a = 0 To ids.Size - 1
		Dim pid2 As String = ids.Get(a)
		Dim mins As Int = minutes.Get(pid2)
		If mins <= 0 Then Continue
		y = AddStatRow(y, w, PlayerName(pid2), mins & " min")
	Next
	Return y + 8dip
End Sub

Private Sub PersistMinutes(minutes As Map)
	Dim stats As Map
	Dim stObj As Object = match.GetDefault("playerStats", Null)
	If stObj <> Null And stObj Is Map Then
		stats = stObj
	Else
		stats.Initialize
	End If
	Dim changed As Boolean = False
	For Each pid As String In minutes.Keys
		Dim mins As Int = minutes.Get(pid)
		Dim ps As Map
		If stats.ContainsKey(pid) Then
			ps = stats.Get(pid)
			If ps.GetDefault("minutesPlayed", -1) <> mins Then changed = True
		Else
			ps.Initialize
			ps.Put("goals", 0)
			ps.Put("assists", 0)
			ps.Put("yellowCards", 0)
			ps.Put("redCards", 0)
			changed = True
		End If
		ps.Put("minutesPlayed", mins)
		stats.Put(pid, ps)
	Next
	If changed = False Then Return
	match.Put("playerStats", stats)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("MatchHub")
End Sub
