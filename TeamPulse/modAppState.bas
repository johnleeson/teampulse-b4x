B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' In-memory app state shared across B4XPages.
Sub Process_Globals
	Public CurrentUser As Map
	Public Clubs As List
	Public Matches As List
	Public FeedEvents As List
	Public SelectedClubId As String
	Public SelectedMatchId As String
	Public IsAuthenticated As Boolean
End Sub

Public Sub Initialize
	CurrentUser.Initialize
	Clubs.Initialize
	Matches.Initialize
	FeedEvents.Initialize
	SelectedClubId = ""
	SelectedMatchId = ""
	IsAuthenticated = False
End Sub

Public Sub SetUser(u As Map)
	CurrentUser = u
	IsAuthenticated = u.IsInitialized And u.ContainsKey("id") And u.Get("id") <> ""
End Sub

Public Sub ClearUser
	CurrentUser.Initialize
	IsAuthenticated = False
End Sub

Public Sub FindClub(clubId As String) As Map
	Dim empty As Map
	empty.Initialize
	For Each c As Map In Clubs
		If c.GetDefault("id", "") = clubId Then Return c
	Next
	Return empty
End Sub

Public Sub FindMatch(matchId As String) As Map
	Dim empty As Map
	empty.Initialize
	For Each m As Map In Matches
		If m.GetDefault("id", "") = matchId Then Return m
	Next
	Return empty
End Sub

Public Sub ClubsForCurrentUser As List
	Dim result As List
	result.Initialize
	If IsAuthenticated = False Then Return result
	Dim uid As String = CurrentUser.GetDefault("id", "")
	For Each c As Map In Clubs
		Dim members As List = c.GetDefault("members", DummyList)
		For Each mem As Map In members
			If mem.GetDefault("id", "") = uid Then
				result.Add(c)
				Exit
			End If
		Next
	Next
	Return result
End Sub

Private Sub DummyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Public Sub EventsForMatch(matchId As String) As List
	Dim result As List
	result.Initialize
	For Each e As Map In FeedEvents
		If e.GetDefault("matchId", "") = matchId Then result.Add(e)
	Next
	Return result
End Sub

Public Sub UpsertClub(club As Map)
	Dim id As String = club.GetDefault("id", "")
	For i = 0 To Clubs.Size - 1
		Dim c As Map = Clubs.Get(i)
		If c.GetDefault("id", "") = id Then
			Clubs.Set(i, club)
			Return
		End If
	Next
	Clubs.Add(club)
End Sub

Public Sub UpsertMatch(match As Map)
	Dim id As String = match.GetDefault("id", "")
	For i = 0 To Matches.Size - 1
		Dim m As Map = Matches.Get(i)
		If m.GetDefault("id", "") = id Then
			Matches.Set(i, match)
			Return
		End If
	Next
	Matches.Add(match)
End Sub

Public Sub UpsertEvent(ev As Map)
	Dim id As String = ev.GetDefault("id", "")
	For i = 0 To FeedEvents.Size - 1
		Dim e As Map = FeedEvents.Get(i)
		If e.GetDefault("id", "") = id Then
			FeedEvents.Set(i, ev)
			Return
		End If
	Next
	FeedEvents.Add(ev)
End Sub

Public Sub RemoveMatch(matchId As String)
	For i = Matches.Size - 1 To 0 Step -1
		Dim m As Map = Matches.Get(i)
		If m.GetDefault("id", "") = matchId Then Matches.RemoveAt(i)
	Next
End Sub

Public Sub NewId As String
	Dim t As Long = DateTime.Now
	Dim r As Int = Rnd(1000, 9999)
	Return t & "_" & r
End Sub
