B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Club / player statistics (no AI).
Sub Class_Globals
	Private Root As B4XView
	Private spnClub As Spinner
	Private spnMatch As Spinner
	Private clv As CustomListView
	Private lblSummary As Label
	Private clubIds As List
	Private matchIds As List
End Sub

Public Sub Initialize
	clubIds.Initialize
	matchIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFFF8FAFC
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadClubs
	Refresh
End Sub

Private Sub BuildUI
	Dim title As Label
	title.Initialize("")
	title.Text = "Statistics"
	title.TextSize = 22
	title.Typeface = Typeface.DEFAULT_BOLD
	title.TextColor = modConfig.COLOR_PRIMARY
	Root.AddView(title, 16dip, 16dip, Root.Width - 100dip, 36dip)
	
	Dim btnBack As Button
	btnBack.Initialize("btnBack")
	btnBack.Text = "Back"
	Root.AddView(btnBack, Root.Width - 88dip, 16dip, 72dip, 36dip)
	
	spnClub.Initialize("spnClub")
	Root.AddView(spnClub, 16dip, 60dip, Root.Width - 32dip, 40dip)
	
	spnMatch.Initialize("spnMatch")
	Root.AddView(spnMatch, 16dip, 108dip, Root.Width - 32dip, 40dip)
	
	lblSummary.Initialize("")
	lblSummary.TextSize = 14
	lblSummary.TextColor = modConfig.COLOR_PRIMARY
	Root.AddView(lblSummary, 16dip, 156dip, Root.Width - 32dip, 72dip)
	
	' Simple bar row container label
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Player leaderboard (by goals)"
	hint.Typeface = Typeface.DEFAULT_BOLD
	hint.TextColor = modConfig.COLOR_MUTED
	Root.AddView(hint, 16dip, 232dip, Root.Width - 32dip, 24dip)
	
	clv.Initialize(Me, "clv")
	Root.AddView(clv.AsView, 0, 260dip, Root.Width, Root.Height - 268dip)
End Sub

Private Sub LoadClubs
	spnClub.Clear
	clubIds.Initialize
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	For Each c As Map In myClubs
		spnClub.Add(c.GetDefault("name", "Club"))
		clubIds.Add(c.Get("id"))
	Next
	LoadMatches
End Sub

Private Sub LoadMatches
	spnMatch.Clear
	matchIds.Initialize
	spnMatch.Add("All completed")
	matchIds.Add("all")
	If clubIds.Size = 0 Then Return
	Dim cid As String = clubIds.Get(Max(0, spnClub.SelectedIndex))
	For Each m As Map In modAppState.Matches
		If m.GetDefault("clubId", "") = cid And m.GetDefault("status", "") = "COMPLETED" Then
			spnMatch.Add(m.GetDefault("title", "Match") & " (" & m.GetDefault("date", "") & ")")
			matchIds.Add(m.Get("id"))
		End If
	Next
End Sub

Public Sub Refresh
	clv.Clear
	If clubIds.Size = 0 Then
		lblSummary.Text = "Join a club to see statistics."
		Return
	End If
	Dim cid As String = clubIds.Get(Max(0, spnClub.SelectedIndex))
	Dim club As Map = modAppState.FindClub(cid)
	Dim mid As String = "all"
	If matchIds.Size > 0 Then mid = matchIds.Get(Max(0, spnMatch.SelectedIndex))
	
	Dim stats As Map = modStats.Compute(club, modAppState.Matches, modAppState.FeedEvents, mid)
	lblSummary.Text = "P " & stats.GetDefault("played", 0) & _
		"   W " & stats.GetDefault("wins", 0) & _
		"   D " & stats.GetDefault("draws", 0) & _
		"   L " & stats.GetDefault("losses", 0) & CRLF & _
		"GF " & stats.GetDefault("goalsFor", 0) & "   GA " & stats.GetDefault("goalsAgainst", 0)
	
	Dim players As List = stats.Get("players")
	Dim maxGoals As Int = 1
	For Each p As Map In players
		maxGoals = Max(maxGoals, p.GetDefault("goals", 0))
	Next
	For Each p As Map In players
		Dim g As Int = p.GetDefault("goals", 0)
		Dim barLen As Int = 0
		If maxGoals > 0 Then barLen = (g * 12) / maxGoals
		Dim bar As String = ""
		For i = 1 To barLen
			bar = bar & "█"
		Next
		Dim line As String = p.GetDefault("name", "") & CRLF & _
			"G " & g & "  A " & p.GetDefault("assists", 0) & _
			"  Apps " & p.GetDefault("apps", 0) & _
			"  YC " & p.GetDefault("yellowCards", 0) & _
			"  RC " & p.GetDefault("redCards", 0) & _
			"  POTM " & p.GetDefault("potmWins", 0) & _
			"  Min " & p.GetDefault("minutesPlayed", 0) & CRLF & bar
		clv.AddTextItem(line, p.GetDefault("id", ""))
	Next
	If players.Size = 0 Then clv.AddTextItem("No player stats yet.", "")
End Sub

Private Sub spnClub_ItemClick (Position As Int, Value As Object)
	LoadMatches
	Refresh
End Sub

Private Sub spnMatch_ItemClick (Position As Int, Value As Object)
	Refresh
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Dashboard")
End Sub
