B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Authentication helpers — email/password via Supabase Auth REST.
' Static modules cannot Wait For events; uses blocking HTTP in modSupabase.

Sub Process_Globals
	Public LastError As String
End Sub

Public Sub SignInEmail(email As String, password As String) As Boolean
	LastError = ""
	Try
		Dim body As Map
		body.Initialize
		body.Put("email", email)
		body.Put("password", password)
		Dim data As Map = modSupabase.AuthPost("token?grant_type=password", body)
		If data.Size = 0 Or data.ContainsKey("access_token") = False Then
			LastError = modSupabase.LastError
			If LastError = "" Then LastError = "Sign in failed"
			Return False
		End If
		If modSupabase.ApplyAuthResponse(data) = False Then
			LastError = modSupabase.LastError
			Return False
		End If
		Return LoadOrCreateProfile(False, "", "SPECTATOR")
	Catch
		LastError = LastException.Message
		Return False
	End Try
End Sub

Public Sub SignUpEmail(email As String, password As String, displayName As String, role As String) As Boolean
	LastError = ""
	Try
		Dim meta As Map
		meta.Initialize
		meta.Put("full_name", displayName)
		meta.Put("primary_role", role)
		Dim body As Map
		body.Initialize
		body.Put("email", email)
		body.Put("password", password)
		body.Put("data", meta)
		Dim data As Map = modSupabase.AuthPost("signup", body)
		If data.Size = 0 Then
			LastError = modSupabase.LastError
			If LastError = "" Then LastError = "Sign up failed"
			Return False
		End If
		' signup may return user without session if email confirm is required
		If data.ContainsKey("access_token") Then
			If modSupabase.ApplyAuthResponse(data) = False Then
				LastError = modSupabase.LastError
				Return False
			End If
		Else
			Dim userObj As Object = data.Get("user")
			If userObj Is Map Then
				Dim u As Map = userObj
				modSupabase.UserId = u.GetDefault("id", "")
				modSupabase.UserEmail = u.GetDefault("email", email)
				modSupabase.DisplayName = displayName
			End If
			If modSupabase.UserId = "" Then
				LastError = "Sign up created no user (check email confirmation settings)"
				Return False
			End If
			' Try password grant immediately when confirm is off
			If SignInEmail(email, password) = False Then
				LastError = "Account created; sign in after confirming email. " & LastError
				Return False
			End If
			Return True
		End If
		Return LoadOrCreateProfile(True, displayName, role)
	Catch
		LastError = LastException.Message
		Return False
	End Try
End Sub

Public Sub RestoreSessionIfLoggedIn As Boolean
	If modSupabase.IsLoggedIn = False Then Return False
	' Avoid blocking splash on network: use saved session locally, refresh profile best-effort.
	Try
		Dim profile As Map = modDb.GetProfile(modSupabase.UserId)
		If profile.IsInitialized And profile.ContainsKey("id") And profile.Get("id") <> "" Then
			modAppState.SetUser(profile)
			Return True
		End If
	Catch
		Log("RestoreSession profile: " & LastException.Message)
	End Try
	Dim u As Map
	u.Initialize
	u.Put("id", modSupabase.UserId)
	Dim name As String = modSupabase.DisplayName
	If name = "" Then name = modSupabase.UserEmail
	If name = "" Then name = "User"
	u.Put("name", name)
	u.Put("avatar", "")
	Dim roles As List
	roles.Initialize
	roles.Add("SPECTATOR")
	u.Put("roles", roles)
	modAppState.SetUser(u)
	Return True
End Sub

Private Sub LoadOrCreateProfile(forceCreate As Boolean, displayName As String, role As String) As Boolean
	Dim uid As String = modSupabase.UserId
	If uid = "" Then
		LastError = "No Supabase user"
		Return False
	End If
	Dim profile As Map = modDb.GetProfile(uid)
	If forceCreate = False And profile.IsInitialized And profile.ContainsKey("id") And profile.Get("id") <> "" Then
		modAppState.SetUser(profile)
		Return True
	End If
	Dim name As String = displayName
	If name = "" Then name = modSupabase.DisplayName
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
