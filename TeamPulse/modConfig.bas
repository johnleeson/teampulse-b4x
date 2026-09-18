B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' TeamPulse Firebase / app configuration (from AI Studio web export).
' Add an Android app in Firebase Console and replace google-services.json.
Sub Process_Globals
	Public Const APP_NAME As String = "TeamPulse"
	Public Const PACKAGE_NAME As String = "com.teampulse.app"
	
	' Web / shared Firebase project (client config — same as web export)
	Public Const FIREBASE_PROJECT_ID As String = "gen-lang-client-0447702787"
	Public Const FIREBASE_API_KEY As String = "AIzaSyAaOoK89yBNOqsYYyMRUuNYHhiS4gnVmg0"
	Public Const FIREBASE_AUTH_DOMAIN As String = "gen-lang-client-0447702787.firebaseapp.com"
	Public Const FIREBASE_STORAGE_BUCKET As String = "gen-lang-client-0447702787.firebasestorage.app"
	Public Const FIREBASE_MESSAGING_SENDER_ID As String = "238865893799"
	Public Const FIREBASE_WEB_APP_ID As String = "1:238865893799:web:6820a525eb439dff270e82"
	
	' Named Firestore database used by the web app (NOT "(default)")
	Public Const FIRESTORE_DATABASE_ID As String = "ai-studio-5af61b00-360c-4924-838f-431be734b14d"
	
	Public Const COLOR_PRIMARY As Int = 0xFF0F172A
	Public Const COLOR_ACCENT As Int = 0xFF3B82F6
	Public Const COLOR_SUCCESS As Int = 0xFF10B981
	Public Const COLOR_DANGER As Int = 0xFFEF4444
	Public Const COLOR_MUTED As Int = 0xFF64748B
	Public Const COLOR_PITCH As Int = 0xFF166534
End Sub
