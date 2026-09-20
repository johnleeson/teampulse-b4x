B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=TeamPulse.zip

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
	B4XPages.AddPage("Dashboard", dash)
	
	Dim clubs As PageClubs
	clubs.Initialize
	B4XPages.AddPage("Clubs", clubs)
	
	Dim members As PageClubMembers
	members.Initialize
	B4XPages.AddPage("ClubMembers", members)
	
	Dim matches As PageMatches
	matches.Initialize
	B4XPages.AddPage("Matches", matches)
	
	Dim schedule As PageScheduleMatch
	schedule.Initialize
	B4XPages.AddPage("ScheduleMatch", schedule)
	
	Dim clubForm As PageClubForm
	clubForm.Initialize
	B4XPages.AddPage("ClubForm", clubForm)
	
	Dim hub As PageMatchHub
	hub.Initialize
	B4XPages.AddPage("MatchHub", hub)
	
	Dim squad As PageMatchSquad
	squad.Initialize
	B4XPages.AddPage("MatchSquad", squad)
	
	Dim lineup As PageMatchLineup
	lineup.Initialize
	B4XPages.AddPage("MatchLineup", lineup)
	
	Dim subs As PageMatchSubs
	subs.Initialize
	B4XPages.AddPage("MatchSubs", subs)
	
	Dim prep As PageMatchPrep
	prep.Initialize
	B4XPages.AddPage("MatchPrep", prep)
	
	Dim live As PageLiveFeed
	live.Initialize
	B4XPages.AddPage("LiveFeed", live)
	
	Dim eventEdit As PageEventEdit
	eventEdit.Initialize
	B4XPages.AddPage("EventEdit", eventEdit)
	
	Dim matchStats As PageMatchStats
	matchStats.Initialize
	B4XPages.AddPage("MatchStats", matchStats)
	
	Dim matchSummary As PageMatchSummary
	matchSummary.Initialize
	B4XPages.AddPage("MatchSummary", matchSummary)
	
	Dim stats As PageStats
	stats.Initialize
	B4XPages.AddPage("Stats", stats)
	
	' Must not navigate during B4XPage_Created — UI stays stuck on splash otherwise.
	CallSubDelayed(Me, "StartApp")
End Sub

Private Sub BuildUI
	Root.Color = modConfig.COLOR_PRIMARY
	Dim lbl As Label
	lbl.Initialize("")
	lblStatus = lbl
	lbl.Text = "Starting TeamPulse..."
	lbl.TextColor = Colors.White
	lbl.Gravity = Gravity.CENTER
	lbl.TextSize = 18
	Root.AddView(lbl, 0, Root.Height * 0.4, Root.Width, 80dip)
End Sub

Private Sub StartApp
	Try
		lblStatus.Text = "Connecting..."
		modSupabase.Initialize
		If modSupabase.Ready = False Then
			Dim errMsg As String = modSupabase.LastError
			lblStatus.Text = "Supabase config missing." & CRLF & errMsg & CRLF & "Set SUPABASE_URL / SUPABASE_ANON_KEY in modConfig."
			Return
		End If
		If modSupabase.IsLoggedIn Then
			lblStatus.Text = "Restoring session..."
			If modAuth.RestoreSessionIfLoggedIn Then
				RefreshDataAndGoDashboard
			Else
				lblStatus.Text = "Session expired. Opening login..."
				B4XPages.ShowPageAndRemovePreviousPages("Login")
			End If
		Else
			lblStatus.Text = "Opening login..."
			B4XPages.ShowPageAndRemovePreviousPages("Login")
		End If
	Catch
		lblStatus.Text = "Startup error:" & CRLF & LastException.Message
		Log("StartApp: " & LastException)
	End Try
End Sub

Public Sub RefreshDataAndGoDashboard
	Try
		lblStatus.Text = "Loading clubs & matches..."
		modDb.FetchInitialData
		If modSupabase.LastError <> "" Then
			Log("FetchInitialData warning: " & modSupabase.LastError)
		End If
		B4XPages.ShowPageAndRemovePreviousPages("Dashboard")
	Catch
		lblStatus.Text = "Load failed:" & CRLF & LastException.Message & CRLF & "Tap back or restart."
		Log("RefreshDataAndGoDashboard: " & LastException)
		B4XPages.ShowPageAndRemovePreviousPages("Login")
	End Try
End Sub

Public Sub AfterLogin
	' Return to splash so FetchInitialData progress is visible; StrictMode allows sync REST.
	B4XPages.ShowPageAndRemovePreviousPages("MainPage")
	lblStatus.Text = "Loading clubs & matches..."
	Sleep(50)
	RefreshDataAndGoDashboard
End Sub
