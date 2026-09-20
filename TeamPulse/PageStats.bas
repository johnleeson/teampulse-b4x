B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Club / player statistics.
Sub Class_Globals
	Private Root As B4XView
	Private spnClub As Spinner
	Private spnMatch As Spinner
	Private clv As CustomListView
	Private summaryBar As Panel
	Private clubIds As List
	Private matchIds As List
End Sub

Public Sub Initialize
	clubIds.Initialize
	matchIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadClubs
	Refresh
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Statistics", "btnBack", "", "", False)
	Dim top As Int = chrome.Get("ContentTop")
	
	spnClub.Initialize("spnClub")
	spnClub.TextSize = 14
	Root.AddView(spnClub, 16dip, top, Root.Width - 32dip, 40dip)
	
	spnMatch.Initialize("spnMatch")
	spnMatch.TextSize = 14
	Root.AddView(spnMatch, 16dip, top + 48dip, Root.Width - 32dip, 40dip)
	
	summaryBar.Initialize("")
	summaryBar.Color = Colors.Transparent
	Root.AddView(summaryBar, 12dip, top + 96dip, Root.Width - 24dip, 64dip)
	
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "PLAYER LEADERBOARD"
	hint.TextSize = 11
	hint.Typeface = Typeface.DEFAULT_BOLD
	hint.TextColor = modConfig.COLOR_MUTED
	Root.AddView(hint, 16dip, top + 172dip, Root.Width - 32dip, 20dip)
	
	Dim listTop As Int = top + 196dip
	clv = modUI.AddCustomListView(Root, 0, listTop, Root.Width, Root.Height - listTop, Me, "clv")
End Sub

Private Sub LoadClubs
	spnClub.Clear
	clubIds.Initialize
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	Dim i As Int
	For i = 0 To myClubs.Size - 1
		Dim c As Map = myClubs.Get(i)
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
	Dim matches As List = modAppState.Matches
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		If m.GetDefault("clubId", "") = cid And m.GetDefault("status", "") = "COMPLETED" Then
			spnMatch.Add(m.GetDefault("title", "Match") & " (" & NormalizeDateShort(m.GetDefault("date", "")) & ")")
			matchIds.Add(m.Get("id"))
		End If
	Next
End Sub

Private Sub NormalizeDateShort(dateStr As String) As String
	Dim s As String = dateStr
	Dim ti As Int = s.IndexOf("T")
	If ti > 0 Then s = s.SubString2(0, ti)
	Return s
End Sub

Public Sub Refresh
	clv.Clear
	summaryBar.RemoveAllViews
	If clubIds.Size = 0 Then
		Dim empty As Panel = modUI.CreateSimpleRow(Root.Width - 24dip, "Join a club to see statistics.", "")
		empty.SetLayout(0, 0, Root.Width - 24dip, modUI.SimpleRowHeight)
		clv.Add(empty, "")
		Return
	End If
	Dim cid As String = clubIds.Get(Max(0, spnClub.SelectedIndex))
	Dim club As Map = modAppState.FindClub(cid)
	Dim mid As String = "all"
	If matchIds.Size > 0 Then mid = matchIds.Get(Max(0, spnMatch.SelectedIndex))
	
	Dim stats As Map = modStats.Compute(club, modAppState.Matches, modAppState.FeedEvents, mid)
	Dim pillW As Int = (Root.Width - 24dip - 24dip) / 5
	Dim gap As Int = 6dip
	Dim x As Int = 0
	AddPill(x, pillW, "P", "" & stats.GetDefault("played", 0), modConfig.COLOR_PRIMARY)
	x = x + pillW + gap
	AddPill(x, pillW, "W", "" & stats.GetDefault("wins", 0), modConfig.COLOR_SUCCESS)
	x = x + pillW + gap
	AddPill(x, pillW, "D", "" & stats.GetDefault("draws", 0), modConfig.COLOR_MUTED)
	x = x + pillW + gap
	AddPill(x, pillW, "L", "" & stats.GetDefault("losses", 0), modConfig.COLOR_DANGER)
	x = x + pillW + gap
	AddPill(x, pillW, "GF", "" & stats.GetDefault("goalsFor", 0), modConfig.COLOR_ACCENT)
	
	Dim playersObj As Object = stats.Get("players")
	Dim players As List
	If playersObj <> Null And playersObj Is List Then
		players = playersObj
	Else
		players.Initialize
	End If
	Dim maxGoals As Int = 1
	Dim i As Int
	For i = 0 To players.Size - 1
		Dim p0 As Map = players.Get(i)
		maxGoals = Max(maxGoals, p0.GetDefault("goals", 0))
	Next
	Dim cardW As Int = Root.Width - 24dip
	For i = 0 To players.Size - 1
		Dim p As Map = players.Get(i)
		Dim row As Panel = modUI.CreatePlayerStatRow(cardW, p, maxGoals)
		Dim h As Int = modUI.PlayerStatRowHeight + 8dip
		row.SetLayout(0, 0, cardW, h)
		clv.Add(row, p.GetDefault("id", ""))
	Next
	If players.Size = 0 Then
		Dim none As Panel = modUI.CreateSimpleRow(cardW, "No player stats yet.", "")
		none.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(none, "")
	End If
End Sub

Private Sub AddPill(left As Int, width As Int, label As String, value As String, accent As Int)
	Dim pill As Panel = modUI.CreateStatPill(width, label, value, accent)
	summaryBar.AddView(pill, left, 0, width, 60dip)
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
