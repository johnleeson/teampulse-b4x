B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private clv As CustomListView
	Private lblHello As Label
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFFF8FAFC
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Refresh
End Sub

Private Sub BuildUI
	Dim bar As Panel
	bar.Initialize("")
	bar.Color = modConfig.COLOR_PRIMARY
	Root.AddView(bar, 0, 0, Root.Width, 96dip)
	
	lblHello.Initialize("")
	lblHello.TextColor = Colors.White
	lblHello.TextSize = 18
	lblHello.Typeface = Typeface.DEFAULT_BOLD
	bar.AddView(lblHello, 16dip, 40dip, Root.Width - 32dip, 40dip)
	
	Dim nav As Panel
	nav.Initialize("")
	nav.Color = Colors.White
	Root.AddView(nav, 0, Root.Height - 64dip, Root.Width, 64dip)
	AddNavBtn(nav, 0, "Clubs", "btnClubs")
	AddNavBtn(nav, 1, "Matches", "btnMatches")
	AddNavBtn(nav, 2, "Stats", "btnStats")
	AddNavBtn(nav, 3, "Out", "btnOut")
	
	Dim pnl As Panel
	pnl.Initialize("")
	Root.AddView(pnl, 0, 96dip, Root.Width, Root.Height - 96dip - 64dip)
	clv.Initialize(Me, "clv")
	pnl.AddView(clv.AsView, 0, 0, pnl.Width, pnl.Height)
	
	Dim btnRefresh As Button
	btnRefresh.Initialize("btnRefresh")
	btnRefresh.Text = "Refresh"
	btnRefresh.Color = modConfig.COLOR_ACCENT
	btnRefresh.TextColor = Colors.White
	Root.AddView(btnRefresh, Root.Width - 112dip, 28dip, 96dip, 40dip)
End Sub

Private Sub AddNavBtn(parent As Panel, index As Int, text As String, event As String)
	Dim w As Int = parent.Width / 4
	Dim b As Button
	b.Initialize(event)
	b.Text = text
	b.TextSize = 12
	b.Color = Colors.White
	b.TextColor = modConfig.COLOR_PRIMARY
	parent.AddView(b, index * w, 8dip, w, 48dip)
End Sub

Public Sub Refresh
	Dim name As String = "Coach"
	If modAppState.IsAuthenticated Then name = modAppState.CurrentUser.GetDefault("name", "Coach")
	lblHello.Text = "Hi, " & name
	clv.Clear
	clv.AddTextItem("Live & upcoming matches", "")
	Dim any As Boolean = False
	For Each m As Map In modAppState.Matches
		Dim st As String = m.GetDefault("status", "")
		If st = "LIVE" Or st = "UPCOMING" Then
			any = True
			Dim line As String = m.GetDefault("title", "Match") & " · " & st & CRLF & _
				m.GetDefault("date", "") & " " & m.GetDefault("kickOffTime", "") & " @ " & m.GetDefault("location", "")
			clv.AddTextItem(line, m.Get("id"))
		End If
	Next
	If any = False Then clv.AddTextItem("No upcoming matches. Create one under Matches.", "")
	clv.AddTextItem("Your clubs", "")
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	If myClubs.Size = 0 Then
		clv.AddTextItem("You are not in a club yet. Join or create one.", "")
	Else
		For Each c As Map In myClubs
			clv.AddTextItem(c.GetDefault("name", "Club") & " (" & c.GetDefault("type", "") & ")", "club:" & c.Get("id"))
		Next
	End If
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	Dim v As String = Value
	If v = "" Then Return
	If v.StartsWith("club:") Then
		modAppState.SelectedClubId = v.SubString(5)
		B4XPages.ShowPage("ClubMembers")
	Else
		modAppState.SelectedMatchId = v
		Dim m As Map = modAppState.FindMatch(v)
		If m.GetDefault("status", "") = "LIVE" Then
			B4XPages.ShowPage("LiveFeed")
		Else
			B4XPages.ShowPage("MatchPrep")
		End If
	End If
End Sub

Private Sub btnClubs_Click
	B4XPages.ShowPage("Clubs")
End Sub

Private Sub btnMatches_Click
	B4XPages.ShowPage("Matches")
End Sub

Private Sub btnStats_Click
	B4XPages.ShowPage("Stats")
End Sub

Private Sub btnOut_Click
	modFirebase.SignOut
	B4XPages.ShowPageAndRemovePreviousPages("Login")
End Sub

Private Sub btnRefresh_Click
	ProgressDialogShow("Refreshing…")
	modDb.FetchInitialData
	ProgressDialogHide
	Refresh
End Sub
