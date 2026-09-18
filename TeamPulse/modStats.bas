B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Stats aggregation ported from StatsDashboard.tsx (no AI / Gemini).

Sub Process_Globals
End Sub

' club: Map with id, type, members
' matches: all matches list
' events: all feed events
' selectedMatchId: "all" or specific id
' Returns Map: wins, draws, losses, goalsFor, goalsAgainst, players (List of player stat maps)
Public Sub Compute(club As Map, matches As List, events As List, selectedMatchId As String) As Map
	Dim clubId As String = club.GetDefault("id", "")
	Dim isTeam As Boolean = club.GetDefault("type", "TEAM") = "TEAM"
	
	Dim clubMatches As List
	clubMatches.Initialize
	For Each m As Map In matches
		If m.GetDefault("clubId", "") = clubId And m.GetDefault("status", "") = "COMPLETED" Then
			If selectedMatchId = "all" Or selectedMatchId = "" Or m.GetDefault("id", "") = selectedMatchId Then
				clubMatches.Add(m)
			End If
		End If
	Next
	
	Dim wins, draws, losses, goalsFor, goalsAgainst As Int
	
	Dim playerStats As Map
	playerStats.Initialize
	Dim members As List = club.GetDefault("members", EmptyList)
	For Each mem As Map In members
		Dim pid As String = mem.GetDefault("id", "")
		Dim ps As Map
		ps.Initialize
		ps.Put("id", pid)
		ps.Put("name", mem.GetDefault("name", "Unknown"))
		ps.Put("avatar", mem.GetDefault("avatar", ""))
		ps.Put("goals", 0)
		ps.Put("assists", 0)
		ps.Put("apps", 0)
		ps.Put("wins", 0)
		ps.Put("draws", 0)
		ps.Put("losses", 0)
		ps.Put("minutesPlayed", 0)
		ps.Put("yellowCards", 0)
		ps.Put("redCards", 0)
		ps.Put("ballsOverFence", 0)
		ps.Put("isInjured", 0)
		ps.Put("isLastMinuteDropout", 0)
		ps.Put("potmWins", 0)
		playerStats.Put(pid, ps)
	Next
	
	For Each m As Map In clubMatches
		Dim scoreA As Int = m.GetDefault("scoreA", 0)
		Dim scoreB As Int = m.GetDefault("scoreB", 0)
		Dim clubScore, oppScore As Int
		If isTeam Then
			If m.GetDefault("isHome", True) = True Then
				clubScore = scoreA
				oppScore = scoreB
			Else
				clubScore = scoreB
				oppScore = scoreA
			End If
			goalsFor = goalsFor + clubScore
			goalsAgainst = goalsAgainst + oppScore
			If clubScore > oppScore Then
				wins = wins + 1
			Else If clubScore = oppScore Then
				draws = draws + 1
			Else
				losses = losses + 1
			End If
		Else
			goalsFor = goalsFor + scoreA + scoreB
		End If
		
		' Appearances via availability CONFIRMED
		Dim availability As Map = m.GetDefault("availability", EmptyMap)
		For Each uid As String In availability.Keys
			If availability.Get(uid) = "CONFIRMED" And playerStats.ContainsKey(uid) Then
				Dim p1 As Map = playerStats.Get(uid)
				p1.Put("apps", p1.GetDefault("apps", 0) + 1)
			End If
		Next
		
		' W/D/L for players on teamA (home side convention used by web for TEAM)
		If isTeam Then
			Dim teamA As List = m.GetDefault("teamA", EmptyList)
			Dim teamB As List = m.GetDefault("teamB", EmptyList)
			ApplyResultToTeam(teamA, playerStats, scoreA, scoreB)
			ApplyResultToTeam(teamB, playerStats, scoreB, scoreA)
		End If
		
		Dim mPlayerStats As Map = m.GetDefault("playerStats", EmptyMap)
		For Each pid As String In mPlayerStats.Keys
			If playerStats.ContainsKey(pid) Then
				Dim src As Map = mPlayerStats.Get(pid)
				Dim dst As Map = playerStats.Get(pid)
				dst.Put("goals", dst.GetDefault("goals", 0) + src.GetDefault("goals", 0))
				dst.Put("assists", dst.GetDefault("assists", 0) + src.GetDefault("assists", 0))
				dst.Put("yellowCards", dst.GetDefault("yellowCards", 0) + src.GetDefault("yellowCards", 0))
				dst.Put("redCards", dst.GetDefault("redCards", 0) + src.GetDefault("redCards", 0))
				dst.Put("ballsOverFence", dst.GetDefault("ballsOverFence", 0) + src.GetDefault("ballsOverFence", 0))
				dst.Put("minutesPlayed", dst.GetDefault("minutesPlayed", 0) + src.GetDefault("minutesPlayed", 0))
				If src.GetDefault("isInjured", False) = True Then dst.Put("isInjured", dst.GetDefault("isInjured", 0) + 1)
				If src.GetDefault("isLastMinuteDropout", False) = True Then dst.Put("isLastMinuteDropout", dst.GetDefault("isLastMinuteDropout", 0) + 1)
			End If
		Next
		
		' POTM: most votes wins
		Dim potmVotes As Map = m.GetDefault("potmVotes", EmptyMap)
		If potmVotes.Size > 0 Then
			Dim counts As Map
			counts.Initialize
			For Each voter As String In potmVotes.Keys
				Dim votedId As String = potmVotes.Get(voter)
				counts.Put(votedId, counts.GetDefault(votedId, 0) + 1)
			Next
			Dim winnerId As String = ""
			Dim best As Int = -1
			For Each cand As String In counts.Keys
				Dim c As Int = counts.Get(cand)
				If c > best Then
					best = c
					winnerId = cand
				End If
			Next
			If winnerId <> "" And playerStats.ContainsKey(winnerId) Then
				Dim pw As Map = playerStats.Get(winnerId)
				pw.Put("potmWins", pw.GetDefault("potmWins", 0) + 1)
			End If
		End If
	Next
	
	' Event-based goals/assists/cards for selected matches
	Dim matchIdSet As Map
	matchIdSet.Initialize
	For Each m2 As Map In clubMatches
		matchIdSet.Put(m2.Get("id"), True)
	Next
	For Each e As Map In events
		Dim mid As String = e.GetDefault("matchId", "")
		If matchIdSet.ContainsKey(mid) = False Then Continue
		Dim details As Map = e.GetDefault("details", EmptyMap)
		Dim etype As String = e.GetDefault("type", "")
		If etype = "GOAL" Then
			Dim scorer As String = details.GetDefault("scorer", "")
			Dim assist As String = details.GetDefault("assist", "")
			If scorer <> "" And playerStats.ContainsKey(scorer) Then
				Dim psG As Map = playerStats.Get(scorer)
				psG.Put("goals", psG.GetDefault("goals", 0) + 1)
			End If
			If assist <> "" And playerStats.ContainsKey(assist) Then
				Dim psA As Map = playerStats.Get(assist)
				psA.Put("assists", psA.GetDefault("assists", 0) + 1)
			End If
		Else If etype = "YELLOW_CARD" Then
			Dim yp As String = details.GetDefault("player", "")
			If yp <> "" And playerStats.ContainsKey(yp) Then
				Dim psY As Map = playerStats.Get(yp)
				psY.Put("yellowCards", psY.GetDefault("yellowCards", 0) + 1)
			End If
		Else If etype = "RED_CARD" Then
			Dim rp As String = details.GetDefault("player", "")
			If rp <> "" And playerStats.ContainsKey(rp) Then
				Dim psR As Map = playerStats.Get(rp)
				psR.Put("redCards", psR.GetDefault("redCards", 0) + 1)
			End If
		End If
	Next
	
	Dim players As List
	players.Initialize
	For Each pid2 As String In playerStats.Keys
		players.Add(playerStats.Get(pid2))
	Next
	' Sort by goals desc
	players = SortPlayersByGoals(players)
	
	Dim out As Map
	out.Initialize
	out.Put("wins", wins)
	out.Put("draws", draws)
	out.Put("losses", losses)
	out.Put("goalsFor", goalsFor)
	out.Put("goalsAgainst", goalsAgainst)
	out.Put("played", clubMatches.Size)
	out.Put("players", players)
	Return out
End Sub

Private Sub ApplyResultToTeam(team As List, playerStats As Map, myScore As Int, theirScore As Int)
	For Each pid As Object In team
		Dim id As String = pid
		If playerStats.ContainsKey(id) = False Then Continue
		Dim p As Map = playerStats.Get(id)
		If myScore > theirScore Then
			p.Put("wins", p.GetDefault("wins", 0) + 1)
		Else If myScore < theirScore Then
			p.Put("losses", p.GetDefault("losses", 0) + 1)
		Else
			p.Put("draws", p.GetDefault("draws", 0) + 1)
		End If
	Next
End Sub

Private Sub SortPlayersByGoals(players As List) As List
	Dim arr As List
	arr.Initialize
	For Each o As Object In players
		arr.Add(o)
	Next
	For i = 0 To arr.Size - 2
		For j = i + 1 To arr.Size - 1
			Dim a As Map = arr.Get(i)
			Dim b As Map = arr.Get(j)
			If a.GetDefault("goals", 0) < b.GetDefault("goals", 0) Then
				arr.Set(i, b)
				arr.Set(j, a)
			End If
		Next
	Next
	Return arr
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub
