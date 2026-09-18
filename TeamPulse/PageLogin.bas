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
End Sub

Public Sub Initialize
	chkSignUp = False
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
	edtName.Hint = "Display name (sign up)"
	edtName.Visible = False
	Root.AddView(edtName, 24dip, 150dip, Root.Width - 48dip, 48dip)
	
	spnRole.Initialize("spnRole")
	spnRole.AddAll(Array As String("PLAYER", "ADMIN", "SPECTATOR"))
	spnRole.Visible = False
	Root.AddView(spnRole, 24dip, 206dip, Root.Width - 48dip, 48dip)
	
	edtEmail.Initialize("edtEmail")
	edtEmail.Hint = "Email"
	edtEmail.InputType = edtEmail.INPUT_TYPE_TEXT
	Root.AddView(edtEmail, 24dip, 150dip, Root.Width - 48dip, 48dip)
	
	edtPassword.Initialize("edtPassword")
	edtPassword.Hint = "Password"
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
	lblError.Text = ""
	Dim email As String = edtEmail.Text.Trim
	Dim password As String = edtPassword.Text
	If email = "" Or password = "" Then
		lblError.Text = "Email and password required."
		Return
	End If
	ProgressDialogShow("Signing in…")
	If chkSignUp Then
		Dim name As String = edtName.Text.Trim
		If name = "" Then name = email
		Wait For (modAuth.SignUpEmail(email, password, name, spnRole.SelectedItem)) Complete (ok As Boolean)
		ProgressDialogHide
		If ok Then
			B4XPages.MainPage.AfterLogin
		Else
			lblError.Text = modAuth.LastError
		End If
	Else
		Wait For (modAuth.SignInEmail(email, password)) Complete (ok2 As Boolean)
		ProgressDialogHide
		If ok2 Then
			B4XPages.MainPage.AfterLogin
		Else
			lblError.Text = modAuth.LastError
		End If
	End If
End Sub

Private Sub btnGoogle_Click
	lblError.Text = "Configure Google Sign-In in Firebase + google-services.json, then call modAuth.SignInWithGoogleIdToken from your GoogleSignIn result."
	' Integration point: use B4A GoogleSignIn / FirebaseAuth Google provider,
	' obtain idToken, then:
	' Wait For (modAuth.SignInWithGoogleIdToken(idToken)) Complete (ok As Boolean)
End Sub
