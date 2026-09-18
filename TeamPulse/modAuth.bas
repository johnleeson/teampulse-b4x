B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Authentication helpers — email/password + Google Sign-In → Firebase Auth.

Sub Process_Globals
	Public LastError As String
End Sub

Public Sub SignInEmail(email As String, password As String) As ResumableSub
	LastError = ""
	Try
		Dim auth As JavaObject = modFirebase.GetAuth
		Dim task As Object = auth.RunMethod("signInWithEmailAndPassword", Array(email, password))
		Wait For (AwaitTask(task)) Complete (ok As Boolean)
		If ok = False Then Return False
		Wait For (LoadOrCreateProfile(False, "", "SPECTATOR")) Complete (loaded As Boolean)
		Return loaded
	Catch
		LastError = LastException.Message
		Return False
	End Try
End Sub

Public Sub SignUpEmail(email As String, password As String, displayName As String, role As String) As ResumableSub
	LastError = ""
	Try
		Dim auth As JavaObject = modFirebase.GetAuth
		Dim task As Object = auth.RunMethod("createUserWithEmailAndPassword", Array(email, password))
		Wait For (AwaitTask(task)) Complete (ok As Boolean)
		If ok = False Then Return False
		Try
			Dim user As JavaObject = auth.RunMethod("getCurrentUser", Null)
			Dim profileUpdates As JavaObject
			profileUpdates.InitializeNewInstance("com.google.firebase.auth.UserProfileChangeRequest$Builder", Null)
			profileUpdates = profileUpdates.RunMethodJO("setDisplayName", Array(displayName)).RunMethod("build", Null)
			user.RunMethod("updateProfile", Array(profileUpdates))
		Catch
			Log("updateProfile: " & LastException)
		End Try
		Wait For (LoadOrCreateProfile(True, displayName, role)) Complete (loaded As Boolean)
		Return loaded
	Catch
		LastError = LastException.Message
		Return False
	End Try
End Sub

' Call after GoogleSignIn client returns an idToken.
Public Sub SignInWithGoogleIdToken(idToken As String) As ResumableSub
	LastError = ""
	Try
		Dim cred As JavaObject
		cred.InitializeStatic("com.google.firebase.auth.GoogleAuthProvider")
		Dim credential As Object = cred.RunMethod("getCredential", Array(idToken, Null))
		Dim auth As JavaObject = modFirebase.GetAuth
		Dim task As Object = auth.RunMethod("signInWithCredential", Array(credential))
		Wait For (AwaitTask(task)) Complete (ok As Boolean)
		If ok = False Then Return False
		Dim name As String = modFirebase.CurrentDisplayName
		If name = "" Then name = "User"
		Wait For (LoadOrCreateProfile(False, name, "SPECTATOR")) Complete (loaded As Boolean)
		Return loaded
	Catch
		LastError = LastException.Message
		Return False
	End Try
End Sub

Public Sub RestoreSessionIfLoggedIn As ResumableSub
	Dim uid As String = modFirebase.CurrentUid
	If uid = "" Then Return False
	Wait For (LoadOrCreateProfile(False, modFirebase.CurrentDisplayName, "SPECTATOR")) Complete (loaded As Boolean)
	Return loaded
End Sub

Private Sub LoadOrCreateProfile(forceCreate As Boolean, displayName As String, role As String) As ResumableSub
	Dim uid As String = modFirebase.CurrentUid
	If uid = "" Then
		LastError = "No Firebase user"
		Return False
	End If
	Dim profile As Map = modDb.GetProfile(uid)
	If profile.IsInitialized And profile.ContainsKey("id") And profile.Get("id") <> "" And forceCreate = False Then
		modAppState.SetUser(profile)
		Return True
	End If
	Dim name As String = displayName
	If name = "" Then name = modFirebase.CurrentDisplayName
	If name = "" Then name = "User"
	Dim roles As List
	roles.Initialize
	roles.Add(role)
	Dim u As Map
	u.Initialize
	u.Put("id", uid)
	u.Put("name", name)
	u.Put("avatar", $"https://i.pravatar.cc/150?u=${uid}"$)
	u.Put("roles", roles)
	modDb.SaveProfile(u)
	modAppState.SetUser(u)
	Return True
End Sub

Private Sub AwaitTask(taskObj As Object) As ResumableSub
	Try
		Dim tasks As JavaObject
		tasks.InitializeStatic("com.google.android.gms.tasks.Tasks")
		tasks.RunMethod("await", Array(taskObj))
		Return True
	Catch
		LastError = LastException.Message
		Return False
	End Try
End Sub
