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
	Dim btnBg As Int = modConfig.COLOR_CARD
	Dim btnFg As Int = modConfig.COLOR_PRIMARY
	Dim actionBg As Int = modConfig.COLOR_ACCENT
	If Dark Then
		bg = modConfig.COLOR_DARK_BG
		titleCol = modConfig.COLOR_DARK_TEXT
		btnBg = modConfig.COLOR_DARK_CHIP
		btnFg = Colors.White
		actionBg = modConfig.COLOR_ACCENT
	End If
	Root.Color = bg
	
	Dim left As Int = 8dip
	If BackEvent <> "" Then
		Dim btnBack As Button = CreateChromeIconButton(BackEvent, "←", btnBg, btnFg)
		Root.AddView(btnBack, left, 10dip, 40dip, 36dip)
		left = left + 44dip
	End If
	
	Dim rightPad As Int = 12dip
	If ActionEvent <> "" Then
		Dim btnAct As Button = CreateChromeIconButton(ActionEvent, ActionGlyph, actionBg, Colors.White)
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
	b.Color = bgColor
	b.Gravity = Gravity.CENTER
	b.Padding = Array As Int(0, 0, 0, 0)
	Return b
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
	Dim p As Panel
	p.Initialize("")
	p.Color = Colors.Transparent
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text.ToUpperCase
	lbl.TextSize = 11
	lbl.TextColor = modConfig.COLOR_MUTED
	lbl.Typeface = Typeface.DEFAULT_BOLD
	lbl.Gravity = Gravity.CENTER_VERTICAL
	p.AddView(lbl, 4dip, 0, Width - 8dip, SectionHeaderHeight)
	Return p
End Sub

' header=True → non-clickable section-style; else tappable row when EventName set.
Public Sub CreateSimpleRow(Width As Int, text As String, EventName As String) As Panel
	Dim p As Panel
	If EventName = "" Then
		p.Initialize("")
	Else
		p.Initialize(EventName)
	End If
	p.Background = RoundedBg(modConfig.COLOR_CARD, 10dip)
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 14
	lbl.TextColor = modConfig.COLOR_PRIMARY
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
	Dim card As Panel
	If EventName = "" Then
		card.Initialize("")
	Else
		card.Initialize(EventName)
	End If
	card.Background = RoundedBg(modConfig.COLOR_CARD, 12dip)
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = club.GetDefault("name", "Club")
	lblName.TextSize = 16
	lblName.TextColor = modConfig.COLOR_PRIMARY
	lblName.Typeface = Typeface.DEFAULT_BOLD
	lblName.SingleLine = True
	card.AddView(lblName, 14dip, 12dip, Width - 28dip, 24dip)
	
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
	lblMeta.TextColor = modConfig.COLOR_MUTED
	lblMeta.SingleLine = True
	card.AddView(lblMeta, 14dip, 40dip, Width - 28dip, 18dip)
	
	Dim desc As String = club.GetDefault("description", "")
	If desc <> "" Then
		Dim lblDesc As Label
		lblDesc.Initialize("")
		lblDesc.Text = desc
		lblDesc.TextSize = 12
		lblDesc.TextColor = modConfig.COLOR_MUTED
		lblDesc.SingleLine = True
		card.AddView(lblDesc, 14dip, 60dip, Width - 28dip, 18dip)
	End If
	Return card
End Sub

Public Sub CreateStatPill(Width As Int, label As String, value As String, accent As Int) As Panel
	Dim p As Panel
	p.Initialize("")
	p.Background = RoundedBg(modConfig.COLOR_CARD, 12dip)
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
	lblL.TextColor = modConfig.COLOR_MUTED
	lblL.Typeface = Typeface.DEFAULT_BOLD
	lblL.Gravity = Gravity.CENTER
	p.AddView(lblL, 0, 36dip, Width, 16dip)
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
	If etype = "GOAL" And details.GetDefault("assist", "") <> "" Then Return 118dip
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
		If team = "B" Then
			mainText = "Opponent"
			line2Text = "Opponent"
		Else
			Dim scorerId As String = details.GetDefault("scorer", "")
			If scorerId <> "" And nameById.IsInitialized Then
				mainText = nameById.GetDefault(scorerId, mainText)
			End If
			Dim assistId As String = details.GetDefault("assist", "")
			If assistId <> "" And nameById.IsInitialized Then
				line2Text = "Assist · " & nameById.GetDefault(assistId, "?")
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
	Dim p As Panel
	p.Initialize("")
	p.Background = RoundedBg(modConfig.COLOR_CARD, 10dip)
	Dim lblN As Label
	lblN.Initialize("")
	lblN.Text = name
	lblN.TextSize = 13
	lblN.TextColor = modConfig.COLOR_PRIMARY
	lblN.Typeface = Typeface.DEFAULT_BOLD
	lblN.SingleLine = True
	p.AddView(lblN, 12dip, 8dip, Width * 0.45, 22dip)
	Dim lblM As Label
	lblM.Initialize("")
	lblM.Text = "This game: " & matchMins & "'"
	lblM.TextSize = 12
	lblM.TextColor = modConfig.COLOR_ACCENT
	p.AddView(lblM, Width * 0.45, 8dip, Width * 0.25, 22dip)
	Dim lblS As Label
	lblS.Initialize("")
	lblS.Text = "Season: " & seasonMins & "'"
	lblS.TextSize = 12
	lblS.TextColor = modConfig.COLOR_MUTED
	p.AddView(lblS, Width * 0.72, 8dip, Width * 0.26 - 8dip, 22dip)
	Return p
End Sub

Public Sub MinutesRowHeight As Int
	Return 40dip
End Sub


Public Sub PlayerCardHeight As Int
	Return 76dip
End Sub

Public Sub HubNavCardHeight As Int
	Return 72dip
End Sub

' availabilityStatus: CONFIRMED / UNAVAILABLE / UNKNOWN (or empty)
Public Sub CreatePlayerCard(Width As Int, member As Map, availabilityStatus As String, isStar As Boolean) As Panel
	Dim card As Panel
	card.Initialize("")
	card.Background = RoundedBg(modConfig.COLOR_CARD, 12dip)
	
	Dim name As String = member.GetDefault("name", "Player")
	If isStar Then name = name & "  ★"
	Dim pos As String = member.GetDefault("preferredPosition", member.GetDefault("favPosition", ""))
	If pos = "" Then pos = "No preferred position"
	
	Dim statusLabel As String = "Unknown"
	Dim statusColor As Int = modConfig.COLOR_MUTED
	Dim av As String = availabilityStatus
	If av = "CONFIRMED" Then
		statusLabel = "Confirmed"
		statusColor = modConfig.COLOR_SUCCESS
	Else If av = "UNAVAILABLE" Then
		statusLabel = "Out"
		statusColor = modConfig.COLOR_DANGER
	End If
	
	Dim lblName As Label
	lblName.Initialize("")
	lblName.Text = name
	lblName.TextSize = 15
	lblName.TextColor = modConfig.COLOR_PRIMARY
	lblName.Typeface = Typeface.DEFAULT_BOLD
	lblName.SingleLine = True
	card.AddView(lblName, 14dip, 12dip, Width - 120dip, 24dip)
	
	Dim lblPos As Label
	lblPos.Initialize("")
	lblPos.Text = pos
	lblPos.TextSize = 12
	lblPos.TextColor = modConfig.COLOR_MUTED
	lblPos.SingleLine = True
	card.AddView(lblPos, 14dip, 40dip, Width - 120dip, 20dip)
	
	Dim pill As Panel
	pill.Initialize("")
	pill.Background = RoundedBg(statusColor, 10dip)
	card.AddView(pill, Width - 100dip, 24dip, 86dip, 28dip)
	Dim lblSt As Label
	lblSt.Initialize("")
	lblSt.Text = statusLabel
	lblSt.TextSize = 11
	lblSt.TextColor = Colors.White
	lblSt.Typeface = Typeface.DEFAULT_BOLD
	lblSt.Gravity = Gravity.CENTER
	pill.AddView(lblSt, 0, 0, 86dip, 28dip)
	Return card
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

