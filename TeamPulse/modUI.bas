B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Shared UI helpers — CLV creation + match/hub cards (programmatic, no Designer).

Sub Process_Globals
	Private xui As XUI
#if B4i
	' Class instances, not Panels. A code module cannot store an activity view.
	Private lastPress As clsLongPress
	Private longKeepers As List
	' Maps of callback, event name, and button. Click is raised in this module.
	' Object, not Button: a code module must not construct a view at startup.
	Private buttonRelays As List
	Private lastClicked As Object
	Private panelRelays As List
	Private clickTarget As Object
	Private lastClickedPanel As Object
#End If
End Sub

Public Sub MatchCardHeight As Int
	Return 92dip
End Sub

Public Sub SectionHeaderHeight As Int
	Return 36dip
End Sub

Public Sub SimpleRowHeight As Int
	Return 52dip
End Sub

Public Sub LiveBannerHeight As Int
	Return 72dip
End Sub

' Creates and adds an xCustomListView. Base panel is already added to Parent.
Public Sub AddCustomListView(Parent As B4XView, Left As Int, Top As Int, Width As Int, Height As Int, _
		Callback As Object, EventName As String) As CustomListView
	Return AddCustomListViewThemed(Parent, Left, Top, Width, Height, Callback, EventName, False)
End Sub

' DarkTheme: full slate list (Live Feed) — kills the default white ScrollView strip.
Public Sub AddCustomListViewThemed(Parent As B4XView, Left As Int, Top As Int, Width As Int, Height As Int, _
		Callback As Object, EventName As String, DarkTheme As Boolean) As CustomListView
	Dim bg As Int = Colors.Transparent
	Dim pressed As Int = 0xFFCBCBCB
	Dim div As Int = modConfig.COLOR_BORDER
	Dim divH As Int = 1dip
	If DarkTheme Then
		bg = 0xFF0F172A
		pressed = 0xFF1E293B
		div = 0xFF0F172A
		divH = 0
	End If
	Dim p As Panel
	p.Initialize("")
	p.Color = bg
	Parent.AddView(p, Left, Top, Width, Height)
	Dim clv As CustomListView
	clv.Initialize(Callback, EventName)
	Dim dummy As Label
	dummy.Initialize("")
	Dim props As Map
	props.Initialize
	props.Put("DividerColor", div)
	props.Put("DividerHeight", divH)
	props.Put("PressedColor", pressed)
	props.Put("InsertAnimationDuration", 300)
	props.Put("ListOrientation", "Vertical")
	props.Put("ShowScrollBar", True)
	clv.DesignerCreateView(p, dummy, props)
	If DarkTheme Then ApplyDarkListBackground(clv, bg)
	Return clv
End Sub

Public Sub ApplyDarkListBackground(clv As CustomListView, bg As Int)
	Try
		clv.GetBase.Color = bg
	Catch
		Log("DarkList GetBase: " & LastException.Message)
	End Try
	Try
		clv.AsView.Color = bg
	Catch
		Log("DarkList AsView: " & LastException.Message)
	End Try
	Try
		clv.sv.Color = bg
	Catch
		Log("DarkList sv: " & LastException.Message)
	End Try
	Try
		clv.sv.ScrollViewInnerPanel.Color = bg
	Catch
		Log("DarkList inner: " & LastException.Message)
	End Try
	Try
		Dim base As B4XView = clv.GetBase
		base.Color = bg
		Dim i As Int
		For i = 0 To base.NumberOfViews - 1
			base.GetView(i).Color = bg
		Next
	Catch
		Log("DarkList children: " & LastException.Message)
	End Try
End Sub

' B4A Button.Initialize takes an event name. B4i needs a custom button so Color and text color apply.
' callback is the page that owns EventName_Click. Android ignores it and keeps the existing Initialize.
Public Sub InitButton(callback As Object, b As Button, eventName As String)
#if B4A
	If callback <> Null Then b.Initialize(eventName)
#else if B4i
	If buttonRelays.IsInitialized = False Then buttonRelays.Initialize
	b.InitializeCustom("tpRelay", xui.Color_White, xui.Color_LightGray)
	Dim info As Map
	info.Initialize
	info.Put("callback", callback)
	info.Put("event", eventName)
	info.Put("btn", b)
	buttonRelays.Add(info)
#End If
End Sub

#if B4i
Private Sub tpRelay_Click
	Dim clicked As Button = Sender
	lastClicked = clicked
	Dim i As Int
	For i = buttonRelays.Size - 1 To 0 Step -1
		Dim info As Map = buttonRelays.Get(i)
		Dim stored As Button = info.Get("btn")
		If SameView(stored, clicked) Then
			Dim cb As Object = info.Get("callback")
			Dim ev As String = info.Get("event")
			If cb <> Null And ev <> "" Then CallSub(cb, ev & "_Click")
			Return
		End If
	Next
End Sub
#End If

' Android Click passes the button as Sender. iOS buttons created in modUI do not.
Public Sub ClickedButton(senderObj As Object) As Button
#if B4i
	If senderObj Is Button Then
		Dim direct As Button = senderObj
		Return direct
	End If
	Dim saved As Button = lastClicked
	Return saved
#else
	Dim b As Button = senderObj
	Return b
#End If
End Sub

' iOS panels created in this module raise Click here. Android still initializes them on the page.
Public Sub SetClickTarget(target As Object)
#if B4i
	clickTarget = target
#else
	If target = Null Then Return
#End If
End Sub

Public Sub ClickedPanel(senderObj As Object) As Panel
#if B4i
	If senderObj Is Panel Then
		Dim direct As Panel = senderObj
		Return direct
	End If
	Dim saved As Panel = lastClickedPanel
	Return saved
#else
	Dim p As Panel = senderObj
	Return p
#End If
End Sub

Private Sub WirePanel(p As Panel, EventName As String, callback As Object)
#if B4A
	If callback = Null And EventName = "" Then
		p.Initialize("")
	Else
		p.Initialize(EventName)
	End If
#else if B4i
	If EventName = "" Then
		p.Initialize("")
		Return
	End If
	Dim target As Object = callback
	If target = Null Then target = clickTarget
	If panelRelays.IsInitialized = False Then panelRelays.Initialize
	p.Initialize("tpPanel")
	Dim info As Map
	info.Initialize
	info.Put("callback", target)
	info.Put("event", EventName)
	info.Put("pnl", p)
	panelRelays.Add(info)
#End If
End Sub

#if B4i
Private Sub tpPanel_Click
	Dim clicked As Panel = Sender
	lastClickedPanel = clicked
	If panelRelays.IsInitialized = False Then Return
	Dim i As Int
	For i = panelRelays.Size - 1 To 0 Step -1
		Dim info As Map = panelRelays.Get(i)
		If SameView(info.Get("pnl"), clicked) Then
			Dim cb As Object = info.Get("callback")
			Dim ev As String = info.Get("event")
			If cb <> Null And ev <> "" Then CallSub(cb, ev & "_Click")
			Return
		End If
	Next
End Sub

Private Sub SameView(a As Object, b As Object) As Boolean
	If a = Null Or b = Null Then Return False
	If a = b Then Return True
	Try
		Dim na As NativeObject = a
		Dim same As Object = na.RunMethod("isEqual:", Array(b))
		Return same = True
	Catch
		Return False
	End Try
End Sub
#End If

Public Sub SetButtonTextColor(b As Button, color As Int)
#if B4A
	b.TextColor = color
#else if B4i
	b.CustomLabel.TextColor = color
#End If
End Sub

' B4A ScrollView.Initialize takes the inner height. B4i also takes the event name and width.
Public Sub InitScroll(sv As ScrollView, innerHeight As Int)
#if B4A
	sv.Initialize(innerHeight)
#else if B4i
	Dim w As Int = 100%x
	Dim lv As LayoutValues = GetDeviceLayoutValues
	If lv.Width > w Then w = lv.Width
	If w < 80dip Then w = 320dip
	sv.Initialize("", w, innerHeight)
#End If
End Sub

Public Sub SetScrollContentHeight(sv As ScrollView, height As Int)
#if B4A
	sv.Panel.Height = height
#else if B4i
	sv.ContentHeight = height
#End If
End Sub

Public Sub RoundView(v As Object, color As Int, radius As Int)
	Dim x As B4XView = v
	x.SetColorAndBorder(color, 0, 0, radius)
End Sub

' B4A Panel.SetLayout does not exist on B4i. Assign the frame directly on both.
Public Sub PlaceView(v As Object, left As Int, top As Int, width As Int, height As Int)
	Dim xv As B4XView = v
	xv.Left = left
	xv.Top = top
	xv.Width = width
	xv.Height = height
End Sub

' Root.Width is a sliver while an iOS page is created. Width can follow the phone.
' Height stays shorter than the full screen so the bottom bar is not pushed off.
Public Sub ViewWidth(v As B4XView) As Int
	Dim w As Int = 0
	If v.IsInitialized Then w = v.Width
#if B4i
	Dim screenW As Int = DeviceWidth
	If w < screenW * 0.8 Then w = screenW
#End If
	If w < 80dip Then w = 320dip
	Return w
End Sub

Public Sub ViewHeight(v As B4XView) As Int
	Dim h As Int = 0
	If v.IsInitialized Then h = v.Height
#if B4i
	Dim screenH As Int = DeviceHeight
	If h < screenH * 0.7 Then h = PageHeight
#End If
	If h < 80dip Then h = 568dip
	Return h
End Sub

' Gives a page root a real size before it lays out. Android already has one.
Public Sub ExpandRoot(Root As B4XView)
#if B4i
	Dim w As Int = DeviceWidth
	Dim h As Int = PageHeight
	If Root.Width < w * 0.8 Then Root.Width = w
	If Root.Height < DeviceHeight * 0.7 Then Root.Height = h
#Else
	If Root.IsInitialized = False Then Return
#End If
End Sub

#if B4i
Private Sub DeviceWidth As Int
	Dim w As Int = 100%x
	Dim lv As LayoutValues = GetDeviceLayoutValues
	If lv.Width > w Then w = lv.Width
	If w < 80dip Then w = 320dip
	Return w
End Sub

Private Sub DeviceHeight As Int
	Dim h As Int = 100%y
	Dim lv As LayoutValues = GetDeviceLayoutValues
	If lv.Height > h Then h = lv.Height
	If h < 80dip Then h = 568dip
	Return h
End Sub

' Full screen height includes the status bar and home indicator.
Private Sub PageHeight As Int
	Dim h As Int = DeviceHeight
	If h > 160dip Then h = h - 96dip
	Return h
End Sub
#End If

Public Sub RoundBorder(v As Object, fill As Int, radius As Int, borderWidth As Int, borderColor As Int)
	Dim x As B4XView = v
	x.SetColorAndBorder(fill, borderWidth, borderColor, radius)
End Sub

Public Sub StyleEditText(edt As Object, hint As String)
	StyleFieldColors(edt, hint, modConfig.COLOR_CARD, modConfig.COLOR_PRIMARY, modConfig.COLOR_MUTED, 15, True)
End Sub

Public Sub StyleEditTextDark(edt As Object, hint As String)
	StyleFieldColors(edt, hint, modConfig.COLOR_DARK_CARD, modConfig.COLOR_DARK_TEXT, modConfig.COLOR_DARK_MUTED, 15, True)
End Sub

Public Sub StyleFieldColors(edt As Object, hint As String, bg As Int, fg As Int, hintColor As Int, size As Float, single As Boolean)
#if B4A
	Dim e As EditText = edt
	e.Hint = hint
	e.Color = bg
	e.TextColor = fg
	e.HintColor = hintColor
#else if B4i
	If edt Is TextView Then
		Dim tv As TextView = edt
		tv.Color = bg
		tv.TextColor = fg
	Else
		Dim t As TextField = edt
		t.HintText = hint
		t.Color = bg
		t.TextColor = fg
		Dim hintText As AttributedString
		hintText.Initialize(hint, xui.CreateDefaultFont(size), hintColor)
		Dim no As NativeObject = t
		no.RunMethod("setAttributedPlaceholder:", Array(hintText))
	End If
#End If
	SetTextSize(edt, size)
	SetSingleLine(edt, single)
End Sub

Public Sub SetTextSize(v As Object, size As Float)
	Dim x As B4XView = v
	x.TextSize = size
	x.Font = xui.CreateDefaultFont(size)
End Sub

Public Sub SetBold(v As Object, bold As Boolean)
	Dim x As B4XView = v
	Dim size As Float = x.TextSize
	If size < 1 Then size = 15
	If bold Then
		x.Font = xui.CreateDefaultBoldFont(size)
	Else
		x.Font = xui.CreateDefaultFont(size)
	End If
End Sub

Public Sub SetAlign(v As Object, vertical As String, horizontal As String)
#if B4i
	' UIButton has no setTextAlignment. Custom buttons draw their title on CustomLabel.
	If v Is Button Then
		Dim b As Button = v
		If horizontal = "RIGHT" Then
			b.CustomLabel.TextAlignment = b.CustomLabel.ALIGNMENT_RIGHT
		Else If horizontal = "LEFT" Then
			b.CustomLabel.TextAlignment = b.CustomLabel.ALIGNMENT_LEFT
		Else
			b.CustomLabel.TextAlignment = b.CustomLabel.ALIGNMENT_CENTER
		End If
		Return
	End If
#End If
	Dim x As B4XView = v
	x.SetTextAlignment(vertical, horizontal)
End Sub

Public Sub SetSingleLine(v As Object, single As Boolean)
#if B4A
	If v Is Label Then
		Dim lbl As Label = v
		lbl.SingleLine = single
	Else If v Is Button Then
		Dim b As Button = v
		b.SingleLine = single
	Else If v Is EditText Then
		Dim e As EditText = v
		e.SingleLine = single
	End If
#else if B4i
	If v Is Label Then
		Dim lbl As Label = v
		lbl.Multiline = Not(single)
	End If
#End If
End Sub

Public Sub SetKeyboard(v As Object, kind As String)
#if B4A
	Dim e As EditText = v
	If kind = "numbers" Then
		e.InputType = e.INPUT_TYPE_NUMBERS
	Else If kind = "decimal" Then
		e.InputType = e.INPUT_TYPE_DECIMAL_NUMBERS
	Else If kind = "phone" Then
		e.InputType = e.INPUT_TYPE_PHONE
	Else
		e.InputType = e.INPUT_TYPE_TEXT
	End If
#else if B4i
	If v Is TextField Then
		Dim tf As TextField = v
		If kind = "numbers" Then
			tf.KeyboardType = tf.TYPE_NUMBER_PAD
		Else If kind = "decimal" Then
			tf.KeyboardType = tf.TYPE_DECIMAL_PAD
		Else If kind = "phone" Then
			tf.KeyboardType = tf.TYPE_PHONE_PAD
		Else If kind = "email" Then
			tf.KeyboardType = tf.TYPE_EMAIL_ADDRESS
		Else
			tf.KeyboardType = tf.TYPE_DEFAULT
		End If
	End If
#End If
End Sub

Public Sub SetPassword(v As Object, password As Boolean)
#if B4A
	Dim e As EditText = v
	e.PasswordMode = password
#else if B4i
	Dim tf As TextField = v
	tf.PasswordMode = password
#End If
End Sub

Public Sub SetImageFill(iv As ImageView)
#if B4A
	iv.Gravity = Gravity.FILL
#else if B4i
	iv.ContentMode = iv.MODE_FILL
#End If
End Sub

Public Sub EnableLongClick(pnl As Panel, callback As Object, eventName As String)
	If eventName = "" Or callback = Null Then Return
#if B4A
	Try
		Dim hjo As JavaObject = pnl
		hjo.RunMethod("setLongClickable", Array(True))
		Dim hook As JavaObject
		hook.InitializeStatic(Application.PackageName & ".modui")
		hook.RunMethod("holdForLongPress", Array(hjo))
	Catch
		Log("EnableLongClick: " & LastException.Message)
	End Try
#else if B4i
	If longKeepers.IsInitialized = False Then longKeepers.Initialize
	Dim lp As clsLongPress
	lp.Initialize(pnl, callback, eventName)
	longKeepers.Add(lp)
#End If
End Sub

' iOS calls this with the gesture owner just before RaiseLongClick.
' The panel stays on the class. Process_Globals cannot hold a Panel.
#if B4i
Public Sub NoteLongPress(lp As clsLongPress)
	lastPress = lp
End Sub
#End If

Public Sub RaiseLongClick(callback As Object, eventName As String)
	CallSub(callback, eventName & "_LongClick")
End Sub

' Android long-click passes the panel as Sender. iOS returns the panel from the gesture class.
Public Sub LongClickPanel(senderObj As Object) As Panel
	If senderObj Is Panel Then Return senderObj
#if B4i
	If lastPress.IsInitialized Then Return lastPress.HostPanel
#End If
	Dim empty As Panel
	Return empty
End Sub

' Standard top bar height (back + title + optional action).
Public Sub PageChromeHeight As Int
	Return 56dip
End Sub

' Consistent chrome: ← on the left, title beside it, optional trailing glyph button on the right.
' Returns Map: ContentTop (Int), TitleLabel (Label).
Public Sub AddPageChrome(callback As Object, Root As B4XView, Title As String, BackEvent As String, _
		ActionEvent As String, ActionGlyph As String, Dark As Boolean) As Map
	Dim bg As Int = modConfig.COLOR_SURFACE
	Dim titleCol As Int = modConfig.COLOR_PRIMARY
	Dim btnFg As Int = modConfig.COLOR_PRIMARY
	Dim actionBg As Int = modConfig.COLOR_ACCENT
	If Dark Then
		bg = modConfig.COLOR_DARK_BG
		titleCol = modConfig.COLOR_DARK_TEXT
		btnFg = Colors.White
		actionBg = modConfig.COLOR_ACCENT
	End If
	Root.Color = bg
	ExpandRoot(Root)
	Dim pageW As Int = ViewWidth(Root)
	
	Dim left As Int = 4dip
	If BackEvent <> "" Then
		Dim btnBack As Button = CreateChromeIconButton(callback, BackEvent, "←", Colors.Transparent, btnFg)
		SetTextSize(btnBack, 26)
		Root.AddView(btnBack, left, 6dip, 44dip, 44dip)
		left = left + 44dip
	End If
	
	Dim rightPad As Int = 12dip
	If ActionEvent <> "" Then
		Dim btnAct As Button = CreateChromeIconButton(callback, ActionEvent, ActionGlyph, actionBg, Colors.White)
		SetTextSize(btnAct, 22)
		Root.AddView(btnAct, pageW - 52dip, 10dip, 40dip, 36dip)
		rightPad = 60dip
	End If
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = Title
	SetTextSize(lblTitle, 20)
	SetBold(lblTitle, True)
	lblTitle.TextColor = titleCol
	SetAlign(lblTitle, "CENTER", "LEFT")
	SetSingleLine(lblTitle, True)
	Root.AddView(lblTitle, left, 10dip, pageW - left - rightPad, 36dip)
	
	Dim out As Map
	out.Initialize
	out.Put("ContentTop", PageChromeHeight)
	out.Put("TitleLabel", lblTitle)
	Return out
End Sub

Public Sub CreateChromeIconButton(callback As Object, EventName As String, glyph As String, bgColor As Int, fgColor As Int) As Button
	Dim b As Button
	InitButton(callback, b, EventName)
	b.Text = glyph
	SetTextSize(b, 18)
	SetBold(b, True)
	SetButtonTextColor(b, fgColor)
	If bgColor = Colors.Transparent Then
		RoundView(b, Colors.Transparent, 0)
	Else
		b.Color = bgColor
	End If
	SetAlign(b, "CENTER", "CENTER")
#if B4A
	b.Padding = Array As Int(0, 0, 0, 0)
#End If
	Return b
End Sub

' yyyy-MM-dd or similar → dd/MM/yyyy (UK).
Public Sub FormatUkDate(raw As String) As String
	Dim s As String = raw.Trim
	If s = "" Then Return ""
	If s.Length >= 10 And s.CharAt(4) = "-" And s.CharAt(7) = "-" Then
		Return s.SubString2(8, 10) & "/" & s.SubString2(5, 7) & "/" & s.SubString2(0, 4)
	End If
	If s.Length >= 10 And s.CharAt(4) = "/" And s.CharAt(7) = "/" Then
		Return s.SubString2(8, 10) & "/" & s.SubString2(5, 7) & "/" & s.SubString2(0, 4)
	End If
	Return s
End Sub

' Normalise to HH:mm (24h UK).
Public Sub FormatUkTime(raw As String) As String
	Dim s As String = raw.Trim
	If s = "" Then Return ""
	Dim colon As Int = s.IndexOf(":")
	If colon < 1 Then Return s
	Try
		Dim hh As Int = s.SubString2(0, colon)
		Dim rest As String = s.SubString(colon + 1)
		Dim mm As Int = 0
		If rest.Length >= 2 Then mm = rest.SubString2(0, 2)
		Return NumberFormat(hh, 2, 0) & ":" & NumberFormat(mm, 2, 0)
	Catch
		Return s
	End Try
End Sub

' EventName: use "" for CLV items; non-empty for ScrollView click (e.g. "card").
Public Sub CreateMatchCard(Width As Int, match As Map, EventName As String) As Panel
	Return CreateMatchCardThemed(Width, match, EventName, False)
End Sub

Public Sub CreateMatchCardThemed(Width As Int, match As Map, EventName As String, Dark As Boolean) As Panel
	Dim status As String = match.GetDefault("status", "UPCOMING")
	Dim cardBg As Int = modConfig.COLOR_CARD
	Dim titleColor As Int = modConfig.COLOR_PRIMARY
	Dim mutedColor As Int = modConfig.COLOR_MUTED
	Dim chipBg As Int = modConfig.COLOR_CHIP
	Dim chipFg As Int = modConfig.COLOR_PRIMARY
	If Dark Then
		cardBg = modConfig.COLOR_DARK_CARD
		titleColor = modConfig.COLOR_DARK_TEXT
		mutedColor = modConfig.COLOR_DARK_MUTED
		chipBg = modConfig.COLOR_DARK_CHIP
		chipFg = modConfig.COLOR_DARK_TEXT
		If status = "LIVE" Then cardBg = 0xFF172554
		If status = "CANCELLED" Then cardBg = 0xFF450A0A
	Else
		If status = "LIVE" Then cardBg = modConfig.COLOR_LIVE_BG
		If status = "CANCELLED" Then cardBg = modConfig.COLOR_CANCEL_BG
	End If
	If status = "LIVE" Then
		chipBg = modConfig.COLOR_ACCENT
		chipFg = Colors.White
	Else If status = "CANCELLED" Then
		If Dark Then
			chipBg = 0xFF7F1D1D
			chipFg = 0xFFFECACA
		Else
			chipBg = 0xFFFECACA
			chipFg = modConfig.COLOR_DANGER
		End If
	End If
	
	Dim card As Panel
	WirePanel(card, EventName, Null)
	RoundView(card, cardBg, 12dip)
	
	Dim dateStr As String = match.GetDefault("date", "")
	Dim monthTxt As String = MonthAbbrFromDate(dateStr)
	Dim dayTxt As String = DayFromDate(dateStr)
	
	Dim chip As Panel
	chip.Initialize("")
	RoundView(chip, chipBg, 10dip)
	card.AddView(chip, 10dip, 14dip, 58dip, 64dip)
	
	Dim lblDate As Label
	lblDate.Initialize("")
	lblDate.Text = monthTxt & " " & dayTxt
	SetTextSize(lblDate, 12)
	lblDate.TextColor = chipFg
	SetAlign(lblDate, "CENTER", "CENTER")
	SetBold(lblDate, True)
	chip.AddView(lblDate, 2dip, 0, 54dip, 64dip)
	
	Dim midLeft As Int = 78dip
	Dim midW As Int = Width - midLeft - 16dip
	If status = "LIVE" Then midW = Width - midLeft - 72dip
	
	If status = "CANCELLED" And Dark = False Then titleColor = modConfig.COLOR_MUTED
	If status = "CANCELLED" And Dark Then titleColor = modConfig.COLOR_DARK_MUTED
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = match.GetDefault("title", "Match")
	SetTextSize(lblTitle, 15)
	lblTitle.TextColor = titleColor
	SetBold(lblTitle, True)
	SetAlign(lblTitle, "CENTER", "LEFT")
	SetSingleLine(lblTitle, True)
	card.AddView(lblTitle, midLeft, 10dip, midW, 24dip)
	
	Dim loc As String = match.GetDefault("location", "")
	If loc = "" Then loc = "TBC"
	Dim lblLoc As Label
	lblLoc.Initialize("")
	lblLoc.Text = loc
	SetTextSize(lblLoc, 12)
	lblLoc.TextColor = mutedColor
	SetSingleLine(lblLoc, True)
	card.AddView(lblLoc, midLeft, 36dip, midW, 18dip)
	
	Dim meta As String = BuildMatchMeta(match, status)
	Dim lblMeta As Label
	lblMeta.Initialize("")
	lblMeta.Text = meta
	SetTextSize(lblMeta, 12)
	lblMeta.TextColor = mutedColor
	If status = "LIVE" Then lblMeta.TextColor = modConfig.COLOR_LIVE
	SetSingleLine(lblMeta, True)
	card.AddView(lblMeta, midLeft, 56dip, midW, 18dip)
	
	If status = "LIVE" Then
		Dim badge As Panel
		badge.Initialize("")
		RoundView(badge, modConfig.COLOR_LIVE, 8dip)
		card.AddView(badge, Width - 64dip, 14dip, 50dip, 22dip)
		Dim lblLive As Label
		lblLive.Initialize("")
		lblLive.Text = "LIVE"
		SetTextSize(lblLive, 10)
		lblLive.TextColor = Colors.White
		SetBold(lblLive, True)
		SetAlign(lblLive, "CENTER", "CENTER")
		badge.AddView(lblLive, 0, 0, 50dip, 22dip)
	End If
	
	Return card
End Sub

Public Sub CreateLiveBanner(Width As Int, match As Map, EventName As String) As Panel
	Dim banner As Panel
	WirePanel(banner, EventName, Null)
	RoundView(banner, modConfig.COLOR_LIVE, 12dip)
	
	Dim lblPill As Label
	lblPill.Initialize("")
	lblPill.Text = "LIVE NOW"
	SetTextSize(lblPill, 10)
	lblPill.TextColor = Colors.White
	SetBold(lblPill, True)
	SetAlign(lblPill, "CENTER", "LEFT")
	banner.AddView(lblPill, 14dip, 8dip, 100dip, 16dip)
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = match.GetDefault("title", "Match")
	SetTextSize(lblTitle, 15)
	lblTitle.TextColor = Colors.White
	SetBold(lblTitle, True)
	SetSingleLine(lblTitle, True)
	banner.AddView(lblTitle, 14dip, 26dip, Width - 164dip, 22dip)
	
	Dim score As String = modLocal.ScoreLine(match)
	Dim lblScore As Label
	lblScore.Initialize("")
	lblScore.Text = score
	SetTextSize(lblScore, 20)
	If score.Length > 7 Then SetTextSize(lblScore, 13)
	lblScore.TextColor = Colors.White
	SetBold(lblScore, True)
	SetAlign(lblScore, "CENTER", "RIGHT")
	SetSingleLine(lblScore, True)
	banner.AddView(lblScore, Width - 150dip, 18dip, 136dip, 36dip)
	
	Return banner
End Sub

Public Sub CreateSectionHeader(Width As Int, text As String) As Panel
	Return CreateSectionHeaderThemed(Width, text, False)
End Sub

Public Sub CreateSectionHeaderThemed(Width As Int, text As String, Dark As Boolean) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Color = Colors.Transparent
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text.ToUpperCase
	SetTextSize(lbl, 11)
	If Dark Then
		lbl.TextColor = modConfig.COLOR_DARK_MUTED
	Else
		lbl.TextColor = modConfig.COLOR_MUTED
	End If
	SetBold(lbl, True)
	SetAlign(lbl, "CENTER", "LEFT")
	p.AddView(lbl, 4dip, 0, Width - 8dip, SectionHeaderHeight)
	Return p
End Sub

' header=True → non-clickable section-style; else tappable row when EventName set.
Public Sub CreateSimpleRow(Width As Int, text As String, EventName As String) As Panel
	Return CreateSimpleRowThemed(Width, text, EventName, False)
End Sub

Public Sub CreateSimpleRowThemed(Width As Int, text As String, EventName As String, Dark As Boolean) As Panel
	Dim p As Panel
	WirePanel(p, EventName, Null)
	Dim bg As Int = modConfig.COLOR_CARD
	Dim fg As Int = modConfig.COLOR_PRIMARY
	If Dark Then
		bg = modConfig.COLOR_DARK_CARD
		fg = modConfig.COLOR_DARK_TEXT
	End If
	RoundView(p, bg, 10dip)
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	SetTextSize(lbl, 14)
	lbl.TextColor = fg
	SetAlign(lbl, "CENTER", "LEFT")
	SetSingleLine(lbl, True)
	p.AddView(lbl, 14dip, 0, Width - 28dip, SimpleRowHeight)
	Return p
End Sub

Private Sub BuildMatchMeta(match As Map, status As String) As String
	Dim kick As String = match.GetDefault("kickOffTime", "")
	If status = "LIVE" Or status = "COMPLETED" Then
		Return modLocal.ScoreLine(match) & "  ·  " & status
	Else If status = "CANCELLED" Then
		Return "MATCH CANCELLED"
	Else
		If kick = "" Then Return "Upcoming"
		Return "Kickoff: " & kick
	End If
End Sub

Private Sub NormalizeDate(dateStr As String) As String
	Dim s As String = dateStr.Trim
	If s = "" Then Return ""
	Dim ti As Int = s.IndexOf("T")
	If ti > 0 Then s = s.SubString2(0, ti)
	Dim si As Int = s.IndexOf(" ")
	If si > 0 Then s = s.SubString2(0, si)
	Return s
End Sub

Private Sub MonthAbbrFromDate(dateStr As String) As String
	Try
		Dim s As String = NormalizeDate(dateStr)
		Dim parts() As String = Regex.Split("-", s)
		If parts.Length >= 2 Then
			Dim mo As Int = parts(1)
			Select mo
				Case 1: Return "JAN"
				Case 2: Return "FEB"
				Case 3: Return "MAR"
				Case 4: Return "APR"
				Case 5: Return "MAY"
				Case 6: Return "JUN"
				Case 7: Return "JUL"
				Case 8: Return "AUG"
				Case 9: Return "SEP"
				Case 10: Return "OCT"
				Case 11: Return "NOV"
				Case 12: Return "DEC"
			End Select
		End If
	Catch
		Log("MonthAbbrFromDate: " & LastException.Message)
	End Try
	Return "-"
End Sub

Private Sub DayFromDate(dateStr As String) As String
	Try
		Dim s As String = NormalizeDate(dateStr)
		Dim parts() As String = Regex.Split("-", s)
		If parts.Length >= 3 Then
			Dim d As String = parts(2)
			Dim digits As StringBuilder
			digits.Initialize
			Dim i As Int
			For i = 0 To d.Length - 1
				Dim c As Int = Asc(d.CharAt(i))
				If c >= 48 And c <= 57 Then digits.Append(Chr(c))
			Next
			Dim day As String = digits.ToString
			If day.Length = 1 Then Return "0" & day
			If day.Length >= 2 Then Return day.SubString2(0, 2)
			Return day
		End If
	Catch
		Log("DayFromDate: " & LastException.Message)
	End Try
	Return "-"
End Sub

Public Sub ClubCardHeight As Int
	Return 88dip
End Sub

Public Sub CreateClubCard(Width As Int, club As Map, EventName As String) As Panel
	Return CreateClubCardThemed(Width, club, EventName, False)
End Sub

Public Sub CreateClubCardThemed(Width As Int, club As Map, EventName As String, Dark As Boolean) As Panel
	Dim card As Panel
	WirePanel(card, EventName, Null)
	Dim bg As Int = modConfig.COLOR_CARD
	Dim nameCol As Int = modConfig.COLOR_PRIMARY
	Dim mutedCol As Int = modConfig.COLOR_MUTED
	If Dark Then
		bg = modConfig.COLOR_DARK_CARD
		nameCol = modConfig.COLOR_DARK_TEXT
		mutedCol = modConfig.COLOR_DARK_MUTED
	End If
	RoundView(card, bg, 12dip)
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = club.GetDefault("name", "Club")
	SetTextSize(lblName, 16)
	lblName.TextColor = nameCol
	SetBold(lblName, True)
	SetSingleLine(lblName, True)
	card.AddView(lblName, 14dip, 12dip, Width - 48dip, 24dip)
	
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Dim meta As String = club.GetDefault("type", "TEAM") & "  ·  " & members.Size & " members"
	Dim code As String = club.GetDefault("inviteCode", "")
	If code <> "" Then meta = meta & "  ·  code " & code
	
	Dim lblMeta As Label
	lblMeta.Initialize("")
	lblMeta.Text = meta
	SetTextSize(lblMeta, 12)
	lblMeta.TextColor = mutedCol
	SetSingleLine(lblMeta, True)
	card.AddView(lblMeta, 14dip, 40dip, Width - 48dip, 18dip)
	
	Dim desc As String = club.GetDefault("description", "")
	If desc <> "" Then
		Dim lblDesc As Label
		lblDesc.Initialize("")
		lblDesc.Text = desc
		SetTextSize(lblDesc, 12)
		lblDesc.TextColor = mutedCol
		SetSingleLine(lblDesc, True)
		card.AddView(lblDesc, 14dip, 60dip, Width - 48dip, 18dip)
	End If
	
	Dim chev As Label
	chev.Initialize("")
	chev.Text = ">"
	SetTextSize(chev, 18)
	chev.TextColor = modConfig.COLOR_ACCENT
	SetAlign(chev, "CENTER", "CENTER")
	card.AddView(chev, Width - 36dip, 24dip, 28dip, 36dip)
	Return card
End Sub

Public Sub CreateStatPill(Width As Int, label As String, value As String, accent As Int) As Panel
	Return CreateStatPillThemed(Width, label, value, accent, False)
End Sub

Public Sub CreateStatPillThemed(Width As Int, label As String, value As String, accent As Int, Dark As Boolean) As Panel
	Dim p As Panel
	p.Initialize("")
	Dim bg As Int = modConfig.COLOR_CARD
	Dim mutedCol As Int = modConfig.COLOR_MUTED
	If Dark Then
		bg = modConfig.COLOR_DARK_CARD
		mutedCol = modConfig.COLOR_DARK_MUTED
	End If
	RoundView(p, bg, 12dip)
	Dim lblV As Label
	lblV.Initialize("")
	lblV.Text = value
	SetTextSize(lblV, 20)
	lblV.TextColor = accent
	SetBold(lblV, True)
	SetAlign(lblV, "CENTER", "CENTER")
	p.AddView(lblV, 0, 8dip, Width, 28dip)
	Dim lblL As Label
	lblL.Initialize("")
	lblL.Text = label
	SetTextSize(lblL, 10)
	lblL.TextColor = mutedCol
	SetBold(lblL, True)
	SetAlign(lblL, "CENTER", "CENTER")
	p.AddView(lblL, 0, 36dip, Width, 16dip)
	Return p
End Sub

Public Sub CreateLeaderboardRow(Width As Int, rank As Int, name As String, valueText As String, Dark As Boolean) As Panel
	Dim p As Panel
	p.Initialize("")
	Dim bg As Int = modConfig.COLOR_CARD
	Dim nameCol As Int = modConfig.COLOR_PRIMARY
	If Dark Then
		bg = modConfig.COLOR_DARK_CARD
		nameCol = modConfig.COLOR_DARK_TEXT
	End If
	RoundView(p, bg, 10dip)
	
	Dim lblR As Label
	lblR.Initialize("")
	lblR.Text = "#" & rank
	SetTextSize(lblR, 13)
	lblR.TextColor = modConfig.COLOR_ACCENT
	SetBold(lblR, True)
	SetAlign(lblR, "CENTER", "CENTER")
	p.AddView(lblR, 8dip, 12dip, 40dip, 24dip)
	
	Dim lblN As Label
	lblN.Initialize("")
	lblN.Text = name
	SetTextSize(lblN, 14)
	lblN.TextColor = nameCol
	SetBold(lblN, True)
	SetSingleLine(lblN, True)
	p.AddView(lblN, 52dip, 12dip, Width - 120dip, 24dip)
	
	Dim lblV As Label
	lblV.Initialize("")
	lblV.Text = valueText
	SetTextSize(lblV, 15)
	lblV.TextColor = Colors.White
	If Dark = False Then lblV.TextColor = modConfig.COLOR_PRIMARY
	SetBold(lblV, True)
	SetAlign(lblV, "CENTER", "CENTER")
	p.AddView(lblV, Width - 64dip, 10dip, 52dip, 28dip)
	Return p
End Sub

Public Sub CreatePlayerStatRow(Width As Int, player As Map, maxGoals As Int) As Panel
	Dim p As Panel
	p.Initialize("")
	RoundView(p, modConfig.COLOR_CARD, 10dip)
	Dim name As String = player.GetDefault("name", "Player")
	Dim g As Int = player.GetDefault("goals", 0)
	Dim a As Int = player.GetDefault("assists", 0)
	Dim apps As Int = player.GetDefault("apps", 0)
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = name
	SetTextSize(lblName, 14)
	lblName.TextColor = modConfig.COLOR_PRIMARY
	SetBold(lblName, True)
	SetSingleLine(lblName, True)
	p.AddView(lblName, 12dip, 8dip, Width - 24dip, 20dip)
	
	Dim lblMeta As Label
	lblMeta.Initialize("")
	lblMeta.Text = "G " & g & "   A " & a & "   Apps " & apps & "   YC " & player.GetDefault("yellowCards", 0) & "   POTM " & player.GetDefault("potmWins", 0)
	SetTextSize(lblMeta, 11)
	lblMeta.TextColor = modConfig.COLOR_MUTED
	SetSingleLine(lblMeta, True)
	p.AddView(lblMeta, 12dip, 30dip, Width - 24dip, 16dip)
	
	Dim track As Panel
	track.Initialize("")
	track.Color = modConfig.COLOR_CHIP
	p.AddView(track, 12dip, 52dip, Width - 24dip, 8dip)
	Dim fillW As Int = 4dip
	If maxGoals > 0 Then fillW = Max(4dip, ((Width - 24dip) * g) / maxGoals)
	Dim fill As Panel
	fill.Initialize("")
	RoundView(fill, modConfig.COLOR_ACCENT, 4dip)
	track.AddView(fill, 0, 0, fillW, 8dip)
	Return p
End Sub

Public Sub PlayerStatRowHeight As Int
	Return 72dip
End Sub

Public Sub EventCardHeight As Int
	Return 100dip
End Sub

Public Sub TimelineItemHeight(ev As Map) As Int
	Dim details As Map
	Dim dObj As Object = ev.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then
		details = dObj
	Else
		details.Initialize
	End If
	Dim etype As String = ev.GetDefault("type", "")
	If etype = "SUB" Or etype = "PLANNED_SUB" Then Return 130dip
	If etype = "GOAL" Then
		Dim assistId As String = details.GetDefault("assist", "")
		Dim assistUnknown As String = "" & details.GetDefault("assistUnknown", False)
		assistUnknown = assistUnknown.ToLowerCase
		If assistId <> "" Or assistUnknown = "true" Then Return 118dip
	End If
	If etype = "COMMENT" Or etype = "POSITION" Then
		Dim content As String = ev.GetDefault("content", "")
		Dim wrapAt As Int = 28
		If etype = "POSITION" Then wrapAt = 22
		If content.Length > 48 Then Return 128dip
		If content.Length > wrapAt Then Return 112dip
	End If
	Return 100dip
End Sub

' Text shown on a timeline card and on the shared image. Keys: typeLabel, minute, clock, main, line2, line2Color, mainWrap.
Public Sub TimelineLines(ev As Map, nameById As Map, sideNames As Map) As Map
	Dim details As Map
	Dim dObj As Object = ev.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then
		details = dObj
	Else
		details.Initialize
	End If
	Dim etype As String = ev.GetDefault("type", "EVENT")
	Dim minute As Int = details.GetDefault("minute", -1)
	Dim clock As String = details.GetDefault("clockTime", "")
	If clock = "" Then clock = FormatClock(ev.GetDefault("timestamp", DateTime.Now))
	Dim timeLabel As String = "--'"
	If minute >= 0 Then timeLabel = minute & "'"
	Dim mainText As String = ev.GetDefault("content", "")
	Dim line2Text As String = ""
	Dim line2Color As Int = 0xFF94A3B8
	Dim mainWrap As Boolean = False
	If etype = "GOAL" Then
		Dim team As String = details.GetDefault("team", "A")
		Dim ownGoal As Boolean = modLocal.IsOwnGoal(details)
		If ownGoal Then
			mainText = "Own goal"
			If team = "B" Then
				line2Text = SideLabel(sideNames, "A", "Our team")
			Else
				line2Text = SideLabel(sideNames, "B", "Opposition")
			End If
		Else If team = "B" Then
			mainText = SideLabel(sideNames, "B", "Opposition")
			line2Text = ""
		Else
			Dim scorerId As String = details.GetDefault("scorer", "")
			If scorerId <> "" And nameById.IsInitialized Then
				mainText = nameById.GetDefault(scorerId, mainText)
			End If
			Dim assistId As String = details.GetDefault("assist", "")
			Dim assistUnknown As String = "" & details.GetDefault("assistUnknown", False)
			assistUnknown = assistUnknown.ToLowerCase
			If assistId <> "" And nameById.IsInitialized Then
				line2Text = "Assist · " & nameById.GetDefault(assistId, "?")
			Else If assistUnknown = "true" Then
				line2Text = "Assist unknown"
			Else
				line2Text = SideLabel(sideNames, "A", "Our team")
				line2Color = 0xFF64748B
			End If
		End If
	Else If etype = "SUB" Or etype = "PLANNED_SUB" Then
		Dim outId As String = details.GetDefault("playerOut", "")
		Dim inId As String = details.GetDefault("playerIn", "")
		Dim outName As String = ResolveName(nameById, outId, "")
		Dim inName As String = ResolveName(nameById, inId, "")
		If outName = "" Or inName = "" Then
			Dim parsed As Map = ParseSubNames(mainText)
			If outName = "" Then outName = parsed.GetDefault("out", "?")
			If inName = "" Then inName = parsed.GetDefault("in", "?")
		End If
		mainText = "↓  " & outName
		line2Text = "↑  " & inName
		line2Color = modConfig.COLOR_SUCCESS
	Else If etype = "YELLOW_CARD" Or etype = "RED_CARD" Then
		Dim cardPid As String = details.GetDefault("player", "")
		mainText = ResolveName(nameById, cardPid, StripCardPrefix(mainText))
		mainWrap = True
	Else If etype = "CORNER" Or etype = "PENALTY" Then
		If details.GetDefault("team", "A") = "B" Then
			mainText = SideLabel(sideNames, "B", "Opposition")
		Else
			mainText = SideLabel(sideNames, "A", "Our team")
		End If
	Else If etype = "SHOOTOUT" Then
		If details.GetDefault("kind", "") = "setup" Then
			mainText = details.GetDefault("kicksEach", 0) & " each"
			If details.GetDefault("firstTeam", "A") = "B" Then
				line2Text = SideLabel(sideNames, "B", "Opposition") & " start"
			Else
				line2Text = SideLabel(sideNames, "A", "Our team") & " start"
			End If
		Else
			If details.GetDefault("team", "A") = "B" Then
				mainText = SideLabel(sideNames, "B", "Opposition")
			Else
				Dim takerId As String = details.GetDefault("player", "")
				mainText = ResolveName(nameById, takerId, SideLabel(sideNames, "A", "Our team"))
			End If
			If modLocal.IsFlag(details, "scored") Then
				line2Text = "Scored"
				line2Color = modConfig.COLOR_SUCCESS
			Else
				line2Text = "Missed"
				line2Color = modConfig.COLOR_DANGER
			End If
		End If
	Else If etype = "COMMENT" Or etype = "POSITION" Then
		mainWrap = True
	Else
		mainWrap = (mainText.Length > 22)
	End If
	Dim typeLabel As String = FriendlyType(etype)
	If etype = "SHOOTOUT" And details.GetDefault("kind", "") <> "setup" And modLocal.IsFlag(details, "suddenDeath") Then
		typeLabel = "SUDDEN DEATH"
	End If
	If etype = "PLANNED_SUB" And modLocal.IsFlag(details, "due") Then typeLabel = "DUE"
	Dim out As Map
	out.Initialize
	out.Put("typeLabel", typeLabel)
	out.Put("minute", timeLabel)
	out.Put("clock", clock)
	out.Put("main", mainText)
	out.Put("line2", line2Text)
	out.Put("line2Color", line2Color)
	out.Put("mainWrap", mainWrap)
	Return out
End Sub

' Timeline row: rail + node + dark card. nameById used for goal scorer/assist lines.
Public Sub CreateTimelineItem(Width As Int, ev As Map, nameById As Map, sideNames As Map, isFirst As Boolean, isLast As Boolean) As Panel
	Dim h As Int = TimelineItemHeight(ev)
	Dim railW As Int = 28dip
	Dim row As Panel
	row.Initialize("")
	row.Color = 0xFF0F172A
	Dim lineColor As Int = 0xFF334155
	If isFirst = False Then
		Dim lineTop As Panel
		lineTop.Initialize("")
		lineTop.Color = lineColor
		row.AddView(lineTop, railW / 2 - 1dip, 0, 2dip, h / 2 - 5dip)
	End If
	If isLast = False Then
		Dim lineBot As Panel
		lineBot.Initialize("")
		lineBot.Color = lineColor
		row.AddView(lineBot, railW / 2 - 1dip, h / 2 + 5dip, 2dip, h / 2 - 5dip)
	End If
	Dim etype As String = ev.GetDefault("type", "EVENT")
	Dim lines As Map = TimelineLines(ev, nameById, sideNames)
	Dim nodeCol As Int = TypeColor(etype)
	If lines.GetDefault("typeLabel", "") = "SUDDEN DEATH" Or lines.GetDefault("typeLabel", "") = "DUE" Then nodeCol = 0xFFF97316
	Dim node As Panel
	node.Initialize("")
	RoundView(node, nodeCol, 8dip)
	row.AddView(node, railW / 2 - 7dip, h / 2 - 7dip, 14dip, 14dip)
	Dim cardW As Int = Width - railW - 4dip
	Dim card As Panel
	card.Initialize("")
	RoundView(card, 0xFF1E293B, 12dip)
	row.AddView(card, railW, 4dip, cardW, h - 8dip)
	Dim accent As Panel
	accent.Initialize("")
	accent.Color = nodeCol
	card.AddView(accent, 0, 0, 4dip, h - 8dip)
	Dim lblMin As Label
	lblMin.Initialize("")
	lblMin.Text = lines.Get("minute")
	SetTextSize(lblMin, 15)
	lblMin.TextColor = modConfig.COLOR_ACCENT
	SetBold(lblMin, True)
	SetAlign(lblMin, "CENTER", "CENTER")
	card.AddView(lblMin, 10dip, 10dip, 44dip, 24dip)
	Dim lblClock As Label
	lblClock.Initialize("")
	lblClock.Text = lines.Get("clock")
	SetTextSize(lblClock, 11)
	lblClock.TextColor = 0xFF94A3B8
	SetAlign(lblClock, "CENTER", "CENTER")
	card.AddView(lblClock, 10dip, 36dip, 44dip, 16dip)
	Dim textLeft As Int = 58dip
	' Leave room for the buttons overlaid on the right of the row.
	Dim reserve As Int = 88dip
	If etype = "PLANNED_SUB" Then reserve = 96dip
	Dim textW As Int = cardW - textLeft - reserve
	If textW < 80dip Then textW = 80dip
	Dim lblType As Label
	lblType.Initialize("")
	lblType.Text = lines.Get("typeLabel")
	SetTextSize(lblType, 10)
	lblType.TextColor = nodeCol
	SetBold(lblType, True)
	card.AddView(lblType, textLeft, 8dip, textW, 16dip)
	
	Dim mainText As String = lines.Get("main")
	Dim line2Text As String = lines.Get("line2")
	Dim line2Color As Int = lines.Get("line2Color")
	Dim mainWrap As Boolean = lines.Get("mainWrap")
	
	Dim mainH As Int = 22dip
	If etype = "SUB" Or etype = "PLANNED_SUB" Then
		mainH = 24dip
		mainWrap = True
	Else If mainWrap Then
		If h >= 120dip Then
			mainH = 44dip
		Else If h >= 108dip Then
			mainH = 34dip
		End If
	End If
	Dim lblMain As Label
	lblMain.Initialize("")
	lblMain.Text = mainText
	SetTextSize(lblMain, 14)
	lblMain.TextColor = Colors.White
	SetBold(lblMain, True)
	SetSingleLine(lblMain, Not(mainWrap))
	If mainWrap Then
		SetAlign(lblMain, "TOP", "LEFT")
	End If
	card.AddView(lblMain, textLeft, 28dip, textW, mainH)
	
	If line2Text <> "" Then
		Dim lbl2 As Label
		lbl2.Initialize("")
		lbl2.Text = line2Text
		SetTextSize(lbl2, 14)
		SetBold(lbl2, True)
		If etype = "SUB" Or etype = "PLANNED_SUB" Then
			lbl2.TextColor = 0xFF4ADE80
			SetSingleLine(lbl2, False)
			SetAlign(lbl2, "TOP", "LEFT")
			lblMain.TextColor = 0xFFF87171
			card.AddView(lbl2, textLeft, 56dip, textW, 28dip)
		Else
			SetTextSize(lbl2, 12)
			SetBold(lbl2, False)
			lbl2.TextColor = line2Color
			SetSingleLine(lbl2, True)
			card.AddView(lbl2, textLeft, 52dip, textW, 18dip)
		End If
	End If
	Return row
End Sub

Private Sub SideLabel(sideNames As Map, team As String, fallback As String) As String
	If sideNames.IsInitialized And sideNames.ContainsKey(team) Then
		Dim n As String = ("" & sideNames.Get(team)).Trim
		If n <> "" And n <> "null" Then Return n
	End If
	Return fallback
End Sub

Private Sub ResolveName(nameById As Map, playerId As String, fallback As String) As String
	If playerId <> "" And nameById.IsInitialized And nameById.ContainsKey(playerId) Then
		Return nameById.Get(playerId)
	End If
	Return fallback
End Sub

' Best-effort parse of legacy "Substitution: A → B" content.
Private Sub ParseSubNames(content As String) As Map
	Dim m As Map
	m.Initialize
	m.Put("out", "")
	m.Put("in", "")
	Dim s As String = content
	Dim low As String = s.ToLowerCase
	If low.StartsWith("substitution:") Then s = s.SubString(13).Trim
	Dim arrow As Int = s.IndexOf("→")
	Dim arrowLen As Int = 1
	If arrow < 0 Then
		arrow = s.IndexOf("->")
		arrowLen = 2
	End If
	If arrow < 0 Then Return m
	m.Put("out", s.SubString2(0, arrow).Trim)
	m.Put("in", s.SubString(arrow + arrowLen).Trim)
	Return m
End Sub

Private Sub StripCardPrefix(content As String) As String
	Dim s As String = content.Trim
	Dim low As String = s.ToLowerCase
	If low.StartsWith("yellow card:") Then Return s.SubString(12).Trim
	If low.StartsWith("red card:") Then Return s.SubString(9).Trim
	Return s
End Sub

Private Sub FriendlyType(etype As String) As String
	Select etype
		Case "GOAL"
			Return "GOAL"
		Case "YELLOW_CARD"
			Return "YELLOW CARD"
		Case "RED_CARD"
			Return "RED CARD"
		Case "HALF_TIME"
			Return "HALF TIME"
		Case "SECOND_HALF"
			Return "2ND HALF"
		Case "START"
			Return "KICK-OFF"
		Case "END"
			Return "FULL TIME"
		Case "SUB"
			Return "SUBSTITUTION"
		Case "PLANNED_SUB"
			Return "PLANNED SUB"
		Case "POSITION"
			Return "POSITION CHANGE"
		Case "COMMENT"
			Return "COMMENTARY"
		Case "CORNER"
			Return "CORNER"
		Case "PENALTY"
			Return "PENALTY"
		Case "SHOOTOUT"
			Return "SHOOTOUT"
		Case Else
			Return etype
	End Select
End Sub

Public Sub CreateIconButton(callback As Object, EventName As String, glyph As String, bgColor As Int, tag As Object) As Button
	Dim b As Button
	InitButton(callback, b, EventName)
	b.Text = glyph
	SetTextSize(b, 16)
	SetBold(b, True)
	SetButtonTextColor(b, Colors.White)
	b.Color = bgColor
	SetAlign(b, "CENTER", "CENTER")
#if B4A
	b.Padding = Array As Int(0, 0, 0, 0)
#End If
	b.Tag = tag
	Return b
End Sub

Private Sub TypeColor(etype As String) As Int
	Select etype
		Case "GOAL"
			Return modConfig.COLOR_SUCCESS
		Case "YELLOW_CARD"
			Return 0xFFF59E0B
		Case "RED_CARD"
			Return modConfig.COLOR_DANGER
		Case "SUB", "PLANNED_SUB"
			Return modConfig.COLOR_ACCENT
		Case "POSITION"
			Return 0xFF2DD4BF
		Case "HALF_TIME", "SECOND_HALF"
			Return 0xFFFB923C
		Case "START", "END"
			Return 0xFF38BDF8
		Case "COMMENT"
			Return 0xFF6366F1
		Case "CORNER"
			Return 0xFF14B8A6
		Case "PENALTY", "SHOOTOUT"
			Return 0xFFA855F7
		Case Else
			Return 0xFF94A3B8
	End Select
End Sub

Private Sub FormatClock(ts As Object) As String
	Try
		Dim ms As Long = ts
		DateTime.TimeFormat = "HH:mm"
		Return DateTime.Time(ms)
	Catch
		Return "--:--"
	End Try
End Sub

Public Sub CreateMinutesRow(Width As Int, name As String, matchMins As Int, seasonMins As Int) As Panel
	Return CreateMinutesRowThemed(Width, name, matchMins, seasonMins, False)
End Sub

Public Sub CreateMinutesRowThemed(Width As Int, name As String, matchMins As Int, seasonMins As Int, Dark As Boolean) As Panel
	Dim p As Panel
	p.Initialize("")
	Dim bg As Int = modConfig.COLOR_CARD
	Dim nameCol As Int = modConfig.COLOR_PRIMARY
	Dim mutedCol As Int = modConfig.COLOR_MUTED
	If Dark Then
		bg = modConfig.COLOR_DARK_CARD
		nameCol = modConfig.COLOR_DARK_TEXT
		mutedCol = modConfig.COLOR_DARK_MUTED
	End If
	RoundView(p, bg, 10dip)
	Dim lblN As Label
	lblN.Initialize("")
	lblN.Text = name
	SetTextSize(lblN, 13)
	lblN.TextColor = nameCol
	SetBold(lblN, True)
	SetSingleLine(lblN, True)
	p.AddView(lblN, 12dip, 8dip, Width * 0.42, 22dip)
	Dim lblM As Label
	lblM.Initialize("")
	lblM.Text = matchMins & "' game"
	SetTextSize(lblM, 12)
	lblM.TextColor = modConfig.COLOR_ACCENT
	p.AddView(lblM, Width * 0.42, 8dip, Width * 0.28, 22dip)
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = seasonMins & "' season"
	SetTextSize(lblS, 12)
	lblS.TextColor = mutedCol
	p.AddView(lblS, Width * 0.70, 8dip, Width * 0.28 - 8dip, 22dip)
	Return p
End Sub

Public Sub MinutesRowHeight As Int
	Return 40dip
End Sub


Public Sub PlayerCardHeight As Int
	Return 88dip
End Sub

Public Sub HubNavCardHeight As Int
	Return 72dip
End Sub

Public Sub AvatarSize As Int
	Return 52dip
End Sub

' Initials for avatar placeholder (e.g. "JD").
Public Sub PlayerInitials(name As String) As String
	Dim n As String = name.Trim
	If n = "" Then Return "?"
	Dim parts() As String = Regex.Split("\s+", n)
	If parts.Length >= 2 Then
		Dim a As String = parts(0)
		Dim b As String = parts(parts.Length - 1)
		If a.Length > 0 And b.Length > 0 Then
			Return a.SubString2(0, 1).ToUpperCase & b.SubString2(0, 1).ToUpperCase
		End If
	End If
	If n.Length >= 2 Then Return n.SubString2(0, 2).ToUpperCase
	Return n.ToUpperCase
End Sub

' Stable accent tint from a name (avatar ring / fill).
Public Sub AvatarColorForName(name As String) As Int
	Dim palette() As Int = Array As Int(0xFF3B82F6, 0xFF10B981, 0xFFF59E0B, 0xFF8B5CF6, 0xFFEC4899, 0xFF06B6D4, 0xFFEF4444, 0xFF84CC16)
	Dim h As Int = 0
	Dim i As Int
	For i = 0 To name.Length - 1
		h = (h * 31 + Asc(name.CharAt(i))) Mod 997
	Next
	If h < 0 Then h = -h
	Return palette(h Mod palette.Length)
End Sub

' availabilityStatus: CONFIRMED / UNAVAILABLE / UNKNOWN (or empty)
' card.Tag = ImageView (may have Tag = avatar URL) for async photo load.
Public Sub CreatePlayerCard(Width As Int, member As Map, availabilityStatus As String, isStar As Boolean) As Panel
	Return CreatePlayerCardThemed(Width, member, availabilityStatus, isStar, True)
End Sub

Public Sub CreatePlayerCardThemed(Width As Int, member As Map, availabilityStatus As String, isStar As Boolean, Dark As Boolean) As Panel
	Dim card As Panel
	card.Initialize("")
	Dim cardBg As Int = modConfig.COLOR_CARD
	Dim nameColor As Int = modConfig.COLOR_PRIMARY
	Dim mutedColor As Int = modConfig.COLOR_MUTED
	Dim chipBg As Int = modConfig.COLOR_CHIP
	If Dark Then
		cardBg = modConfig.COLOR_DARK_CARD
		nameColor = modConfig.COLOR_DARK_TEXT
		mutedColor = modConfig.COLOR_DARK_MUTED
		chipBg = modConfig.COLOR_DARK_CHIP
	End If
	RoundView(card, cardBg, 14dip)
	
	Dim name As String = member.GetDefault("name", "Player")
	Dim pos As String = member.GetDefault("preferredPosition", member.GetDefault("favPosition", ""))
	If pos = "" Then pos = "Position TBD"
	Dim numObj As Object = member.GetDefault("squadNumber", 0)
	Dim numStr As String = ""
	
	Dim statusLabel As String = AvailabilityLabel(availabilityStatus)
	Dim statusColor As Int = AvailabilityColor(availabilityStatus, Dark)
	
	Dim avSize As Int = AvatarSize
	Dim avLeft As Int = 12dip
	Dim avTop As Int = (PlayerCardHeight - avSize) / 2
	Dim textLeft As Int = avLeft + avSize + 12dip
	Dim pillW As Int = 56dip
	Dim editW As Int = 40dip
	Dim gap As Int = 10dip
	Dim rightPad As Int = 12dip
	Dim pillLeft As Int = Width - rightPad - pillW
	Dim editLeft As Int = pillLeft - gap - editW
	Dim textW As Int = editLeft - textLeft - 8dip
	If textW < 80dip Then textW = 80dip
	
	Dim avColor As Int = AvatarColorForName(name)
	Dim avPanel As Panel
	avPanel.Initialize("")
	RoundView(avPanel, avColor, avSize / 2)
	card.AddView(avPanel, avLeft, avTop, avSize, avSize)
	ClipToOutline(avPanel)
	
	Dim lblInit As Label
	lblInit.Initialize("")
	lblInit.Text = PlayerInitials(name)
	SetTextSize(lblInit, 16)
	lblInit.TextColor = Colors.White
	SetBold(lblInit, True)
	SetAlign(lblInit, "CENTER", "CENTER")
	avPanel.AddView(lblInit, 0, 0, avSize, avSize)
	
	Dim iv As ImageView
	iv.Initialize("")
	SetImageFill(iv)
	Dim avatarUrl As String = member.GetDefault("avatar", "")
	iv.Tag = avatarUrl
	avPanel.AddView(iv, 0, 0, avSize, avSize)
	
	Dim numVal As Int = 0
	Try
		numVal = numObj
	Catch
		numVal = 0
	End Try
	If numVal > 0 Then
		numStr = "#" & numVal
		Dim numBadge As Panel
		numBadge.Initialize("")
		RoundView(numBadge, chipBg, 8dip)
		card.AddView(numBadge, avLeft + avSize - 18dip, avTop + avSize - 16dip, 22dip, 16dip)
		Dim lblNum As Label
		lblNum.Initialize("")
		lblNum.Text = numVal
		SetTextSize(lblNum, 9)
		lblNum.TextColor = nameColor
		SetBold(lblNum, True)
		SetAlign(lblNum, "CENTER", "CENTER")
		numBadge.AddView(lblNum, 0, 0, 22dip, 16dip)
	End If
	
	Dim nameLine As String = name
	If isStar Then nameLine = "★ " & name
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = nameLine
	SetTextSize(lblName, 15)
	lblName.TextColor = nameColor
	SetBold(lblName, True)
	SetSingleLine(lblName, True)
	card.AddView(lblName, textLeft, avTop + 4dip, textW, 24dip)
	
	Dim lblPos As Label
	lblPos.Initialize("")
	If numStr <> "" Then
		lblPos.Text = numStr & " · " & pos
	Else
		lblPos.Text = pos
	End If
	SetTextSize(lblPos, 12)
	lblPos.TextColor = mutedColor
	SetSingleLine(lblPos, True)
	card.AddView(lblPos, textLeft, avTop + 28dip, textW, 20dip)
	
	Dim pill As Panel
	pill.Initialize("")
	RoundView(pill, statusColor, 12dip)
	card.AddView(pill, pillLeft, (PlayerCardHeight - 28dip) / 2, pillW, 28dip)
	Dim lblSt As Label
	lblSt.Initialize("")
	lblSt.Text = statusLabel
	SetTextSize(lblSt, 11)
	lblSt.TextColor = Colors.White
	SetBold(lblSt, True)
	SetAlign(lblSt, "CENTER", "CENTER")
	pill.AddView(lblSt, 0, 0, pillW, 28dip)
	
	Dim meta As Map
	meta.Initialize
	meta.Put("iv", iv)
	meta.Put("statusPill", pill)
	meta.Put("statusLabel", lblSt)
	meta.Put("nameLabel", lblName)
	meta.Put("baseName", name)
	meta.Put("editLeft", editLeft)
	meta.Put("editTop", (PlayerCardHeight - 40dip) / 2)
	meta.Put("editW", editW)
	card.Tag = meta
	Return card
End Sub

' Round lineup-style spot. Panel.Tag is `tag`. Map keys: panel, imageView (uninitialized when there is no photo).
' displayName empty shows emptyLabel inside the circle (a free position or a chip such as "Own goal").
Public Sub CreateRoundPlayerSlot(Callback As Object, eventName As String, tag As Object, size As Int, displayName As String, avatarUrl As String, emptyLabel As String, selected As Boolean) As Map
	Dim wrap As Panel
	wrap.Initialize("")
	wrap.Color = Colors.Transparent
	wrap.Tag = tag
	Dim circle As Panel
	circle.Initialize("")
	Dim filled As Boolean = displayName <> ""
	If filled Then
		RoundView(circle, 0xFF0F172A, size / 2)
	Else
		RoundView(circle, Colors.ARGB(80, 0, 0, 0), size / 2)
	End If
	wrap.AddView(circle, 0, 0, size, size)
	ClipToOutline(circle)
	Dim ring As Panel
	ring.Initialize("")
	Dim ringCol As Int = Colors.White
	Dim ringW As Int = 2dip
	If selected Then
		ringCol = modConfig.COLOR_ACCENT
		ringW = 3dip
	Else If filled = False Then
		ringCol = Colors.ARGB(180, 255, 255, 255)
	End If
	RoundBorder(ring, Colors.Transparent, size / 2, ringW, ringCol)
	wrap.AddView(ring, 0, 0, size, size)
	Dim iv As ImageView
	Dim hasPhoto As Boolean = False
	If filled Then
		Dim initials As Label
		initials.Initialize("")
		initials.Text = PlayerInitials(displayName)
		SetTextSize(initials, 13)
		initials.TextColor = Colors.White
		SetBold(initials, True)
		SetAlign(initials, "CENTER", "CENTER")
		circle.AddView(initials, 0, 0, size, size)
		If avatarUrl <> "" Then
			iv.Initialize("")
			SetImageFill(iv)
			circle.AddView(iv, 0, 0, size, size)
			hasPhoto = True
		End If
		Dim lblName As Label
		lblName.Initialize("")
		lblName.Text = FirstToken(displayName)
		SetTextSize(lblName, 9)
		lblName.TextColor = Colors.White
		SetBold(lblName, True)
		SetAlign(lblName, "CENTER", "CENTER")
		SetSingleLine(lblName, True)
		wrap.AddView(lblName, -6dip, size + 1dip, size + 12dip, 14dip)
	Else
		Dim lblPos As Label
		lblPos.Initialize("")
		lblPos.Text = emptyLabel
		SetTextSize(lblPos, 9)
		lblPos.TextColor = Colors.White
		SetBold(lblPos, True)
		SetAlign(lblPos, "CENTER", "CENTER")
		SetSingleLine(lblPos, False)
		circle.AddView(lblPos, 4dip, 0, size - 8dip, size)
	End If
	Dim hit As Panel
	hit.Initialize(eventName)
	' A fully clear panel is skipped by hit testing.
	hit.Color = Colors.ARGB(1, 0, 0, 0)
	hit.Tag = tag
	EnableLongClick(hit, Callback, eventName)
	wrap.AddView(hit, -4dip, 0, size + 8dip, size + 16dip)
	Dim out As Map
	out.Initialize
	out.Put("panel", wrap)
	If hasPhoto Then out.Put("imageView", iv)
	Return out
End Sub

Private Sub FirstToken(fullName As String) As String
	Dim n As String = fullName.Trim
	If n = "" Then Return "?"
	Dim space As Int = n.IndexOf(" ")
	If space > 0 Then Return n.SubString2(0, space)
	Return n
End Sub

' Clip a view to its background outline (circular ColorDrawable → round avatar).
Public Sub ClipToOutline(v As View)
#if B4A
	Try
		Dim jo As JavaObject = v
		jo.RunMethod("setClipToOutline", Array(True))
	Catch
		Log("ClipToOutline: " & LastException.Message)
	End Try
#else if B4i
	Try
		Dim xv As B4XView = v
		Dim radius As Float = xv.Width / 2
		If radius < 1 Then radius = xv.Height / 2
		Dim no As NativeObject = v
		Dim layer As NativeObject = no.GetField("layer")
		layer.SetField("cornerRadius", radius)
		layer.SetField("masksToBounds", True)
	Catch
		Log("ClipToOutline: " & LastException.Message)
	End Try
#End If
End Sub

Public Sub AvailabilityLabel(status As String) As String
	If status = "CONFIRMED" Then Return "In"
	If status = "UNAVAILABLE" Then Return "Out"
	Return "Maybe"
End Sub

Public Sub AvailabilityColor(status As String, Dark As Boolean) As Int
	If status = "CONFIRMED" Then Return modConfig.COLOR_SUCCESS
	If status = "UNAVAILABLE" Then Return modConfig.COLOR_DANGER
	If Dark Then Return modConfig.COLOR_DARK_MUTED
	Return modConfig.COLOR_MUTED
End Sub

' Cycle: Maybe → In → Out → Maybe
Public Sub NextAvailability(status As String) As String
	If status = "CONFIRMED" Then Return "UNAVAILABLE"
	If status = "UNAVAILABLE" Then Return "UNKNOWN"
	Return "CONFIRMED"
End Sub

' In-place status update (avoids CLV rebuild flicker).
Public Sub UpdatePlayerCardAvailability(card As Panel, status As String)
	If (card.Tag Is Map) = False Then Return
	Dim meta As Map = card.Tag
	Dim pill As Panel = meta.Get("statusPill")
	Dim lblSt As Label = meta.Get("statusLabel")
	RoundView(pill, AvailabilityColor(status, True), 12dip)
	lblSt.Text = AvailabilityLabel(status)
End Sub

Public Sub UpdatePlayerCardStar(card As Panel, isStar As Boolean)
	If (card.Tag Is Map) = False Then Return
	Dim meta As Map = card.Tag
	Dim lblName As Label = meta.Get("nameLabel")
	Dim baseName As String = meta.GetDefault("baseName", "Player")
	If isStar Then
		lblName.Text = "★ " & baseName
	Else
		lblName.Text = baseName
	End If
End Sub

Public Sub PlayerCardImageView(card As Panel) As ImageView
	Dim iv As ImageView
	If card.Tag Is Map Then
		Dim meta As Map = card.Tag
		If meta.ContainsKey("iv") Then Return meta.Get("iv")
	Else If card.Tag Is ImageView Then
		Return card.Tag
	End If
	Return iv
End Sub

Public Sub CreateHubNavCard(Width As Int, title As String, subtitle As String, EventName As String) As Panel
	Dim card As Panel
	WirePanel(card, EventName, Null)
	RoundView(card, modConfig.COLOR_CARD, 14dip)
	
	Dim lblT As Label
	lblT.Initialize("")
	lblT.Text = title
	SetTextSize(lblT, 16)
	lblT.TextColor = modConfig.COLOR_PRIMARY
	SetBold(lblT, True)
	SetSingleLine(lblT, True)
	card.AddView(lblT, 16dip, 14dip, Width - 48dip, 24dip)
	
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = subtitle
	SetTextSize(lblS, 12)
	lblS.TextColor = modConfig.COLOR_MUTED
	SetSingleLine(lblS, True)
	card.AddView(lblS, 16dip, 40dip, Width - 48dip, 20dip)
	
	Dim chev As Label
	chev.Initialize("")
	chev.Text = ">"
	SetTextSize(chev, 18)
	chev.TextColor = modConfig.COLOR_ACCENT
	SetAlign(chev, "CENTER", "CENTER")
	card.AddView(chev, Width - 36dip, 18dip, 28dip, 36dip)
	Return card
End Sub

' Compact half-pitch for sub-plan quarter previews.
' minutesById: optional map playerId -> planned minutes; shown under each name when present.
' highlighted: accent border when this pitch is the selected swap break.
' layout: optional slotId -> {x,y} display percentages. Empty uses the formation.
' EventName: when set, a long-press raises that event on the calling page.
' The marker tag is a map with slotId and quarter. holdSlotId draws an accent ring.
Public Sub CreatePitchPanel(Width As Int, Height As Int, formation As String, lineupMap As Map, _
		nameById As Map, minutesById As Map, highlighted As Boolean, layout As Map, _
		Callback As Object, EventName As String, quarter As Int, holdSlotId As String) As Panel
	Dim wrap As Panel
	wrap.Initialize("")
	wrap.Color = Colors.Transparent
	
	Dim borderCol As Int = Colors.ARGB(180, 22, 101, 52)
	If highlighted Then borderCol = modConfig.COLOR_ACCENT
	Dim borderW As Int = 2dip
	If highlighted Then borderW = 3dip
	
	Dim pitch As Panel
	pitch.Initialize("")
	pitch.Color = 0xFF15803D
	RoundBorder(pitch, 0xFF15803D, 12dip, borderW, borderCol)
	wrap.AddView(pitch, 0, 0, Width, Height)
	
	PaintPitchMarkings(pitch)
	
	Dim slotSize As Int = Max(26dip, Min(36dip, Width / 8))
	Dim positions As List = modFormations.GetPositions(formation)
	If positions.IsInitialized = False Then
		positions.Initialize
	End If
	Dim minsOk As Boolean = minutesById.IsInitialized And minutesById.Size > 0
	Dim namesOk As Boolean = nameById.IsInitialized
	Dim i As Int
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		Dim posId As String = p.GetDefault("id", "")
		Dim spread As Map = modFormations.DisplaySlot(p, layout)
		Dim xPct As Float = spread.Get("x")
		Dim yPct As Float = spread.Get("y")
		Dim origin As Map = PitchSlotLeftTop(Width, Height, slotSize, xPct, yPct)
		Dim left As Int = origin.Get("left")
		Dim top As Int = origin.Get("top")
		
		Dim playerId As String = ""
		If lineupMap.IsInitialized Then playerId = lineupMap.GetDefault(posId, "")
		Dim mins As Int = -1
		If minsOk And playerId <> "" Then mins = minutesById.GetDefault(playerId, -1)
		Dim nm As String = ""
		If namesOk And playerId <> "" Then nm = nameById.GetDefault(playerId, "?")
		Dim slotHeld As Boolean = holdSlotId <> "" And posId = holdSlotId
		Dim slot As Panel = CreateCompactPitchSlot(slotSize, p.GetDefault("label", ""), playerId, nm, mins, _
			Callback, EventName, quarter, posId, slotHeld)
		pitch.AddView(slot, left, top, slotSize, slotSize + 18dip)
	Next
	Return wrap
End Sub

' Top-left of a marker so the circle stays inside the pitch. Matches CreatePitchPanel.
Public Sub PitchSlotLeftTop(pitchW As Int, pitchH As Int, slotSize As Int, xPct As Float, yPct As Float) As Map
	Dim left As Int = pitchW * xPct / 100 - slotSize / 2
	Dim top As Int = pitchH * yPct / 100 - slotSize / 2
	If left < 2dip Then left = 2dip
	If top < 2dip Then top = 2dip
	If left + slotSize > pitchW - 2dip Then left = pitchW - slotSize - 2dip
	If top + slotSize > pitchH - 4dip Then top = pitchH - slotSize - 4dip
	Dim m As Map
	m.Initialize
	m.Put("left", left)
	m.Put("top", top)
	Return m
End Sub

' Clamp a finger point (pitch-local) to a marker center, returned as display percentages.
Public Sub ClampSlotCenter(pitchW As Int, pitchH As Int, slotSize As Int, cx As Float, cy As Float) As Map
	Dim half As Float = slotSize / 2
	Dim minX As Float = 2dip + half
	Dim maxX As Float = pitchW - 2dip - half
	Dim minY As Float = 2dip + half
	Dim maxY As Float = pitchH - 4dip - half
	If maxX < minX Then
		minX = pitchW / 2
		maxX = minX
	End If
	If maxY < minY Then
		minY = pitchH / 2
		maxY = minY
	End If
	If cx < minX Then cx = minX
	If cx > maxX Then cx = maxX
	If cy < minY Then cy = minY
	If cy > maxY Then cy = maxY
	Dim m As Map
	m.Initialize
	If pitchW <= 0 Then
		m.Put("x", 50)
	Else
		m.Put("x", cx / pitchW * 100)
	End If
	If pitchH <= 0 Then
		m.Put("y", 50)
	Else
		m.Put("y", cy / pitchH * 100)
	End If
	Return m
End Sub

Public Sub CompactPitchHeight(Width As Int) As Int
	Dim h As Int = Width * 0.92
	If h < 180dip Then h = 180dip
	If h > 260dip Then h = 260dip
	Return h
End Sub

' Shared pitch markings (half-pitch, green stripes, box).
Public Sub PaintPitchMarkings(pitch As Panel)
	Dim lineCol As Int = Colors.ARGB(140, 255, 255, 255)
	Dim cvs As Canvas
	If pitch.IsInitialized = False Or pitch.Width < 2dip Or pitch.Height < 2dip Then Return
	cvs.Initialize(pitch)
	
	Dim stripeW As Float = pitch.Width / 10
	Dim s As Int
	For s = 1 To 9 Step 2
		Dim r As Rect
		r.Initialize(s * stripeW, 0, (s + 1) * stripeW, pitch.Height)
		cvs.DrawRect(r, Colors.ARGB(28, 255, 255, 255), True, 0)
	Next
	
	cvs.DrawLine(0, 1dip, pitch.Width, 1dip, lineCol, 2dip)
	
	Dim arcR As Float = Min(pitch.Width * 0.12, 36dip)
	cvs.DrawCircle(pitch.Width / 2, 0, arcR, lineCol, False, 2dip)
	
	Dim penW As Float = pitch.Width * 0.44
	Dim penH As Float = pitch.Height * 0.20
	Dim penLeft As Float = (pitch.Width - penW) / 2
	Dim pen As Rect
	pen.Initialize(penLeft, pitch.Height - penH, penLeft + penW, pitch.Height)
	cvs.DrawRect(pen, lineCol, False, 2dip)
	
	Dim sixW As Float = pitch.Width * 0.24
	Dim sixH As Float = pitch.Height * 0.09
	Dim sixLeft As Float = (pitch.Width - sixW) / 2
	Dim six As Rect
	six.Initialize(sixLeft, pitch.Height - sixH, sixLeft + sixW, pitch.Height)
	cvs.DrawRect(six, lineCol, False, 2dip)
	
	Dim goalW As Float = pitch.Width * 0.12
	Dim goalLeft As Float = (pitch.Width - goalW) / 2
	cvs.DrawLine(goalLeft, pitch.Height - 2dip, goalLeft + goalW, pitch.Height - 2dip, lineCol, 3dip)
#if B4i
	cvs.Refresh
	cvs.Release
#End If
End Sub

Private Sub CreateCompactPitchSlot(slotSize As Int, posLabel As String, playerId As String, playerName As String, mins As Int, _
		Callback As Object, EventName As String, quarter As Int, posId As String, slotHeld As Boolean) As Panel
	Dim wrap As Panel
	wrap.Initialize("")
	wrap.Color = Colors.Transparent
	
	Dim circle As Panel
	circle.Initialize("")
	Dim filled As Boolean = playerId <> ""
	If filled Then
		RoundView(circle, 0xFF0F172A, slotSize / 2)
	Else
		RoundView(circle, Colors.ARGB(70, 0, 0, 0), slotSize / 2)
	End If
	wrap.AddView(circle, 0, 0, slotSize, slotSize)
	ClipToOutline(circle)
	
	Dim ring As Panel
	ring.Initialize("")
	Dim ringCol As Int = Colors.White
	Dim ringW As Int = 2dip
	If slotHeld Then
		ringCol = modConfig.COLOR_ACCENT
		ringW = 3dip
	Else If filled = False Then
		ringCol = Colors.ARGB(180, 255, 255, 255)
	End If
	RoundBorder(ring, Colors.Transparent, slotSize / 2, ringW, ringCol)
	wrap.AddView(ring, 0, 0, slotSize, slotSize)
	
	If filled Then
		Dim initials As Label
		initials.Initialize("")
		initials.Text = PlayerInitials(playerName)
		SetTextSize(initials, 10)
		initials.TextColor = Colors.White
		SetBold(initials, True)
		SetAlign(initials, "CENTER", "CENTER")
		circle.AddView(initials, 0, 0, slotSize, slotSize)
		
		Dim caption As String = FirstNameOf(playerName)
		If mins >= 0 Then caption = caption & " " & mins & "'"
		Dim lblName As Label
		lblName.Initialize("")
		lblName.Text = caption
		SetTextSize(lblName, 8)
		lblName.TextColor = Colors.White
		SetBold(lblName, True)
		SetAlign(lblName, "CENTER", "CENTER")
		SetSingleLine(lblName, True)
		wrap.AddView(lblName, -10dip, slotSize, slotSize + 20dip, 16dip)
	Else
		Dim lblPos As Label
		lblPos.Initialize("")
		lblPos.Text = posLabel
		SetTextSize(lblPos, 9)
		lblPos.TextColor = Colors.ARGB(230, 255, 255, 255)
		SetBold(lblPos, True)
		SetAlign(lblPos, "CENTER", "CENTER")
		circle.AddView(lblPos, 0, 0, slotSize, slotSize)
	End If
	If EventName <> "" And Callback <> Null Then
		Dim hit As Panel
		' The event is registered on the caller (the page), not this module.
		WirePanel(hit, EventName, Callback)
		' A fully clear panel is skipped by hit testing.
		hit.Color = Colors.ARGB(1, 0, 0, 0)
		Dim info As Map
		info.Initialize
		info.Put("slotId", posId)
		info.Put("quarter", quarter)
		hit.Tag = info
		EnableLongClick(hit, Callback, EventName)
		wrap.AddView(hit, 0, 0, slotSize, slotSize + 18dip)
	End If
	Return wrap
End Sub

Private Sub FirstNameOf(full As String) As String
	Dim n As String = full.Trim
	If n = "" Then Return "?"
	Dim parts() As String = Regex.Split("\s+", n)
	Return parts(0)
End Sub

#If JAVA
public static void holdForLongPress(android.view.View view) {
	view.setOnTouchListener(new android.view.View.OnTouchListener() {
		public boolean onTouch(android.view.View v, android.view.MotionEvent event) {
			if (event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
				android.view.ViewParent parent = v.getParent();
				if (parent != null) parent.requestDisallowInterceptTouchEvent(true);
			}
			return false;
		}
	});
}
#End If

