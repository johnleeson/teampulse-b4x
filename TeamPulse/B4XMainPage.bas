B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private lblStatus As B4XView
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	modAppState.Initialize
	BuildUI
	B4XPages.SetTitle(Me, modConfig.APP_NAME)
	
	Dim login As PageLogin
	login.Initialize
	B4XPages.AddPage("Login", login)
	
	Dim dash As PageDashboard
	dash.Initialize
	B4XPages.AddPageAndCreate("Dashboard", dash)
	
	Dim clubs As PageClubs
	clubs.Initialize
	B4XPages.AddPage("Clubs", clubs)
	
	Dim members As PageClubMembers
	members.Initialize
	B4XPages.AddPage("ClubMembers", members)
	
	Dim matches As PageMatches
	matches.Initialize
	B4XPages.AddPage("Matches", matches)
	
	Dim prep As PageMatchPrep
	prep.Initialize
	B4XPages.AddPage("MatchPrep", prep)
	
	Dim live As PageLiveFeed
	live.Initialize
	B4XPages.AddPage("LiveFeed", live)
	
	Dim stats As PageStats
	stats.Initialize
	B4XPages.AddPage("Stats", stats)
	
	StartApp
End Sub

Private Sub BuildUI
	Root.Color = modConfig.COLOR_PRIMARY
	Dim lbl As Label
	lbl.Initialize("")
	lblStatus = lbl
	lbl.Text = "Starting TeamPulse…"
	lbl.TextColor = Colors.White
	lbl.Gravity = Gravity.CENTER
	lbl.TextSize = 18
	Root.AddView(lbl, 0, 40%y, 100%x, 80dip)
End Sub

Private Sub StartApp
	modFirebase.Initialize
	If modFirebase.Ready = False Then
		lblStatus.Text = "Firebase init pending." & CRLF & modFirebase.LastError & CRLF & _
			"Configure google-services.json in B4A, then rebuild."
	End If
	Wait For (modAuth.RestoreSessionIfLoggedIn) Complete (ok As Boolean)
	If ok Then
		RefreshDataAndGoDashboard
	Else
		B4XPages.ShowPageAndRemovePreviousPages("Login")
	End If
End Sub

Public Sub RefreshDataAndGoDashboard
	lblStatus.Text = "Loading clubs & matches…"
	modDb.FetchInitialData
	B4XPages.ShowPageAndRemovePreviousPages("Dashboard")
End Sub

Public Sub AfterLogin
	RefreshDataAndGoDashboard
End Sub
