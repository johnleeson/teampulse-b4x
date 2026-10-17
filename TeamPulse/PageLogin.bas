B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
#if B4A
	Private edtEmail As EditText
#else if B4i
	Private edtEmail As TextField
#End If
#if B4A
	Private edtPassword As EditText
#else if B4i
	Private edtPassword As TextField
#End If
#if B4A
	Private edtName As EditText
#else if B4i
	Private edtName As TextField
#End If
	Private lblError As Label
	Private btnLogin As Button
	Private btnSignUp As Button
	Private btnGoogle As Button
	Private chkSignUp As Boolean
#if B4A
	Private spnRole As Spinner
#else if B4i
	Private btnRole As Button
	Private roleNames As List
	Private roleIndex As Int
#End If
	Private http As clsHttp
	Private busy As Boolean
	Private lblTitle As Label
	Private lblSubtitle As Label
	Private uiReady As Boolean
	Private pageW As Int
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
	CallSubDelayed(Me, "FitRoot")
End Sub

Private Sub B4XPage_Appear
#if B4i
	Main.NavControl.NavigationBarVisible = False
#End If
	FitRoot
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	pageW = Width
	FitRoot
End Sub

Private Sub ScreenWidth As Int
	Return modUI.ViewWidth(Root)
End Sub

Private Sub FitRoot
	Dim w As Int = ScreenWidth
	Log("login FitRoot w=" & w & " root=" & Root.Width & " page=" & pageW)
	Layout(w)
End Sub

Private Sub BuildUI
	lblTitle.Initialize("")
	lblTitle.Text = "TeamPulse"
	modUI.SetTextSize(lblTitle, 28)
	lblTitle.TextColor = Colors.White
	modUI.SetBold(lblTitle, True)
	modUI.SetAlign(lblTitle, "CENTER", "CENTER")
	Root.AddView(lblTitle, 0, 0, 10dip, 10dip)
	
	lblSubtitle.Initialize("")
	lblSubtitle.Text = "Grassroots sports, professionalized."
	modUI.SetTextSize(lblSubtitle, 14)
	lblSubtitle.TextColor = 0xFF94A3B8
	modUI.SetAlign(lblSubtitle, "CENTER", "CENTER")
	Root.AddView(lblSubtitle, 0, 0, 10dip, 10dip)
	
	edtName.Initialize("edtName")
	StyleField(edtName, "Display name (sign up)")
	edtName.Visible = False
	Root.AddView(edtName, 0, 0, 10dip, 10dip)
	
#if B4A
	spnRole.Initialize("spnRole")
	spnRole.AddAll(Array As String("PLAYER", "ADMIN", "COACH", "SPECTATOR"))
	spnRole.Visible = False
	spnRole.TextSize = 16
	Root.AddView(spnRole, 0, 0, 10dip, 10dip)
#else if B4i
	roleNames.Initialize
	roleNames.AddAll(Array As String("PLAYER", "ADMIN", "COACH", "SPECTATOR"))
	roleIndex = 0
	MakeButton(btnRole, "btnRole")
	btnRole.Text = roleNames.Get(0)
	btnRole.Color = Colors.White
	modUI.SetButtonTextColor(btnRole, Colors.Black)
	modUI.SetTextSize(btnRole, 16)
	btnRole.Visible = False
	Root.AddView(btnRole, 0, 0, 10dip, 10dip)
#End If
	
	edtEmail.Initialize("edtEmail")
	StyleField(edtEmail, "Email")
	modUI.SetKeyboard(edtEmail, "text")
	Root.AddView(edtEmail, 0, 0, 10dip, 10dip)
	
	edtPassword.Initialize("edtPassword")
	StyleField(edtPassword, "Password")
	modUI.SetPassword(edtPassword, True)
	Root.AddView(edtPassword, 0, 0, 10dip, 10dip)
	
	MakeButton(btnLogin, "btnLogin")
	btnLogin.Text = "Sign in"
	btnLogin.Color = modConfig.COLOR_ACCENT
	modUI.SetButtonTextColor(btnLogin, Colors.White)
	Root.AddView(btnLogin, 0, 0, 10dip, 10dip)
	
	MakeButton(btnSignUp, "btnToggle")
	btnSignUp.Text = "Need an account? Sign up"
	btnSignUp.Color = Colors.Transparent
	modUI.SetButtonTextColor(btnSignUp, 0xFF94A3B8)
	Root.AddView(btnSignUp, 0, 0, 10dip, 10dip)
	
	MakeButton(btnGoogle, "btnGoogle")
	btnGoogle.Text = "Continue with Google"
	btnGoogle.Color = 0xFF1E293B
	modUI.SetButtonTextColor(btnGoogle, Colors.White)
	Root.AddView(btnGoogle, 0, 0, 10dip, 10dip)
	
	lblError.Initialize("")
	lblError.TextColor = modConfig.COLOR_DANGER
	modUI.SetAlign(lblError, "CENTER", "CENTER")
	modUI.SetTextSize(lblError, 12)
	Root.AddView(lblError, 0, 0, 10dip, 10dip)
	uiReady = True
	FitRoot
End Sub

Private Sub Layout(pageWidth As Int)
	If uiReady = False Or pageWidth < 80dip Then Return
	pageW = pageWidth
	Dim w As Int = pageWidth - 48dip
	modUI.PlaceView(lblTitle, 24dip, 48dip, w, 48dip)
	modUI.PlaceView(lblSubtitle, 24dip, 96dip, w, 28dip)
	Dim emailTop As Int = 150dip
	Dim passwordTop As Int = 210dip
	Dim loginTop As Int = 280dip
	Dim signUpTop As Int = 340dip
	Dim googleTop As Int = 400dip
	Dim errorTop As Int = 470dip
	If chkSignUp Then
		emailTop = 270dip
		passwordTop = 330dip
		loginTop = 400dip
		signUpTop = 460dip
		googleTop = 510dip
		errorTop = 580dip
	End If
	modUI.PlaceView(edtName, 24dip, 150dip, w, 48dip)
#if B4A
	modUI.PlaceView(spnRole, 24dip, 206dip, w, 48dip)
#else if B4i
	modUI.PlaceView(btnRole, 24dip, 206dip, w, 48dip)
#End If
	modUI.PlaceView(edtEmail, 24dip, emailTop, w, 48dip)
	modUI.PlaceView(edtPassword, 24dip, passwordTop, w, 48dip)
	modUI.PlaceView(btnLogin, 24dip, loginTop, w, 52dip)
	modUI.PlaceView(btnSignUp, 24dip, signUpTop, w, 40dip)
	modUI.PlaceView(btnGoogle, 24dip, googleTop, w, 52dip)
	modUI.PlaceView(lblError, 24dip, errorTop, w, 60dip)
End Sub

Private Sub RolePickerVisible(visible As Boolean)
#if B4A
	spnRole.Visible = visible
#else if B4i
	btnRole.Visible = visible
#End If
End Sub

Private Sub SelectedRole As String
#if B4A
	Return spnRole.SelectedItem
#else if B4i
	Return roleNames.Get(roleIndex)
#End If
End Sub

#if B4i
Private Sub btnRole_Click
	roleIndex = (roleIndex + 1) Mod roleNames.Size
	btnRole.Text = roleNames.Get(roleIndex)
End Sub
#End If

Private Sub MakeButton(b As Button, eventName As String)
#if B4A
	b.Initialize(eventName)
#else if B4i
	b.InitializeCustom(eventName, xui.Color_White, xui.Color_LightGray)
#End If
End Sub

Private Sub StyleField(edt As Object, hint As String)
	modUI.StyleFieldColors(edt, hint, Colors.White, Colors.Black, 0xFF64748B, 16, True)
End Sub

Private Sub btnToggle_Click
	chkSignUp = Not(chkSignUp)
	If chkSignUp Then
		edtName.Visible = True
		RolePickerVisible(True)
		btnLogin.Text = "Create account"
		btnSignUp.Text = "Have an account? Sign in"
	Else
		edtName.Visible = False
		RolePickerVisible(False)
		btnLogin.Text = "Sign in"
		btnSignUp.Text = "Need an account? Sign up"
	End If
	FitRoot
End Sub

Private Sub btnLogin_Click
	Log("login click")
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
	modPlatform.ProgressShow("Signing in…")
	Dim ok As Boolean = False
	If chkSignUp Then
		Dim name As String = edtName.Text.Trim
		If name = "" Then name = email
		Wait For (SignUpAsync(email, password, name, SelectedRole)) Complete (signUpOk As Boolean)
		ok = signUpOk
	Else
		Wait For (SignInAsync(email, password)) Complete (signInOk As Boolean)
		ok = signInOk
	End If
	modPlatform.ProgressHide
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
