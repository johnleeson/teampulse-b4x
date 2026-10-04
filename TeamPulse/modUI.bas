B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Shared UI helpers — CLV creation + match/hub cards (programmatic, no Designer).

Sub Process_Globals
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

Public Sub StyleEditText(edt As EditText, hint As String)
	edt.Hint = hint
	edt.Color = modConfig.COLOR_CARD
	edt.TextColor = modConfig.COLOR_PRIMARY
	edt.HintColor = modConfig.COLOR_MUTED
	edt.TextSize = 15
	edt.SingleLine = True
End Sub

Public Sub StyleEditTextDark(edt As EditText, hint As String)
	edt.Hint = hint
	edt.Color = modConfig.COLOR_DARK_CARD
	edt.TextColor = modConfig.COLOR_DARK_TEXT
	edt.HintColor = modConfig.COLOR_DARK_MUTED
	edt.TextSize = 15
	edt.SingleLine = True
End Sub

Public Sub RoundedBg(color As Int, radius As Int) As ColorDrawable
	Dim cd As ColorDrawable
	cd.Initialize(color, radius)
	Return cd
End Sub

' Standard top bar height (back + title + optional action).
Public Sub PageChromeHeight As Int
	Return 56dip
End Sub

' Consistent chrome: ← on the left, title beside it, optional trailing glyph button on the right.
' Returns Map: ContentTop (Int), TitleLabel (Label).
Public Sub AddPageChrome(Root As B4XView, Title As String, BackEvent As String, _
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
	
	Dim left As Int = 4dip
	If BackEvent <> "" Then
		Dim btnBack As Button = CreateChromeIconButton(BackEvent, "←", Colors.Transparent, btnFg)
		btnBack.TextSize = 26
		Root.AddView(btnBack, left, 6dip, 44dip, 44dip)
		left = left + 44dip
	End If
	
	Dim rightPad As Int = 12dip
	If ActionEvent <> "" Then
		Dim btnAct As Button = CreateChromeIconButton(ActionEvent, ActionGlyph, actionBg, Colors.White)
		btnAct.TextSize = 22
		Root.AddView(btnAct, Root.Width - 52dip, 10dip, 40dip, 36dip)
		rightPad = 60dip
	End If
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = Title
	lblTitle.TextSize = 20
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.TextColor = titleCol
	lblTitle.Gravity = Gravity.CENTER_VERTICAL
	lblTitle.SingleLine = True
	Root.AddView(lblTitle, left, 10dip, Root.Width - left - rightPad, 36dip)
	
	Dim out As Map
	out.Initialize
	out.Put("ContentTop", PageChromeHeight)
	out.Put("TitleLabel", lblTitle)
	Return out
End Sub

Public Sub CreateChromeIconButton(EventName As String, glyph As String, bgColor As Int, fgColor As Int) As Button
	Dim b As Button
	b.Initialize(EventName)
	b.Text = glyph
	b.TextSize = 18
	b.Typeface = Typeface.DEFAULT_BOLD
	b.TextColor = fgColor
	If bgColor = Colors.Transparent Then
		Dim cd As ColorDrawable
		cd.Initialize(Colors.Transparent, 0)
		b.Background = cd
	Else
		b.Color = bgColor
	End If
	b.Gravity = Gravity.CENTER
	b.Padding = Array As Int(0, 0, 0, 0)
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
	If EventName = "" Then
		card.Initialize("")
	Else
		card.Initialize(EventName)
	End If
	card.Background = RoundedBg(cardBg, 12dip)
	
	Dim dateStr As String = match.GetDefault("date", "")
	Dim monthTxt As String = MonthAbbrFromDate(dateStr)
	Dim dayTxt As String = DayFromDate(dateStr)
	
	Dim chip As Panel
	chip.Initialize("")
	chip.Background = RoundedBg(chipBg, 10dip)
	card.AddView(chip, 10dip, 14dip, 58dip, 64dip)
	
	Dim lblDate As Label
	lblDate.Initialize("")
	lblDate.Text = monthTxt & " " & dayTxt
	lblDate.TextSize = 12
	lblDate.TextColor = chipFg
	lblDate.Gravity = Gravity.CENTER
	lblDate.Typeface = Typeface.DEFAULT_BOLD
	chip.AddView(lblDate, 2dip, 0, 54dip, 64dip)
	
	Dim midLeft As Int = 78dip
	Dim midW As Int = Width - midLeft - 16dip
	If status = "LIVE" Then midW = Width - midLeft - 72dip
	
	If status = "CANCELLED" And Dark = False Then titleColor = modConfig.COLOR_MUTED
	If status = "CANCELLED" And Dark Then titleColor = modConfig.COLOR_DARK_MUTED
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = match.GetDefault("title", "Match")
	lblTitle.TextSize = 15
	lblTitle.TextColor = titleColor
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.Gravity = Gravity.CENTER_VERTICAL
	lblTitle.SingleLine = True
	card.AddView(lblTitle, midLeft, 10dip, midW, 24dip)
	
	Dim loc As String = match.GetDefault("location", "")
	If loc = "" Then loc = "TBC"
	Dim lblLoc As Label
	lblLoc.Initialize("")
	lblLoc.Text = loc
	lblLoc.TextSize = 12
	lblLoc.TextColor = mutedColor
	lblLoc.SingleLine = True
	card.AddView(lblLoc, midLeft, 36dip, midW, 18dip)
	
	Dim meta As String = BuildMatchMeta(match, status)
	Dim lblMeta As Label
	lblMeta.Initialize("")
	lblMeta.Text = meta
	lblMeta.TextSize = 12
	lblMeta.TextColor = mutedColor
	If status = "LIVE" Then lblMeta.TextColor = modConfig.COLOR_LIVE
	lblMeta.SingleLine = True
	card.AddView(lblMeta, midLeft, 56dip, midW, 18dip)
	
	If status = "LIVE" Then
		Dim badge As Panel
		badge.Initialize("")
		badge.Background = RoundedBg(modConfig.COLOR_LIVE, 8dip)
		card.AddView(badge, Width - 64dip, 14dip, 50dip, 22dip)
		Dim lblLive As Label
		lblLive.Initialize("")
		lblLive.Text = "LIVE"
		lblLive.TextSize = 10
		lblLive.TextColor = Colors.White
		lblLive.Typeface = Typeface.DEFAULT_BOLD
		lblLive.Gravity = Gravity.CENTER
		badge.AddView(lblLive, 0, 0, 50dip, 22dip)
	End If
	
	Return card
End Sub

Public Sub CreateLiveBanner(Width As Int, match As Map, EventName As String) As Panel
	Dim banner As Panel
	If EventName = "" Then
		banner.Initialize("")
	Else
		banner.Initialize(EventName)
	End If
	banner.Background = RoundedBg(modConfig.COLOR_LIVE, 12dip)
	
	Dim lblPill As Label
	lblPill.Initialize("")
	lblPill.Text = "LIVE NOW"
	lblPill.TextSize = 10
	lblPill.TextColor = Colors.White
	lblPill.Typeface = Typeface.DEFAULT_BOLD
	lblPill.Gravity = Gravity.CENTER_VERTICAL
	banner.AddView(lblPill, 14dip, 8dip, 100dip, 16dip)
	
	Dim lblTitle As Label
	lblTitle.Initialize("")
	lblTitle.Text = match.GetDefault("title", "Match")
	lblTitle.TextSize = 15
	lblTitle.TextColor = Colors.White
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.SingleLine = True
	banner.AddView(lblTitle, 14dip, 26dip, Width - 100dip, 22dip)
	
	Dim score As String = match.GetDefault("scoreA", 0) & " - " & match.GetDefault("scoreB", 0)
	Dim lblScore As Label
	lblScore.Initialize("")
	lblScore.Text = score
	lblScore.TextSize = 20
	lblScore.TextColor = Colors.White
	lblScore.Typeface = Typeface.DEFAULT_BOLD
	lblScore.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.RIGHT)
	banner.AddView(lblScore, Width - 90dip, 18dip, 76dip, 36dip)
	
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
	lbl.TextSize = 11
	If Dark Then
		lbl.TextColor = modConfig.COLOR_DARK_MUTED
	Else
		lbl.TextColor = modConfig.COLOR_MUTED
	End If
	lbl.Typeface = Typeface.DEFAULT_BOLD
	lbl.Gravity = Gravity.CENTER_VERTICAL
	p.AddView(lbl, 4dip, 0, Width - 8dip, SectionHeaderHeight)
	Return p
End Sub

' header=True → non-clickable section-style; else tappable row when EventName set.
Public Sub CreateSimpleRow(Width As Int, text As String, EventName As String) As Panel
	Return CreateSimpleRowThemed(Width, text, EventName, False)
End Sub

Public Sub CreateSimpleRowThemed(Width As Int, text As String, EventName As String, Dark As Boolean) As Panel
	Dim p As Panel
	If EventName = "" Then
		p.Initialize("")
	Else
		p.Initialize(EventName)
	End If
	Dim bg As Int = modConfig.COLOR_CARD
	Dim fg As Int = modConfig.COLOR_PRIMARY
	If Dark Then
		bg = modConfig.COLOR_DARK_CARD
		fg = modConfig.COLOR_DARK_TEXT
	End If
	p.Background = RoundedBg(bg, 10dip)
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 14
	lbl.TextColor = fg
	lbl.Gravity = Gravity.CENTER_VERTICAL
	lbl.SingleLine = True
	p.AddView(lbl, 14dip, 0, Width - 28dip, SimpleRowHeight)
	Return p
End Sub

Private Sub BuildMatchMeta(match As Map, status As String) As String
	Dim kick As String = match.GetDefault("kickOffTime", "")
	Dim scoreA As Object = match.GetDefault("scoreA", 0)
	Dim scoreB As Object = match.GetDefault("scoreB", 0)
	If status = "LIVE" Or status = "COMPLETED" Then
		Return scoreA & " - " & scoreB & "  ·  " & status
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
	If EventName = "" Then
		card.Initialize("")
	Else
		card.Initialize(EventName)
	End If
	Dim bg As Int = modConfig.COLOR_CARD
	Dim nameCol As Int = modConfig.COLOR_PRIMARY
	Dim mutedCol As Int = modConfig.COLOR_MUTED
	If Dark Then
		bg = modConfig.COLOR_DARK_CARD
		nameCol = modConfig.COLOR_DARK_TEXT
		mutedCol = modConfig.COLOR_DARK_MUTED
	End If
	card.Background = RoundedBg(bg, 12dip)
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = club.GetDefault("name", "Club")
	lblName.TextSize = 16
	lblName.TextColor = nameCol
	lblName.Typeface = Typeface.DEFAULT_BOLD
	lblName.SingleLine = True
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
	lblMeta.TextSize = 12
	lblMeta.TextColor = mutedCol
	lblMeta.SingleLine = True
	card.AddView(lblMeta, 14dip, 40dip, Width - 48dip, 18dip)
	
	Dim desc As String = club.GetDefault("description", "")
	If desc <> "" Then
		Dim lblDesc As Label
		lblDesc.Initialize("")
		lblDesc.Text = desc
		lblDesc.TextSize = 12
		lblDesc.TextColor = mutedCol
		lblDesc.SingleLine = True
		card.AddView(lblDesc, 14dip, 60dip, Width - 48dip, 18dip)
	End If
	
	Dim chev As Label
	chev.Initialize("")
	chev.Text = ">"
	chev.TextSize = 18
	chev.TextColor = modConfig.COLOR_ACCENT
	chev.Gravity = Gravity.CENTER
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
	p.Background = RoundedBg(bg, 12dip)
	Dim lblV As Label
	lblV.Initialize("")
	lblV.Text = value
	lblV.TextSize = 20
	lblV.TextColor = accent
	lblV.Typeface = Typeface.DEFAULT_BOLD
	lblV.Gravity = Gravity.CENTER
	p.AddView(lblV, 0, 8dip, Width, 28dip)
	Dim lblL As Label
	lblL.Initialize("")
	lblL.Text = label
	lblL.TextSize = 10
	lblL.TextColor = mutedCol
	lblL.Typeface = Typeface.DEFAULT_BOLD
	lblL.Gravity = Gravity.CENTER
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
	p.Background = RoundedBg(bg, 10dip)
	
	Dim lblR As Label
	lblR.Initialize("")
	lblR.Text = "#" & rank
	lblR.TextSize = 13
	lblR.TextColor = modConfig.COLOR_ACCENT
	lblR.Typeface = Typeface.DEFAULT_BOLD
	lblR.Gravity = Gravity.CENTER
	p.AddView(lblR, 8dip, 12dip, 40dip, 24dip)
	
	Dim lblN As Label
	lblN.Initialize("")
	lblN.Text = name
	lblN.TextSize = 14
	lblN.TextColor = nameCol
	lblN.Typeface = Typeface.DEFAULT_BOLD
	lblN.SingleLine = True
	p.AddView(lblN, 52dip, 12dip, Width - 120dip, 24dip)
	
	Dim lblV As Label
	lblV.Initialize("")
	lblV.Text = valueText
	lblV.TextSize = 15
	lblV.TextColor = Colors.White
	If Dark = False Then lblV.TextColor = modConfig.COLOR_PRIMARY
	lblV.Typeface = Typeface.DEFAULT_BOLD
	lblV.Gravity = Gravity.CENTER
	p.AddView(lblV, Width - 64dip, 10dip, 52dip, 28dip)
	Return p
End Sub

Public Sub CreatePlayerStatRow(Width As Int, player As Map, maxGoals As Int) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Background = RoundedBg(modConfig.COLOR_CARD, 10dip)
	Dim name As String = player.GetDefault("name", "Player")
	Dim g As Int = player.GetDefault("goals", 0)
	Dim a As Int = player.GetDefault("assists", 0)
	Dim apps As Int = player.GetDefault("apps", 0)
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = name
	lblName.TextSize = 14
	lblName.TextColor = modConfig.COLOR_PRIMARY
	lblName.Typeface = Typeface.DEFAULT_BOLD
	lblName.SingleLine = True
	p.AddView(lblName, 12dip, 8dip, Width - 24dip, 20dip)
	
	Dim lblMeta As Label
	lblMeta.Initialize("")
	lblMeta.Text = "G " & g & "   A " & a & "   Apps " & apps & "   YC " & player.GetDefault("yellowCards", 0) & "   POTM " & player.GetDefault("potmWins", 0)
	lblMeta.TextSize = 11
	lblMeta.TextColor = modConfig.COLOR_MUTED
	lblMeta.SingleLine = True
	p.AddView(lblMeta, 12dip, 30dip, Width - 24dip, 16dip)
	
	Dim track As Panel
	track.Initialize("")
	track.Color = modConfig.COLOR_CHIP
	p.AddView(track, 12dip, 52dip, Width - 24dip, 8dip)
	Dim fillW As Int = 4dip
	If maxGoals > 0 Then fillW = Max(4dip, ((Width - 24dip) * g) / maxGoals)
	Dim fill As Panel
	fill.Initialize("")
	fill.Background = RoundedBg(modConfig.COLOR_ACCENT, 4dip)
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
	If etype = "SUB" Then Return 130dip
	If etype = "GOAL" Then
		Dim assistId As String = details.GetDefault("assist", "")
		Dim assistUnknown As String = ("" & details.GetDefault("assistUnknown", False)).ToLowerCase
		If assistId <> "" Or assistUnknown = "true" Then Return 118dip
	End If
	If etype = "COMMENT" Then
		Dim content As String = ev.GetDefault("content", "")
		If content.Length > 48 Then Return 128dip
		If content.Length > 28 Then Return 112dip
	End If
	Return 100dip
End Sub

' Timeline row: rail + node + dark card. nameById used for goal scorer/assist lines.
Public Sub CreateTimelineItem(Width As Int, ev As Map, nameById As Map, isFirst As Boolean, isLast As Boolean) As Panel
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
	Dim details As Map
	Dim dObj As Object = ev.GetDefault("details", Null)
	If dObj <> Null And dObj Is Map Then
		details = dObj
	Else
		details.Initialize
	End If
	Dim etype As String = ev.GetDefault("type", "EVENT")
	Dim nodeCol As Int = TypeColor(etype)
	Dim node As Panel
	node.Initialize("")
	node.Background = RoundedBg(nodeCol, 8dip)
	row.AddView(node, railW / 2 - 7dip, h / 2 - 7dip, 14dip, 14dip)
	Dim cardW As Int = Width - railW - 4dip
	Dim card As Panel
	card.Initialize("")
	card.Background = RoundedBg(0xFF1E293B, 12dip)
	row.AddView(card, railW, 4dip, cardW, h - 8dip)
	Dim accent As Panel
	accent.Initialize("")
	accent.Color = nodeCol
	card.AddView(accent, 0, 0, 4dip, h - 8dip)
	Dim minute As Int = details.GetDefault("minute", -1)
	Dim clock As String = details.GetDefault("clockTime", "")
	If clock = "" Then clock = FormatClock(ev.GetDefault("timestamp", DateTime.Now))
	Dim timeLabel As String = "--'"
	If minute >= 0 Then timeLabel = minute & "'"
	Dim lblMin As Label
	lblMin.Initialize("")
	lblMin.Text = timeLabel
	lblMin.TextSize = 15
	lblMin.TextColor = modConfig.COLOR_ACCENT
	lblMin.Typeface = Typeface.DEFAULT_BOLD
	lblMin.Gravity = Gravity.CENTER
	card.AddView(lblMin, 10dip, 10dip, 44dip, 24dip)
	Dim lblClock As Label
	lblClock.Initialize("")
	lblClock.Text = clock
	lblClock.TextSize = 11
	lblClock.TextColor = 0xFF94A3B8
	lblClock.Gravity = Gravity.CENTER
	card.AddView(lblClock, 10dip, 36dip, 44dip, 16dip)
	Dim textLeft As Int = 58dip
	' Leave room for edit/delete overlay buttons on the right of the row
	Dim textW As Int = cardW - textLeft - 88dip
	If textW < 80dip Then textW = 80dip
	Dim lblType As Label
	lblType.Initialize("")
	lblType.Text = FriendlyType(etype)
	lblType.TextSize = 10
	lblType.TextColor = nodeCol
	lblType.Typeface = Typeface.DEFAULT_BOLD
	card.AddView(lblType, textLeft, 8dip, textW, 16dip)
	
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
				line2Text = "Our team"
			Else
				line2Text = "Opposition"
			End If
		Else If team = "B" Then
			mainText = "Opposition goal"
			line2Text = ""
		Else
			Dim scorerId As String = details.GetDefault("scorer", "")
			If scorerId <> "" And nameById.IsInitialized Then
				mainText = nameById.GetDefault(scorerId, mainText)
			End If
			Dim assistId As String = details.GetDefault("assist", "")
			Dim assistUnknown As String = ("" & details.GetDefault("assistUnknown", False)).ToLowerCase
			If assistId <> "" And nameById.IsInitialized Then
				line2Text = "Assist · " & nameById.GetDefault(assistId, "?")
			Else If assistUnknown = "true" Then
				line2Text = "Assist unknown"
			Else
				line2Text = "Our team"
				line2Color = 0xFF64748B
			End If
		End If
	Else If etype = "SUB" Then
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
			mainText = "Opposition"
		Else
			mainText = "Our team"
		End If
	Else If etype = "COMMENT" Then
		mainWrap = True
	Else
		mainWrap = (mainText.Length > 22)
	End If
	
	Dim mainH As Int = 22dip
	If etype = "SUB" Then
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
	lblMain.TextSize = 14
	lblMain.TextColor = Colors.White
	lblMain.Typeface = Typeface.DEFAULT_BOLD
	lblMain.SingleLine = Not(mainWrap)
	If mainWrap Then
		lblMain.Gravity = Bit.Or(Gravity.TOP, Gravity.LEFT)
	End If
	card.AddView(lblMain, textLeft, 28dip, textW, mainH)
	
	If line2Text <> "" Then
		Dim lbl2 As Label
		lbl2.Initialize("")
		lbl2.Text = line2Text
		lbl2.TextSize = 14
		lbl2.Typeface = Typeface.DEFAULT_BOLD
		If etype = "SUB" Then
			lbl2.TextColor = 0xFF4ADE80
			lbl2.SingleLine = False
			lbl2.Gravity = Bit.Or(Gravity.TOP, Gravity.LEFT)
			lblMain.TextColor = 0xFFF87171
			card.AddView(lbl2, textLeft, 56dip, textW, 28dip)
		Else
			lbl2.TextSize = 12
			lbl2.Typeface = Typeface.DEFAULT
			lbl2.TextColor = line2Color
			lbl2.SingleLine = True
			card.AddView(lbl2, textLeft, 52dip, textW, 18dip)
		End If
	End If
	Return row
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
		Case "COMMENT"
			Return "COMMENTARY"
		Case "CORNER"
			Return "CORNER"
		Case "PENALTY"
			Return "PENALTY"
		Case Else
			Return etype
	End Select
End Sub

Public Sub CreateIconButton(EventName As String, glyph As String, bgColor As Int, tag As Object) As Button
	Dim b As Button
	b.Initialize(EventName)
	b.Text = glyph
	b.TextSize = 16
	b.Typeface = Typeface.DEFAULT_BOLD
	b.TextColor = Colors.White
	b.Color = bgColor
	b.Gravity = Gravity.CENTER
	b.Padding = Array As Int(0, 0, 0, 0)
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
		Case "SUB"
			Return modConfig.COLOR_ACCENT
		Case "HALF_TIME", "SECOND_HALF"
			Return 0xFFFB923C
		Case "START", "END"
			Return 0xFF38BDF8
		Case "COMMENT"
			Return 0xFF6366F1
		Case "CORNER"
			Return 0xFF14B8A6
		Case "PENALTY"
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
	p.Background = RoundedBg(bg, 10dip)
	Dim lblN As Label
	lblN.Initialize("")
	lblN.Text = name
	lblN.TextSize = 13
	lblN.TextColor = nameCol
	lblN.Typeface = Typeface.DEFAULT_BOLD
	lblN.SingleLine = True
	p.AddView(lblN, 12dip, 8dip, Width * 0.42, 22dip)
	Dim lblM As Label
	lblM.Initialize("")
	lblM.Text = matchMins & "' game"
	lblM.TextSize = 12
	lblM.TextColor = modConfig.COLOR_ACCENT
	p.AddView(lblM, Width * 0.42, 8dip, Width * 0.28, 22dip)
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = seasonMins & "' season"
	lblS.TextSize = 12
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
	card.Background = RoundedBg(cardBg, 14dip)
	
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
	avPanel.Background = RoundedBg(avColor, avSize / 2)
	card.AddView(avPanel, avLeft, avTop, avSize, avSize)
	ClipToOutline(avPanel)
	
	Dim lblInit As Label
	lblInit.Initialize("")
	lblInit.Text = PlayerInitials(name)
	lblInit.TextSize = 16
	lblInit.TextColor = Colors.White
	lblInit.Typeface = Typeface.DEFAULT_BOLD
	lblInit.Gravity = Gravity.CENTER
	avPanel.AddView(lblInit, 0, 0, avSize, avSize)
	
	Dim iv As ImageView
	iv.Initialize("")
	iv.Gravity = Gravity.FILL
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
		numBadge.Background = RoundedBg(chipBg, 8dip)
		card.AddView(numBadge, avLeft + avSize - 18dip, avTop + avSize - 16dip, 22dip, 16dip)
		Dim lblNum As Label
		lblNum.Initialize("")
		lblNum.Text = numVal
		lblNum.TextSize = 9
		lblNum.TextColor = nameColor
		lblNum.Typeface = Typeface.DEFAULT_BOLD
		lblNum.Gravity = Gravity.CENTER
		numBadge.AddView(lblNum, 0, 0, 22dip, 16dip)
	End If
	
	Dim nameLine As String = name
	If isStar Then nameLine = "★ " & name
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = nameLine
	lblName.TextSize = 15
	lblName.TextColor = nameColor
	lblName.Typeface = Typeface.DEFAULT_BOLD
	lblName.SingleLine = True
	card.AddView(lblName, textLeft, avTop + 4dip, textW, 24dip)
	
	Dim lblPos As Label
	lblPos.Initialize("")
	If numStr <> "" Then
		lblPos.Text = numStr & " · " & pos
	Else
		lblPos.Text = pos
	End If
	lblPos.TextSize = 12
	lblPos.TextColor = mutedColor
	lblPos.SingleLine = True
	card.AddView(lblPos, textLeft, avTop + 28dip, textW, 20dip)
	
	Dim pill As Panel
	pill.Initialize("")
	pill.Background = RoundedBg(statusColor, 12dip)
	card.AddView(pill, pillLeft, (PlayerCardHeight - 28dip) / 2, pillW, 28dip)
	Dim lblSt As Label
	lblSt.Initialize("")
	lblSt.Text = statusLabel
	lblSt.TextSize = 11
	lblSt.TextColor = Colors.White
	lblSt.Typeface = Typeface.DEFAULT_BOLD
	lblSt.Gravity = Gravity.CENTER
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
Public Sub CreateRoundPlayerSlot(eventName As String, tag As Object, size As Int, displayName As String, avatarUrl As String, emptyLabel As String, selected As Boolean) As Map
	Dim wrap As Panel
	wrap.Initialize("")
	wrap.Color = Colors.Transparent
	wrap.Tag = tag
	Dim circle As Panel
	circle.Initialize("")
	Dim filled As Boolean = displayName <> ""
	If filled Then
		circle.Background = RoundedBg(0xFF0F172A, size / 2)
	Else
		circle.Background = RoundedBg(Colors.ARGB(80, 0, 0, 0), size / 2)
	End If
	wrap.AddView(circle, 0, 0, size, size)
	ClipToOutline(circle)
	Dim ring As Panel
	ring.Initialize("")
	Dim ringCd As ColorDrawable
	Dim ringCol As Int = Colors.White
	Dim ringW As Int = 2dip
	If selected Then
		ringCol = modConfig.COLOR_ACCENT
		ringW = 3dip
	Else If filled = False Then
		ringCol = Colors.ARGB(180, 255, 255, 255)
	End If
	ringCd.Initialize2(Colors.Transparent, size / 2, ringW, ringCol)
	ring.Background = ringCd
	wrap.AddView(ring, 0, 0, size, size)
	Dim iv As ImageView
	Dim hasPhoto As Boolean = False
	If filled Then
		Dim initials As Label
		initials.Initialize("")
		initials.Text = PlayerInitials(displayName)
		initials.TextSize = 13
		initials.TextColor = Colors.White
		initials.Typeface = Typeface.DEFAULT_BOLD
		initials.Gravity = Gravity.CENTER
		circle.AddView(initials, 0, 0, size, size)
		If avatarUrl <> "" Then
			iv.Initialize("")
			iv.Gravity = Gravity.FILL
			circle.AddView(iv, 0, 0, size, size)
			hasPhoto = True
		End If
		Dim lblName As Label
		lblName.Initialize("")
		lblName.Text = FirstToken(displayName)
		lblName.TextSize = 9
		lblName.TextColor = Colors.White
		lblName.Typeface = Typeface.DEFAULT_BOLD
		lblName.Gravity = Gravity.CENTER
		lblName.SingleLine = True
		wrap.AddView(lblName, -6dip, size + 1dip, size + 12dip, 14dip)
	Else
		Dim lblPos As Label
		lblPos.Initialize("")
		lblPos.Text = emptyLabel
		lblPos.TextSize = 9
		lblPos.TextColor = Colors.White
		lblPos.Typeface = Typeface.DEFAULT_BOLD
		lblPos.Gravity = Gravity.CENTER
		lblPos.SingleLine = False
		circle.AddView(lblPos, 4dip, 0, size - 8dip, size)
	End If
	Dim hit As Panel
	hit.Initialize(eventName)
	hit.Color = Colors.Transparent
	hit.Tag = tag
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
	Try
		Dim jo As JavaObject = v
		jo.RunMethod("setClipToOutline", Array(True))
	Catch
		Log("ClipToOutline: " & LastException.Message)
	End Try
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
	pill.Background = RoundedBg(AvailabilityColor(status, True), 12dip)
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
	If EventName = "" Then
		card.Initialize("")
	Else
		card.Initialize(EventName)
	End If
	card.Background = RoundedBg(modConfig.COLOR_CARD, 14dip)
	
	Dim lblT As Label
	lblT.Initialize("")
	lblT.Text = title
	lblT.TextSize = 16
	lblT.TextColor = modConfig.COLOR_PRIMARY
	lblT.Typeface = Typeface.DEFAULT_BOLD
	lblT.SingleLine = True
	card.AddView(lblT, 16dip, 14dip, Width - 48dip, 24dip)
	
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = subtitle
	lblS.TextSize = 12
	lblS.TextColor = modConfig.COLOR_MUTED
	lblS.SingleLine = True
	card.AddView(lblS, 16dip, 40dip, Width - 48dip, 20dip)
	
	Dim chev As Label
	chev.Initialize("")
	chev.Text = ">"
	chev.TextSize = 18
	chev.TextColor = modConfig.COLOR_ACCENT
	chev.Gravity = Gravity.CENTER
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
	Dim cd As ColorDrawable
	cd.Initialize2(0xFF15803D, 12dip, borderW, borderCol)
	pitch.Background = cd
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
		circle.Background = RoundedBg(0xFF0F172A, slotSize / 2)
	Else
		circle.Background = RoundedBg(Colors.ARGB(70, 0, 0, 0), slotSize / 2)
	End If
	wrap.AddView(circle, 0, 0, slotSize, slotSize)
	ClipToOutline(circle)
	
	Dim ring As Panel
	ring.Initialize("")
	Dim ringCd As ColorDrawable
	Dim ringCol As Int = Colors.White
	Dim ringW As Int = 2dip
	If slotHeld Then
		ringCol = modConfig.COLOR_ACCENT
		ringW = 3dip
	Else If filled = False Then
		ringCol = Colors.ARGB(180, 255, 255, 255)
	End If
	ringCd.Initialize2(Colors.Transparent, slotSize / 2, ringW, ringCol)
	ring.Background = ringCd
	wrap.AddView(ring, 0, 0, slotSize, slotSize)
	
	If filled Then
		Dim initials As Label
		initials.Initialize("")
		initials.Text = PlayerInitials(playerName)
		initials.TextSize = 10
		initials.TextColor = Colors.White
		initials.Typeface = Typeface.DEFAULT_BOLD
		initials.Gravity = Gravity.CENTER
		circle.AddView(initials, 0, 0, slotSize, slotSize)
		
		Dim caption As String = FirstNameOf(playerName)
		If mins >= 0 Then caption = caption & " " & mins & "'"
		Dim lblName As Label
		lblName.Initialize("")
		lblName.Text = caption
		lblName.TextSize = 8
		lblName.TextColor = Colors.White
		lblName.Typeface = Typeface.DEFAULT_BOLD
		lblName.Gravity = Gravity.CENTER
		lblName.SingleLine = True
		wrap.AddView(lblName, -10dip, slotSize, slotSize + 20dip, 16dip)
	Else
		Dim lblPos As Label
		lblPos.Initialize("")
		lblPos.Text = posLabel
		lblPos.TextSize = 9
		lblPos.TextColor = Colors.ARGB(230, 255, 255, 255)
		lblPos.Typeface = Typeface.DEFAULT_BOLD
		lblPos.Gravity = Gravity.CENTER
		circle.AddView(lblPos, 0, 0, slotSize, slotSize)
	End If
	If EventName <> "" And Callback <> Null Then
		Dim hit As Panel
		' The event is registered on the caller (the page), not this module.
		hit.Initialize(EventName)
		' A fully clear panel is skipped by hit testing.
		hit.Color = Colors.ARGB(1, 0, 0, 0)
		Dim info As Map
		info.Initialize
		info.Put("slotId", posId)
		info.Put("quarter", quarter)
		hit.Tag = info
		Dim hjo As JavaObject = hit
		hjo.RunMethod("setLongClickable", Array(True))
		' Keep the scroll view from cancelling a held press. Returning false lets the long-click through.
		Dim hook As JavaObject
		hook.InitializeStatic(Application.PackageName & ".modui")
		hook.RunMethod("holdForLongPress", Array(hjo))
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

