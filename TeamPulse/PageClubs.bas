B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
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
	Dim chrome As Map = modUI.AddPageChrome(Root, "My Clubs", "btnBack", "btnNew", "+", False)
	Dim top As Int = chrome.Get("ContentTop")
	clv = modUI.AddCustomListView(Root, 0, top, Root.Width, Root.Height - top, Me, "clv")
End Sub

Public Sub Refresh
	clv.Clear
	Dim myClubs As List = modAppState.ClubsForCurrentUser
	Dim cardW As Int = Root.Width - 24dip
	If myClubs.Size = 0 Then
		Dim emptyH As Int = modUI.SimpleRowHeight
		Dim empty As Panel = modUI.CreateSimpleRow(cardW, "No clubs yet. Tap New / Join.", "")
		empty.SetLayout(0, 0, cardW, emptyH)
		clv.Add(empty, "")
		Return
	End If
	Dim i As Int
	For i = 0 To myClubs.Size - 1
		Dim c As Map = myClubs.Get(i)
		Dim h As Int = modUI.ClubCardHeight + 8dip
		Dim card As Panel = modUI.CreateClubCard(cardW, c, "")
		card.SetLayout(0, 0, cardW, h)
		clv.Add(card, c.Get("id"))
	Next
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	modAppState.SelectedClubId = Value
	B4XPages.ShowPage("ClubMembers")
End Sub

Private Sub btnNew_Click
	B4XPages.ShowPage("ClubForm")
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("Dashboard")
End Sub
