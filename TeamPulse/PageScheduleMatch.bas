B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Schedule a new match (separate screen from the Matches list).
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private sv As ScrollView
	Private content As Panel
	Private edtTitle As EditText
	Private edtLocation As EditText
	Private edtOpponent As EditText
	Private btnDate As Button
	Private btnTime As Button
	Private btnClub As Button
	Private lblClub As Label
	Private btnFriendly As Button
	Private btnLeague As Button
	Private btnCup As Button
	Private btnHome As Button
	Private btnAway As Button
	Private btnLocSuggest As Button
	Private btnCreate As Button
	Private chromeTitle As Label
	Private clubIds As List
	Private clubNames As List
	Private selectedClubIndex As Int
	Private selectedCompetition As String
	Private isHome As Boolean
	Private selectedDateTicks As Long
	Private selectedHour As Int
	Private selectedMinute As Int
	Private clvHour As CustomListView
	Private clvMinute As CustomListView
	Private pendingHour As Int
	Private pendingMinute As Int
End Sub

Public Sub Initialize
	clubIds.Initialize
	clubNames.Initialize
	selectedClubIndex = 0
	selectedCompetition = "FRIENDLY"
	isHome = True
	selectedDateTicks = DateTime.Now
	selectedHour = 15
	selectedMinute = 0
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadClubs
	If modAppState.EditingExistingMatch Then
		LoadExistingMatch
	Else
		ResetNewMatchDefaults
	End If
	RefreshPickers
	ApplyHomeLocationIfNeeded
	If modAppState.EditingExistingMatch Then
		chromeTitle.Text = "Edit match"
		btnCreate.Text = "Save changes"
	Else
		chromeTitle.Text = "Schedule match"
		btnCreate.Text = "Create match"
	End If
End Sub

Private Sub ResetNewMatchDefaults
	selectedCompetition = "FRIENDLY"
	isHome = True
	selectedDateTicks = DateTime.Now
	selectedHour = 15
	selectedMinute = 0
	edtTitle.Text = ""
	edtOpponent.Text = ""
	edtLocation.Text = ""
	RefreshCompetitionButtons
	RefreshVenueButtons
End Sub

Private Sub LoadExistingMatch
	Dim m As Map = modAppState.FindMatch(modAppState.SelectedMatchId)
	If m.ContainsKey("id") = False Then
		modAppState.EditingExistingMatch = False
		ResetNewMatchDefaults
		Return
	End If
	Dim cid As String = m.GetDefault("clubId", "")
	Dim i As Int
	For i = 0 To clubIds.Size - 1
		If clubIds.Get(i) = cid Then
			selectedClubIndex = i
			Exit
		End If
	Next
	selectedCompetition = m.GetDefault("competition", "FRIENDLY")
	If selectedCompetition = "" Then selectedCompetition = "FRIENDLY"
	isHome = m.GetDefault("isHome", True)
	edtTitle.Text = m.GetDefault("title", "")
	edtOpponent.Text = m.GetDefault("opponentName", "")
	edtLocation.Text = m.GetDefault("location", "")
	Dim d As String = m.GetDefault("date", "")
	If d.Length >= 10 Then
		Try
			DateTime.DateFormat = "yyyy-MM-dd"
			selectedDateTicks = DateTime.DateParse(d.SubString2(0, 10))
		Catch
			selectedDateTicks = DateTime.Now
		End Try
	End If
	Dim kt As String = m.GetDefault("kickOffTime", "15:00")
	Dim colon As Int = kt.IndexOf(":")
	If colon > 0 Then
		Try
			selectedHour = kt.SubString2(0, colon)
			selectedMinute = kt.SubString(colon + 1)
		Catch
			selectedHour = 15
			selectedMinute = 0
		End Try
	End If
	RefreshCompetitionButtons
	RefreshVenueButtons
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Schedule match", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	chromeTitle = chrome.Get("TitleLabel")
	sv.Initialize(2000dip)
	Root.AddView(sv, 0, top, Root.Width, Root.Height - top)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
	
	Dim y As Int = 8dip
	Dim w As Int = Root.Width - 32dip
	
	lblClub.Initialize("")
	lblClub.Text = "CLUB"
	lblClub.TextSize = 11
	lblClub.TextColor = modConfig.COLOR_DARK_MUTED
	lblClub.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lblClub, 16dip, y, w, 18dip)
	y = y + 22dip
	btnClub.Initialize("btnClub")
	StylePickerButton(btnClub)
	content.AddView(btnClub, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "TYPE")
	Dim typeRow As Panel
	typeRow.Initialize("")
	typeRow.Color = Colors.Transparent
	content.AddView(typeRow, 16dip, y, w, 44dip)
	Dim tw As Int = (w - 16dip) / 3
	btnFriendly.Initialize("btnFriendly")
	btnLeague.Initialize("btnLeague")
	btnCup.Initialize("btnCup")
	typeRow.AddView(btnFriendly, 0, 0, tw, 44dip)
	typeRow.AddView(btnLeague, tw + 8dip, 0, tw, 44dip)
	typeRow.AddView(btnCup, 2 * (tw + 8dip), 0, tw, 44dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "VENUE")
	Dim venueRow As Panel
	venueRow.Initialize("")
	venueRow.Color = Colors.Transparent
	content.AddView(venueRow, 16dip, y, w, 44dip)
	Dim vw As Int = (w - 8dip) / 2
	btnHome.Initialize("btnHome")
	btnAway.Initialize("btnAway")
	venueRow.AddView(btnHome, 0, 0, vw, 44dip)
	venueRow.AddView(btnAway, vw + 8dip, 0, vw, 44dip)
	y = y + 56dip
	
	edtTitle.Initialize("")
	modUI.StyleEditTextDark(edtTitle, "Title (optional)")
	content.AddView(edtTitle, 16dip, y, w, 48dip)
	y = y + 56dip
	
	edtOpponent.Initialize("")
	modUI.StyleEditTextDark(edtOpponent, "Opponent")
	content.AddView(edtOpponent, 16dip, y, w, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "DATE & KICK-OFF")
	btnDate.Initialize("btnDate")
	StylePickerButton(btnDate)
	content.AddView(btnDate, 16dip, y, Root.Width / 2 - 20dip, 48dip)
	btnTime.Initialize("btnTime")
	StylePickerButton(btnTime)
	content.AddView(btnTime, Root.Width / 2, y, Root.Width / 2 - 16dip, 48dip)
	y = y + 56dip
	
	y = AddFieldLabel(y, w, "LOCATION")
	edtLocation.Initialize("")
	modUI.StyleEditTextDark(edtLocation, "Ground / venue")
	content.AddView(edtLocation, 16dip, y, w - 56dip, 48dip)
	btnLocSuggest.Initialize("btnLocSuggest")
	btnLocSuggest.Text = "▾"
	btnLocSuggest.TextSize = 18
	btnLocSuggest.Color = modConfig.COLOR_DARK_CARD
	btnLocSuggest.TextColor = modConfig.COLOR_DARK_TEXT
	content.AddView(btnLocSuggest, Root.Width - 64dip, y, 48dip, 48dip)
	y = y + 64dip
	
	btnCreate.Initialize("btnCreate")
	btnCreate.Text = "Create match"
	btnCreate.Color = modConfig.COLOR_ACCENT
	btnCreate.TextColor = Colors.White
	btnCreate.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(btnCreate, 16dip, y, w, 52dip)
	y = y + 72dip
	
	content.Height = Max(y, Root.Height)
	sv.Panel.Height = content.Height
	
	RefreshCompetitionButtons
	RefreshVenueButtons
End Sub

Private Sub AddFieldLabel(y As Int, w As Int, text As String) As Int
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 11
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	lbl.Typeface = Typeface.DEFAULT_BOLD
	content.AddView(lbl, 16dip, y, w, 18dip)
	Return y + 22dip
End Sub

Private Sub StylePickerButton(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	b.TextColor = modConfig.COLOR_DARK_TEXT
	b.TextSize = 15
	b.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
	b.Typeface = Typeface.DEFAULT
	b.Padding = Array As Int(14dip, 0, 14dip, 0)
End Sub

Private Sub StyleToggle(b As Button, selected As Boolean)
	If selected Then
		b.Color = modConfig.COLOR_ACCENT
		b.TextColor = Colors.White
	Else
		b.Color = modConfig.COLOR_DARK_CARD
		b.TextColor = modConfig.COLOR_DARK_MUTED
	End If
	b.TextSize = 13
	b.Typeface = Typeface.DEFAULT_BOLD
	b.Gravity = Gravity.CENTER
End Sub

Private Sub RefreshCompetitionButtons
	btnFriendly.Text = "Friendly"
	btnLeague.Text = "League"
	btnCup.Text = "Cup"
	StyleToggle(btnFriendly, selectedCompetition = "FRIENDLY")
	StyleToggle(btnLeague, selectedCompetition = "LEAGUE")
	StyleToggle(btnCup, selectedCompetition = "CUP")
End Sub

Private Sub RefreshVenueButtons
	btnHome.Text = "Home"
	btnAway.Text = "Away"
	StyleToggle(btnHome, isHome)
	StyleToggle(btnAway, isHome = False)
End Sub

Private Sub RefreshPickers
	btnDate.Text = FormatTicksAsUkDate(selectedDateTicks)
	btnTime.Text = NumberFormat(selectedHour, 2, 0) & ":" & NumberFormat(selectedMinute, 2, 0)
	If clubNames.Size = 0 Then
		btnClub.Text = "No clubs yet"
	Else If selectedClubIndex >= 0 And selectedClubIndex < clubNames.Size Then
		btnClub.Text = clubNames.Get(selectedClubIndex)
	End If
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
	' Single club: hide picker, auto-select
	Dim single As Boolean = (clubIds.Size <= 1)
	lblClub.Visible = Not(single)
	btnClub.Visible = Not(single)
	If clubIds.Size = 1 Then selectedClubIndex = 0
	RefreshPickers
End Sub

Private Sub SelectedClubId As String
	If clubIds.Size = 0 Then Return ""
	Return clubIds.Get(selectedClubIndex)
End Sub

Private Sub btnClub_Click
	If clubNames.Size = 0 Then
		ToastMessageShow("Create or join a club first", False)
		Return
	End If
	StyleDarkDialog
	Dim template As B4XListTemplate
	template.Initialize
	Try
		template.CustomListView1.DefaultTextColor = Colors.White
		template.CustomListView1.DefaultTextBackgroundColor = modConfig.COLOR_DARK_CARD
	Catch
		Log("clubTpl: " & LastException.Message)
	End Try
	template.Options = clubNames
	If selectedClubIndex >= 0 And selectedClubIndex < clubNames.Size Then
		template.SelectedItem = clubNames.Get(selectedClubIndex)
	End If
	dialog.Title = "Club"
	Wait For (dialog.ShowTemplate(template, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	Dim idx As Int = clubNames.IndexOf(template.SelectedItem)
	If idx >= 0 Then selectedClubIndex = idx
	RefreshPickers
	ApplyHomeLocationIfNeeded
End Sub

Private Sub btnFriendly_Click
	selectedCompetition = "FRIENDLY"
	RefreshCompetitionButtons
End Sub

Private Sub btnLeague_Click
	selectedCompetition = "LEAGUE"
	RefreshCompetitionButtons
End Sub

Private Sub btnCup_Click
	selectedCompetition = "CUP"
	RefreshCompetitionButtons
End Sub

Private Sub btnHome_Click
	isHome = True
	RefreshVenueButtons
	ApplyHomeLocationIfNeeded
End Sub

Private Sub btnAway_Click
	isHome = False
	RefreshVenueButtons
	' Don't clear location if user typed one; only clear when it matches usual home ground
	Dim homeLoc As String = UsualHomeLocation
	If edtLocation.Text.Trim = homeLoc Then edtLocation.Text = ""
End Sub

Private Sub ApplyHomeLocationIfNeeded
	If isHome = False Then Return
	Dim homeLoc As String = UsualHomeLocation
	If homeLoc <> "" Then edtLocation.Text = homeLoc
End Sub

' Most common location among past home matches for the selected club.
Private Sub UsualHomeLocation As String
	Dim cid As String = SelectedClubId
	If cid = "" Then Return ""
	Dim counts As Map
	counts.Initialize
	Dim matches As List = modAppState.Matches
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		If m.GetDefault("clubId", "") <> cid Then Continue
		If m.GetDefault("isHome", True) = False Then Continue
		Dim loc As String = m.GetDefault("location", "")
		loc = loc.Trim
		If loc = "" Then Continue
		counts.Put(loc, counts.GetDefault(loc, 0) + 1)
	Next
	Dim best As String = ""
	Dim bestN As Int = 0
	For Each loc2 As String In counts.Keys
		Dim n As Int = counts.Get(loc2)
		If n > bestN Then
			bestN = n
			best = loc2
		End If
	Next
	Return best
End Sub

Private Sub LocationHistory As List
	Dim out As List
	out.Initialize
	Dim seen As Map
	seen.Initialize
	Dim cid As String = SelectedClubId
	Dim matches As List = modAppState.Matches
	Dim i As Int
	For i = matches.Size - 1 To 0 Step -1
		Dim m As Map = matches.Get(i)
		If cid <> "" And m.GetDefault("clubId", "") <> cid Then Continue
		Dim loc As String = m.GetDefault("location", "")
		loc = loc.Trim
		If loc = "" Or seen.ContainsKey(loc) Then Continue
		seen.Put(loc, True)
		out.Add(loc)
		If out.Size >= 12 Then Exit
	Next
	Return out
End Sub

Private Sub btnLocSuggest_Click
	Dim hist As List = LocationHistory
	If hist.Size = 0 Then
		ToastMessageShow("No previous locations yet", False)
		Return
	End If
	StyleDarkDialog
	Dim template As B4XListTemplate
	template.Initialize
	Try
		template.CustomListView1.DefaultTextColor = Colors.White
		template.CustomListView1.DefaultTextBackgroundColor = modConfig.COLOR_DARK_CARD
	Catch
		Log("locTpl: " & LastException.Message)
	End Try
	template.Options = hist
	dialog.Title = "Recent locations"
	Wait For (dialog.ShowTemplate(template, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	If template.SelectedItem <> "" Then edtLocation.Text = template.SelectedItem
End Sub

Private Sub btnDate_Click
	StyleDarkDialog
	Dim template As B4XDateTemplate
	template.Initialize
	template.Date = selectedDateTicks
	Try
		template.MinYear = DateTime.GetYear(DateTime.Now) - 1
		template.MaxYear = DateTime.GetYear(DateTime.Now) + 2
	Catch
		Log("DateTemplate years: " & LastException.Message)
	End Try
	dialog.Title = "Match date"
	Wait For (dialog.ShowTemplate(template, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	selectedDateTicks = template.Date
	RefreshPickers
End Sub

Private Sub btnTime_Click
	StyleDarkDialog
	pendingHour = selectedHour
	pendingMinute = selectedMinute
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, 300dip, 300dip)
	pnl.Color = modConfig.COLOR_DARK_CARD
	
	Dim lblH As Label
	lblH.Initialize("")
	lblH.Text = "Hour"
	lblH.TextSize = 12
	lblH.TextColor = modConfig.COLOR_DARK_MUTED
	lblH.Gravity = Gravity.CENTER
	pnl.AddView(lblH, 0, 4dip, 150dip, 20dip)
	
	Dim lblM As Label
	lblM.Initialize("")
	lblM.Text = "Minute"
	lblM.TextSize = 12
	lblM.TextColor = modConfig.COLOR_DARK_MUTED
	lblM.Gravity = Gravity.CENTER
	pnl.AddView(lblM, 150dip, 4dip, 150dip, 20dip)
	
	clvHour = modUI.AddCustomListViewThemed(pnl, 8dip, 28dip, 136dip, 260dip, Me, "clvHour", True)
	clvMinute = modUI.AddCustomListViewThemed(pnl, 156dip, 28dip, 136dip, 260dip, Me, "clvMinute", True)
	
	FillTimeLists
	dialog.Title = "Kick-off time"
	Wait For (dialog.ShowCustom(pnl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	selectedHour = pendingHour
	selectedMinute = pendingMinute
	RefreshPickers
End Sub

Private Sub FillTimeLists
	clvHour.Clear
	clvMinute.Clear
	Dim h As Int
	For h = 0 To 23
		AddTimeRow(clvHour, NumberFormat(h, 2, 0), h, h = pendingHour)
	Next
	Dim m As Int
	For m = 0 To 55 Step 5
		AddTimeRow(clvMinute, NumberFormat(m, 2, 0), m, m = pendingMinute)
	Next
	Try
		clvHour.ScrollToItem(pendingHour)
		clvMinute.ScrollToItem(pendingMinute / 5)
	Catch
		Log("ScrollToItem: " & LastException.Message)
	End Try
End Sub

Private Sub AddTimeRow(clv As CustomListView, text As String, value As Int, selected As Boolean)
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, clv.AsView.Width, 44dip)
	If selected Then
		p.Color = modConfig.COLOR_ACCENT
	Else
		p.Color = modConfig.COLOR_DARK_CARD
	End If
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 18
	lbl.TextColor = Colors.White
	lbl.Gravity = Gravity.CENTER
	lbl.Typeface = Typeface.DEFAULT_BOLD
	p.AddView(lbl, 0, 0, p.Width, 44dip)
	clv.Add(p, value)
End Sub

Private Sub clvHour_ItemClick (Index As Int, Value As Object)
	pendingHour = Value
	FillTimeLists
End Sub

Private Sub clvMinute_ItemClick (Index As Int, Value As Object)
	pendingMinute = Value
	FillTimeLists
End Sub

Private Sub btnCreate_Click
	If clubIds.Size = 0 Then
		ToastMessageShow("Create or join a club first", False)
		Return
	End If
	Dim title As String = edtTitle.Text.Trim
	If title = "" Then
		Dim opp As String = edtOpponent.Text.Trim
		Dim clubName As String = ""
		If selectedClubIndex >= 0 And selectedClubIndex < clubNames.Size Then clubName = clubNames.Get(selectedClubIndex)
		If isHome Then
			title = clubName & " vs " & opp
		Else
			title = opp & " vs " & clubName
		End If
	End If
	
	If modAppState.EditingExistingMatch Then
		Dim match As Map = modAppState.FindMatch(modAppState.SelectedMatchId)
		If match.ContainsKey("id") = False Then
			ToastMessageShow("Match not found", False)
			Return
		End If
		match.Put("clubId", SelectedClubId)
		match.Put("title", title)
		match.Put("date", FormatTicksAsIsoDate(selectedDateTicks))
		match.Put("kickOffTime", NumberFormat(selectedHour, 2, 0) & ":" & NumberFormat(selectedMinute, 2, 0))
		match.Put("location", edtLocation.Text.Trim)
		match.Put("opponentName", edtOpponent.Text.Trim)
		match.Put("isHome", isHome)
		match.Put("competition", selectedCompetition)
		modDb.SaveMatch(match)
		modAppState.UpsertMatch(match)
		modAppState.EditingExistingMatch = False
		ToastMessageShow("Match updated", False)
		B4XPages.ShowPage("MatchHub")
		Return
	End If
	
	Dim match As Map
	match.Initialize
	match.Put("id", modAppState.NewId)
	match.Put("clubId", SelectedClubId)
	match.Put("title", title)
	match.Put("date", FormatTicksAsIsoDate(selectedDateTicks))
	match.Put("kickOffTime", NumberFormat(selectedHour, 2, 0) & ":" & NumberFormat(selectedMinute, 2, 0))
	match.Put("meetTime", "")
	match.Put("location", edtLocation.Text.Trim)
	match.Put("status", "UPCOMING")
	match.Put("scoreA", 0)
	match.Put("scoreB", 0)
	match.Put("opponentName", edtOpponent.Text.Trim)
	match.Put("isHome", isHome)
	Dim emptyL As List
	emptyL.Initialize
	Dim emptyM As Map
	emptyM.Initialize
	match.Put("signedUpPlayerIds", emptyL)
	match.Put("availability", emptyM)
	match.Put("startingLineupIds", emptyL)
	match.Put("benchIds", emptyL)
	match.Put("starPlayerIds", emptyL)
	match.Put("weakerPlayerIds", emptyL)
	match.Put("teamA", emptyL)
	match.Put("teamB", emptyL)
	match.Put("potmVotes", modDb.EmptyPotmVotes)
	match.Put("photoUrls", emptyL)
	match.Put("competition", selectedCompetition)
	Dim club As Map = modAppState.FindClub(SelectedClubId)
	Dim ts As Int = club.GetDefault("preferredTeamSize", 11)
	If ts = 0 Then ts = 11
	Dim form As String = club.GetDefault("preferredFormation", "")
	If form = "" Or modFormations.FormationsForSize(ts).IndexOf(form) < 0 Then
		form = modFormations.DefaultFormationForSize(ts)
	End If
	match.Put("teamSize", ts)
	match.Put("formation", form)
	match.Put("tacticalLineup", emptyM)
	match.Put("lineup", emptyM)
	match.Put("subPlan", emptyM)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	ToastMessageShow("Match created", False)
	B4XPages.ShowPage("Matches")
End Sub

Private Sub btnBack_Click
	If modAppState.EditingExistingMatch Then
		modAppState.EditingExistingMatch = False
		B4XPages.ShowPage("MatchHub")
	Else
		B4XPages.ShowPage("Matches")
	End If
End Sub
