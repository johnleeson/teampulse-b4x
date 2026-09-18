B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=12.80
@EndOfDesignText@
#Region Project Attributes
	#ApplicationLabel: TeamPulse
	#VersionCode: 1
	#VersionName: 1.0.0
	#SupportedOrientations: portrait
	#CanInstallToExternalStorage: False
#End Region

#Region Activity Attributes
	#FullScreen: False
	#IncludeTitle: False
#End Region

'Required libraries (B4A): Core, XUI, B4XPages, XUI Views, JavaObject,
'FirebaseAuth, GooglePlayServices / Firebase BoM via google-services.json,
'OkHttpUtils2 (optional), CustomListView (or xCustomListView).

Sub Process_Globals
	Public ActionBarHomeClicked As Boolean
End Sub

Sub Globals
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Dim pm As B4XPagesManager
	pm.Initialize(Activity)
End Sub

Sub Activity_Resume
End Sub

Sub Activity_Pause (UserClosed As Boolean)
End Sub

Sub Activity_KeyPress (KeyCode As Int) As Boolean
	Return B4XPages.Delegate.Activity_KeyPress(KeyCode)
End Sub

Sub Activity_PermissionResult (Permission As String, Result As Boolean)
	B4XPages.Delegate.Activity_PermissionResult(Permission, Result)
End Sub
