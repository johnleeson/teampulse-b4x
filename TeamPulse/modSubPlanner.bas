B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Substitution planner ported from MatchFeed.tsx subPlanResult useMemo.
' Inputs are Maps/Lists matching Firestore match + club member shapes.

Sub Process_Globals
End Sub

' Returns Map:
'   error: String (optional)
'   events: List of {minute, subs:[{playerOut,playerIn,outName,inName}], pitchState}
'   playTimes: Map id -> minutes
'   fixedPlayerIds: List
Public Sub BuildPlan(confirmedSquad As List, tacticalLineup As Map, formationName As String, _
		starPlayerIds As List, weakerPlayerIds As List, _
		matchDuration As Int, subInterval As Int, maxSubsPerWindow As Int) As Map
	
	Dim result As Map
	result.Initialize
	
	Dim positions As List = modFormations.GetPositions(formationName)
	Dim pitchPlayerIds As List
	pitchPlayerIds.Initialize
	For Each k As String In tacticalLineup.Keys
		Dim pid As String = tacticalLineup.Get(k)
		If pid <> "" Then pitchPlayerIds.Add(pid)
	Next
	
	If pitchPlayerIds.Size = 0 Then
		result.Put("error", "Please assign players to the pitch first.")
		Return result
	End If
	
	Dim confirmedIds As List
	confirmedIds.Initialize
	Dim nameById As Map
	nameById.Initialize
	For Each p As Map In confirmedSquad
		Dim id As String = p.GetDefault("id", "")
		confirmedIds.Add(id)
		nameById.Put(id, p.GetDefault("name", "Unknown"))
	Next
	
	Dim benchPlayerIds As List
	benchPlayerIds.Initialize
	For Each id As String In confirmedIds
		If pitchPlayerIds.IndexOf(id) = -1 Then benchPlayerIds.Add(id)
	Next
	
	Dim fixed As Map
	fixed.Initialize
	Dim gkPosId As String = modFormations.FindGkPositionId(formationName)
	If gkPosId <> "" Then
		Dim gkId As String = tacticalLineup.GetDefault(gkPosId, "")
		If gkId <> "" Then fixed.Put(gkId, True)
	End If
	For Each id As String In pitchPlayerIds
		If starPlayerIds.IndexOf(id) > -1 Then fixed.Put(id, True)
	Next
	
	Dim rotationPitch As List
	rotationPitch.Initialize
	Dim rotationBench As List
	rotationBench.Initialize
	For Each id As String In pitchPlayerIds
		If fixed.ContainsKey(id) = False Then rotationPitch.Add(id)
	Next
	For Each id As String In benchPlayerIds
		If fixed.ContainsKey(id) = False Then rotationBench.Add(id)
	Next
	
	Dim rotationPoolCount As Int = rotationPitch.Size + rotationBench.Size
	If rotationPoolCount = 0 Then
		result.Put("error", "No outfield players available for rotation (everyone assigned is a Star Player or Goalkeeper).")
		result.Put("fixedPlayerIds", KeysList(fixed))
		Return result
	End If
	
	Dim stepsCount As Int = Floor(matchDuration / subInterval)
	If stepsCount <= 1 Then
		result.Put("error", "Match duration and interval must allow at least 2 sub windows.")
		Return result
	End If
	
	Dim playTimes As Map
	playTimes.Initialize
	For Each id As String In confirmedIds
		playTimes.Put(id, 0)
	Next
	For Each fid As String In KeysList(fixed)
		playTimes.Put(fid, matchDuration)
	Next
	
	Dim currentPitch As List = CopyList(rotationPitch)
	Dim currentBench As List = CopyList(rotationBench)
	Dim planEvents As List
	planEvents.Initialize
	
	For step = 1 To stepsCount
		For Each id As String In currentPitch
			playTimes.Put(id, playTimes.GetDefault(id, 0) + subInterval)
		Next
		If step = stepsCount Then Exit
		
		Dim nextMin As Int = step * subInterval
		If currentBench.Size > 0 And currentPitch.Size > 0 Then
			Dim sortedBench As List = SortByPlayTimeAsc(currentBench, playTimes, weakerPlayerIds)
			Dim sortedPitch As List = SortByPlayTimeDesc(currentPitch, playTimes, starPlayerIds)
			Dim swapCount As Int = Min(Min(sortedBench.Size, sortedPitch.Size), maxSubsPerWindow)
			
			Dim intervalSubs As List
			intervalSubs.Initialize
			Dim nextPitch As List = CopyList(currentPitch)
			Dim nextBench As List = CopyList(currentBench)
			
			For i = 0 To swapCount - 1
				Dim pOut As String = sortedPitch.Get(i)
				Dim pIn As String = sortedBench.Get(i)
				Dim sub As Map
				sub.Initialize
				sub.Put("playerOut", pOut)
				sub.Put("playerIn", pIn)
				sub.Put("outName", nameById.GetDefault(pOut, "Unknown"))
				sub.Put("inName", nameById.GetDefault(pIn, "Unknown"))
				intervalSubs.Add(sub)
				
				Dim outIdx As Int = nextPitch.IndexOf(pOut)
				If outIdx > -1 Then nextPitch.Set(outIdx, pIn)
				Dim inIdx As Int = nextBench.IndexOf(pIn)
				If inIdx > -1 Then nextBench.Set(inIdx, pOut)
			Next
			
			currentPitch = nextPitch
			currentBench = nextBench
			
			Dim evt As Map
			evt.Initialize
			evt.Put("minute", nextMin)
			evt.Put("subs", intervalSubs)
			evt.Put("pitchState", CopyList(currentPitch))
			planEvents.Add(evt)
		End If
	Next
	
	result.Put("events", planEvents)
	result.Put("playTimes", playTimes)
	result.Put("fixedPlayerIds", KeysList(fixed))
	Return result
End Sub

Private Sub KeysList(m As Map) As List
	Dim l As List
	l.Initialize
	For Each k As String In m.Keys
		l.Add(k)
	Next
	Return l
End Sub

Private Sub CopyList(src As List) As List
	Dim l As List
	l.Initialize
	For Each o As Object In src
		l.Add(o)
	Next
	Return l
End Sub

Private Sub SortByPlayTimeAsc(ids As List, playTimes As Map, weakerPlayerIds As List) As List
	Dim arr As List = CopyList(ids)
	For i = 0 To arr.Size - 2
		For j = i + 1 To arr.Size - 1
			Dim a As String = arr.Get(i)
			Dim b As String = arr.Get(j)
			Dim diff As Int = playTimes.GetDefault(a, 0) - playTimes.GetDefault(b, 0)
			Dim swap As Boolean = False
			If diff > 0 Then
				swap = True
			Else If diff = 0 Then
				Dim aW As Boolean = weakerPlayerIds.IndexOf(a) > -1
				Dim bW As Boolean = weakerPlayerIds.IndexOf(b) > -1
				If aW = False And bW = True Then swap = True
				If aW = bW And a.CompareTo(b) > 0 Then swap = True
			End If
			If swap Then
				arr.Set(i, b)
				arr.Set(j, a)
			End If
		Next
	Next
	Return arr
End Sub

Private Sub SortByPlayTimeDesc(ids As List, playTimes As Map, starPlayerIds As List) As List
	Dim arr As List = CopyList(ids)
	For i = 0 To arr.Size - 2
		For j = i + 1 To arr.Size - 1
			Dim a As String = arr.Get(i)
			Dim b As String = arr.Get(j)
			Dim diff As Int = playTimes.GetDefault(b, 0) - playTimes.GetDefault(a, 0)
			Dim swap As Boolean = False
			If playTimes.GetDefault(a, 0) < playTimes.GetDefault(b, 0) Then
				swap = True
			Else If playTimes.GetDefault(a, 0) = playTimes.GetDefault(b, 0) Then
				Dim aS As Boolean = starPlayerIds.IndexOf(a) > -1
				Dim bS As Boolean = starPlayerIds.IndexOf(b) > -1
				' Prefer subbing non-stars first when times equal? Web: star sorts after (return 1 means a after b)
				If aS = True And bS = False Then swap = True
				If aS = bS And a.CompareTo(b) > 0 Then swap = True
			End If
			If swap Then
				arr.Set(i, b)
				arr.Set(j, a)
			End If
		Next
	Next
	Return arr
End Sub
