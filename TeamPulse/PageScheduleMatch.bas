B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Schedule a new match (separate screen from the Matches list).
Sub Class_Globals
	Private Root As B4XView
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
	Root.Color = modConfig.COLOR_SURFACE
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadClubSpinner
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Schedule match", "btnBack", "", "", False)
	Dim y As Int = chrome.Get("ContentTop") + 8dip
	Dim lblClub As Label
	lblClub.Initialize("")
	lblClub.Text = "CLUB"
	lblClub.TextSize = 11
	lblClub.TextColor = modConfig.COLOR_MUTED
	lblClub.Typeface = Typeface.DEFAULT_BOLD
	Root.AddView(lblClub, 16dip, y, Root.Width - 32dip, 18dip)
	y = y + 22dip
	spnClub.Initialize("")
	spnClub.TextSize = 15
	Root.AddView(spnClub, 16dip, y, Root.Width - 32dip, 44dip)
	y = y + 56dip
	
	edtTitle.Initialize("")
	modUI.StyleEditText(edtTitle, "Title")
	Root.AddView(edtTitle, 16dip, y, Root.Width - 32dip, 48dip)
	y = y + 56dip
	
	edtOpponent.Initialize("")
	modUI.StyleEditText(edtOpponent, "Opponent")
	Root.AddView(edtOpponent, 16dip, y, Root.Width - 32dip, 48dip)
	y = y + 56dip
	
	edtDate.Initialize("")
	modUI.StyleEditText(edtDate, "Date YYYY-MM-DD")
	Root.AddView(edtDate, 16dip, y, Root.Width / 2 - 20dip, 48dip)
	
	edtKickOff.Initialize("")
	modUI.StyleEditText(edtKickOff, "Kick-off HH:MM")
	Root.AddView(edtKickOff, Root.Width / 2, y, Root.Width / 2 - 16dip, 48dip)
	y = y + 56dip
	
	edtLocation.Initialize("")
	modUI.StyleEditText(edtLocation, "Location")
	Root.AddView(edtLocation, 16dip, y, Root.Width - 32dip, 48dip)
	y = y + 64dip
	
	Dim btnCreate As Button
	btnCreate.Initialize("btnCreate")
	btnCreate.Text = "Create match"
	btnCreate.Color = modConfig.COLOR_ACCENT
	btnCreate.TextColor = Colors.White
	Root.AddView(btnCreate, 16dip, y, Root.Width - 32dip, 52dip)
End Sub

Private Sub LoadClubSpinner
	spnClub.Clear
	clubIds.Initialize
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	Dim i As Int
	For i = 0 To myClubs.Size - 1
		Dim c As Map = myClubs.Get(i)
		spnClub.Add(c.GetDefault("name", "Club"))
		clubIds.Add(c.Get("id"))
	Next
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
	match.Put("potmVotes", modDb.EmptyPotmVotes)
	match.Put("photoUrls", emptyL)
	match.Put("competition", "FRIENDLY")
	match.Put("teamSize", 11)
	match.Put("formation", "4-4-2")
	match.Put("tacticalLineup", emptyM)
	match.Put("lineup", emptyM)
	match.Put("subPlan", emptyM)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	ToastMessageShow("Match created", False)
	B4XPages.ShowPage("Matches")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Matches")
End Sub
