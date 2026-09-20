B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Edit an existing live-feed event (clock + minute linked, HT-aware).
Sub Class_Globals
	Private Root As B4XView
	Private match As Map
	Private club As Map
	Private ev As Map
	Private edtMinute As EditText
	Private edtClock As EditText
	Private edtContent As EditText
	Private spnTeam As Spinner
	Private spnPlayer As Spinner
	Private spnAssist As Spinner
	Private lblType As Label
	Private lblHint As Label
	Private memberIds As List
	Private syncing As Boolean
End Sub

Public Sub Initialize
	memberIds.Initialize
	syncing = False
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFF0F172A
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Edit event", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	
	lblType.Initialize("")
	lblType.TextSize = 14
	lblType.TextColor = modConfig.COLOR_ACCENT
	lblType.Typeface = Typeface.DEFAULT_BOLD
	Root.AddView(lblType, 16dip, top, Root.Width - 32dip, 22dip)
	
	lblHint.Initialize("")
	lblHint.Text = "Clock and minutes stay in sync (HT break frozen)."
	lblHint.TextSize = 11
	lblHint.TextColor = 0xFF94A3B8
	Root.AddView(lblHint, 16dip, top + 24dip, Root.Width - 32dip, 18dip)
	
	Dim y As Int = top + 50dip
	Dim lblClock As Label
	lblClock.Initialize("")
	lblClock.Text = "Real time (HH:mm)"
	lblClock.TextSize = 12
	lblClock.TextColor = 0xFF94A3B8
	Root.AddView(lblClock, 16dip, y, Root.Width / 2 - 24dip, 18dip)
	
	Dim lblMin As Label
	lblMin.Initialize("")
	lblMin.Text = "Match minute"
	lblMin.TextSize = 12
	lblMin.TextColor = 0xFF94A3B8
	Root.AddView(lblMin, Root.Width / 2, y, Root.Width / 2 - 16dip, 18dip)
	y = y + 22dip
	
	edtClock.Initialize("edtClock")
	StyleDarkField(edtClock, "15:30")
	Root.AddView(edtClock, 16dip, y, Root.Width / 2 - 24dip, 44dip)
	
	edtMinute.Initialize("edtMinute")
	StyleDarkField(edtMinute, "0")
	edtMinute.InputType = edtMinute.INPUT_TYPE_NUMBERS
	Root.AddView(edtMinute, Root.Width / 2, y, Root.Width / 2 - 16dip, 44dip)
	y = y + 56dip
	
	Dim lblTeam As Label
	lblTeam.Initialize("")
	lblTeam.Text = "Team (goals)"
	lblTeam.TextSize = 12
	lblTeam.TextColor = 0xFF94A3B8
	Root.AddView(lblTeam, 16dip, y, Root.Width - 32dip, 18dip)
	y = y + 22dip
	spnTeam.Initialize("spnTeam")
	Root.AddView(spnTeam, 16dip, y, Root.Width - 32dip, 44dip)
	y = y + 56dip
	
	Dim lblScorer As Label
	lblScorer.Initialize("")
	lblScorer.Text = "Scorer / player"
	lblScorer.TextSize = 12
	lblScorer.TextColor = 0xFF94A3B8
	Root.AddView(lblScorer, 16dip, y, Root.Width - 32dip, 18dip)
	y = y + 22dip
	spnPlayer.Initialize("")
	Root.AddView(spnPlayer, 16dip, y, Root.Width - 32dip, 44dip)
	y = y + 56dip
	
	Dim lblAssist As Label
	lblAssist.Initialize("")
	lblAssist.Text = "Assist / player in"
	lblAssist.TextSize = 12
	lblAssist.TextColor = 0xFF94A3B8
	Root.AddView(lblAssist, 16dip, y, Root.Width - 32dip, 18dip)
	y = y + 22dip
	spnAssist.Initialize("")
	Root.AddView(spnAssist, 16dip, y, Root.Width - 32dip, 44dip)
	y = y + 56dip
	
	Dim lblContent As Label
	lblContent.Initialize("")
	lblContent.Text = "Description"
	lblContent.TextSize = 12
	lblContent.TextColor = 0xFF94A3B8
	Root.AddView(lblContent, 16dip, y, Root.Width - 32dip, 18dip)
	y = y + 22dip
	edtContent.Initialize("")
	StyleDarkField(edtContent, "Event text")
	Root.AddView(edtContent, 16dip, y, Root.Width - 32dip, 48dip)
	y = y + 64dip
	
	Dim btnSave As Button
	btnSave.Initialize("btnSave")
	btnSave.Text = "Save changes"
	btnSave.Color = modConfig.COLOR_SUCCESS
	btnSave.TextColor = Colors.White
	Root.AddView(btnSave, 16dip, y, Root.Width - 32dip, 52dip)
End Sub

Private Sub StyleDarkField(edt As EditText, hint As String)
	edt.Hint = hint
	edt.Color = 0xFF1E293B
	edt.TextColor = Colors.White
	edt.HintColor = 0xFF64748B
	edt.TextSize = 15
	edt.SingleLine = True
End Sub

Private Sub Load
	ev = modAppState.FindEvent(modAppState.SelectedEventId)
	If ev.ContainsKey("id") = False Then
		ToastMessageShow("Event not found", False)
		B4XPages.ShowPage("LiveFeed")
		Return
	End If
	match = modAppState.FindMatch(ev.GetDefault("matchId", modAppState.SelectedMatchId))
	club = modAppState.FindClub(match.GetDefault("clubId", ""))
	
	lblType.Text = ev.GetDefault("type", "EVENT")
	Dim details As Map = EventDetails(ev)
	syncing = True
	edtMinute.Text = "" & details.GetDefault("minute", 0)
	Dim clock As String = details.GetDefault("clockTime", "")
	If clock = "" Then clock = modAppState.FormatHHMM(ev.GetDefault("timestamp", DateTime.Now))
	edtClock.Text = clock
	syncing = False
	edtContent.Text = ev.GetDefault("content", "")
	
	spnTeam.Clear
	spnTeam.Add("Our team")
	spnTeam.Add("Opponent")
	If details.GetDefault("team", "A") = "B" Then
		spnTeam.SelectedIndex = 1
	Else
		spnTeam.SelectedIndex = 0
	End If
	
	FillMembers
	SelectPlayer(spnPlayer, details.GetDefault("scorer", details.GetDefault("player", details.GetDefault("playerOut", ""))), False)
	SelectPlayer(spnAssist, details.GetDefault("assist", details.GetDefault("playerIn", "")), True)
	UpdatePlayerEnabled
End Sub

Private Sub EventDetails(e As Map) As Map
	Dim details As Map
	Dim dObj As Object = e.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then
		details = dObj
	Else
		details.Initialize
	End If
	Return details
End Sub

Private Sub edtMinute_TextChanged (Old As String, New As String)
	If syncing Then Return
	If New.Trim = "" Then Return
	Dim minute As Int = 0
	Try
		minute = New
	Catch
		Return
	End Try
	If minute < 0 Then minute = 0
	syncing = True
	Dim wall As Long = modAppState.WallClockForMinute(match, minute)
	edtClock.Text = modAppState.FormatHHMM(wall)
	syncing = False
End Sub

Private Sub edtClock_TextChanged (Old As String, New As String)
	If syncing Then Return
	Dim s As String = New.Trim
	If s.Length < 4 Or s.IndexOf(":") < 1 Then Return
	syncing = True
	Dim wall As Long = modAppState.ParseHHMMOnMatchDay(match, s)
	edtMinute.Text = "" & modAppState.PlayingMinuteAt(match, wall)
	syncing = False
End Sub

Private Sub FillMembers
	memberIds.Initialize
	spnPlayer.Clear
	spnAssist.Clear
	spnAssist.Add("(none)")
	memberIds.Add("")
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
		spnPlayer.Add(mem.GetDefault("name", "?"))
		spnAssist.Add(mem.GetDefault("name", "?"))
		memberIds.Add(mem.Get("id"))
	Next
End Sub

Private Sub SelectPlayer(spn As Spinner, playerId As String, assistStyle As Boolean)
	If playerId = "" Then
		If assistStyle Then spn.SelectedIndex = 0
		Return
	End If
	Dim i As Int
	For i = 1 To memberIds.Size - 1
		If memberIds.Get(i) = playerId Then
			If assistStyle Then
				spn.SelectedIndex = i
			Else
				spn.SelectedIndex = i - 1
			End If
			Return
		End If
	Next
End Sub

Private Sub spnTeam_ItemClick (Position As Int, Value As Object)
	UpdatePlayerEnabled
End Sub

Private Sub UpdatePlayerEnabled
	Dim etype As String = ev.GetDefault("type", "")
	Dim needPlayers As Boolean = True
	If etype = "GOAL" And spnTeam.SelectedIndex = 1 Then needPlayers = False
	If etype = "HALF_TIME" Or etype = "SECOND_HALF" Or etype = "END" Or etype = "COMMENT" Or etype = "START" Then needPlayers = False
	spnPlayer.Enabled = needPlayers
	spnAssist.Enabled = needPlayers And (etype = "GOAL" Or etype = "SUB")
	spnTeam.Enabled = (etype = "GOAL")
End Sub

Private Sub PlayerIdFromSpinner(spn As Spinner, assistStyle As Boolean) As String
	If assistStyle Then
		If spn.SelectedIndex <= 0 Then Return ""
		Return memberIds.Get(spn.SelectedIndex)
	Else
		If spn.SelectedIndex < 0 Then Return ""
		Dim idx As Int = spn.SelectedIndex + 1
		If idx >= memberIds.Size Then Return ""
		Return memberIds.Get(idx)
	End If
End Sub

Private Sub btnSave_Click
	Dim details As Map = EventDetails(ev)
	Dim minute As Int = 0
	Try
		minute = edtMinute.Text
	Catch
		minute = 0
	End Try
	If minute < 0 Then minute = 0
	Dim clock As String = edtClock.Text.Trim
	If clock = "" Then clock = modAppState.FormatHHMM(modAppState.WallClockForMinute(match, minute))
	details.Put("minute", minute)
	details.Put("clockTime", clock)
	
	Dim wall As Long = modAppState.ParseHHMMOnMatchDay(match, clock)
	ev.Put("timestamp", wall)
	
	Dim etype As String = ev.GetDefault("type", "")
	If etype = "GOAL" Then
		If spnTeam.SelectedIndex = 1 Then
			details.Put("team", "B")
			details.Put("scorer", "")
			details.Put("assist", "")
			ev.Put("content", "GOAL! Opponent")
		Else
			details.Put("team", "A")
			Dim sid As String = PlayerIdFromSpinner(spnPlayer, False)
			Dim aid As String = PlayerIdFromSpinner(spnAssist, True)
			details.Put("scorer", sid)
			details.Put("assist", aid)
			Dim sName As String = spnPlayer.SelectedItem
			ev.Put("content", "GOAL! " & sName)
		End If
	Else If etype = "SUB" Then
		details.Put("team", "A")
		details.Put("playerOut", PlayerIdFromSpinner(spnPlayer, False))
		details.Put("playerIn", PlayerIdFromSpinner(spnAssist, True))
		ev.Put("content", spnPlayer.SelectedItem & " → " & spnAssist.SelectedItem)
	Else If etype = "YELLOW_CARD" Or etype = "RED_CARD" Then
		details.Put("team", "A")
		details.Put("player", PlayerIdFromSpinner(spnPlayer, False))
		ev.Put("content", spnPlayer.SelectedItem)
	Else
		ev.Put("content", edtContent.Text.Trim)
	End If
	
	ev.Put("details", details)
	If ev.GetDefault("content", "") = "" Then
		ToastMessageShow("Description required", False)
		Return
	End If
	modDb.SaveEvent(ev)
	modAppState.UpsertEvent(ev)
	CallSubDelayed(B4XPages.GetPage("LiveFeed"), "RecomputeScoresAndStats")
	ToastMessageShow("Event saved", False)
	B4XPages.ShowPage("LiveFeed")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("LiveFeed")
End Sub
