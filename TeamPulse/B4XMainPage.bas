B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files" /XF .gitkeep
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&args=/XF&args=.gitkeep&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=TeamPulse.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private lblStatus As B4XView
	Private http As clsHttp
	Private syncRunning As Boolean
	Private syncAgain As Boolean
	Private wantPull As Boolean
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	http.Initialize
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
	
	Dim playerEdit As PagePlayerEdit
	playerEdit.Initialize
	B4XPages.AddPage("PlayerEdit", playerEdit)
	
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
	
	Dim training As PageTraining
	training.Initialize
	B4XPages.AddPage("Training", training)
	
	Dim trainingEdit As PageTrainingEdit
	trainingEdit.Initialize
	B4XPages.AddPage("TrainingEdit", trainingEdit)
	
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
		modLocal.LoadSnapshot
		If modSupabase.Ready = False Then
			Dim errMsg As String = modSupabase.LastError
			lblStatus.Text = "Supabase config missing." & CRLF & errMsg & CRLF & "Set SUPABASE_URL / SUPABASE_ANON_KEY in modConfig."
			Return
		End If
		If modSupabase.IsLoggedIn Then
			lblStatus.Text = "Restoring session..."
			Dim tokenState As String = modSupabase.EnsureFreshToken
			If tokenState = "rejected" Then
				modSupabase.SignOut
				lblStatus.Text = "Session expired. Opening login..."
				B4XPages.ShowPageAndRemovePreviousPages("Login")
			Else If modAuth.RestoreSessionIfLoggedIn Then
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
	Catch
		Log("RefreshDataAndGoDashboard: " & LastException)
	End Try
	B4XPages.ShowPageAndRemovePreviousPages("Dashboard")
	CallSubDelayed(Me, "KickSync")
End Sub

Public Sub KickSync
	If syncRunning Then
		syncAgain = True
		Return
	End If
	CallSubDelayed(Me, "RunSync")
End Sub

Public Sub KickSyncAndPull
	wantPull = True
	KickSync
End Sub

Private Sub RunSync
	syncRunning = True
	Do While True
		Dim tokenState As String = modSupabase.EnsureFreshToken
		If tokenState = "rejected" Then
			OpenLoginForRejectedSession
			Exit
		End If
		If tokenState = "offline" Then Exit
		Dim evJob As Map = modLocal.NextEventSend
		If evJob.ContainsKey("id") Then
			Wait For (SendEventJob(evJob)) Complete (ok As Boolean)
			If ok = False Then Exit
			Continue
		End If
		Dim matchJob As Map = modLocal.NextMatchSend
		If matchJob.ContainsKey("id") Then
			Wait For (SendMatchJob(matchJob)) Complete (okMatch As Boolean)
			If okMatch = False Then Exit
			Continue
		End If
		If wantPull Then
			wantPull = False
			Wait For (PullServer) Complete (pulled As Boolean)
		End If
		Exit
	Loop
	syncRunning = False
	RefreshLiveFeed
	If syncAgain Then
		syncAgain = False
		CallSubDelayed(Me, "KickSync")
	End If
End Sub

Private Sub SendEventJob(job As Map) As ResumableSub
	Dim eventId As String = job.Get("id")
	Dim op As String = job.GetDefault("op", "upsert")
	Dim rev As Int = modLocal.AsInt(job.GetDefault("rev", 1))
	If op <> "delete" Then
		Dim ev As Map = modAppState.FindEvent(eventId)
		If ev.IsInitialized = False Or ev.ContainsKey("id") = False Then
			modLocal.NoteEventSend(eventId, rev, op, True)
			Return True
		End If
	End If
	Wait For (WriteEvent(eventId, op)) Complete (res As Map)
	Dim ok As Boolean = res.GetDefault("ok", False)
	If ok Then modLocal.NoteEventSend(eventId, rev, op, True)
	Return ok
End Sub

Private Sub WriteEvent(eventId As String, op As String) As ResumableSub
	If op = "delete" Then
		Dim q As String = modDb.TBL_EVENTS & "?id=eq." & modSupabase.UrlEncode(eventId)
		Wait For (http.RestDelete(q)) Complete (delRes As Map)
		Return delRes
	End If
	Dim ev As Map = modAppState.FindEvent(eventId)
	Wait For (http.RestPost(modDb.TBL_EVENTS & "?on_conflict=id", modDb.BuildEventPayload(ev), "resolution=merge-duplicates,return=minimal")) Complete (postRes As Map)
	Return postRes
End Sub

Private Sub SendMatchJob(job As Map) As ResumableSub
	Dim matchId As String = job.Get("id")
	Dim rev As Int = modLocal.AsInt(job.GetDefault("rev", 1))
	Dim match As Map = modAppState.FindMatch(matchId)
	If match.IsInitialized = False Or match.ContainsKey("id") = False Then
		modLocal.NoteMatchSend(matchId, rev, True)
		Return True
	End If
	modLocal.ApplyLiveScore(match)
	Wait For (http.RestPost(modDb.TBL_MATCHES & "?on_conflict=id", modDb.BuildMatchPayload(match), "resolution=merge-duplicates,return=minimal")) Complete (res As Map)
	Dim ok As Boolean = res.GetDefault("ok", False)
	If ok Then modLocal.NoteMatchSend(matchId, rev, True)
	Return ok
End Sub

Private Sub PullServer As ResumableSub
	Wait For (http.RestGet(modDb.TBL_MATCHES & "?select=*&order=date.asc")) Complete (mres As Map)
	If mres.GetDefault("ok", False) Then
		Dim data As Object = mres.Get("data")
		If data Is List Then
			Dim rows As List = data
			Dim mapped As List
			mapped.Initialize
			Dim i As Int
			For i = 0 To rows.Size - 1
				mapped.Add(modDb.MapMatch(rows.Get(i)))
			Next
			modAppState.Matches = modLocal.PreferDirtyMatches(mapped)
		End If
	End If
	Wait For (http.RestGet(modDb.TBL_EVENTS & "?select=*&order=timestamp.desc&limit=100")) Complete (eres As Map)
	If eres.GetDefault("ok", False) Then
		Dim data2 As Object = eres.Get("data")
		If data2 Is List Then
			Dim rows2 As List = data2
			Dim mapped2 As List
			mapped2.Initialize
			Dim j As Int
			For j = 0 To rows2.Size - 1
				mapped2.Add(modDb.MapEvent(rows2.Get(j)))
			Next
			modAppState.FeedEvents = modLocal.PreferDirtyEvents(mapped2)
			modLocal.RecountLoadedScores
		End If
	End If
	modLocal.PersistSnapshot
	Return True
End Sub

Private Sub RefreshLiveFeed
	Try
		CallSubDelayed(B4XPages.GetPage("LiveFeed"), "Refresh")
	Catch
		Log("RefreshLiveFeed: " & LastException)
	End Try
End Sub

Private Sub OpenLoginForRejectedSession
	syncRunning = False
	syncAgain = False
	modSupabase.SignOut
	ToastMessageShow("Please sign in again", True)
	B4XPages.ShowPageAndRemovePreviousPages("Login")
End Sub

Public Sub AfterLogin
	' Return to splash so FetchInitialData progress is visible; StrictMode allows sync REST.
	B4XPages.ShowPageAndRemovePreviousPages("MainPage")
	lblStatus.Text = "Loading clubs & matches..."
	Sleep(50)
	RefreshDataAndGoDashboard
End Sub
