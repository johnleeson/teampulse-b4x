B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
	Private contentTop As Int
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Refresh
End Sub

Private Sub BuildUI
	' ← Matches ......................... 📅
	Dim chrome As Map = modUI.AddPageChrome(Root, "Matches", "btnBack", "btnNew", "📅", True)
	contentTop = chrome.Get("ContentTop")
	clv = modUI.AddCustomListViewThemed(Root, 0, contentTop, Root.Width, Root.Height - contentTop, Me, "clv", True)
End Sub

Public Sub Refresh
	clv.Clear
	Dim matches As List = modAppState.Matches
	Dim cardW As Int = Root.Width - 24dip
	If matches.Size = 0 Then
		Dim emptyH As Int = 64dip
		Dim empty As Panel
		empty.Initialize("")
		empty.Color = modConfig.COLOR_DARK_BG
		Dim lbl As Label
		lbl.Initialize("")
		lbl.Text = "No matches yet. Tap 📅 to schedule."
		lbl.TextSize = 14
		lbl.TextColor = modConfig.COLOR_DARK_MUTED
		lbl.Gravity = Gravity.CENTER
		empty.AddView(lbl, 16dip, 0, cardW - 8dip, emptyH)
		empty.SetLayout(0, 0, cardW, emptyH)
		clv.Add(empty, "")
		modUI.ApplyDarkListBackground(clv, modConfig.COLOR_DARK_BG)
		Return
	End If
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		Dim cardH As Int = modUI.MatchCardHeight + 8dip
		Dim wrap As Panel
		wrap.Initialize("")
		wrap.Color = modConfig.COLOR_DARK_BG
		Dim card As Panel = modUI.CreateMatchCardThemed(cardW, m, "", True)
		wrap.AddView(card, 12dip, 4dip, cardW, modUI.MatchCardHeight)
		wrap.SetLayout(0, 0, Root.Width, cardH)
		clv.Add(wrap, m.Get("id"))
	Next
	modUI.ApplyDarkListBackground(clv, modConfig.COLOR_DARK_BG)
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	modAppState.SelectedMatchId = Value
	Dim m As Map = modAppState.FindMatch(Value)
	modAppState.SelectedClubId = m.GetDefault("clubId", "")
	If m.GetDefault("status", "") = "LIVE" Then
		B4XPages.ShowPage("LiveFeed")
	Else
		B4XPages.ShowPage("MatchHub")
	End If
End Sub

Private Sub btnNew_Click
	B4XPages.ShowPage("ScheduleMatch")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Dashboard")
End Sub
