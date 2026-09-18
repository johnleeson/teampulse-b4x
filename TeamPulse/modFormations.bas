B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Formation pitch positions ported from MatchFeed.tsx FORMATIONS.
' Each position: Map with id, label, x (0-100), y (0-100). x=50 center, y=100=own goal.

Sub Process_Globals
End Sub

Public Sub FormationNames As List
	Dim l As List
	l.Initialize
	l.AddAll(Array As String( _
		"4-4-2", "4-3-3", "3-5-2", "4-2-3-1", _
		"7-a-side (2-3-1)", "9-a-side (3-2-3)", "9-a-side (3-3-2)", _
		"9-a-side (4-3-1)", "9-a-side (3-4-1)", "5-a-side (1-2-1)"))
	Return l
End Sub

Public Sub DefaultFormationForClubType(clubType As String) As String
	If clubType = "SOCIAL" Then Return "5-a-side (1-2-1)"
	Return "4-4-2"
End Sub

Public Sub GetPositions(formationName As String) As List
	Select formationName
		Case "4-3-3"
			Return Positions443
		Case "3-5-2"
			Return Positions352
		Case "4-2-3-1"
			Return Positions4231
		Case "7-a-side (2-3-1)"
			Return Positions7
		Case "9-a-side (3-2-3)"
			Return Positions9323
		Case "9-a-side (3-3-2)"
			Return Positions9332
		Case "9-a-side (4-3-1)"
			Return Positions9431
		Case "9-a-side (3-4-1)"
			Return Positions9341
		Case "5-a-side (1-2-1)"
			Return Positions5
		Case Else
			Return Positions442
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

Private Sub Positions442 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lb", "LB", 15, 70))
	l.Add(Pos("lcb", "CB", 38, 72))
	l.Add(Pos("rcb", "CB", 62, 72))
	l.Add(Pos("rb", "RB", 85, 70))
	l.Add(Pos("lm", "LM", 15, 45))
	l.Add(Pos("lcm", "CM", 38, 47))
	l.Add(Pos("rcm", "CM", 62, 47))
	l.Add(Pos("rm", "RM", 85, 45))
	l.Add(Pos("lst", "ST", 35, 20))
	l.Add(Pos("rst", "ST", 65, 20))
	Return l
End Sub

Private Sub Positions443 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lb", "LB", 15, 70))
	l.Add(Pos("lcb", "CB", 38, 72))
	l.Add(Pos("rcb", "CB", 62, 72))
	l.Add(Pos("rb", "RB", 85, 70))
	l.Add(Pos("lcm", "CM", 25, 48))
	l.Add(Pos("cdm", "DM", 50, 54))
	l.Add(Pos("rcm", "CM", 75, 48))
	l.Add(Pos("lw", "LW", 20, 22))
	l.Add(Pos("st", "ST", 50, 18))
	l.Add(Pos("rw", "RW", 80, 22))
	Return l
End Sub

Private Sub Positions352 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lcb", "CB", 25, 72))
	l.Add(Pos("cb", "CB", 50, 74))
	l.Add(Pos("rcb", "CB", 75, 72))
	l.Add(Pos("lwb", "LM", 15, 48))
	l.Add(Pos("rwb", "RM", 85, 48))
	l.Add(Pos("lcm", "CM", 35, 50))
	l.Add(Pos("cdm", "DM", 50, 56))
	l.Add(Pos("rcm", "CM", 65, 50))
	l.Add(Pos("lst", "ST", 35, 20))
	l.Add(Pos("rst", "ST", 65, 20))
	Return l
End Sub

Private Sub Positions4231 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lb", "LB", 15, 70))
	l.Add(Pos("lcb", "CB", 38, 72))
	l.Add(Pos("rcb", "CB", 62, 72))
	l.Add(Pos("rb", "RB", 85, 70))
	l.Add(Pos("ldm", "DM", 35, 54))
	l.Add(Pos("rdm", "DM", 65, 54))
	l.Add(Pos("lam", "LM", 20, 34))
	l.Add(Pos("cam", "AM", 50, 34))
	l.Add(Pos("ram", "RM", 80, 34))
	l.Add(Pos("st", "ST", 50, 16))
	Return l
End Sub

Private Sub Positions7 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lcb", "CB", 30, 70))
	l.Add(Pos("rcb", "CB", 70, 70))
	l.Add(Pos("lm", "LM", 20, 45))
	l.Add(Pos("cm", "CM", 50, 45))
	l.Add(Pos("rm", "RM", 80, 45))
	l.Add(Pos("st", "ST", 50, 20))
	Return l
End Sub

Private Sub Positions9323 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lb", "LB", 20, 72))
	l.Add(Pos("cb", "CB", 50, 74))
	l.Add(Pos("rb", "RB", 80, 72))
	l.Add(Pos("lcm", "CM", 35, 48))
	l.Add(Pos("rcm", "CM", 65, 48))
	l.Add(Pos("lw", "LW", 20, 24))
	l.Add(Pos("st", "ST", 50, 20))
	l.Add(Pos("rw", "RW", 80, 24))
	Return l
End Sub

Private Sub Positions9332 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lb", "LB", 20, 72))
	l.Add(Pos("cb", "CB", 50, 74))
	l.Add(Pos("rb", "RB", 80, 72))
	l.Add(Pos("lm", "LM", 20, 48))
	l.Add(Pos("cm", "CM", 50, 50))
	l.Add(Pos("rm", "RM", 80, 48))
	l.Add(Pos("lst", "ST", 35, 22))
	l.Add(Pos("rst", "ST", 65, 22))
	Return l
End Sub

Private Sub Positions9431 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lb", "LB", 15, 70))
	l.Add(Pos("lcb", "CB", 38, 72))
	l.Add(Pos("rcb", "CB", 62, 72))
	l.Add(Pos("rb", "RB", 85, 70))
	l.Add(Pos("lcm", "CM", 25, 48))
	l.Add(Pos("cdm", "DM", 50, 54))
	l.Add(Pos("rcm", "CM", 75, 48))
	l.Add(Pos("st", "ST", 50, 20))
	Return l
End Sub

Private Sub Positions9341 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("lb", "LB", 20, 72))
	l.Add(Pos("cb", "CB", 50, 74))
	l.Add(Pos("rb", "RB", 80, 72))
	l.Add(Pos("lm", "LM", 15, 48))
	l.Add(Pos("lcm", "CM", 38, 50))
	l.Add(Pos("rcm", "CM", 62, 50))
	l.Add(Pos("rm", "RM", 85, 48))
	l.Add(Pos("st", "ST", 50, 22))
	Return l
End Sub

Private Sub Positions5 As List
	Dim l As List
	l.Initialize
	l.Add(Pos("gk", "GK", 50, 88))
	l.Add(Pos("cb", "CB", 50, 70))
	l.Add(Pos("lm", "LM", 25, 45))
	l.Add(Pos("rm", "RM", 75, 45))
	l.Add(Pos("st", "ST", 50, 20))
	Return l
End Sub

Public Sub FindGkPositionId(formationName As String) As String
	Dim positions As List = GetPositions(formationName)
	For Each p As Map In positions
		If p.GetDefault("label", "") = "GK" Then Return p.Get("id")
	Next
	Return ""
End Sub
