B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Club / player statistics — separate leaderboards.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private dialog As B4XDialog
	Private btnClub As Button
	Private btnMatch As Button
	Private clv As CustomListView
	Private summaryBar As Panel
	Private clubIds As List
	Private clubNames As List
	Private matchIds As List
	Private matchLabels As List
	Private selectedClubIndex As Int
	Private selectedMatchIndex As Int
End Sub

Public Sub Initialize
	clubIds.Initialize
	clubNames.Initialize
	matchIds.Initialize
	matchLabels.Initialize
	selectedClubIndex = 0
	selectedMatchIndex = 0
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildUI
End Sub

Private Sub B4XPage_Appear
	LoadClubs
	Refresh
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Statistics", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	Dim w As Int = Root.Width - 32dip
	
	btnClub.Initialize("btnClub")
	StylePicker(btnClub)
	Root.AddView(btnClub, 16dip, top, w, 44dip)
	
	btnMatch.Initialize("btnMatch")
	StylePicker(btnMatch)
	Root.AddView(btnMatch, 16dip, top + 52dip, w, 44dip)
	
	summaryBar.Initialize("")
	summaryBar.Color = Colors.Transparent
	Root.AddView(summaryBar, 12dip, top + 108dip, Root.Width - 24dip, 64dip)
	
	Dim listTop As Int = top + 184dip
	clv = modUI.AddCustomListViewThemed(Root, 0, listTop, Root.Width, Root.Height - listTop, Me, "clv", True)
End Sub

Private Sub StylePicker(b As Button)
	b.Color = modConfig.COLOR_DARK_CARD
	b.TextColor = modConfig.COLOR_DARK_TEXT
	b.TextSize = 14
	b.Typeface = Typeface.DEFAULT_BOLD
	b.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
	b.Padding = Array As Int(14dip, 0, 14dip, 0)
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
	LoadMatches
	RefreshPickerLabels
End Sub

Private Sub LoadMatches
	matchIds.Initialize
	matchLabels.Initialize
	matchIds.Add("all")
	matchLabels.Add("All completed")
	If clubIds.Size = 0 Then Return
	Dim cid As String = clubIds.Get(Max(0, selectedClubIndex))
	Dim matches As List = modAppState.Matches
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		If m.GetDefault("clubId", "") = cid And m.GetDefault("status", "") = "COMPLETED" Then
			matchIds.Add(m.Get("id"))
			matchLabels.Add(m.GetDefault("title", "Match") & " (" & NormalizeDateShort(m.GetDefault("date", "")) & ")")
		End If
	Next
	If selectedMatchIndex >= matchIds.Size Then selectedMatchIndex = 0
End Sub

Private Sub RefreshPickerLabels
	If clubNames.Size = 0 Then
		btnClub.Text = "No clubs"
	Else
		btnClub.Text = clubNames.Get(Max(0, selectedClubIndex))
	End If
	If matchLabels.Size = 0 Then
		btnMatch.Text = "No matches"
	Else
		btnMatch.Text = matchLabels.Get(Max(0, selectedMatchIndex))
	End If
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
	modUI.ApplyDarkListBackground(clv, modConfig.COLOR_DARK_BG)
	If clubIds.Size = 0 Then
		Dim empty As Panel = modUI.CreateSimpleRowThemed(Root.Width - 24dip, "Join a club to see statistics.", "", True)
		empty.SetLayout(0, 0, Root.Width - 24dip, modUI.SimpleRowHeight)
		clv.Add(empty, "")
		Return
	End If
	Dim cid As String = clubIds.Get(Max(0, selectedClubIndex))
	Dim club As Map = modAppState.FindClub(cid)
	Dim mid As String = "all"
	If matchIds.Size > 0 Then mid = matchIds.Get(Max(0, selectedMatchIndex))
	
	Dim stats As Map = modStats.Compute(club, modAppState.Matches, modAppState.FeedEvents, mid)
	Dim pillW As Int = (Root.Width - 24dip - 24dip) / 5
	Dim gap As Int = 6dip
	Dim x As Int = 0
	AddPill(x, pillW, "P", "" & stats.GetDefault("played", 0), modConfig.COLOR_ACCENT)
	x = x + pillW + gap
	AddPill(x, pillW, "W", "" & stats.GetDefault("wins", 0), modConfig.COLOR_SUCCESS)
	x = x + pillW + gap
	AddPill(x, pillW, "D", "" & stats.GetDefault("draws", 0), modConfig.COLOR_DARK_MUTED)
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
	
	Dim cardW As Int = Root.Width - 24dip
	AddLeaderboard(cardW, "GOALS", players, "goals", 10)
	AddLeaderboard(cardW, "ASSISTS", players, "assists", 10)
	AddLeaderboard(cardW, "POTM AWARDS", players, "potmWins", 10)
	AddLeaderboard(cardW, "MINUTES PLAYED", players, "minutesPlayed", 0)
End Sub

Private Sub AddLeaderboard(cardW As Int, title As String, players As List, field As String, maxRows As Int)
	Dim hdr As Panel = modUI.CreateSectionHeaderThemed(cardW, title, True)
	hdr.SetLayout(0, 0, cardW, modUI.SectionHeaderHeight)
	clv.Add(hdr, "")
	
	Dim ranked As List = RankByField(players, field)
	If ranked.Size = 0 Then
		Dim none As Panel = modUI.CreateSimpleRowThemed(cardW, "No data yet", "", True)
		none.SetLayout(0, 0, cardW, modUI.SimpleRowHeight)
		clv.Add(none, "")
		Return
	End If
	Dim last As Int = ranked.Size - 1
	If maxRows > 0 Then last = Min(maxRows - 1, last)
	Dim i As Int
	For i = 0 To last
		Dim p As Map = ranked.Get(i)
		Dim val As Int = p.GetDefault(field, 0)
		If val <= 0 Then Continue
		Dim suffix As String = ""
		If field = "minutesPlayed" Then
			suffix = val & "'"
		Else
			suffix = "" & val
		End If
		Dim row As Panel = modUI.CreateLeaderboardRow(cardW, i + 1, p.GetDefault("name", "?"), suffix, True)
		row.SetLayout(0, 0, cardW, 48dip)
		clv.Add(row, p.GetDefault("id", ""))
	Next
End Sub

Private Sub RankByField(players As List, field As String) As List
	Dim out As List
	out.Initialize
	Dim i As Int
	For i = 0 To players.Size - 1
		out.Add(players.Get(i))
	Next
	Dim a, b As Int
	For a = 0 To out.Size - 2
		For b = a + 1 To out.Size - 1
			Dim pa As Map = out.Get(a)
			Dim pb As Map = out.Get(b)
			If pb.GetDefault(field, 0) > pa.GetDefault(field, 0) Then
				out.Set(a, pb)
				out.Set(b, pa)
			End If
		Next
	Next
	Return out
End Sub

Private Sub AddPill(left As Int, width As Int, label As String, value As String, accent As Int)
	Dim pill As Panel = modUI.CreateStatPillThemed(width, label, value, accent, True)
	summaryBar.AddView(pill, left, 0, width, 60dip)
End Sub

Private Sub btnClub_Click
	If clubNames.Size = 0 Then Return
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = clubNames
	tmpl.SelectedItem = clubNames.Get(Max(0, selectedClubIndex))
	dialog.Title = "Club"
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	selectedClubIndex = clubNames.IndexOf(tmpl.SelectedItem)
	If selectedClubIndex < 0 Then selectedClubIndex = 0
	selectedMatchIndex = 0
	LoadMatches
	RefreshPickerLabels
	Refresh
End Sub

Private Sub btnMatch_Click
	If matchLabels.Size = 0 Then Return
	Dim tmpl As B4XListTemplate
	tmpl.Initialize
	tmpl.Options = matchLabels
	tmpl.SelectedItem = matchLabels.Get(Max(0, selectedMatchIndex))
	dialog.Title = "Match"
	Wait For (dialog.ShowTemplate(tmpl, "OK", "", "Cancel")) Complete (Result As Int)
	If Result <> xui.DialogResponse_Positive Then Return
	selectedMatchIndex = matchLabels.IndexOf(tmpl.SelectedItem)
	If selectedMatchIndex < 0 Then selectedMatchIndex = 0
	RefreshPickerLabels
	Refresh
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Dashboard")
End Sub
