B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private edtEmail As EditText
	Private edtPassword As EditText
	Private edtName As EditText
	Private lblError As Label
	Private btnLogin As Button
	Private btnSignUp As Button
	Private btnGoogle As Button
	Private chkSignUp As Boolean
	Private spnRole As Spinner
	Private http As clsHttp
	Private busy As Boolean
End Sub

Public Sub Initialize
	chkSignUp = False
	busy = False
	http.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.Color = 0xFF020617
	BuildUI
End Sub

Private Sub BuildUI
	Dim title As Label
	title.Initialize("")
	title.Text = "TeamPulse"
	title.TextSize = 28
	title.TextColor = Colors.White
	title.Typeface = Typeface.DEFAULT_BOLD
	title.Gravity = Gravity.CENTER
	Root.AddView(title, 24dip, 48dip, Root.Width - 48dip, 48dip)
	
	Dim subtitle As Label
	subtitle.Initialize("")
	subtitle.Text = "Grassroots sports, professionalized."
	subtitle.TextSize = 14
	subtitle.TextColor = 0xFF94A3B8
	subtitle.Gravity = Gravity.CENTER
	Root.AddView(subtitle, 24dip, 96dip, Root.Width - 48dip, 28dip)
	
	edtName.Initialize("edtName")
	StyleField(edtName, "Display name (sign up)")
	edtName.Visible = False
	Root.AddView(edtName, 24dip, 150dip, Root.Width - 48dip, 48dip)
	
	spnRole.Initialize("spnRole")
	spnRole.AddAll(Array As String("PLAYER", "ADMIN", "COACH", "SPECTATOR"))
	spnRole.Visible = False
	spnRole.TextSize = 16
	Root.AddView(spnRole, 24dip, 206dip, Root.Width - 48dip, 48dip)
	
	edtEmail.Initialize("edtEmail")
	StyleField(edtEmail, "Email")
	edtEmail.InputType = edtEmail.INPUT_TYPE_TEXT
	Root.AddView(edtEmail, 24dip, 150dip, Root.Width - 48dip, 48dip)
	
	edtPassword.Initialize("edtPassword")
	StyleField(edtPassword, "Password")
	edtPassword.PasswordMode = True
	Root.AddView(edtPassword, 24dip, 210dip, Root.Width - 48dip, 48dip)
	
	btnLogin.Initialize("btnLogin")
	btnLogin.Text = "Sign in"
	btnLogin.Color = modConfig.COLOR_ACCENT
	btnLogin.TextColor = Colors.White
	Root.AddView(btnLogin, 24dip, 280dip, Root.Width - 48dip, 52dip)
	
	btnSignUp.Initialize("btnToggle")
	btnSignUp.Text = "Need an account? Sign up"
	btnSignUp.Color = Colors.Transparent
	btnSignUp.TextColor = 0xFF94A3B8
	Root.AddView(btnSignUp, 24dip, 340dip, Root.Width - 48dip, 40dip)
	
	btnGoogle.Initialize("btnGoogle")
	btnGoogle.Text = "Continue with Google"
	btnGoogle.Color = 0xFF1E293B
	btnGoogle.TextColor = Colors.White
	Root.AddView(btnGoogle, 24dip, 400dip, Root.Width - 48dip, 52dip)
	
	lblError.Initialize("")
	lblError.TextColor = modConfig.COLOR_DANGER
	lblError.Gravity = Gravity.CENTER
	lblError.TextSize = 12
	Root.AddView(lblError, 24dip, 470dip, Root.Width - 48dip, 60dip)
End Sub

Private Sub StyleField(edt As EditText, hint As String)
	edt.Hint = hint
	edt.Color = Colors.White
	edt.TextColor = Colors.Black
	edt.HintColor = 0xFF64748B
	edt.TextSize = 16
	edt.Padding = Array As Int(12dip, 8dip, 12dip, 8dip)
	edt.SingleLine = True
End Sub

Private Sub btnToggle_Click
	chkSignUp = Not(chkSignUp)
	If chkSignUp Then
		edtName.Visible = True
		spnRole.Visible = True
		edtEmail.Top = 270dip
		edtPassword.Top = 330dip
		btnLogin.Top = 400dip
		btnLogin.Text = "Create account"
		btnSignUp.Text = "Have an account? Sign in"
		btnSignUp.Top = 460dip
		btnGoogle.Top = 510dip
		lblError.Top = 580dip
	Else
		edtName.Visible = False
		spnRole.Visible = False
		edtEmail.Top = 150dip
		edtPassword.Top = 210dip
		btnLogin.Top = 280dip
		btnLogin.Text = "Sign in"
		btnSignUp.Text = "Need an account? Sign up"
		btnSignUp.Top = 340dip
		btnGoogle.Top = 400dip
		lblError.Top = 470dip
	End If
End Sub

Private Sub btnLogin_Click
	If busy Then Return
	lblError.Text = ""
	Dim email As String = edtEmail.Text.Trim
	Dim password As String = edtPassword.Text
	If email = "" Or password = "" Then
		lblError.Text = "Email and password required."
		Return
	End If
	busy = True
	btnLogin.Enabled = False
	ProgressDialogShow("Signing in…")
	Dim ok As Boolean = False
	If chkSignUp Then
		Dim name As String = edtName.Text.Trim
		If name = "" Then name = email
		Wait For (SignUpAsync(email, password, name, spnRole.SelectedItem)) Complete (signUpOk As Boolean)
		ok = signUpOk
	Else
		Wait For (SignInAsync(email, password)) Complete (signInOk As Boolean)
		ok = signInOk
	End If
	ProgressDialogHide
	busy = False
	btnLogin.Enabled = True
	If ok Then
		B4XPages.MainPage.AfterLogin
	Else
		If lblError.Text = "" Then lblError.Text = http.LastError
		If lblError.Text = "" Then lblError.Text = modSupabase.LastError
		If lblError.Text = "" Then lblError.Text = "Sign in failed"
	End If
End Sub

Private Sub SignInAsync(email As String, password As String) As ResumableSub
	Dim body As Map
	body.Initialize
	body.Put("email", email)
	body.Put("password", password)
	Wait For (http.AuthPost("token?grant_type=password", body)) Complete (res As Map)
	If res.GetDefault("ok", False) = False Then
		lblError.Text = res.GetDefault("error", "Sign in failed")
		Return False
	End If
	Dim dataObj As Object = res.Get("data")
	If (dataObj Is Map) = False Then
		lblError.Text = "Sign in failed"
		Return False
	End If
	Dim data As Map = dataObj
	If data.ContainsKey("access_token") = False Then
		lblError.Text = "Sign in failed"
		Return False
	End If
	If modSupabase.ApplyAuthResponse(data) = False Then
		lblError.Text = modSupabase.LastError
		Return False
	End If
	Wait For (LoadOrCreateProfileAsync(False, "", "SPECTATOR")) Complete (ok As Boolean)
	Return ok
End Sub

Private Sub SignUpAsync(email As String, password As String, displayName As String, role As String) As ResumableSub
	Dim meta As Map
	meta.Initialize
	meta.Put("full_name", displayName)
	meta.Put("primary_role", role)
	Dim body As Map
	body.Initialize
	body.Put("email", email)
	body.Put("password", password)
	body.Put("data", meta)
	Wait For (http.AuthPost("signup", body)) Complete (res As Map)
	If res.GetDefault("ok", False) = False Then
		lblError.Text = res.GetDefault("error", "Sign up failed")
		Return False
	End If
	Dim dataObj As Object = res.Get("data")
	If (dataObj Is Map) = False Then
		lblError.Text = "Sign up failed"
		Return False
	End If
	Dim data As Map = dataObj
	If data.ContainsKey("access_token") Then
		If modSupabase.ApplyAuthResponse(data) = False Then
			lblError.Text = modSupabase.LastError
			Return False
		End If
		Wait For (LoadOrCreateProfileAsync(True, displayName, role)) Complete (ok As Boolean)
		Return ok
	End If
	' No session (email confirm) — try password grant
	Dim userObj As Object = data.Get("user")
	If userObj Is Map Then
		Dim u As Map = userObj
		modSupabase.UserId = u.GetDefault("id", "")
		modSupabase.UserEmail = u.GetDefault("email", email)
		modSupabase.DisplayName = displayName
	End If
	Wait For (SignInAsync(email, password)) Complete (ok2 As Boolean)
	If ok2 = False Then
		lblError.Text = "Account created; sign in after confirming email. " & lblError.Text
		Return False
	End If
	Return True
End Sub

Private Sub LoadOrCreateProfileAsync(forceCreate As Boolean, displayName As String, role As String) As ResumableSub
	Dim uid As String = modSupabase.UserId
	If uid = "" Then
		lblError.Text = "No Supabase user"
		Return False
	End If
	Wait For (http.RestGet("profiles?id=eq." & modSupabase.UrlEncode(uid) & "&select=*")) Complete (res As Map)
	Dim profile As Map
	profile.Initialize
	If res.GetDefault("ok", False) Then
		Dim dataObj As Object = res.Get("data")
		If dataObj Is List Then
			Dim lst As List = dataObj
			If lst.Size > 0 Then
				Dim row As Map = lst.Get(0)
				profile = modDb.MapProfile(row)
			End If
		End If
	End If
	If forceCreate = False And profile.ContainsKey("id") And profile.Get("id") <> "" Then
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
	' Save profile async
	Dim payload As Map
	payload.Initialize
	payload.Put("id", uid)
	payload.Put("name", name)
	payload.Put("avatar", u.Get("avatar"))
	payload.Put("roles", roles)
	Wait For (http.RestPost("profiles?on_conflict=id", payload, "resolution=merge-duplicates,return=minimal")) Complete (saveRes As Map)
	If saveRes.GetDefault("ok", False) = False Then
		' Non-fatal if profile row already exists
		Log("SaveProfile: " & saveRes.GetDefault("error", ""))
	End If
	modAppState.SetUser(u)
	Return True
End Sub

Private Sub btnGoogle_Click
	lblError.Text = "Google Sign-In via Supabase is not wired yet. Use email/password for now."
End Sub
