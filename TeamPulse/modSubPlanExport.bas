B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Coach sub-plan sheet. Draws the four quarter pitches plus breaks, bench, and planned minutes
' into one PDF under internal storage. Does not open the share sheet and does not write the database.

Sub Process_Globals
	Private Const PAGE_W As Int = 1240
	Private Const PAGE_H As Int = 1754
	Private Const MARGIN As Int = 48
	Private Const CONTENT_LIMIT As Int = 1682
	Private Const INK As Int = 0xFF0F172A
	Private Const MUTED As Int = 0xFF64748B
	Private Const RULE As Int = 0xFFE2E8F0
	Private Const GRASS As Int = 0xFF15803D
	Private Const BREAK_COL As Int = 0xFFEA580C
	Private xui As XUI
	Private textScale As Float
	Private sheetCvs As B4XCanvas
	Private sheetCvsReady As Boolean
	Private sheetPages As List
	Private sheetPage As Int
	Private sheetY As Int
	Private sheetTitle As String
End Sub

' Result keys: ok, message, dir, file.
' pitches is the four on-screen quarter diagrams, Q1 first. They are snapshotted as drawn.
Public Sub BuildFile(match As Map, club As Map, plan As Map, lineup As Map, _
		formation As String, nameById As Map, squad As List, pitches As List) As Map
	Dim result As Map
	result.Initialize
	result.Put("ok", False)
	result.Put("message", "Could not create the sub plan sheet. Nothing was changed.")
	result.Put("dir", "")
	result.Put("file", "")
	If match.IsInitialized = False Then
		match.Initialize
	End If
	If club.IsInitialized = False Then club.Initialize
	If plan.IsInitialized = False Then plan = modSubPlanner.EmptyPlan(60)
	If lineup.IsInitialized = False Then lineup.Initialize
	If nameById.IsInitialized = False Then nameById.Initialize
	If squad.IsInitialized = False Then
		squad.Initialize
	End If
	If pitches.IsInitialized = False Or pitches.Size < 4 Then
		result.Put("message", "Set a lineup to share the sheet.")
		Return result
	End If
	If HasPlayers(lineup, formation, nameById) = False Then
		result.Put("message", "Set a lineup to share the sheet.")
		Return result
	End If
	Try
		InitScale
		Dim swaps As List = ListOrEmpty(plan.GetDefault("swaps", Null))
		Dim moves As List = ListOrEmpty(plan.GetDefault("moves", Null))
		Dim byQ As Map = modSubPlanner.LineupsByQuarter(lineup, swaps, moves)
		Dim playerIds As List = SheetPlayerIds(squad, lineup, formation)
		Dim projected As Map = modSubPlanner.ProjectMatchMinutes(lineup, plan, playerIds)
		Dim squadById As Map = MembersById(squad)
		Dim images As List = SnapshotPitches(pitches)
		If images.Size < 4 Then
			ReleaseSheet
			result.Put("message", "Could not create the sub plan sheet. Nothing was changed.")
			Return result
		End If
		Dim dir As String = PrepareDir
		Dim fileName As String = "subplan-" & FileStamp & ".pdf"
		sheetTitle = MatchTitle(match)
		Dim err As String = WritePdf(dir, fileName, images, match, club, plan, formation, nameById, squad, squadById, byQ, projected, playerIds)
		If err <> "" Then
			If File.Exists(dir, fileName) Then File.Delete(dir, fileName)
			ReleaseSheet
			result.Put("message", err)
			Return result
		End If
		result.Put("ok", True)
		result.Put("message", "")
		result.Put("dir", dir)
		result.Put("file", fileName)
		Log("Sub plan sheet " & fileName)
	Catch
		Log("BuildFile sub plan: " & LastException)
		result.Put("ok", False)
		result.Put("message", "Could not create the sub plan sheet. Nothing was changed.")
	End Try
	ReleaseSheet
	Return result
End Sub

Private Sub SnapshotPitches(pitches As List) As List
	Dim images As List
	images.Initialize
	Dim i As Int
	For i = 0 To 3
		Dim wrap As Panel = pitches.Get(i)
		If wrap.IsInitialized = False Then Return images
		Dim xv As B4XView = wrap
		Dim w As Int = xv.Width
		Dim h As Int = xv.Height
#if B4A
		If w < 2 Or h < 2 Then
			Dim jo As JavaObject = wrap
			EnsureViewSize(jo, w, h)
			w = jo.RunMethod("getWidth", Null)
			h = jo.RunMethod("getHeight", Null)
		End If
#End If
		If w < 2 Or h < 2 Then
			Log("Snapshot pitch " & i & " has no size")
			Return images
		End If
		Dim bmp As Bitmap = xv.Snapshot
		If bmp.IsInitialized = False Or bmp.Width < 1 Then Return images
		images.Add(bmp)
	Next
	Return images
End Sub

Private Sub WritePdf(dir As String, fileName As String, images As List, match As Map, club As Map, plan As Map, _
		formation As String, nameById As Map, squad As List, squadById As Map, byQ As Map, projected As Map, playerIds As List) As String
	Try
		sheetPages.Initialize
		sheetPage = 1
		Dim cvs As B4XCanvas = BeginPage(False)
		DrawHeader(cvs, match, club, plan)
		DrawGrid(cvs, images, plan, nameById)
		sheetY = sheetY + 8
		cvs = Ensure(cvs, 120)
		cvs = DrawBench(cvs, squad, byQ, formation, nameById)
		cvs = DrawMinutes(cvs, playerIds, nameById, squadById, plan, projected)
		FinishCurrentPage(cvs)
		Return CommitPdf(File.Combine(dir, fileName))
	Catch
		Log("WritePdf: " & LastException)
		Return "Could not create the sub plan sheet. Nothing was changed."
	End Try
End Sub

Private Sub BeginPage(running As Boolean) As B4XCanvas
	Dim sheetPanel As B4XView = xui.CreatePanel("")
	sheetPanel.SetLayoutAnimated(0, 0, 0, PAGE_W, PAGE_H)
	Dim cvs As B4XCanvas
	cvs.Initialize(sheetPanel)
	sheetCvs = cvs
	sheetCvsReady = True
	Dim full As B4XRect
	full.Initialize(0, 0, PAGE_W, PAGE_H)
	cvs.DrawRect(full, Colors.White, True, 0)
	sheetY = MARGIN
	If running = False Then Return cvs
	Dim head As String = Ellipsize(cvs, "Sub plan · " & sheetTitle, True, 18, ContentWidth)
	DrawTopText(cvs, head, MARGIN, sheetY, True, 18, INK, "LEFT")
	sheetY = sheetY + TextHeight(cvs, True, 18)
	cvs.DrawLine(MARGIN, sheetY, PAGE_W - MARGIN, sheetY, RULE, 2)
	sheetY = sheetY + 16
	Return cvs
End Sub

Private Sub FinishCurrentPage(cvs As B4XCanvas)
	DrawFooter(cvs)
	Dim bmp As Bitmap = cvs.CreateBitmap
	sheetPages.Add(bmp)
	cvs.Release
	sheetCvsReady = False
End Sub

#if B4A
Private Sub EnsureViewSize(v As JavaObject, width As Int, height As Int)
	If width < 2 Or height < 2 Then Return
	Dim mode As Int = 1073741824
	v.RunMethod("measure", Array(Bit.Or(mode, width), Bit.Or(mode, height)))
	Dim left As Int = v.RunMethod("getLeft", Null)
	Dim top As Int = v.RunMethod("getTop", Null)
	v.RunMethod("layout", Array(left, top, left + width, top + height))
End Sub
#End If

Private Sub StartNextPage(cvs As B4XCanvas) As B4XCanvas
	FinishCurrentPage(cvs)
	sheetPage = sheetPage + 1
	Return BeginPage(True)
End Sub

Private Sub Ensure(cvs As B4XCanvas, needed As Int) As B4XCanvas
	If sheetY + needed <= CONTENT_LIMIT Then Return cvs
	If needed >= CONTENT_LIMIT - MARGIN Then Return cvs
	Return StartNextPage(cvs)
End Sub

Private Sub DrawHeader(cvs As B4XCanvas, match As Map, club As Map, plan As Map)
	Dim title As String = Ellipsize(cvs, sheetTitle, True, 36, ContentWidth)
	DrawTopText(cvs, title, MARGIN, sheetY, True, 36, INK, "LEFT")
	sheetY = sheetY + TextHeight(cvs, True, 36)
	Dim lines As List = WrapText(cvs, MetaLine(match, club, plan), False, 18, ContentWidth)
	Dim n As Int = lines.Size
	If n > 3 Then n = 3
	Dim i As Int
	For i = 0 To n - 1
		Dim line As String = lines.Get(i)
		If i = 2 And lines.Size > 3 Then line = Ellipsize(cvs, line, False, 18, ContentWidth)
		DrawTopText(cvs, line, MARGIN, sheetY, False, 18, MUTED, "LEFT")
		sheetY = sheetY + TextHeight(cvs, False, 18) - 2
	Next
	sheetY = sheetY + 14
End Sub

Private Sub DrawGrid(cvs As B4XCanvas, images As List, plan As Map, nameById As Map)
	Dim gap As Int = 28
	Dim colW As Int = (PAGE_W - MARGIN * 2 - gap) / 2
	Dim rightX As Int = MARGIN + colW + gap
	Dim row As Int
	For row = 0 To 1
		Dim qA As Int = row * 2 + 1
		Dim qB As Int = qA + 1
		Dim topY As Int = sheetY
		Dim titleH As Int = TextHeight(cvs, True, 22)
		DrawTopText(cvs, QuarterTitle(qA), MARGIN, topY, True, 22, INK, "LEFT")
		DrawTopText(cvs, QuarterTitle(qB), rightX, topY, True, 22, INK, "LEFT")
		Dim imgTop As Int = topY + titleH
		Dim imgA As Bitmap = images.Get(qA - 1)
		Dim imgB As Bitmap = images.Get(qB - 1)
		Dim hA As Int = DrawPitchImage(cvs, imgA, MARGIN, imgTop, colW)
		Dim hB As Int = DrawPitchImage(cvs, imgB, rightX, imgTop, colW)
		Dim notesTop As Int = imgTop + Max(hA, hB) + 8
		Dim nA As Int = DrawQuarterNotes(cvs, plan, nameById, qA, MARGIN, notesTop, colW)
		Dim nB As Int = DrawQuarterNotes(cvs, plan, nameById, qB, rightX, notesTop, colW)
		sheetY = Max(nA, nB) + 16
	Next
End Sub

Private Sub DrawPitchImage(cvs As B4XCanvas, img As Bitmap, x As Int, y As Int, maxW As Int) As Int
	If img.IsInitialized = False Then Return 0
	Dim dw As Int = img.Width
	Dim dh As Int = img.Height
	If dw < 1 Or dh < 1 Then Return 0
	If dw > maxW Then
		dh = Max(1, Round(dh * maxW / dw))
		dw = maxW
	End If
	If dh > 460 Then
		dw = Max(1, Round(dw * 460 / dh))
		dh = 460
	End If
	Dim left As Int = x + (maxW - dw) / 2
	Dim dest As B4XRect
	dest.Initialize(left, y, left + dw, y + dh)
	cvs.DrawRect(dest, GRASS, True, 0)
	Dim xb As B4XBitmap = img
	cvs.DrawBitmap(xb, dest)
	Return dh
End Sub

Private Sub DrawQuarterNotes(cvs As B4XCanvas, plan As Map, nameById As Map, q As Int, x As Int, y As Int, maxW As Int) As Int
	If q <= 1 Then Return y
	DrawTopText(cvs, "After Q" & (q - 1), x, y, True, 16, BREAK_COL, "LEFT")
	y = y + TextHeight(cvs, True, 16) - 2
	Dim lines As List = BreakLines(plan, nameById, q - 1)
	Dim limit As Int = lines.Size
	Dim extra As Int = 0
	If limit > 3 Then
		extra = limit - 2
		limit = 2
	End If
	Dim i As Int
	For i = 0 To limit - 1
		Dim color As Int = INK
		Dim line As String = lines.Get(i)
		If line = "No changes" Then color = MUTED
		line = Ellipsize(cvs, line, False, 16, maxW)
		DrawTopText(cvs, line, x, y, False, 16, color, "LEFT")
		y = y + TextHeight(cvs, False, 16) - 4
	Next
	If extra > 0 Then
		Dim more As String = "+" & extra & " more"
		DrawTopText(cvs, more, x, y, False, 16, MUTED, "LEFT")
		y = y + TextHeight(cvs, False, 16) - 4
	End If
	Return y
End Sub

Private Sub DrawBench(cvs As B4XCanvas, squad As List, byQ As Map, formation As String, nameById As Map) As B4XCanvas
	cvs = Ensure(cvs, 72)
	DrawTopText(cvs, "Bench", MARGIN, sheetY, True, 22, INK, "LEFT")
	sheetY = sheetY + TextHeight(cvs, True, 22)
	Dim text As String = BenchText(squad, byQ, formation, nameById)
	Dim lines As List = WrapText(cvs, text, False, 18, ContentWidth)
	If lines.Size = 0 Then lines.Add("None")
	Dim i As Int
	For i = 0 To lines.Size - 1
		cvs = Ensure(cvs, TextHeight(cvs, False, 18))
		Dim benchLine As String = lines.Get(i)
		DrawTopText(cvs, benchLine, MARGIN, sheetY, False, 18, INK, "LEFT")
		sheetY = sheetY + TextHeight(cvs, False, 18) - 2
	Next
	sheetY = sheetY + 16
	Return cvs
End Sub

Private Sub DrawMinutes(cvs As B4XCanvas, playerIds As List, nameById As Map, squadById As Map, plan As Map, projected As Map) As B4XCanvas
	If playerIds.Size = 0 Then Return cvs
	cvs = Ensure(cvs, 88)
	DrawMinutesHeader(cvs)
	Dim targets As Map = MapOrEmpty(plan.GetDefault("playTargets", Null))
	Dim i As Int
	For i = 0 To playerIds.Size - 1
		Dim before As Int = sheetY
		cvs = Ensure(cvs, 36)
		If sheetY < before Then DrawMinutesHeader(cvs)
		Dim pid As String = playerIds.Get(i)
		Dim label As String = PlayerLabel(pid, nameById, squadById)
		label = Ellipsize(cvs, label, False, 18, PAGE_W - MARGIN - 230)
		DrawTopText(cvs, label, MARGIN, sheetY, False, 18, INK, "LEFT")
		Dim tq As Int = modSubPlanner.TargetQuartersFor(targets, pid)
		Dim mins As Int = 0
		Try
			mins = projected.GetDefault(pid, 0)
		Catch
			mins = 0
		End Try
		DrawTopText(cvs, tq & "Q", PAGE_W - MARGIN - 100, sheetY, False, 18, INK, "RIGHT")
		DrawTopText(cvs, mins & "'", PAGE_W - MARGIN, sheetY, False, 18, INK, "RIGHT")
		sheetY = sheetY + TextHeight(cvs, False, 18) - 2
		cvs.DrawLine(MARGIN, sheetY, PAGE_W - MARGIN, sheetY, RULE, 1)
		sheetY = sheetY + 6
	Next
	Return cvs
End Sub

Private Sub DrawMinutesHeader(cvs As B4XCanvas)
	DrawTopText(cvs, "Playing time", MARGIN, sheetY, True, 22, INK, "LEFT")
	sheetY = sheetY + TextHeight(cvs, True, 22)
	DrawTopText(cvs, "Player", MARGIN, sheetY, True, 14, MUTED, "LEFT")
	DrawTopText(cvs, "Target", PAGE_W - MARGIN - 100, sheetY, True, 14, MUTED, "RIGHT")
	DrawTopText(cvs, "Plan", PAGE_W - MARGIN, sheetY, True, 14, MUTED, "RIGHT")
	sheetY = sheetY + TextHeight(cvs, True, 14)
	cvs.DrawLine(MARGIN, sheetY, PAGE_W - MARGIN, sheetY, RULE, 2)
	sheetY = sheetY + 8
End Sub

Private Sub DrawFooter(cvs As B4XCanvas)
	DrawTopText(cvs, "TeamPulse sub plan · guide only", MARGIN, PAGE_H - 52, False, 14, MUTED, "LEFT")
End Sub

Private Sub DrawTopText(cvs As B4XCanvas, text As String, x As Float, y As Float, bold As Boolean, px As Float, color As Int, align As String)
	Dim fnt As B4XFont = SheetFont(bold, px)
	Dim measured As B4XRect = cvs.MeasureText(text, fnt)
	Dim baseline As Float = y + cvs.MeasureText("Ag", fnt).Height
	Dim dx As Float = x
	If align = "RIGHT" Then dx = x - measured.Width
	If align = "CENTER" Then dx = x - measured.Width / 2
	cvs.DrawText(text, dx, baseline, fnt, color, "LEFT")
End Sub

Private Sub TextHeight(cvs As B4XCanvas, bold As Boolean, px As Float) As Int
	Dim h As Float = cvs.MeasureText("Ag", SheetFont(bold, px)).Height
	Return h + 8
End Sub

Private Sub TextWidth(cvs As B4XCanvas, text As String, bold As Boolean, px As Float) As Float
	Return cvs.MeasureText(text, SheetFont(bold, px)).Width
End Sub

Private Sub SheetFont(bold As Boolean, px As Float) As B4XFont
	Dim size As Float = ScaledText(px)
	If bold Then Return xui.CreateDefaultBoldFont(size)
	Return xui.CreateDefaultFont(size)
End Sub

Private Sub ContentWidth As Float
	Return PAGE_W - MARGIN * 2
End Sub

Private Sub ScaledText(px As Float) As Float
	If textScale <= 0 Then Return px
	Return px / textScale
End Sub

Private Sub InitScale
	textScale = modPlatform.TextScale
	If textScale <= 0 Then textScale = 1
End Sub

Private Sub Ellipsize(cvs As B4XCanvas, text As String, bold As Boolean, px As Float, maxW As Float) As String
	If text = "" Then Return ""
	If TextWidth(cvs, text, bold, px) <= maxW Then Return text
	Dim t As String = text
	Do While t.Length > 1
		t = t.SubString2(0, t.Length - 1)
		Dim trial As String = t & "…"
		If TextWidth(cvs, trial, bold, px) <= maxW Then Return trial
	Loop
	Return "…"
End Sub

Private Sub WrapText(cvs As B4XCanvas, text As String, bold As Boolean, px As Float, maxW As Float) As List
	Dim lines As List
	lines.Initialize
	Dim trimmed As String = text.Trim
	If trimmed = "" Then Return lines
	Dim words() As String = Regex.Split(" ", trimmed)
	Dim current As String = ""
	Dim i As Int
	For i = 0 To words.Length - 1
		Dim word As String = words(i)
		If word = "" Then Continue
		If TextWidth(cvs, word, bold, px) > maxW Then word = Ellipsize(cvs, word, bold, px, maxW)
		Dim trial As String
		If current = "" Then trial = word Else trial = current & " " & word
		If TextWidth(cvs, trial, bold, px) <= maxW Then
			current = trial
		Else
			If current <> "" Then lines.Add(current)
			current = word
		End If
	Next
	If current <> "" Then lines.Add(current)
	Return lines
End Sub

Private Sub ReleaseSheet
	If sheetCvsReady = False Then Return
	Try
		sheetCvs.Release
	Catch
		Log("ReleaseSheet: " & LastException)
	End Try
	sheetCvsReady = False
End Sub

Private Sub PrepareDir As String
	File.MakeDir(modPlatform.AppDir, "shared")
	Dim dir As String = File.Combine(modPlatform.AppDir, "shared")
	Dim existing As List = File.ListFiles(dir)
	If existing.IsInitialized Then
		Dim i As Int
		For i = 0 To existing.Size - 1
			Dim name As String = existing.Get(i)
			If name.StartsWith("subplan-") And name.EndsWith(".pdf") Then File.Delete(dir, name)
		Next
	End If
	Return dir
End Sub

Private Sub CommitPdf(path As String) As String
#if B4A
	Dim pdf As JavaObject
	Try
		pdf.InitializeNewInstance("android.graphics.pdf.PdfDocument", Null)
		Dim i As Int
		For i = 0 To sheetPages.Size - 1
			Dim bmp As Bitmap = sheetPages.Get(i)
			Dim builder As JavaObject
			builder.InitializeNewInstance("android.graphics.pdf.PdfDocument$PageInfo$Builder", Array(PAGE_W, PAGE_H, i + 1))
			Dim info As Object = builder.RunMethod("create", Null)
			Dim page As JavaObject = pdf.RunMethod("startPage", Array(info))
			Dim canvas As JavaObject = page.RunMethod("getCanvas", Null)
			Dim sheet As JavaObject
			sheet.InitializeStatic(Application.PackageName & ".modsubplanexport")
			Dim native As JavaObject = bmp
			sheet.RunMethod("blit", Array(canvas, native))
			pdf.RunMethod("finishPage", Array(page))
		Next
		Dim fos As JavaObject
		fos.InitializeNewInstance("java.io.FileOutputStream", Array(path))
		pdf.RunMethod("writeTo", Array(fos))
		fos.RunMethod("close", Null)
		pdf.RunMethod("close", Null)
		Return ""
	Catch
		Log("CommitPdf: " & LastException)
		Try
			If pdf.IsInitialized Then pdf.RunMethod("close", Null)
		Catch
			Log("CommitPdf close: " & LastException)
		End Try
		Return "Could not create the sub plan sheet. Nothing was changed."
	End Try
#else if B4i
	Try
		Dim no As NativeObject = Me
		Dim started As String = no.RunMethod("beginPdf:width:height:", Array(path, PAGE_W, PAGE_H)).AsString
		If started <> "" Then Return started
		Dim i As Int
		For i = 0 To sheetPages.Size - 1
			Dim bmp As Bitmap = sheetPages.Get(i)
			no.RunMethod("addPdfPage:width:height:", Array(bmp, PAGE_W, PAGE_H))
		Next
		no.RunMethod("endPdf", Null)
		Return ""
	Catch
		Log("CommitPdf: " & LastException)
		Return "Could not create the sub plan sheet. Nothing was changed."
	End Try
#End If
End Sub

Private Sub FileStamp As String
	Dim oldDate As String = DateTime.DateFormat
	Dim oldTime As String = DateTime.TimeFormat
	DateTime.DateFormat = "yyyy-MM-dd"
	DateTime.TimeFormat = "HHmm"
	Dim s As String = DateTime.Date(DateTime.Now) & "-" & DateTime.Time(DateTime.Now)
	DateTime.DateFormat = oldDate
	DateTime.TimeFormat = oldTime
	Return s
End Sub

Private Sub HasPlayers(lineup As Map, formation As String, nameById As Map) As Boolean
	If lineup.IsInitialized = False Or lineup.Size = 0 Then Return False
	Dim ids As List = modSubPlanner.MemberIdsInSlots(lineup, formation, nameById)
	Return ids.Size > 0
End Sub

Private Sub QuarterTitle(q As Int) As String
	If q = 1 Then Return "Q1 · Kick-off"
	Return "Q" & q
End Sub

Private Sub MatchTitle(match As Map) As String
	Dim title As String = "" & match.GetDefault("title", "")
	If title = "" Or title = "null" Then title = "Match"
	Return title
End Sub

Private Sub MetaLine(match As Map, club As Map, plan As Map) As String
	Dim parts As List
	parts.Initialize
	Dim clubName As String = "" & club.GetDefault("name", "")
	If clubName <> "" And clubName <> "null" Then parts.Add(clubName)
	parts.Add("Sub plan")
	Dim when As String = modUI.FormatUkDate("" & match.GetDefault("date", ""))
	Dim kick As String = modUI.FormatUkTime("" & match.GetDefault("kickOffTime", ""))
	If when <> "" And kick <> "" Then
		parts.Add(when & " " & kick)
	Else If when <> "" Then
		parts.Add(when)
	Else If kick <> "" Then
		parts.Add(kick)
	End If
	Dim loc As String = "" & match.GetDefault("location", "")
	If loc <> "" And loc <> "null" Then parts.Add(loc)
	Dim duration As Int = plan.GetDefault("matchMinutes", 60)
	If duration <= 0 Then duration = 60
	Dim qMins As Int = Round(duration / 4)
	parts.Add(duration & "' · 4 × " & qMins & "'")
	Return JoinParts(parts)
End Sub

Private Sub JoinParts(parts As List) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim i As Int
	For i = 0 To parts.Size - 1
		Dim p As String = "" & parts.Get(i)
		If p = "" Then Continue
		If sb.Length > 0 Then sb.Append(" · ")
		sb.Append(p)
	Next
	Return sb.ToString
End Sub

Private Sub BreakLines(plan As Map, nameById As Map, afterQ As Int) As List
	Dim lines As List
	lines.Initialize
	Dim swaps As List = ListOrEmpty(plan.GetDefault("swaps", Null))
	Dim i As Int
	For i = 0 To swaps.Size - 1
		Dim raw As Object = swaps.Get(i)
		If Not(raw Is Map) Then Continue
		Dim s As Map = raw
		If afterQ <> s.GetDefault("afterQuarter", 0) Then Continue
		Dim outN As String = FirstNonEmpty("" & s.GetDefault("outName", ""), "" & nameById.GetDefault(s.GetDefault("playerOut", ""), ""))
		Dim inN As String = FirstNonEmpty("" & s.GetDefault("inName", ""), "" & nameById.GetDefault(s.GetDefault("playerIn", ""), ""))
		lines.Add(outN & " → " & inN)
	Next
	Dim moves As List = ListOrEmpty(plan.GetDefault("moves", Null))
	For i = 0 To moves.Size - 1
		Dim rawMv As Object = moves.Get(i)
		If Not(rawMv Is Map) Then Continue
		Dim mv As Map = rawMv
		If afterQ <> mv.GetDefault("afterQuarter", 0) Then Continue
		Dim a As String = FirstNonEmpty("" & mv.GetDefault("nameA", ""), "" & mv.GetDefault("slotA", ""))
		Dim b As String = FirstNonEmpty("" & mv.GetDefault("nameB", ""), "" & mv.GetDefault("slotB", ""))
		lines.Add(a & " ↔ " & b)
	Next
	If lines.Size = 0 Then lines.Add("No changes")
	Return lines
End Sub

Private Sub BenchText(squad As List, byQ As Map, formation As String, nameById As Map) As String
	Dim onPitch As Map
	onPitch.Initialize
	Dim q1 As Map = LineupAt(byQ, 1, onPitch)
	Dim ids As List = modSubPlanner.MemberIdsInSlots(q1, formation, nameById)
	Dim i As Int
	For i = 0 To ids.Size - 1
		onPitch.Put("" & ids.Get(i), True)
	Next
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To squad.Size - 1
		Dim raw As Object = squad.Get(i)
		If Not(raw Is Map) Then Continue
		Dim mem As Map = raw
		Dim id As String = "" & mem.GetDefault("id", "")
		If id = "" Or id = "null" Or onPitch.ContainsKey(id) Then Continue
		If sb.Length > 0 Then sb.Append(", ")
		sb.Append(MemberLabel(mem, nameById))
	Next
	If sb.Length = 0 Then Return "None"
	Return sb.ToString
End Sub

Private Sub SheetPlayerIds(squad As List, lineup As Map, formation As String) As List
	Dim ids As List
	ids.Initialize
	Dim seen As Map
	seen.Initialize
	Dim i As Int
	For i = 0 To squad.Size - 1
		Dim raw As Object = squad.Get(i)
		If Not(raw Is Map) Then Continue
		Dim mem As Map = raw
		Dim id As String = "" & mem.GetDefault("id", "")
		If id = "" Or id = "null" Or seen.ContainsKey(id) Then Continue
		seen.Put(id, True)
		ids.Add(id)
	Next
	Dim positions As List = modFormations.GetPositions(formation)
	If positions.IsInitialized = False Then Return ids
	For i = 0 To positions.Size - 1
		Dim p As Map = positions.Get(i)
		Dim posId As String = "" & p.GetDefault("id", "")
		If posId = "" Then Continue
		Dim pid As String = "" & lineup.GetDefault(posId, "")
		If pid = "" Or pid = "null" Or seen.ContainsKey(pid) Then Continue
		seen.Put(pid, True)
		ids.Add(pid)
	Next
	Return ids
End Sub

Private Sub MembersById(squad As List) As Map
	Dim byId As Map
	byId.Initialize
	Dim i As Int
	For i = 0 To squad.Size - 1
		Dim raw As Object = squad.Get(i)
		If Not(raw Is Map) Then Continue
		Dim mem As Map = raw
		Dim id As String = "" & mem.GetDefault("id", "")
		If id <> "" And id <> "null" Then byId.Put(id, mem)
	Next
	Return byId
End Sub

Private Sub PlayerLabel(pid As String, nameById As Map, squadById As Map) As String
	If squadById.ContainsKey(pid) Then
		Dim mem As Map = squadById.Get(pid)
		Return MemberLabel(mem, nameById)
	End If
	Dim nm As String = "" & nameById.GetDefault(pid, "")
	If nm = "" Or nm = "null" Then nm = "?"
	Return nm
End Sub

Private Sub MemberLabel(mem As Map, nameById As Map) As String
	Dim id As String = "" & mem.GetDefault("id", "")
	Dim nm As String = "" & nameById.GetDefault(id, "")
	If nm = "" Or nm = "null" Then nm = "" & mem.GetDefault("name", "")
	If nm = "" Or nm = "null" Then nm = "?"
	Dim n As Int = SafeInt(mem.GetDefault("squadNumber", 0))
	If n > 0 Then Return "#" & n & " " & nm
	Return nm
End Sub

Private Sub SafeInt(v As Object) As Int
	Try
		Dim n As Int = v
		If n < 0 Then n = 0
		Return n
	Catch
		Return 0
	End Try
End Sub

Private Sub LineupAt(byQ As Map, q As Int, fallback As Map) As Map
	If byQ.IsInitialized And byQ.ContainsKey("" & q) Then
		Dim m As Map = byQ.Get("" & q)
		If m.IsInitialized Then Return m
	End If
	Return fallback
End Sub

Private Sub FirstNonEmpty(a As String, b As String) As String
	If a <> "" And a <> "null" Then Return a
	If b <> "" And b <> "null" Then Return b
	Return "?"
End Sub

Private Sub MapOrEmpty(raw As Object) As Map
	If raw Is Map Then
		Dim m As Map = raw
		If m.IsInitialized Then Return m
	End If
	Dim empty As Map
	empty.Initialize
	Return empty
End Sub

Private Sub ListOrEmpty(raw As Object) As List
	If raw Is List Then
		Dim l As List = raw
		If l.IsInitialized Then Return l
	End If
	Dim empty As List
	empty.Initialize
	Return empty
End Sub

#If JAVA
public static void blit(android.graphics.Canvas canvas, android.graphics.Bitmap bitmap) {
	bitmap.setDensity(0);
	canvas.drawBitmap(bitmap, 0f, 0f, null);
}
#End If

#if OBJC
- (NSString*)beginPdf:(NSString*)path width:(int)width height:(int)height {
	CGRect pageRect = CGRectMake(0, 0, width, height);
	BOOL ok = UIGraphicsBeginPDFContextToFile(path, pageRect, nil);
	if (!ok) return @"Could not create the sub plan sheet. Nothing was changed.";
	return @"";
}
- (void)addPdfPage:(UIImage*)img width:(int)width height:(int)height {
	CGRect pageRect = CGRectMake(0, 0, width, height);
	UIGraphicsBeginPDFPageWithInfo(pageRect, nil);
	if (img != nil) [img drawInRect:pageRect];
}
- (void)endPdf {
	UIGraphicsEndPDFContext();
}
#End If
