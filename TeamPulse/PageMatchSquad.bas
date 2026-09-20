B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Squad availability — styled player cards.
Sub Class_Globals
	Private Root As B4XView
	Private clv As CustomListView
	Private lblCount As Label
	Private match As Map
	Private club As Map
	Private starIds As List
End Sub

Public Sub Initialize
	starIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	BuildUI
End Sub

Private Sub B4XPage_Appear
	Load
	Refresh
End Sub

Private Sub BuildUI
	Dim chrome As Map = modUI.AddPageChrome(Root, "Squad", "btnBack", "", "", True)
	Dim top As Int = chrome.Get("ContentTop")
	
	lblCount.Initialize("")
	lblCount.TextSize = 12
	lblCount.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(lblCount, 16dip, top, Root.Width - 32dip, 20dip)
	
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Tap to confirm / out · long-press to star"
	hint.TextSize = 11
	hint.TextColor = modConfig.COLOR_DARK_MUTED
	Root.AddView(hint, 16dip, top + 22dip, Root.Width - 32dip, 18dip)
	
	Dim listTop As Int = top + 48dip
	clv = modUI.AddCustomListViewThemed(Root, 0, listTop, Root.Width, Root.Height - listTop, Me, "clv", True)
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", modAppState.SelectedClubId))
	starIds = CopyStrList(match.GetDefault("starPlayerIds", EmptyList))
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub CopyStrList(src As Object) As List
	Dim out As List
	out.Initialize
	If src Is List Then
		Dim lst As List = src
		Dim i As Int
		For i = 0 To lst.Size - 1
			out.Add(lst.Get(i))
		Next
	End If
	Return out
End Sub

Public Sub Refresh
	clv.Clear
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	If availability.IsInitialized = False Then availability.Initialize
	Dim confirmed As Int = 0
	Dim cardW As Int = Root.Width - 24dip
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		Dim id As String = mem.GetDefault("id", "")
		Dim av As String = availability.GetDefault(id, "UNKNOWN")
		If av = "CONFIRMED" Then confirmed = confirmed + 1
		Dim isStar As Boolean = starIds.IndexOf(id) > -1
		Dim card As Panel = modUI.CreatePlayerCard(cardW, mem, av, isStar)
		Dim h As Int = modUI.PlayerCardHeight + 8dip
		card.SetLayout(0, 0, cardW, h)
		clv.Add(card, id)
	Next
	lblCount.Text = confirmed & " confirmed · " & members.Size & " in club"
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub clv_ItemClick (Index As Int, Value As Object)
	If Value = "" Then Return
	Dim id As String = Value
	Dim availability As Map = match.GetDefault("availability", EmptyMap)
	If availability.IsInitialized = False Then availability.Initialize
	Dim cur As String = availability.GetDefault(id, "UNKNOWN")
	If cur = "CONFIRMED" Then
		availability.Put(id, "UNAVAILABLE")
	Else
		availability.Put(id, "CONFIRMED")
	End If
	match.Put("availability", availability)
	PersistSignedUp(availability)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	Refresh
End Sub

Private Sub clv_ItemLongClick (Index As Int, Value As Object)
	If Value = "" Then Return
	Dim id As String = Value
	Dim idx As Int = starIds.IndexOf(id)
	If idx > -1 Then
		starIds.RemoveAt(idx)
	Else
		starIds.Add(id)
	End If
	match.Put("starPlayerIds", starIds)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	Refresh
End Sub

Private Sub PersistSignedUp(availability As Map)
	Dim signed As List
	signed.Initialize
	For Each k As String In availability.Keys
		If availability.Get(k) = "CONFIRMED" Then signed.Add(k)
	Next
	match.Put("signedUpPlayerIds", signed)
End Sub

Private Sub btnBack_Click
	B4XPages.ShowPage("MatchHub")
End Sub
