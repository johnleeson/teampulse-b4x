B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Edit live-feed event — layout adapts to GOAL / SUB / cards / COMMENT / etc.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private sv As ScrollView
	Private content As Panel
	Private match As Map
	Private club As Map
	Private ev As Map
	Private edtMinute As EditText
	Private edtClock As EditText
	Private edtContent As EditText
	Private lblType As Label
	Private lblHint As Label
	Private lblTeam As Label
	Private lblPlayer As Label
	Private lblAssist As Label
	Private lblContent As Label
	Private btnTeam As Button
	Private btnPlayer As Button
	Private btnAssist As Button
	Private memberIds As List
	Private memberNames As List
	Private selectedTeamB As Boolean
	Private selectedOwnGoal As Boolean
	Private selectedPlayerId As String
	Private selectedAssistId As String
	Private syncing As Boolean
	Private photoPath As String
	Private lblPhoto As Label
	Private btnPhoto As Button
End Sub

Public Sub Initialize
	memberIds.Initialize
	memberNames.Initialize
	selectedTeamB = False
	selectedOwnGoal = False
	selectedPlayerId = ""
	selectedAssistId = ""
	photoPath = ""
	syncing = False
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
	Dim chrome As Map = modUI.AddPageChrome(Root, "Edit event", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	sv.Initialize(1600dip)
	Root.AddView(sv, 0, top, Root.Width, Root.Height - top)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
	
	Dim y As Int = 8dip
	Dim w As Int = Root.Width - 32dip
	
	lblType.Initialize("")
	lblType.TextSize = 14
	lblType.TextColor = modConfig.COLOR_ACCENT
	lblType.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblType, 16dip, y, w, 22dip)
	y = y + 26dip
	
	lblHint.Initialize("")
	lblHint.Text = "Clock and minutes stay in sync (HT break frozen)."
	lblHint.TextSize = 11
	lblHint.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(lblHint, 16dip, y, w, 18dip)
	y = y + 26dip
	
	Dim lblClock As Label
	lblClock.Initialize("")
	lblClock.Text = "REAL TIME"
	lblClock.TextSize = 11
	lblClock.TextColor = modConfig.COLOR_DARK_MUTED
	lblClock.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblClock, 16dip, y, w / 2 - 8dip, 16dip)
	
	Dim lblMin As Label
	lblMin.Initialize("")
	lblMin.Text = "MATCH MINUTE"
	lblMin.TextSize = 11
	lblMin.TextColor = modConfig.COLOR_DARK_MUTED
	lblMin.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblMin, 16dip + w / 2, y, w / 2 - 8dip, 16dip)
	y = y + 20dip
	
	edtClock.Initialize("edtClock")
	modUI.StyleEditTextDark(edtClock, "15:30")
	content.AddView(edtClock, 16dip, y, w / 2 - 8dip, 48dip)
	
	edtMinute.Initialize("edtMinute")
	modUI.StyleEditTextDark(edtMinute, "0")
	edtMinute.InputType = edtMinute.INPUT_TYPE_NUMBERS
	content.AddView(edtMinute, 16dip + w / 2, y, w / 2 - 8dip, 48dip)
	y = y + 60dip
	
	lblTeam.Initialize("")
	lblTeam.Text = "TEAM"
	lblTeam.TextSize = 11
	lblTeam.TextColor = modConfig.COLOR_DARK_MUTED
	lblTeam.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblTeam, 16dip, y, w, 16dip)
	y = y + 20dip
	btnTeam.Initialize("btnTeam")
	StylePicker(btnTeam)
	content.AddView(btnTeam, 16dip, y, w, 48dip)
	y = y + 60dip
	
	lblPlayer.Initialize("")
	lblPlayer.Text = "PLAYER"
	lblPlayer.TextSize = 11
	lblPlayer.TextColor = modConfig.COLOR_DARK_MUTED
	lblPlayer.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblPlayer, 16dip, y, w, 16dip)
	y = y + 20dip
	btnPlayer.Initialize("btnPlayer")
	StylePicker(btnPlayer)
	content.AddView(btnPlayer, 16dip, y, w, 48dip)
	y = y + 60dip
	
	lblAssist.Initialize("")
	lblAssist.Text = "ASSIST / PLAYER ON"
	lblAssist.TextSize = 11
	lblAssist.TextColor = modConfig.COLOR_DARK_MUTED
	lblAssist.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblAssist, 16dip, y, w, 16dip)
	y = y + 20dip
	btnAssist.Initialize("btnAssist")
	StylePicker(btnAssist)
	content.AddView(btnAssist, 16dip, y, w, 48dip)
	y = y + 60dip
	
	lblContent.Initialize("")
	lblContent.Text = "NOTE"
	lblContent.TextSize = 11
	lblContent.TextColor = modConfig.COLOR_DARK_MUTED
	lblContent.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblContent, 16dip, y, w, 16dip)
	y = y + 20dip
	edtContent.Initialize("edtContent")
	modUI.StyleEditTextDark(edtContent, "Note text")
	edtContent.SingleLine = False
	edtContent.Gravity = Bit.Or(Gravity.TOP, Gravity.LEFT)
	content.AddView(edtContent, 16dip, y, w, 96dip)
	y = y + 108dip
	
	btnPhoto.Initialize("btnPhoto")
	btnPhoto.Text = "Add photo"
	btnPhoto.Color = modConfig.COLOR_DARK_CHIP
	btnPhoto.TextColor = modConfig.COLOR_DARK_TEXT
	btnPhoto.TextSize = 13
	btnPhoto.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(btnPhoto, 16dip, y, w, 44dip)
	y = y + 52dip
	
	lblPhoto.Initialize("")
	lblPhoto.TextSize = 12
	lblPhoto.TextColor = modConfig.COLOR_DARK_MUTED
	lblPhoto.SingleLine = True
	content.AddView(lblPhoto, 16dip, y, w, 20dip)
	y = y + 32dip
	
	Dim btnSave As Button
	btnSave.Initialize("btnSave")
	btnSave.Text = "Save changes"
	btnSave.Color = modConfig.COLOR_SUCCESS
	btnSave.TextColor = Colors.White
	btnSave.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(btnSave, 16dip, y, w, 52dip)
	y = y + 72dip
	
	content.Height = Max(y, sv.Height + 1)
End Sub

Private Sub StylePicker(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	b.TextColor = modConfig.COLOR_DARK_TEXT
	b.TextSize = 15
	b.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
	b.Padding = Array As Int(14dip, 0, 14dip, 0)
	b.Typeface = Typeface.DEFAULT_BOLD
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
	
	Dim etype As String = ev.GetDefault("type", "EVENT")
	lblType.Text = FriendlyType(etype)
	Dim details As Map = EventDetails(ev)
	syncing = True
	edtMinute.Text = "" & details.GetDefault("minute", 0)
	Dim clock As String = details.GetDefault("clockTime", "")
	If clock = "" Then clock = modAppState.FormatHHMM(ev.GetDefault("timestamp", DateTime.Now))
	edtClock.Text = clock
	syncing = False
	edtContent.Text = ev.GetDefault("content", "")
	photoPath = details.GetDefault("photoPath", "")
	RefreshPhotoLabel
	
	selectedTeamB = (details.GetDefault("team", "A") = "B")
	selectedOwnGoal = modLocal.IsOwnGoal(details)
	FillMembers
	selectedPlayerId = details.GetDefault("scorer", details.GetDefault("player", details.GetDefault("playerOut", "")))
	selectedAssistId = details.GetDefault("assist", details.GetDefault("playerIn", ""))
	ApplyTypeLayout
	RefreshPickerLabels
	AutoFillContent
End Sub

Private Sub FriendlyType(t As String) As String
	Select t
		Case "GOAL"
			Return "GOAL"
		Case "SUB"
			Return "SUBSTITUTION"
		Case "YELLOW_CARD"
			Return "YELLOW CARD"
		Case "RED_CARD"
			Return "RED CARD"
		Case "COMMENT"
			Return "NOTE"
		Case "HALF_TIME"
			Return "HALF TIME"
		Case "SECOND_HALF"
			Return "SECOND HALF"
		Case "START"
			Return "KICK-OFF"
		Case "END"
			Return "FULL TIME"
		Case "CORNER"
			Return "CORNER"
		Case "PENALTY"
			Return "PENALTY"
		Case Else
			Return t
	End Select
End Sub

Private Sub ApplyTypeLayout
	Dim etype As String = ev.GetDefault("type", "")
	Dim showTeam As Boolean = (etype = "GOAL" Or etype = "CORNER" Or etype = "PENALTY")
	Dim showPlayer As Boolean = (etype = "GOAL" Or etype = "SUB" Or etype = "YELLOW_CARD" Or etype = "RED_CARD")
	Dim showAssist As Boolean = (etype = "GOAL" Or etype = "SUB")
	Dim editNote As Boolean = (etype = "COMMENT" Or etype = "HALF_TIME" Or etype = "SECOND_HALF" Or etype = "START" Or etype = "END")
	Dim showPhoto As Boolean = (etype = "COMMENT")
	
	If etype = "GOAL" And (selectedTeamB Or selectedOwnGoal) Then
		showAssist = False
	End If
	
	lblTeam.Visible = showTeam
	btnTeam.Visible = showTeam
	lblPlayer.Visible = showPlayer
	btnPlayer.Visible = showPlayer
	lblAssist.Visible = showAssist
	btnAssist.Visible = showAssist
	btnPhoto.Visible = showPhoto
	lblPhoto.Visible = showPhoto
	
	If etype = "GOAL" Then
		lblPlayer.Text = "SCORER"
		lblAssist.Text = "ASSIST (optional)"
		lblContent.Text = "PREVIEW"
		edtContent.Enabled = False
	Else If etype = "SUB" Then
		lblPlayer.Text = "PLAYER OFF"
		lblAssist.Text = "PLAYER ON"
		lblContent.Text = "PREVIEW"
		edtContent.Enabled = False
	Else If etype = "YELLOW_CARD" Or etype = "RED_CARD" Then
		lblPlayer.Text = "PLAYER"
		lblContent.Text = "PREVIEW"
		edtContent.Enabled = False
	Else If etype = "CORNER" Or etype = "PENALTY" Then
		lblContent.Text = "PREVIEW"
		edtContent.Enabled = False
	Else If etype = "COMMENT" Then
		lblContent.Text = "NOTE"
		edtContent.Enabled = True
	Else
		lblContent.Text = "TEXT"
		edtContent.Enabled = editNote
	End If
End Sub

Private Sub EventDetails(e As Map) As Map
	Dim details As Map
	Dim dObj As Object = e.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then
		Return dObj
	End If
	details.Initialize
	Return details
End Sub

Private Sub FillMembers
	memberIds.Initialize
	memberNames.Initialize
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
		memberIds.Add(mem.GetDefault("id", ""))
		memberNames.Add(mem.GetDefault("name", "?"))
	Next
End Sub

Private Sub NameOf(pid As String) As String
	If pid = "" Then Return ""
	Dim i As Int
	For i = 0 To memberIds.Size - 1
		If memberIds.Get(i) = pid Then Return memberNames.Get(i)
	Next
	Return "?"
End Sub

Private Sub RefreshPickerLabels
	If selectedTeamB Then
		btnTeam.Text = "Opponent"
	Else
		btnTeam.Text = "Our team"
	End If
	Dim etypeNow As String = ev.GetDefault("type", "")
	If etypeNow = "GOAL" And selectedOwnGoal Then
		btnPlayer.Text = "Own goal"
	Else If etypeNow = "GOAL" And selectedTeamB Then
		btnPlayer.Text = "Opposition goal"
	Else If selectedPlayerId = "" Then
		btnPlayer.Text = "Choose player…"
	Else
		btnPlayer.Text = NameOf(selectedPlayerId)
	End If
	Dim etype As String = ev.GetDefault("type", "")
	If etype = "GOAL" Then
		If selectedAssistId = "" Then
			btnAssist.Text = "(none)"
		Else
			btnAssist.Text = NameOf(selectedAssistId)
		End If
	Else
		If selectedAssistId = "" Then
			btnAssist.Text = "Choose player…"
		Else
			btnAssist.Text = NameOf(selectedAssistId)
		End If
	End If
End Sub

Private Sub AutoFillContent
	Dim etype As String = ev.GetDefault("type", "")
	If etype = "COMMENT" Or etype = "HALF_TIME" Or etype = "SECOND_HALF" Or etype = "START" Or etype = "END" Then Return
	syncing = True
	If etype = "GOAL" Then
		If selectedOwnGoal Then
			edtContent.Text = "Own goal"
		Else If selectedTeamB Then
			edtContent.Text = "Opposition goal"
		Else
			Dim s As String = NameOf(selectedPlayerId)
			If s = "" Then s = "?"
			edtContent.Text = "GOAL! " & s
		End If
	Else If etype = "SUB" Then
		Dim outN As String = NameOf(selectedPlayerId)
		Dim inN As String = NameOf(selectedAssistId)
		If outN = "" Then outN = "?"
		If inN = "" Then inN = "?"
		edtContent.Text = outN & " → " & inN
	Else If etype = "YELLOW_CARD" Or etype = "RED_CARD" Then
		Dim pn As String = NameOf(selectedPlayerId)
		If pn = "" Then pn = "?"
		edtContent.Text = pn
	Else If etype = "CORNER" Or etype = "PENALTY" Then
		edtContent.Text = SetPieceContent(etype, selectedTeamB)
	End If
	syncing = False
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

Private Sub btnTeam_Click
	Dim opts As List
	opts.Initialize
	opts.AddAll(Array As String("Our team", "Opponent"))
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	If selectedTeamB Then tmpl.SelectedItem = "Opponent" Else tmpl.SelectedItem = "Our team"
	dialog.Title = "Team"
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	selectedTeamB = (tmpl.SelectedItem = "Opponent")
	selectedOwnGoal = False
	If selectedTeamB Then selectedPlayerId = ""
	ApplyTypeLayout
	RefreshPickerLabels
	AutoFillContent
End Sub

Private Sub btnPlayer_Click
	Dim etype As String = ev.GetDefault("type", "")
	If etype = "GOAL" Then
		Wait For (PickGoalScorer) Complete (picked As String)
		If picked = "__cancel__" Then Return
		If picked = "__own__" Then
			selectedOwnGoal = True
			selectedPlayerId = ""
			selectedAssistId = ""
		Else If picked = "__opp__" Then
			selectedOwnGoal = False
			selectedPlayerId = ""
			selectedAssistId = ""
		Else
			selectedOwnGoal = False
			selectedPlayerId = picked
		End If
		ApplyTypeLayout
		RefreshPickerLabels
		AutoFillContent
		Return
	End If
	If memberNames.Size = 0 Then
		ToastMessageShow("No players in club", False)
		Return
	End If
	Wait For (PickMember(selectedPlayerId, "Choose player")) Complete (pid As String)
	If pid = "__cancel__" Then Return
	selectedPlayerId = pid
	RefreshPickerLabels
	AutoFillContent
End Sub

Private Sub PickGoalScorer As ResumableSub
	Dim opts As List
	opts.Initialize
	opts.Add("Own goal")
	If selectedTeamB Then
		opts.Add("Opposition goal")
	Else
		If memberNames.Size = 0 Then
			ToastMessageShow("No players in club", False)
			Return "__cancel__"
		End If
		Dim i As Int
		For i = 0 To memberNames.Size - 1
			opts.Add(memberNames.Get(i))
		Next
	End If
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = opts
	dialog.Title = "Who scored?"
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return "__cancel__"
	Dim sel As String = tmpl.SelectedItem
	If sel = "Own goal" Then Return "__own__"
	If sel = "Opposition goal" Then Return "__opp__"
	Dim selIdx As Int = memberNames.IndexOf(sel)
	If selIdx < 0 Then Return "__cancel__"
	Return memberIds.Get(selIdx)
End Sub

Private Sub btnAssist_Click
	Dim etype As String = ev.GetDefault("type", "")
	If etype = "GOAL" Then
		Dim opts As List
		opts.Initialize
		opts.Add("(none)")
		Dim i As Int
		For i = 0 To memberNames.Size - 1
			opts.Add(memberNames.Get(i))
		Next
		Dim tmpl As B4XListTemplate
		tmpl.Initialize
		tmpl.Options = opts
		dialog.Title = "Assist"
		Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
		If Result <> xui.DialogResponse_Positive Then Return
		Dim idx As Int = opts.IndexOf(tmpl.SelectedItem)
		If idx <= 0 Then
			selectedAssistId = ""
		Else
			selectedAssistId = memberIds.Get(idx - 1)
		End If
		RefreshPickerLabels
		AutoFillContent
		Return
	End If
	If memberNames.Size = 0 Then
		ToastMessageShow("No players in club", False)
		Return
	End If
	Wait For (PickMember(selectedAssistId, "Player on")) Complete (pid As String)
	If pid = "__cancel__" Then Return
	selectedAssistId = pid
	RefreshPickerLabels
	AutoFillContent
End Sub

Private Sub PickMember(currentId As String, title As String) As ResumableSub
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = memberNames
	Dim curIdx As Int = memberIds.IndexOf(currentId)
	If curIdx >= 0 Then tmpl.SelectedItem = memberNames.Get(curIdx)
	dialog.Title = title
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return "__cancel__"
	Dim selIdx As Int = memberNames.IndexOf(tmpl.SelectedItem)
	If selIdx < 0 Then Return "__cancel__"
	Return memberIds.Get(selIdx)
End Sub

Private Sub RefreshPhotoLabel
	If photoPath = "" Then
		lblPhoto.Text = "No photo attached"
		btnPhoto.Text = "Add photo"
	Else
		lblPhoto.Text = "Photo attached"
		btnPhoto.Text = "Change photo"
	End If
End Sub

Private Sub btnPhoto_Click
	Dim cc As ContentChooser
	cc.Initialize("cc")
	cc.Show("image/*", "Choose photo")
End Sub

Private Sub cc_Result (Success As Boolean, Dir As String, FileName As String)
	If Success = False Then Return
	Try
		Dim destName As String = "note_" & modAppState.NewId & ".jpg"
		File.Copy(Dir, FileName, File.DirInternal, destName)
		photoPath = destName
		RefreshPhotoLabel
	Catch
		ToastMessageShow("Could not attach photo", False)
		Log(LastException.Message)
	End Try
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
		details.Put("ownGoal", selectedOwnGoal)
		If selectedOwnGoal Then
			details.Put("scorer", "")
			details.Put("assist", "")
			If selectedTeamB Then
				details.Put("team", "B")
			Else
				details.Put("team", "A")
			End If
			ev.Put("content", "Own goal")
		Else If selectedTeamB Then
			details.Put("team", "B")
			details.Put("scorer", "")
			details.Put("assist", "")
			ev.Put("content", "Opposition goal")
		Else
			If selectedPlayerId = "" Then
				ToastMessageShow("Choose a scorer", False)
				Return
			End If
			details.Put("team", "A")
			details.Put("scorer", selectedPlayerId)
			details.Put("assist", selectedAssistId)
			If selectedAssistId <> "" Then details.Put("assistUnknown", False)
			ev.Put("content", "GOAL! " & NameOf(selectedPlayerId))
		End If
	Else If etype = "SUB" Then
		If selectedPlayerId = "" Or selectedAssistId = "" Then
			ToastMessageShow("Need player off and player on", False)
			Return
		End If
		details.Put("team", "A")
		details.Put("playerOut", selectedPlayerId)
		details.Put("playerIn", selectedAssistId)
		ev.Put("content", NameOf(selectedPlayerId) & " → " & NameOf(selectedAssistId))
	Else If etype = "YELLOW_CARD" Or etype = "RED_CARD" Then
		If selectedPlayerId = "" Then
			ToastMessageShow("Choose a player", False)
			Return
		End If
		details.Put("team", "A")
		details.Put("player", selectedPlayerId)
		ev.Put("content", NameOf(selectedPlayerId))
	Else If etype = "CORNER" Or etype = "PENALTY" Then
		If selectedTeamB Then
			details.Put("team", "B")
		Else
			details.Put("team", "A")
		End If
		ev.Put("content", SetPieceContent(etype, selectedTeamB))
	Else
		Dim note As String = edtContent.Text.Trim
		If note = "" Then
			ToastMessageShow("Enter note text", False)
			Return
		End If
		ev.Put("content", note)
		If etype = "COMMENT" Then
			If photoPath <> "" Then details.Put("photoPath", photoPath)
		End If
	End If
	
	ev.Put("details", details)
	modDb.SaveEvent(ev)
	modAppState.UpsertEvent(ev)
	CallSubDelayed(B4XPages.GetPage("LiveFeed"), "RecomputeScoresAndStats")
	ToastMessageShow("Event saved", False)
	B4XPages.ShowPage("LiveFeed")
End Sub

Private Sub SetPieceContent(etype As String, teamB As Boolean) As String
	Dim side As String = "(us)"
	If teamB Then side = "(them)"
	If etype = "PENALTY" Then Return "Penalty " & side
	Return "Corner " & side
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("LiveFeed")
End Sub
