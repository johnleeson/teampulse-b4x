B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Log one training session: date, attendance, trainer of the week, behaviour.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private clv As CustomListView
	Private btnClub As Button
	Private btnDate As Button
	Private btnAttendance As Button
	Private btnAwards As Button
	Private lblHint As Label
	Private lblSummary As Label
	Private btnSave As Button
	Private btnDelete As Button
	Private clubIds As List
	Private clubNames As List
	Private selectedClubIndex As Int
	Private selectedDateTicks As Long
	Private sessionId As String
	Private editingExisting As Boolean
	Private mode As String
	Private trainerId As String
	Private presentIds As List
	Private absentIds As List
	Private wellIds As List
	Private poorIds As List
	Private saving As Boolean
End Sub

Public Sub Initialize
	clubIds.Initialize
	clubNames.Initialize
	presentIds.Initialize
	absentIds.Initialize
	wellIds.Initialize
	poorIds.Initialize
	selectedClubIndex = 0
	selectedDateTicks = DateTime.Now
	mode = "attendance"
	trainerId = ""
	sessionId = ""
	editingExisting = False
	saving = False
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildUI
End Sub

Private Sub B4XPage_Appear
	saving = False
	LoadClubs
	If modAppState.EditingExistingTraining Then
		LoadExisting
	Else
		ResetNew
	End If
	RefreshChrome
	LayoutBody
	RefreshList
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Me, Root, "Training", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	
	modUI.InitButton(Me, btnClub, "btnClub")
	StylePickerButton(btnClub)
	Root.AddView(btnClub, 16dip, top, modUI.ViewWidth(Root) - 32dip, 44dip)
	
	modUI.InitButton(Me, btnDate, "btnDate")
	StylePickerButton(btnDate)
	Root.AddView(btnDate, 16dip, top + 52dip, modUI.ViewWidth(Root) - 32dip, 44dip)
	
	modUI.InitButton(Me, btnAttendance, "btnAttendance")
	modUI.InitButton(Me, btnAwards, "btnAwards")
	Dim modeW As Int = (modUI.ViewWidth(Root) - 40dip) / 2
	Root.AddView(btnAttendance, 16dip, top + 104dip, modeW, 40dip)
	Root.AddView(btnAwards, 24dip + modeW, top + 104dip, modeW, 40dip)
	
	lblHint.Initialize("")
	modUI.SetTextSize(lblHint, 11)
	lblHint.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(lblHint, 16dip, top + 148dip, modUI.ViewWidth(Root) - 32dip, 18dip)
	
	lblSummary.Initialize("")
	modUI.SetTextSize(lblSummary, 12)
	lblSummary.TextColor = modConfig.COLOR_DARK_TEXT
	modUI.SetBold(lblSummary, True)
	Root.AddView(lblSummary, 16dip, top + 166dip, modUI.ViewWidth(Root) - 32dip, 20dip)
	
	clv = modUI.AddCustomListViewThemed(Root, 0, top + 190dip, modUI.ViewWidth(Root), 200dip, Me, "clv", True)
	
	modUI.InitButton(Me, btnSave, "btnSave")
	btnSave.Text = "Save session"
	modUI.SetButtonTextColor(btnSave, Colors.White)
	modUI.SetTextSize(btnSave, 15)
	modUI.SetBold(btnSave, True)
	modUI.RoundView(btnSave, modConfig.COLOR_ACCENT, 8dip)
	Root.AddView(btnSave, 16dip, modUI.ViewHeight(Root) - 60dip, modUI.ViewWidth(Root) - 32dip, 48dip)
	
	modUI.InitButton(Me, btnDelete, "btnDelete")
	btnDelete.Text = "Delete session"
	modUI.SetButtonTextColor(btnDelete, Colors.White)
	modUI.SetTextSize(btnDelete, 14)
	modUI.RoundView(btnDelete, modConfig.COLOR_DANGER, 8dip)
	Root.AddView(btnDelete, 16dip, modUI.ViewHeight(Root) - 112dip, modUI.ViewWidth(Root) - 32dip, 40dip)
End Sub

Private Sub LayoutBody
	Dim top As Int = modUI.PageChromeHeight + 8dip
	Dim y As Int = top
	If clubIds.Size > 1 Then
		btnClub.Visible = True
		modUI.PlaceView(btnClub, 16dip, y, modUI.ViewWidth(Root) - 32dip, 44dip)
		y = y + 52dip
	Else
		btnClub.Visible = False
	End If
	modUI.PlaceView(btnDate, 16dip, y, modUI.ViewWidth(Root) - 32dip, 44dip)
	y = y + 52dip
	Dim modeW As Int = (modUI.ViewWidth(Root) - 40dip) / 2
	modUI.PlaceView(btnAttendance, 16dip, y, modeW, 40dip)
	modUI.PlaceView(btnAwards, 24dip + modeW, y, modeW, 40dip)
	y = y + 46dip
	modUI.PlaceView(lblHint, 16dip, y, modUI.ViewWidth(Root) - 32dip, 18dip)
	y = y + 20dip
	modUI.PlaceView(lblSummary, 16dip, y, modUI.ViewWidth(Root) - 32dip, 20dip)
	y = y + 24dip
	
	Dim bottom As Int = 16dip + 48dip
	If editingExisting Then
		btnDelete.Visible = True
		modUI.PlaceView(btnDelete, 16dip, modUI.ViewHeight(Root) - 16dip - 48dip - 8dip - 40dip, modUI.ViewWidth(Root) - 32dip, 40dip)
		bottom = 16dip + 48dip + 8dip + 40dip
	Else
		btnDelete.Visible = False
	End If
	modUI.PlaceView(btnSave, 16dip, modUI.ViewHeight(Root) - 16dip - 48dip, modUI.ViewWidth(Root) - 32dip, 48dip)
	Dim listH As Int = modUI.ViewHeight(Root) - bottom - y
	If listH < 80dip Then listH = 80dip
	Dim listBase As B4XView = clv.GetBase
	listBase.SetLayoutAnimated(0, 0, y, modUI.ViewWidth(Root), listH)
End Sub

Private Sub ResetNew
	editingExisting = False
	sessionId = modAppState.NewId
	selectedDateTicks = DateTime.Now
	mode = "attendance"
	trainerId = ""
	presentIds.Initialize
	absentIds.Initialize
	wellIds.Initialize
	poorIds.Initialize
	Dim preferred As String = modAppState.SelectedClubId
	selectedClubIndex = 0
	Dim i As Int
	For i = 0 To clubIds.Size - 1
		If clubIds.Get(i) = preferred Then
			selectedClubIndex = i
			Exit
		End If
	Next
End Sub

Private Sub LoadExisting
	Dim s As Map = modAppState.FindTraining(modAppState.SelectedTrainingId)
	If s.ContainsKey("id") = False Or s.GetDefault("id", "") = "" Then
		ResetNew
		Return
	End If
	editingExisting = True
	sessionId = s.Get("id")
	trainerId = s.GetDefault("trainerOfWeekId", "")
	presentIds = CopyIds(s.GetDefault("presentIds", Null))
	absentIds = CopyIds(s.GetDefault("absentIds", Null))
	wellIds = CopyIds(s.GetDefault("wellBehavedIds", Null))
	poorIds = CopyIds(s.GetDefault("poorlyBehavedIds", Null))
	mode = "attendance"
	Dim cid As String = s.GetDefault("clubId", "")
	selectedClubIndex = 0
	Dim i As Int
	For i = 0 To clubIds.Size - 1
		If clubIds.Get(i) = cid Then
			selectedClubIndex = i
			Exit
		End If
	Next
	Dim d As String = s.GetDefault("date", "")
	selectedDateTicks = DateTime.Now
	If d.Length >= 10 Then
		Dim prev As String = DateTime.DateFormat
		Try
			DateTime.DateFormat = "yyyy-MM-dd"
			selectedDateTicks = DateTime.DateParse(d.SubString2(0, 10))
		Catch
			selectedDateTicks = DateTime.Now
		End Try
		DateTime.DateFormat = prev
	End If
End Sub

Private Sub LoadClubs
	clubIds.Initialize
	clubNames.Initialize
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	Dim i As Int
	For i = 0 To myClubs.Size - 1
		Dim c As Map = myClubs.Get(i)
		clubIds.Add(c.Get("id"))
		clubNames.Add(c.GetDefault("name", "Club"))
	Next
	If selectedClubIndex >= clubIds.Size Then selectedClubIndex = 0
End Sub

Private Sub RefreshChrome
	If clubNames.Size = 0 Then
		btnClub.Text = "No clubs yet"
	Else
		btnClub.Text = clubNames.Get(selectedClubIndex)
	End If
	btnDate.Text = FormatTicksAsUkDate(selectedDateTicks)
	btnAttendance.Text = "Attendance"
	btnAwards.Text = "Awards"
	StyleToggle(btnAttendance, mode = "attendance")
	StyleToggle(btnAwards, mode = "awards")
	If mode = "attendance" Then
		lblHint.Text = "Tap a player: Present, then Absent, then clear"
	Else
		lblHint.Text = "Trainer is one player. Good and Not can be several."
	End If
	btnSave.Text = "Save session"
	RefreshSummary
End Sub

Private Sub RefreshSummary
	lblSummary.Text = presentIds.Size & " present · " & absentIds.Size & " absent"
	If trainerId <> "" Then
		Dim name As String = MemberName(trainerId)
		If name <> "" Then lblSummary.Text = lblSummary.Text & " · Trainer: " & name
	End If
End Sub

Private Sub RefreshList
	clv.Clear
	modUI.ApplyDarkListBackground(clv, modConfig.COLOR_DARK_BG)
	RefreshSummary
	Dim members As List = CurrentMembers
	Dim cardW As Int = modUI.ViewWidth(Root) - 24dip
	If members.Size = 0 Then
		Dim empty As Panel = modUI.CreateSimpleRowThemed(cardW, "No players in this club yet.", "", True)
		modUI.PlaceView(empty, 0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(empty, "")
		Return
	End If
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		Dim id As String = mem.GetDefault("id", "")
		Dim row As Panel
		Dim rowH As Int
		If mode = "attendance" Then
			row = CreateAttendanceRow(cardW, mem)
			rowH = 56dip
		Else
			row = CreateAwardsRow(cardW, mem)
			rowH = 64dip
		End If
		Dim h As Int = rowH + 8dip
		Dim wrap As Panel
		wrap.Initialize("")
		wrap.Color = modConfig.COLOR_DARK_BG
		wrap.AddView(row, 12dip, 4dip, cardW, rowH)
		modUI.PlaceView(wrap, 0, 0, modUI.ViewWidth(Root), h)
		clv.Add(wrap, id)
	Next
End Sub

Private Sub CurrentMembers As List
	Dim empty As List
	empty.Initialize
	If clubIds.Size = 0 Then Return empty
	Dim club As Map = modAppState.FindClub(clubIds.Get(selectedClubIndex))
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj Is List Then Return memObj
	Return empty
End Sub

Private Sub CreateAttendanceRow(Width As Int, member As Map) As Panel
	Dim id As String = member.GetDefault("id", "")
	Dim status As String = AttendanceOf(id)
	Dim p As Panel
	p.Initialize("")
	modUI.RoundView(p, modConfig.COLOR_DARK_CARD, 12dip)
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = member.GetDefault("name", "Player")
	modUI.SetTextSize(lbl, 15)
	lbl.TextColor = modConfig.COLOR_DARK_TEXT
	modUI.SetBold(lbl, True)
	modUI.SetAlign(lbl, "CENTER", "LEFT")
	modUI.SetSingleLine(lbl, True)
	p.AddView(lbl, 14dip, 0, Width - 110dip, 56dip)
	Dim chip As Label
	chip.Initialize("")
	chip.Text = AttendanceLabel(status)
	modUI.SetTextSize(chip, 12)
	chip.TextColor = Colors.White
	modUI.SetBold(chip, True)
	modUI.SetAlign(chip, "CENTER", "CENTER")
	modUI.RoundView(chip, AttendanceColor(status), 10dip)
	p.AddView(chip, Width - 92dip, 14dip, 78dip, 28dip)
	Return p
End Sub

Private Sub CreateAwardsRow(Width As Int, member As Map) As Panel
	Dim id As String = member.GetDefault("id", "")
	Dim p As Panel
	p.Initialize("")
	modUI.RoundView(p, modConfig.COLOR_DARK_CARD, 12dip)
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = member.GetDefault("name", "Player")
	modUI.SetTextSize(lbl, 14)
	lbl.TextColor = modConfig.COLOR_DARK_TEXT
	modUI.SetBold(lbl, True)
	modUI.SetAlign(lbl, "CENTER", "LEFT")
	modUI.SetSingleLine(lbl, True)
	Dim btnW As Int = 68dip
	If Width < 320dip Then btnW = 58dip
	Dim gap As Int = 6dip
	Dim buttonsW As Int = btnW * 3 + gap * 2
	p.AddView(lbl, 12dip, 0, Width - buttonsW - 24dip, 64dip)
	Dim x As Int = Width - 10dip - buttonsW
	p.AddView(AwardButton("btnTrainer", "Trainer", id, trainerId = id, modConfig.COLOR_ACCENT), x, 16dip, btnW, 32dip)
	x = x + btnW + gap
	p.AddView(AwardButton("btnGood", "Good", id, IdIn(wellIds, id), modConfig.COLOR_SUCCESS), x, 16dip, btnW, 32dip)
	x = x + btnW + gap
	p.AddView(AwardButton("btnPoor", "Not", id, IdIn(poorIds, id), modConfig.COLOR_DANGER), x, 16dip, btnW, 32dip)
	Return p
End Sub

Private Sub AwardButton(eventName As String, text As String, playerId As String, selected As Boolean, onColor As Int) As Button
	Dim b As Button
	modUI.InitButton(Me, b, eventName)
	b.Text = text
	modUI.SetTextSize(b, 11)
	modUI.SetBold(b, True)
	modUI.SetAlign(b, "CENTER", "CENTER")
	b.Tag = playerId
	If selected Then
		modUI.RoundView(b, onColor, 8dip)
		modUI.SetButtonTextColor(b, Colors.White)
	Else
		modUI.RoundView(b, modConfig.COLOR_DARK_CHIP, 8dip)
		modUI.SetButtonTextColor(b, modConfig.COLOR_DARK_MUTED)
	End If
	Return b
End Sub

Private Sub AttendanceOf(id As String) As String
	If IdIn(presentIds, id) Then Return "PRESENT"
	If IdIn(absentIds, id) Then Return "ABSENT"
	Return ""
End Sub

Private Sub AttendanceLabel(status As String) As String
	If status = "PRESENT" Then Return "Present"
	If status = "ABSENT" Then Return "Absent"
	Return "—"
End Sub

Private Sub AttendanceColor(status As String) As Int
	If status = "PRESENT" Then Return modConfig.COLOR_SUCCESS
	If status = "ABSENT" Then Return modConfig.COLOR_DANGER
	Return modConfig.COLOR_DARK_MUTED
End Sub

Private Sub CycleAttendance(id As String)
	If IdIn(presentIds, id) Then
		RemoveId(presentIds, id)
		If IdIn(absentIds, id) = False Then absentIds.Add(id)
	Else If IdIn(absentIds, id) Then
		RemoveId(absentIds, id)
	Else
		presentIds.Add(id)
	End If
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If mode <> "attendance" Then Return
	Dim id As String = Value
	If id = "" Then Return
	CycleAttendance(id)
	RefreshList
End Sub

Private Sub btnTrainer_Click
	Dim b As Button = modUI.ClickedButton(Sender)
	Dim id As String = b.Tag
	If trainerId = id Then
		trainerId = ""
	Else
		trainerId = id
	End If
	RefreshList
End Sub

Private Sub btnGood_Click
	Dim b As Button = modUI.ClickedButton(Sender)
	Dim id As String = b.Tag
	If IdIn(wellIds, id) Then
		RemoveId(wellIds, id)
	Else
		wellIds.Add(id)
		RemoveId(poorIds, id)
	End If
	RefreshList
End Sub

Private Sub btnPoor_Click
	Dim b As Button = modUI.ClickedButton(Sender)
	Dim id As String = b.Tag
	If IdIn(poorIds, id) Then
		RemoveId(poorIds, id)
	Else
		poorIds.Add(id)
		RemoveId(wellIds, id)
	End If
	RefreshList
End Sub

Private Sub btnAttendance_Click
	mode = "attendance"
	RefreshChrome
	RefreshList
End Sub

Private Sub btnAwards_Click
	mode = "awards"
	RefreshChrome
	RefreshList
End Sub

Private Sub btnClub_Click
	If clubNames.Size = 0 Then
		modPlatform.Toast("Create or join a club first", False)
		Return
	End If
	StyleDarkDialog
	Dim template As B4XListTemplate
	template.Initialize
	Try
		template.CustomListView1.DefaultTextColor = Colors.White
		template.CustomListView1.DefaultTextBackgroundColor = modConfig.COLOR_DARK_CARD
	Catch
		Log("training club list: " & LastException.Message)
	End Try
	template.Options = clubNames
	If selectedClubIndex >= 0 And selectedClubIndex < clubNames.Size Then
		template.SelectedItem = clubNames.Get(selectedClubIndex)
	End If
	dialog.Title = "Club"
	Wait For (dialog.ShowTemplate(template, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim idx As Int = clubNames.IndexOf(template.SelectedItem)
	If idx < 0 Or idx = selectedClubIndex Then Return
	selectedClubIndex = idx
	presentIds.Initialize
	absentIds.Initialize
	wellIds.Initialize
	poorIds.Initialize
	trainerId = ""
	RefreshChrome
	RefreshList
End Sub

Private Sub btnDate_Click
	StyleDarkDialog
	Dim template As B4XDateTemplate
	template.Initialize
	template.Date = selectedDateTicks
	Try
		template.MinYear = DateTime.GetYear(DateTime.Now) - 2
		template.MaxYear = DateTime.GetYear(DateTime.Now) + 1
	Catch
		Log("training date years: " & LastException.Message)
	End Try
	dialog.Title = "Training date"
	Wait For (dialog.ShowTemplate(template, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	selectedDateTicks = template.Date
	btnDate.Text = FormatTicksAsUkDate(selectedDateTicks)
End Sub

Private Sub btnSave_Click
	If saving Then Return
	If clubIds.Size = 0 Then
		xui.MsgboxAsync("Join a club before logging training.", "Training")
		Return
	End If
	saving = True
	Dim session As Map
	session.Initialize
	session.Put("id", sessionId)
	session.Put("clubId", clubIds.Get(selectedClubIndex))
	session.Put("date", FormatTicksAsIsoDate(selectedDateTicks))
	session.Put("trainerOfWeekId", trainerId)
	session.Put("presentIds", CopyIds(presentIds))
	session.Put("absentIds", CopyIds(absentIds))
	session.Put("wellBehavedIds", CopyIds(wellIds))
	session.Put("poorlyBehavedIds", CopyIds(poorIds))
	modDb.SaveTraining(session)
	saving = False
	If modSupabase.LastError <> "" Then
		xui.MsgboxAsync("Could not save this session. Run the training_sessions SQL in Supabase if this is the first time.", "Training")
		Return
	End If
	modAppState.SelectedClubId = session.Get("clubId")
	B4XPages.ShowPage("Training")
End Sub

Private Sub btnDelete_Click
	If editingExisting = False Or sessionId = "" Then Return
	Dim sf As Object = xui.Msgbox2Async("Delete this training session?", "Training", "Delete", "Cancel", "", Null)
	Wait For (sf) Msgbox_Result (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	If modDb.DeleteTraining(sessionId) = False Then
		xui.MsgboxAsync("Could not delete this session.", "Training")
		Return
	End If
	B4XPages.ShowPage("Training")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Training")
End Sub

Private Sub MemberName(userId As String) As String
	Dim members As List = CurrentMembers
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim m As Map = members.Get(i)
		If m.GetDefault("id", "") = userId Then Return m.GetDefault("name", "")
	Next
	Return ""
End Sub

Private Sub CopyIds(src As Object) As List
	Dim out As List
	out.Initialize
	If (src Is List) = False Then Return out
	Dim lst As List = src
	Dim i As Int
	For i = 0 To lst.Size - 1
		Dim id As String = "" & lst.Get(i)
		If id <> "" Then out.Add(id)
	Next
	Return out
End Sub

Private Sub IdIn(lst As List, id As String) As Boolean
	Return lst.IndexOf(id) >= 0
End Sub

Private Sub RemoveId(lst As List, id As String)
	Dim i As Int
	For i = lst.Size - 1 To 0 Step -1
		If lst.Get(i) = id Then lst.RemoveAt(i)
	Next
End Sub

Private Sub StylePickerButton(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	modUI.SetButtonTextColor(b, modConfig.COLOR_DARK_TEXT)
	modUI.SetTextSize(b, 15)
	modUI.SetAlign(b, "CENTER", "LEFT")
#if B4A
	b.Padding = Array As Int(14dip, 0, 14dip, 0)
#End If
End Sub

Private Sub StyleToggle(b As Button, selected As Boolean)
	If selected Then
		b.Color = modConfig.COLOR_ACCENT
		modUI.SetButtonTextColor(b, Colors.White)
	Else
		b.Color = modConfig.COLOR_DARK_CARD
		modUI.SetButtonTextColor(b, modConfig.COLOR_DARK_MUTED)
	End If
	modUI.SetTextSize(b, 13)
	modUI.SetBold(b, True)
	modUI.SetAlign(b, "CENTER", "CENTER")
End Sub

Private Sub StyleDarkDialog
	dialog.BackgroundColor = modConfig.COLOR_DARK_CARD
	dialog.BorderColor = modConfig.COLOR_DARK_CHIP
	dialog.BorderWidth = 1dip
	dialog.BorderCornersRadius = 18dip
	dialog.OverlayColor = 0xCC020617
	dialog.TitleBarColor = modConfig.COLOR_DARK_BG
	dialog.BodyTextColor = modConfig.COLOR_DARK_TEXT
	dialog.ButtonsColor = modConfig.COLOR_DARK_CHIP
	dialog.ButtonsTextColor = Colors.White
End Sub

Private Sub FormatTicksAsUkDate(ticks As Long) As String
	Dim prev As String = DateTime.DateFormat
	DateTime.DateFormat = "dd/MM/yyyy"
	Dim s As String = DateTime.Date(ticks)
	DateTime.DateFormat = prev
	Return s
End Sub

Private Sub FormatTicksAsIsoDate(ticks As Long) As String
	Dim prev As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy-MM-dd"
	Dim s As String = DateTime.Date(ticks)
	DateTime.DateFormat = prev
	Return s
End Sub
