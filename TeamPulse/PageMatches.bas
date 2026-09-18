B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
	Private edtTitle As EditText
	Private edtDate As EditText
	Private edtKickOff As EditText
	Private edtLocation As EditText
	Private edtOpponent As EditText
	Private spnClub As Spinner
	Private clubIds As List
End Sub

Public Sub Initialize
	clubIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFFF8FAFC
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadClubSpinner
	Refresh
End Sub

Private Sub BuildUI
	Dim title As Label
	title.Initialize("")
	title.Text = "Matches"
	title.TextSize = 22
	title.Typeface = Typeface.DEFAULT_BOLD
	title.TextColor = modConfig.COLOR_PRIMARY
	Root.AddView(title, 16dip, 16dip, Root.Width - 100dip, 36dip)
	
	Dim btnBack As Button
	btnBack.Initialize("btnBack")
	btnBack.Text = "Back"
	Root.AddView(btnBack, Root.Width - 88dip, 16dip, 72dip, 36dip)
	
	clv.Initialize(Me, "clv")
	Root.AddView(clv.AsView, 0, 56dip, Root.Width, 220dip)
	
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = "Schedule match"
	lbl.Typeface = Typeface.DEFAULT_BOLD
	Root.AddView(lbl, 16dip, 284dip, Root.Width - 32dip, 24dip)
	
	spnClub.Initialize("")
	Root.AddView(spnClub, 16dip, 316dip, Root.Width - 32dip, 40dip)
	
	edtTitle.Initialize("")
	edtTitle.Hint = "Title"
	Root.AddView(edtTitle, 16dip, 364dip, Root.Width - 32dip, 40dip)
	
	edtOpponent.Initialize("")
	edtOpponent.Hint = "Opponent"
	Root.AddView(edtOpponent, 16dip, 412dip, Root.Width - 32dip, 40dip)
	
	edtDate.Initialize("")
	edtDate.Hint = "Date YYYY-MM-DD"
	Root.AddView(edtDate, 16dip, 460dip, Root.Width / 2 - 20dip, 40dip)
	
	edtKickOff.Initialize("")
	edtKickOff.Hint = "Kick-off HH:MM"
	Root.AddView(edtKickOff, Root.Width / 2, 460dip, Root.Width / 2 - 16dip, 40dip)
	
	edtLocation.Initialize("")
	edtLocation.Hint = "Location"
	Root.AddView(edtLocation, 16dip, 508dip, Root.Width - 32dip, 40dip)
	
	Dim btnCreate As Button
	btnCreate.Initialize("btnCreate")
	btnCreate.Text = "Create match"
	btnCreate.Color = modConfig.COLOR_ACCENT
	btnCreate.TextColor = Colors.White
	Root.AddView(btnCreate, 16dip, 560dip, Root.Width - 32dip, 48dip)
End Sub

Private Sub LoadClubSpinner
	spnClub.Clear
	clubIds.Initialize
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	For Each c As Map In myClubs
		spnClub.Add(c.GetDefault("name", "Club"))
		clubIds.Add(c.Get("id"))
	Next
End Sub

Public Sub Refresh
	clv.Clear
	If modAppState.Matches.Size = 0 Then
		clv.AddTextItem("No matches yet.", "")
		Return
	End If
	For Each m As Map In modAppState.Matches
		Dim line As String = m.GetDefault("title", "Match") & " [" & m.GetDefault("status", "") & "]" & CRLF & _
			m.GetDefault("date", "") & " " & m.GetDefault("kickOffTime", "") & " vs " & m.GetDefault("opponentName", "") & _
			" · " & m.GetDefault("scoreA", 0) & "-" & m.GetDefault("scoreB", 0)
		clv.AddTextItem(line, m.Get("id"))
	Next
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	modAppState.SelectedMatchId = Value
	Dim m As Map = modAppState.FindMatch(Value)
	modAppState.SelectedClubId = m.GetDefault("clubId", "")
	If m.GetDefault("status", "") = "LIVE" Or m.GetDefault("status", "") = "COMPLETED" Then
		B4XPages.ShowPage("LiveFeed")
	Else
		B4XPages.ShowPage("MatchPrep")
	End If
End Sub

Private Sub btnCreate_Click
	If clubIds.Size = 0 Then
		ToastMessageShow("Create or join a club first", False)
		Return
	End If
	Dim title As String = edtTitle.Text.Trim
	If title = "" Then title = "Match vs " & edtOpponent.Text.Trim
	Dim match As Map
	match.Initialize
	match.Put("id", modAppState.NewId)
	match.Put("clubId", clubIds.Get(spnClub.SelectedIndex))
	match.Put("title", title)
	match.Put("date", edtDate.Text.Trim)
	match.Put("kickOffTime", edtKickOff.Text.Trim)
	match.Put("meetTime", "")
	match.Put("location", edtLocation.Text.Trim)
	match.Put("status", "UPCOMING")
	match.Put("scoreA", 0)
	match.Put("scoreB", 0)
	match.Put("opponentName", edtOpponent.Text.Trim)
	match.Put("isHome", True)
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
	match.Put("playerStats", emptyM)
	match.Put("potmVotes", emptyM)
	match.Put("formation", "4-4-2")
	match.Put("tacticalLineup", emptyM)
	match.Put("managerSummary", "")
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	ToastMessageShow("Match created", False)
	Refresh
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Dashboard")
End Sub
