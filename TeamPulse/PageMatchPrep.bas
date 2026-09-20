B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Legacy entry — redirects to MatchHub.
Sub Class_Globals
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
End Sub

Private Sub B4XPage_Appear
	B4XPages.ShowPageAndRemovePreviousPages("MatchHub")
End Sub
