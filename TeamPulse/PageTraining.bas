B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Training log — one row per session for the coach's clubs.
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Refresh
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Training", "btnBack", "btnNew", "+", True)
	Dim top As Int = chrome.Get("ContentTop")
	clv = modUI.AddCustomListViewThemed(Root, 0, top, Root.Width, Root.Height - top, Me, "clv", True)
End Sub

Public Sub Refresh
	clv.Clear
	modUI.ApplyDarkListBackground(clv, modConfig.COLOR_DARK_BG)
	Dim sessions As List = modAppState.TrainingsForCurrentUser
	Dim cardW As Int = Root.Width - 24dip
	If modAppState.ClubsForCurrentUser.Size = 0 Then
		Dim noClub As Panel = modUI.CreateSimpleRowThemed(cardW, "Join a club before logging training.", "", True)
		noClub.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(noClub, "")
		Return
	End If
	If sessions.Size = 0 Then
		Dim empty As Panel = modUI.CreateSimpleRowThemed(cardW, "No sessions yet. Tap + to log training.", "", True)
		empty.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(empty, "")
		Return
	End If
	Dim showClub As Boolean = modAppState.ClubsForCurrentUser.Size > 1
	Dim i As Int
	For i = 0 To sessions.Size - 1
		Dim s As Map = sessions.Get(i)
		Dim h As Int = 86dip
		Dim wrap As Panel
		wrap.Initialize("")
		wrap.Color = modConfig.COLOR_DARK_BG
		Dim card As Panel = CreateSessionCard(cardW, s, showClub)
		wrap.AddView(card, 12dip, 4dip, cardW, 78dip)
		wrap.SetLayout(0, 0, Root.Width, h)
		clv.Add(wrap, s.GetDefault("id", ""))
	Next
End Sub

Private Sub CreateSessionCard(Width As Int, session As Map, showClub As Boolean) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Background = modUI.RoundedBg(modConfig.COLOR_DARK_CARD, 12dip)
	Dim title As String = FormatSessionDate(session.GetDefault("date", ""))
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = title
	lblTitle.TextSize = 16
	lblTitle.TextColor = modConfig.COLOR_DARK_TEXT
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.SingleLine = True
	p.AddView(lblTitle, 14dip, 10dip, Width - 28dip, 24dip)
	
	Dim presentN As Int = IdCount(session.GetDefault("presentIds", Null))
	Dim absentN As Int = IdCount(session.GetDefault("absentIds", Null))
	Dim line2 As String = presentN & " present · " & absentN & " absent"
	Dim trainerId As String = session.GetDefault("trainerOfWeekId", "")
	If trainerId <> "" Then
		Dim trainerName As String = MemberName(session.GetDefault("clubId", ""), trainerId)
		If trainerName <> "" Then line2 = line2 & " · Trainer: " & trainerName
	End If
	If showClub Then
		Dim club As Map = modAppState.FindClub(session.GetDefault("clubId", ""))
		Dim clubName As String = club.GetDefault("name", "")
		If clubName <> "" Then line2 = clubName & " · " & line2
	End If
	Dim lblMeta As Label
	lblMeta.Initialize("")
	lblMeta.Text = line2
	lblMeta.TextSize = 12
	lblMeta.TextColor = modConfig.COLOR_DARK_MUTED
	lblMeta.SingleLine = True
	p.AddView(lblMeta, 14dip, 36dip, Width - 28dip, 20dip)
	Return p
End Sub

Private Sub IdCount(raw As Object) As Int
	If raw Is List Then
		Dim lst As List = raw
		Return lst.Size
	End If
	Return 0
End Sub

Private Sub MemberName(clubId As String, userId As String) As String
	Dim club As Map = modAppState.FindClub(clubId)
	Dim memObj As Object = club.GetDefault("members", Null)
	If (memObj Is List) = False Then Return ""
	Dim members As List = memObj
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim m As Map = members.Get(i)
		If m.GetDefault("id", "") = userId Then Return m.GetDefault("name", "")
	Next
	Return ""
End Sub

Private Sub FormatSessionDate(iso As String) As String
	If iso.Length < 10 Then
		If iso = "" Then Return "Training"
		Return iso
	End If
	Dim prev As String = DateTime.DateFormat
	Try
		DateTime.DateFormat = "yyyy-MM-dd"
		Dim ticks As Long = DateTime.DateParse(iso.SubString2(0, 10))
		DateTime.DateFormat = "dd MMM yyyy"
		Dim s As String = DateTime.Date(ticks)
		DateTime.DateFormat = prev
		Return s
	Catch
		DateTime.DateFormat = prev
		Return iso
	End Try
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	modAppState.SelectedTrainingId = Value
	modAppState.EditingExistingTraining = True
	B4XPages.ShowPage("TrainingEdit")
End Sub

Private Sub btnNew_Click
	If modAppState.ClubsForCurrentUser.Size = 0 Then
		ToastMessageShow("Join a club before logging training", False)
		Return
	End If
	modAppState.EditingExistingTraining = False
	modAppState.SelectedTrainingId = ""
	B4XPages.ShowPage("TrainingEdit")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Dashboard")
End Sub
