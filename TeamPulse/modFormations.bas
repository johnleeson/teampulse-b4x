B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Formations from reference/lib/formations.ts (teampulse-app).

Sub Process_Globals
End Sub

Public Sub TeamSizes As List
	Dim l As List
	l.Initialize
	l.Add(5)
	l.Add(7)
	l.Add(9)
	l.Add(11)
	Return l
End Sub

Public Sub FormationNames As List
	Return FormationsForSize(11)
End Sub

Public Sub FormationsForSize(teamSize As Int) As List
	Dim l As List
	l.Initialize
	Select teamSize
		Case 5
			l.Add("1-2-1")
			l.Add("2-1-1")
			l.Add("1-1-2")
		Case 7
			l.Add("2-3-1")
			l.Add("3-2-1")
			l.Add("2-2-2")
			l.Add("3-1-2")
		Case 9
			l.Add("3-4-1")
			l.Add("3-3-2")
			l.Add("2-4-2")
			l.Add("3-2-3")
			l.Add("2-3-3")
		Case Else
			l.Add("4-4-2")
			l.Add("4-3-3")
			l.Add("4-2-3-1")
			l.Add("3-5-2")
			l.Add("3-4-3")
	End Select
	Return l
End Sub

Public Sub DefaultFormationForSize(teamSize As Int) As String
	Select teamSize
		Case 5
			Return "1-2-1"
		Case 7
			Return "2-3-1"
		Case 9
			Return "3-4-1"
		Case Else
			Return "4-4-2"
	End Select
End Sub

Public Sub DefaultFormationForClubType(clubType As String) As String
	If clubType = "SOCIAL" Then Return "1-2-1"
	Return "4-4-2"
End Sub

Public Sub TeamSizeForFormation(formationName As String) As Int
	Dim positions As List = GetPositions(formationName)
	Dim n As Int = positions.Size
	If n = 5 Or n = 7 Or n = 9 Or n = 11 Then Return n
	Return 11
End Sub

Public Sub GetPositions(formationName As String) As List
	Select formationName
		Case "1-2-1"
			Return Positions_1_2_1
		Case "2-1-1"
			Return Positions_2_1_1
		Case "1-1-2"
			Return Positions_1_1_2
		Case "2-3-1"
			Return Positions_2_3_1
		Case "3-2-1"
			Return Positions_3_2_1
		Case "2-2-2"
			Return Positions_2_2_2
		Case "3-1-2"
			Return Positions_3_1_2
		Case "3-4-1"
			Return Positions_3_4_1
		Case "3-3-2"
			Return Positions_3_3_2
		Case "2-4-2"
			Return Positions_2_4_2
		Case "3-2-3"
			Return Positions_3_2_3
		Case "2-3-3"
			Return Positions_2_3_3
		Case "4-3-3"
			Return Positions_4_3_3
		Case "4-2-3-1"
			Return Positions_4_2_3_1
		Case "3-5-2"
			Return Positions_3_5_2
		Case "3-4-3"
			Return Positions_3_4_3
		Case Else
			Return Positions_4_4_2
	End Select
End Sub

Private Sub Pos(id As String, label As String, x As Float, y As Float) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", id)
	m.Put("label", label)
	m.Put("x", x)
	m.Put("y", y)
	Return m
End Sub

Private Sub Positions_1_2_1 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 88))
	l.Add(Pos("CB", "CB", 50, 68))
	l.Add(Pos("RM", "RM", 78, 42))
	l.Add(Pos("LM", "LM", 22, 42))
	l.Add(Pos("ST", "ST", 50, 18))
	Return l
End Sub

Private Sub Positions_2_1_1 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 88))
	l.Add(Pos("CB1", "CB", 68, 68))
	l.Add(Pos("CB2", "CB", 32, 68))
	l.Add(Pos("CM", "CM", 50, 42))
	l.Add(Pos("ST", "ST", 50, 18))
	Return l
End Sub

Private Sub Positions_1_1_2 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 88))
	l.Add(Pos("CB", "CB", 50, 68))
	l.Add(Pos("CM", "CM", 50, 42))
	l.Add(Pos("ST1", "ST", 68, 18))
	l.Add(Pos("ST2", "ST", 32, 18))
	Return l
End Sub

Private Sub Positions_2_3_1 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 68, 72))
	l.Add(Pos("CB2", "CB", 32, 72))
	l.Add(Pos("RM", "RM", 82, 45))
	l.Add(Pos("CM", "CM", 50, 48))
	l.Add(Pos("LM", "LM", 18, 45))
	l.Add(Pos("ST", "ST", 50, 18))
	Return l
End Sub

Private Sub Positions_3_2_1 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 72, 72))
	l.Add(Pos("CB2", "CB", 50, 75))
	l.Add(Pos("CB3", "CB", 28, 72))
	l.Add(Pos("CM1", "CM", 65, 42))
	l.Add(Pos("CM2", "CM", 35, 42))
	l.Add(Pos("ST", "ST", 50, 18))
	Return l
End Sub

Private Sub Positions_2_2_2 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 68, 72))
	l.Add(Pos("CB2", "CB", 32, 72))
	l.Add(Pos("CM1", "CM", 65, 45))
	l.Add(Pos("CM2", "CM", 35, 45))
	l.Add(Pos("ST1", "ST", 65, 18))
	l.Add(Pos("ST2", "ST", 35, 18))
	Return l
End Sub

Private Sub Positions_3_1_2 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 72, 72))
	l.Add(Pos("CB2", "CB", 50, 75))
	l.Add(Pos("CB3", "CB", 28, 72))
	l.Add(Pos("CM", "CM", 50, 45))
	l.Add(Pos("ST1", "ST", 65, 18))
	l.Add(Pos("ST2", "ST", 35, 18))
	Return l
End Sub

Private Sub Positions_3_4_1 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 72, 74))
	l.Add(Pos("CB2", "CB", 50, 78))
	l.Add(Pos("CB3", "CB", 28, 74))
	l.Add(Pos("RM", "RM", 85, 48))
	l.Add(Pos("CM1", "CM", 62, 50))
	l.Add(Pos("CM2", "CM", 38, 50))
	l.Add(Pos("LM", "LM", 15, 48))
	l.Add(Pos("ST", "ST", 50, 18))
	Return l
End Sub

Private Sub Positions_3_3_2 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 72, 74))
	l.Add(Pos("CB2", "CB", 50, 78))
	l.Add(Pos("CB3", "CB", 28, 74))
	l.Add(Pos("CM1", "CM", 72, 48))
	l.Add(Pos("CM2", "CM", 50, 50))
	l.Add(Pos("CM3", "CM", 28, 48))
	l.Add(Pos("ST1", "ST", 62, 18))
	l.Add(Pos("ST2", "ST", 38, 18))
	Return l
End Sub

Private Sub Positions_2_4_2 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 65, 74))
	l.Add(Pos("CB2", "CB", 35, 74))
	l.Add(Pos("RM", "RM", 85, 48))
	l.Add(Pos("CM1", "CM", 62, 50))
	l.Add(Pos("CM2", "CM", 38, 50))
	l.Add(Pos("LM", "LM", 15, 48))
	l.Add(Pos("ST1", "ST", 62, 18))
	l.Add(Pos("ST2", "ST", 38, 18))
	Return l
End Sub

Private Sub Positions_3_2_3 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 72, 74))
	l.Add(Pos("CB2", "CB", 50, 78))
	l.Add(Pos("CB3", "CB", 28, 74))
	l.Add(Pos("CM1", "CM", 62, 50))
	l.Add(Pos("CM2", "CM", 38, 50))
	l.Add(Pos("RW", "RW", 82, 22))
	l.Add(Pos("ST", "ST", 50, 16))
	l.Add(Pos("LW", "LW", 18, 22))
	Return l
End Sub

Private Sub Positions_2_3_3 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 65, 74))
	l.Add(Pos("CB2", "CB", 35, 74))
	l.Add(Pos("RM", "RM", 82, 48))
	l.Add(Pos("CM", "CM", 50, 50))
	l.Add(Pos("LM", "LM", 18, 48))
	l.Add(Pos("RW", "RW", 82, 22))
	l.Add(Pos("ST", "ST", 50, 16))
	l.Add(Pos("LW", "LW", 18, 22))
	Return l
End Sub

Private Sub Positions_4_4_2 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("RB", "RB", 82, 72))
	l.Add(Pos("CB1", "CB", 62, 75))
	l.Add(Pos("CB2", "CB", 38, 75))
	l.Add(Pos("LB", "LB", 18, 72))
	l.Add(Pos("RM", "RM", 82, 48))
	l.Add(Pos("CM1", "CM", 62, 50))
	l.Add(Pos("CM2", "CM", 38, 50))
	l.Add(Pos("LM", "LM", 18, 48))
	l.Add(Pos("ST1", "ST", 62, 22))
	l.Add(Pos("ST2", "ST", 38, 22))
	Return l
End Sub

Private Sub Positions_4_3_3 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("RB", "RB", 82, 72))
	l.Add(Pos("CB1", "CB", 62, 75))
	l.Add(Pos("CB2", "CB", 38, 75))
	l.Add(Pos("LB", "LB", 18, 72))
	l.Add(Pos("CDM", "CDM", 50, 58))
	l.Add(Pos("CM1", "CM", 68, 45))
	l.Add(Pos("CM2", "CM", 32, 45))
	l.Add(Pos("RW", "RW", 82, 22))
	l.Add(Pos("ST", "ST", 50, 18))
	l.Add(Pos("LW", "LW", 18, 22))
	Return l
End Sub

Private Sub Positions_4_2_3_1 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("RB", "RB", 82, 72))
	l.Add(Pos("CB1", "CB", 62, 75))
	l.Add(Pos("CB2", "CB", 38, 75))
	l.Add(Pos("LB", "LB", 18, 72))
	l.Add(Pos("CDM1", "CDM", 62, 55))
	l.Add(Pos("CDM2", "CDM", 38, 55))
	l.Add(Pos("RM", "RM", 82, 35))
	l.Add(Pos("CAM", "CAM", 50, 35))
	l.Add(Pos("LM", "LM", 18, 35))
	l.Add(Pos("ST", "ST", 50, 16))
	Return l
End Sub

Private Sub Positions_3_5_2 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 70, 75))
	l.Add(Pos("CB2", "CB", 50, 78))
	l.Add(Pos("CB3", "CB", 30, 75))
	l.Add(Pos("RWB", "RWB", 88, 50))
	l.Add(Pos("CDM", "CDM", 50, 58))
	l.Add(Pos("CM1", "CM", 66, 45))
	l.Add(Pos("CM2", "CM", 34, 45))
	l.Add(Pos("LWB", "LWB", 12, 50))
	l.Add(Pos("ST1", "ST", 62, 20))
	l.Add(Pos("ST2", "ST", 38, 20))
	Return l
End Sub

Private Sub Positions_3_4_3 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("GK", "GK", 50, 90))
	l.Add(Pos("CB1", "CB", 70, 75))
	l.Add(Pos("CB2", "CB", 50, 78))
	l.Add(Pos("CB3", "CB", 30, 75))
	l.Add(Pos("RM", "RM", 85, 48))
	l.Add(Pos("CM1", "CM", 62, 50))
	l.Add(Pos("CM2", "CM", 38, 50))
	l.Add(Pos("LM", "LM", 15, 48))
	l.Add(Pos("RW", "RW", 78, 22))
	l.Add(Pos("ST", "ST", 50, 18))
	l.Add(Pos("LW", "LW", 22, 22))
	Return l
End Sub
