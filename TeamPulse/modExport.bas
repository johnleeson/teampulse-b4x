B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Coach spreadsheet backup. Reads players, matches, events, and season stats.
' Writes one .xlsx on the phone and opens the share sheet. No database writes.

Sub Process_Globals
	Private Const PAGE_SIZE As Int = 1000
End Sub

Public Sub UserCanExport As Boolean
	Return ExportClubs.Size > 0
End Sub

Public Sub UserCanExportClub(clubId As String) As Boolean
	If clubId = "" Then Return False
	Dim clubs As List = ExportClubs
	Dim i As Int
	For i = 0 To clubs.Size - 1
		Dim club As Map = clubs.Get(i)
		If club.GetDefault("id", "") = clubId Then Return True
	Next
	Return False
End Sub

' Builds the workbook under internal storage. Does not open the share sheet.
' Result keys: ok, message, dir, file
Public Sub BuildFile As Map
	Dim result As Map
	result.Initialize
	result.Put("ok", False)
	result.Put("message", "Could not create the spreadsheet. Nothing was changed.")
	result.Put("dir", "")
	result.Put("file", "")
	Try
		Dim clubs As List = ExportClubs
		If clubs.Size = 0 Then
			result.Put("message", "Export is only available to a coach.")
			Return result
		End If
		Dim clubIds As Map = IdSet(clubs)
		Dim names As Map = PlayerNames(clubs)
		Dim matches As List = MatchesForClubs(clubIds)
		Dim matchIds As List = MatchIdList(matches)
		Dim eventsResult As Map = FetchAllEvents(matchIds)
		If eventsResult.GetDefault("ok", False) = False Then
			result.Put("message", eventsResult.GetDefault("error", "Could not read events. Nothing was changed."))
			Return result
		End If
		Dim events As List = eventsResult.Get("events")
		Dim profilesResult As Map = FetchProfiles(MemberIds(clubs))
		If profilesResult.GetDefault("ok", False) = False Then
			result.Put("message", profilesResult.GetDefault("error", "Could not read player details. Nothing was changed."))
			Return result
		End If
		Dim profiles As Map = profilesResult.Get("profiles")
		Dim sheets As List
		sheets.Initialize
		sheets.Add(PlayersSheet(clubs, profiles))
		sheets.Add(MatchesSheet(clubs, matches))
		sheets.Add(EventsSheet(clubs, matches, events, names))
		sheets.Add(StatsSheet(clubs, matches, events))
		Dim dir As String = PrepareSharedDir
		Dim fileName As String = "TeamPulse-" & FileStamp & ".xlsx"
		Dim writeErr As String = WriteWorkbook(dir, fileName, sheets)
		If writeErr <> "" Then
			File.Delete(dir, fileName)
			result.Put("message", writeErr)
			Return result
		End If
		result.Put("ok", True)
		result.Put("message", "")
		result.Put("dir", dir)
		result.Put("file", fileName)
		Log("Export file " & fileName)
	Catch
		Log("BuildFile: " & LastException)
		result.Put("ok", False)
		result.Put("message", "Could not create the spreadsheet. Nothing was changed.")
	End Try
	Return result
End Sub

Public Sub ShareFile(dir As String, fileName As String) As String
	Return ShareDocument(dir, fileName, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Save spreadsheet")
End Sub

Public Sub ShareDocument(dir As String, fileName As String, mime As String, chooserTitle As String) As String
	Try
		If dir = "" Or fileName = "" Or File.Exists(dir, fileName) = False Then
			Return "Could not open the share sheet. Nothing was changed."
		End If
		Dim context As JavaObject
		context.InitializeContext
		Dim provider As JavaObject
		provider.InitializeStatic("androidx.core.content.FileProvider")
		Dim jfile As JavaObject
		jfile.InitializeNewInstance("java.io.File", Array(dir, fileName))
		Dim uri As Object = provider.RunMethod("getUriForFile", Array(context, Application.PackageName & ".provider", jfile))
		Dim shareIntent As Intent
		shareIntent.Initialize(shareIntent.ACTION_SEND, "")
		shareIntent.SetType(mime)
		shareIntent.PutExtra("android.intent.extra.STREAM", uri)
		shareIntent.Flags = 1
		shareIntent.WrapAsIntentChooser(chooserTitle)
		shareIntent.Flags = 1
		StartActivity(shareIntent)
		Return ""
	Catch
		Log("ShareDocument: " & LastException)
		Return "Could not open the share sheet. Nothing was changed."
	End Try
End Sub

Private Sub ExportClubs As List
	Dim result As List
	result.Initialize
	If modAppState.IsAuthenticated = False Then Return result
	Dim uid As String = modAppState.CurrentUser.GetDefault("id", "")
	If uid = "" Then Return result
	Dim profileCoach As Boolean = modDb.RoleListHas(modAppState.CurrentUser.GetDefault("roles", Null), "COACH")
	Dim mine As List = modAppState.ClubsForCurrentUser
	Dim i As Int
	For i = 0 To mine.Size - 1
		Dim club As Map = mine.Get(i)
		If club.GetDefault("ownerId", "") = uid Or profileCoach Then
			result.Add(club)
			Continue
		End If
		Dim memObj As Object = club.GetDefault("members", Null)
		If (memObj Is List) = False Then Continue
		Dim members As List = memObj
		Dim j As Int
		For j = 0 To members.Size - 1
			Dim mem As Map = members.Get(j)
			If mem.GetDefault("id", "") <> uid Then Continue
			If modDb.RoleListHas(mem.GetDefault("roles", Null), "COACH") Then result.Add(club)
			Exit
		Next
	Next
	Return result
End Sub

Private Sub IdSet(clubs As List) As Map
	Dim ids As Map
	ids.Initialize
	Dim i As Int
	For i = 0 To clubs.Size - 1
		Dim club As Map = clubs.Get(i)
		Dim id As String = club.GetDefault("id", "")
		If id <> "" Then ids.Put(id, club.GetDefault("name", "Club"))
	Next
	Return ids
End Sub

Private Sub PlayerNames(clubs As List) As Map
	Dim names As Map
	names.Initialize
	Dim i As Int
	For i = 0 To clubs.Size - 1
		Dim club As Map = clubs.Get(i)
		Dim memObj As Object = club.GetDefault("members", Null)
		If (memObj Is List) = False Then Continue
		Dim members As List = memObj
		Dim j As Int
		For j = 0 To members.Size - 1
			Dim mem As Map = members.Get(j)
			Dim id As String = mem.GetDefault("id", "")
			If id <> "" Then names.Put(id, mem.GetDefault("name", ""))
		Next
	Next
	Return names
End Sub

Private Sub MemberIds(clubs As List) As List
	Dim ids As List
	ids.Initialize
	Dim seen As Map
	seen.Initialize
	Dim i As Int
	For i = 0 To clubs.Size - 1
		Dim club As Map = clubs.Get(i)
		Dim memObj As Object = club.GetDefault("members", Null)
		If (memObj Is List) = False Then Continue
		Dim members As List = memObj
		Dim j As Int
		For j = 0 To members.Size - 1
			Dim mem As Map = members.Get(j)
			Dim id As String = mem.GetDefault("id", "")
			If id = "" Or seen.ContainsKey(id) Then Continue
			seen.Put(id, True)
			ids.Add(id)
		Next
	Next
	Return ids
End Sub

Private Sub MatchesForClubs(clubIds As Map) As List
	Dim result As List
	result.Initialize
	Dim i As Int
	For i = 0 To modAppState.Matches.Size - 1
		Dim m As Map = modAppState.Matches.Get(i)
		If clubIds.ContainsKey(m.GetDefault("clubId", "")) Then result.Add(m)
	Next
	Return result
End Sub

Private Sub MatchIdList(matches As List) As List
	Dim ids As List
	ids.Initialize
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		Dim id As String = m.GetDefault("id", "")
		If id <> "" Then ids.Add(id)
	Next
	Return ids
End Sub

Private Sub FetchAllEvents(matchIds As List) As Map
	Dim out As Map
	out.Initialize
	Dim events As List
	events.Initialize
	out.Put("ok", True)
	out.Put("events", events)
	out.Put("error", "")
	Dim chunkStart As Int = 0
	Do While chunkStart < matchIds.Size
		Dim chunkEnd As Int = Min(chunkStart + 40, matchIds.Size)
		Dim ids As List
		ids.Initialize
		Dim i As Int
		For i = chunkStart To chunkEnd - 1
			ids.Add(matchIds.Get(i))
		Next
		Dim page As Map = FetchEventChunk(ids)
		If page.GetDefault("ok", False) = False Then
			out.Put("ok", False)
			out.Put("error", page.GetDefault("error", "Could not read events. Nothing was changed."))
			Return out
		End If
		Dim got As List = page.Get("events")
		Dim g As Int
		For g = 0 To got.Size - 1
			events.Add(got.Get(g))
		Next
		chunkStart = chunkEnd
	Loop
	SortEvents(events)
	Return out
End Sub

Private Sub FetchEventChunk(matchIds As List) As Map
	Dim out As Map
	out.Initialize
	Dim events As List
	events.Initialize
	out.Put("ok", True)
	out.Put("events", events)
	out.Put("error", "")
		Dim joinedIds As String = JoinIds(matchIds)
		Dim offset As Int = 0
	Dim guard As Int = 0
	Dim previousFirst As String = ""
	Dim more As Boolean = False
	Do While guard < 50
		guard = guard + 1
		Dim query As String = modDb.TBL_EVENTS & "?select=*&match_id=in." & joinedIds & _
			"&order=timestamp.asc,id.asc&limit=" & PAGE_SIZE & "&offset=" & offset
		Dim raw As Object = modSupabase.RestGet(query)
		If modSupabase.LastError <> "" Or (raw Is List) = False Then
			Log("FetchEventChunk: " & modSupabase.LastError)
			out.Put("ok", False)
			out.Put("error", "Could not read events. Nothing was changed.")
			Return out
		End If
		Dim rows As List = raw
		If rows.Size = 0 Then Exit
		Dim first As Map = rows.Get(0)
		Dim firstId As String = first.GetDefault("id", "")
		If firstId <> "" And firstId = previousFirst Then
			out.Put("ok", False)
			out.Put("error", "Could not read every event. Nothing was changed.")
			Return out
		End If
		previousFirst = firstId
		Dim r As Int
		For r = 0 To rows.Size - 1
			events.Add(modDb.MapEvent(rows.Get(r)))
		Next
		If rows.Size < PAGE_SIZE Then
			more = False
			Exit
		End If
		more = True
		offset = offset + rows.Size
	Loop
	If more Then
		out.Put("ok", False)
		out.Put("error", "Could not read every event. Nothing was changed.")
	End If
	Return out
End Sub

Private Sub FetchProfiles(ids As List) As Map
	Dim out As Map
	out.Initialize
	Dim profiles As Map
	profiles.Initialize
	out.Put("ok", True)
	out.Put("profiles", profiles)
	out.Put("error", "")
	Dim chunkStart As Int = 0
	Do While chunkStart < ids.Size
		Dim chunkEnd As Int = Min(chunkStart + 40, ids.Size)
		Dim chunk As List
		chunk.Initialize
		Dim i As Int
		For i = chunkStart To chunkEnd - 1
			chunk.Add(ids.Get(i))
		Next
		Dim query As String = modDb.TBL_PROFILES & "?select=id,name,squad_number,preferred_position,secondary_position,phone,emergency_contact,date_of_birth,medical_notes&id=in." & JoinIds(chunk)
		Dim raw As Object = modSupabase.RestGet(query)
		If modSupabase.LastError <> "" Or (raw Is List) = False Then
			Log("FetchProfiles: " & modSupabase.LastError)
			out.Put("ok", False)
			out.Put("error", "Could not read player details. Nothing was changed.")
			Return out
		End If
		Dim rows As List = raw
		Dim r As Int
		For r = 0 To rows.Size - 1
			Dim profile As Map = modDb.MapProfile(rows.Get(r))
			Dim id As String = profile.GetDefault("id", "")
			If id <> "" Then profiles.Put(id, profile)
		Next
		chunkStart = chunkEnd
	Loop
	Return out
End Sub

Private Sub JoinIds(ids As List) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("(")
	Dim i As Int
	For i = 0 To ids.Size - 1
		If i > 0 Then sb.Append(",")
		sb.Append(ids.Get(i))
	Next
	sb.Append(")")
	Return sb.ToString
End Sub

Private Sub PlayersSheet(clubs As List, profiles As Map) As Map
	Dim headers As List = Cells(Array As Object("Club", "Name", "Squad number", "Preferred position", "Secondary position", "Phone", "Emergency contact", "Date of birth", "Medical notes"))
	Dim rows As List
	rows.Initialize
	Dim i As Int
	For i = 0 To clubs.Size - 1
		Dim club As Map = clubs.Get(i)
		Dim clubName As String = club.GetDefault("name", "")
		Dim memObj As Object = club.GetDefault("members", Null)
		If (memObj Is List) = False Then Continue
		Dim members As List = memObj
		Dim j As Int
		For j = 0 To members.Size - 1
			Dim mem As Map = members.Get(j)
			Dim profile As Map = mem
			Dim pid As String = mem.GetDefault("id", "")
			If pid <> "" And profiles.ContainsKey(pid) Then profile = profiles.Get(pid)
			Dim squad As String = ""
			Dim squadNo As Int = AsInt(profile.GetDefault("squadNumber", 0))
			If squadNo <> 0 Then squad = "" & squadNo
			rows.Add(Cells(Array As Object( _
				clubName, _
				profile.GetDefault("name", mem.GetDefault("name", "")), _
				squad, _
				profile.GetDefault("preferredPosition", ""), _
				profile.GetDefault("secondaryPosition", ""), _
				profile.GetDefault("phone", ""), _
				profile.GetDefault("emergencyContact", ""), _
				profile.GetDefault("dateOfBirth", ""), _
				profile.GetDefault("medicalNotes", ""))))
		Next
	Next
	SortPlayerRows(rows)
	Return MakeSheet("Players", headers, rows, NumericCols(Array As Int(2)))
End Sub

Private Sub MatchesSheet(clubs As List, matches As List) As Map
	Dim headers As List = Cells(Array As Object("Club", "Date", "Opponent", "Home/Away", "Competition", "Location", "Meet time", "Kickoff", "Status", "Score", "Formation", "Report"))
	Dim clubNames As Map = IdSet(clubs)
	Dim rows As List
	rows.Initialize
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		Dim side As String = "Home"
		If IsHomeMatch(m) = False Then side = "Away"
		Dim opponent As String = m.GetDefault("opponentName", "")
		If opponent = "" Then opponent = m.GetDefault("title", "")
		rows.Add(Cells(Array As Object( _
			clubNames.GetDefault(m.GetDefault("clubId", ""), ""), _
			DateOnly(m.GetDefault("date", "")), _
			opponent, _
			side, _
			m.GetDefault("competition", ""), _
			m.GetDefault("location", ""), _
			m.GetDefault("meetTime", ""), _
			m.GetDefault("kickOffTime", ""), _
			m.GetDefault("status", ""), _
			AsInt(m.GetDefault("scoreA", 0)) & "-" & AsInt(m.GetDefault("scoreB", 0)), _
			m.GetDefault("formation", ""), _
			m.GetDefault("aiSummary", ""))))
	Next
	Dim noNumbers As Map
	noNumbers.Initialize
	Return MakeSheet("Matches", headers, rows, noNumbers)
End Sub

Private Sub EventsSheet(clubs As List, matches As List, events As List, names As Map) As Map
	Dim headers As List = Cells(Array As Object("Club", "Match", "Time", "Minute", "Type", "Team", "Scorer", "Assist", "Player", "Player out", "Player in", "Notes"))
	Dim clubNames As Map = IdSet(clubs)
	Dim matchLabels As Map
	matchLabels.Initialize
	Dim matchClubs As Map
	matchClubs.Initialize
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim m As Map = matches.Get(i)
		Dim mid As String = m.GetDefault("id", "")
		If mid = "" Then Continue
		matchLabels.Put(mid, MatchLabel(m))
		matchClubs.Put(mid, clubNames.GetDefault(m.GetDefault("clubId", ""), ""))
	Next
	Dim rows As List
	rows.Initialize
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		Dim matchId As String = e.GetDefault("matchId", "")
		Dim details As Map = DetailsOf(e)
		Dim eventType As String = e.GetDefault("type", "")
		Dim scorerText As String = ""
		Dim assistText As String = ""
		If eventType = "GOAL" Then
			scorerText = Person(names, FirstText(details, Array As String("scorer")))
			assistText = Person(names, details.GetDefault("assist", ""))
		End If
		Dim playerText As String = Person(names, FirstText(details, Array As String("player", "playerId")))
		If playerText = "" And (eventType = "YELLOW_CARD" Or eventType = "RED_CARD") Then
			playerText = Person(names, FirstText(details, Array As String("scorer")))
		End If
		rows.Add(Cells(Array As Object( _
			matchClubs.GetDefault(matchId, ""), _
			matchLabels.GetDefault(matchId, matchId), _
			FormatMillis(e.GetDefault("timestamp", 0)), _
			MinuteText(details), _
			eventType, _
			details.GetDefault("team", ""), _
			scorerText, _
			assistText, _
			playerText, _
			Person(names, details.GetDefault("playerOut", "")), _
			Person(names, details.GetDefault("playerIn", "")), _
			e.GetDefault("content", ""))))
	Next
	Return MakeSheet("Events", headers, rows, NumericCols(Array As Int(3)))
End Sub

Private Sub StatsSheet(clubs As List, matches As List, events As List) As Map
	Dim headers As List = Cells(Array As Object("Club", "Player", "Goals", "Assists", "Appearances", "Minutes", "Yellow cards", "Red cards", "POTM"))
	Dim rows As List
	rows.Initialize
	Dim i As Int
	For i = 0 To clubs.Size - 1
		Dim club As Map = clubs.Get(i)
		' Cached match JSON repeats goals that are also stored as events. Count those from the full event list.
		Dim stats As Map = modStats.Compute(club, MatchesForStats(matches, events), events, "all")
		Dim playersObj As Object = stats.GetDefault("players", Null)
		If (playersObj Is List) = False Then Continue
		Dim players As List = playersObj
		Dim clubName As String = club.GetDefault("name", "")
		Dim p As Int
		For p = 0 To players.Size - 1
			Dim player As Map = players.Get(p)
			rows.Add(Cells(Array As Object( _
				clubName, _
				player.GetDefault("name", ""), _
				AsInt(player.GetDefault("goals", 0)), _
				AsInt(player.GetDefault("assists", 0)), _
				AsInt(player.GetDefault("apps", 0)), _
				AsInt(player.GetDefault("minutesPlayed", 0)), _
				AsInt(player.GetDefault("yellowCards", 0)), _
				AsInt(player.GetDefault("redCards", 0)), _
				AsInt(player.GetDefault("potmWins", 0)))))
		Next
	Next
	Return MakeSheet("Stats", headers, rows, NumericCols(Array As Int(2, 3, 4, 5, 6, 7, 8)))
End Sub

Private Sub MatchLabel(m As Map) As String
	Dim side As String = "Home"
	If IsHomeMatch(m) = False Then side = "Away"
	Dim opponent As String = m.GetDefault("opponentName", "")
	If opponent = "" Then opponent = m.GetDefault("title", "Match")
	Return DateOnly(m.GetDefault("date", "")) & " vs " & opponent & " (" & side & ")"
End Sub

Private Sub MakeSheet(name As String, headers As List, rows As List, numeric As Map) As Map
	Dim sheet As Map
	sheet.Initialize
	sheet.Put("name", name)
	sheet.Put("headers", headers)
	sheet.Put("rows", rows)
	sheet.Put("numeric", numeric)
	Return sheet
End Sub

Private Sub Cells(values() As Object) As List
	Dim row As List
	row.Initialize
	Dim i As Int
	For i = 0 To values.Length - 1
		row.Add(TextOf(values(i)))
	Next
	Return row
End Sub

Private Sub TextOf(v As Object) As String
	If v = Null Then Return ""
	Dim s As String = "" & v
	If s = "null" Then Return ""
	Return s
End Sub

' Copy matches so the live app state is left untouched. Drop cached goals, assists,
' and cards when the match already has those events; keep minutes as a fallback.
Private Sub MatchesForStats(matches As List, events As List) As List
	Dim copy As List
	copy.Initialize
	Dim i As Int
	For i = 0 To matches.Size - 1
		Dim src As Map = matches.Get(i)
		Dim m As Map
		m.Initialize
		Dim k As Int
		For k = 0 To src.Size - 1
			m.Put(src.GetKeyAt(k), src.GetValueAt(k))
		Next
		If MatchHasCountingEvents(m.GetDefault("id", ""), events) Then
			m.Put("playerStats", MinutesOnly(src.GetDefault("playerStats", Null)))
		End If
		copy.Add(m)
	Next
	Return copy
End Sub

Private Sub MatchHasCountingEvents(matchId As String, events As List) As Boolean
	If matchId = "" Then Return False
	Dim i As Int
	For i = 0 To events.Size - 1
		Dim e As Map = events.Get(i)
		If e.GetDefault("matchId", "") <> matchId Then Continue
		Dim eventType As String = e.GetDefault("type", "")
		If eventType = "GOAL" Or eventType = "YELLOW_CARD" Or eventType = "RED_CARD" Then Return True
	Next
	Return False
End Sub

Private Sub MinutesOnly(playerStats As Object) As Map
	Dim stripped As Map
	stripped.Initialize
	If playerStats = Null Or (playerStats Is Map) = False Then Return stripped
	Dim ps As Map = playerStats
	Dim i As Int
	For i = 0 To ps.Size - 1
		Dim rowObj As Object = ps.GetValueAt(i)
		If (rowObj Is Map) = False Then Continue
		Dim row As Map = rowObj
		Dim kept As Map
		kept.Initialize
		kept.Put("minutesPlayed", row.GetDefault("minutesPlayed", 0))
		stripped.Put(ps.GetKeyAt(i), kept)
	Next
	Return stripped
End Sub

Private Sub NumericCols(indexes() As Int) As Map
	Dim flags As Map
	flags.Initialize
	Dim i As Int
	For i = 0 To indexes.Length - 1
		flags.Put("" & indexes(i), True)
	Next
	Return flags
End Sub

Private Sub SortPlayerRows(rows As List)
	Dim a As Int
	For a = 0 To rows.Size - 2
		Dim b As Int
		For b = a + 1 To rows.Size - 1
			Dim later As List = rows.Get(b)
			Dim earlier As List = rows.Get(a)
			If PlayerRowBefore(later, earlier) Then
				Dim tmp As Object = rows.Get(a)
				rows.Set(a, rows.Get(b))
				rows.Set(b, tmp)
			End If
		Next
	Next
End Sub

Private Sub PlayerRowBefore(left As List, right As List) As Boolean
	Dim club As Int = ("" & left.Get(0)).CompareTo("" & right.Get(0))
	If club <> 0 Then Return club < 0
	Dim ls As Int = SquadSortKey(left.Get(2))
	Dim rs As Int = SquadSortKey(right.Get(2))
	If ls <> rs Then Return ls < rs
	Return ("" & left.Get(1)).CompareTo("" & right.Get(1)) < 0
End Sub

Private Sub SquadSortKey(v As Object) As Int
	Dim s As String = "" & v
	If s = "" Then Return 9999
	Return AsInt(s)
End Sub

Private Sub SortEvents(events As List)
	Dim a As Int
	For a = 0 To events.Size - 2
		Dim b As Int
		For b = a + 1 To events.Size - 1
			Dim ea As Map = events.Get(a)
			Dim eb As Map = events.Get(b)
			Dim ta As Long = ToLong(ea.GetDefault("timestamp", 0))
			Dim tb As Long = ToLong(eb.GetDefault("timestamp", 0))
			If tb < ta Then
				events.Set(a, eb)
				events.Set(b, ea)
			End If
		Next
	Next
End Sub

Private Sub PrepareSharedDir As String
	File.MakeDir(File.DirInternal, "shared")
	Dim dir As String = File.Combine(File.DirInternal, "shared")
	Dim existing As List = File.ListFiles(dir)
	If existing.IsInitialized Then
		Dim i As Int
		For i = 0 To existing.Size - 1
			Dim name As String = existing.Get(i)
			If name.EndsWith(".xlsx") Then File.Delete(dir, name)
		Next
	End If
	Return dir
End Sub

Private Sub FileStamp As String
	Dim oldFormat As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy-MM-dd"
	Dim s As String = DateTime.Date(DateTime.Now)
	DateTime.DateFormat = oldFormat
	Return s
End Sub

Private Sub WriteWorkbook(dir As String, fileName As String, sheets As List) As String
	Dim fos As JavaObject
	Dim zip As JavaObject
	Try
		Dim path As String = File.Combine(dir, fileName)
		fos.InitializeNewInstance("java.io.FileOutputStream", Array(path))
		zip.InitializeNewInstance("java.util.zip.ZipOutputStream", Array(fos))
		AddZipText(zip, "[Content_Types].xml", ContentTypesXml(sheets.Size))
		AddZipText(zip, "_rels/.rels", RootRelsXml)
		AddZipText(zip, "xl/workbook.xml", WorkbookXml(sheets))
		AddZipText(zip, "xl/_rels/workbook.xml.rels", WorkbookRelsXml(sheets.Size))
		AddZipText(zip, "xl/styles.xml", StylesXml)
		Dim i As Int
		For i = 0 To sheets.Size - 1
			Dim sheet As Map = sheets.Get(i)
			AddZipText(zip, "xl/worksheets/sheet" & (i + 1) & ".xml", WorksheetXml(sheet))
		Next
		zip.RunMethod("close", Null)
		Return ""
	Catch
		Log("WriteWorkbook: " & LastException)
		Try
			If zip.IsInitialized Then zip.RunMethod("close", Null)
		Catch
			Log("WriteWorkbook close: " & LastException)
		End Try
		Return "Could not create the spreadsheet. Nothing was changed."
	End Try
End Sub

Private Sub AddZipText(zip As JavaObject, entryName As String, xml As String)
	Dim bytes() As Byte = xml.GetBytes("UTF8")
	Dim crc As JavaObject
	crc.InitializeNewInstance("java.util.zip.CRC32", Null)
	crc.RunMethod("update", Array(bytes, 0, bytes.Length))
	Dim entry As JavaObject
	entry.InitializeNewInstance("java.util.zip.ZipEntry", Array(entryName))
	entry.RunMethod("setMethod", Array(0))
	Dim size As Long = bytes.Length
	entry.RunMethod("setSize", Array(size))
	entry.RunMethod("setCompressedSize", Array(size))
	Dim crcVal As Long = crc.RunMethod("getValue", Null)
	entry.RunMethod("setCrc", Array(crcVal))
	zip.RunMethod("putNextEntry", Array(entry))
	zip.RunMethod("write", Array(bytes, 0, bytes.Length))
	zip.RunMethod("closeEntry", Null)
End Sub

Private Sub ContentTypesXml(sheetCount As Int) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>")
	sb.Append("<Types xmlns=""http://schemas.openxmlformats.org/package/2006/content-types"">")
	sb.Append("<Default Extension=""rels"" ContentType=""application/vnd.openxmlformats-package.relationships+xml""/>")
	sb.Append("<Default Extension=""xml"" ContentType=""application/xml""/>")
	sb.Append("<Override PartName=""/xl/workbook.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml""/>")
	sb.Append("<Override PartName=""/xl/styles.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml""/>")
	Dim i As Int
	For i = 1 To sheetCount
		sb.Append("<Override PartName=""/xl/worksheets/sheet" & i & ".xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml""/>")
	Next
	sb.Append("</Types>")
	Return sb.ToString
End Sub

Private Sub RootRelsXml As String
	Return "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>" & _
		"<Relationships xmlns=""http://schemas.openxmlformats.org/package/2006/relationships"">" & _
		"<Relationship Id=""rId1"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"" Target=""xl/workbook.xml""/>" & _
		"</Relationships>"
End Sub

Private Sub WorkbookXml(sheets As List) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>")
	sb.Append("<workbook xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main"" xmlns:r=""http://schemas.openxmlformats.org/officeDocument/2006/relationships"">")
	sb.Append("<sheets>")
	Dim i As Int
	For i = 0 To sheets.Size - 1
		Dim sheet As Map = sheets.Get(i)
		sb.Append("<sheet name=""" & XmlText(sheet.GetDefault("name", "Sheet" & (i + 1))) & """ sheetId=""" & (i + 1) & """ r:id=""rId" & (i + 1) & """/>")
	Next
	sb.Append("</sheets></workbook>")
	Return sb.ToString
End Sub

Private Sub WorkbookRelsXml(sheetCount As Int) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>")
	sb.Append("<Relationships xmlns=""http://schemas.openxmlformats.org/package/2006/relationships"">")
	Dim i As Int
	For i = 1 To sheetCount
		sb.Append("<Relationship Id=""rId" & i & """ Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"" Target=""worksheets/sheet" & i & ".xml""/>")
	Next
	sb.Append("<Relationship Id=""rId" & (sheetCount + 1) & """ Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"" Target=""styles.xml""/>")
	sb.Append("</Relationships>")
	Return sb.ToString
End Sub

Private Sub StylesXml As String
	Return "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>" & _
		"<styleSheet xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main"">" & _
		"<fonts count=""1""><font><sz val=""11""/><name val=""Calibri""/></font></fonts>" & _
		"<fills count=""2""><fill><patternFill patternType=""none""/></fill><fill><patternFill patternType=""gray125""/></fill></fills>" & _
		"<borders count=""1""><border/></borders>" & _
		"<cellStyleXfs count=""1""><xf numFmtId=""0"" fontId=""0"" fillId=""0"" borderId=""0""/></cellStyleXfs>" & _
		"<cellXfs count=""1""><xf numFmtId=""0"" fontId=""0"" fillId=""0"" borderId=""0"" xfId=""0""/></cellXfs>" & _
		"</styleSheet>"
End Sub

Private Sub WorksheetXml(sheet As Map) As String
	Dim headers As List = sheet.Get("headers")
	Dim rows As List = sheet.Get("rows")
	Dim numeric As Map = sheet.Get("numeric")
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>")
	sb.Append("<worksheet xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main""><sheetData>")
	sb.Append(RowXml(1, headers, numeric, False))
	Dim r As Int
	For r = 0 To rows.Size - 1
		Dim rowValues As List = rows.Get(r)
		sb.Append(RowXml(r + 2, rowValues, numeric, True))
	Next
	sb.Append("</sheetData></worksheet>")
	Return sb.ToString
End Sub

Private Sub RowXml(rowNumber As Int, values As List, numeric As Map, useNumeric As Boolean) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<row r=""" & rowNumber & """>")
	Dim c As Int
	For c = 0 To values.Size - 1
		Dim text As String = "" & values.Get(c)
		If text = "" Then Continue
		Dim ref As String = ColumnName(c) & rowNumber
		If useNumeric And numeric.ContainsKey("" & c) And IsIntegerText(text) Then
			sb.Append("<c r=""" & ref & """><v>" & text & "</v></c>")
		Else
			sb.Append("<c r=""" & ref & """ t=""inlineStr""><is><t xml:space=""preserve"">" & XmlText(text) & "</t></is></c>")
		End If
	Next
	sb.Append("</row>")
	Return sb.ToString
End Sub

Private Sub ColumnName(indexZero As Int) As String
	Dim n As Int = indexZero + 1
	Dim s As String = ""
	Do While n > 0
		n = n - 1
		s = Chr(65 + (n Mod 26)) & s
		n = Floor(n / 26)
	Loop
	Return s
End Sub

Private Sub IsIntegerText(text As String) As Boolean
	If text = "" Then Return False
	Dim startAt As Int = 0
	If text.StartsWith("-") Then
		If text.Length = 1 Then Return False
		startAt = 1
	End If
	Dim i As Int
	For i = startAt To text.Length - 1
		Dim code As Int = Asc(text.CharAt(i))
		If code < 48 Or code > 57 Then Return False
	Next
	Return True
End Sub

Private Sub XmlText(raw As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim i As Int
	For i = 0 To raw.Length - 1
		Dim code As Int = Asc(raw.CharAt(i))
		If code <> 9 And code <> 10 And code <> 13 And code < 32 Then Continue
		If code = 38 Then
			sb.Append("&amp;")
		Else If code = 60 Then
			sb.Append("&lt;")
		Else If code = 62 Then
			sb.Append("&gt;")
		Else If code = 34 Then
			sb.Append("&quot;")
		Else
			sb.Append(raw.CharAt(i))
		End If
	Next
	Return sb.ToString
End Sub

Private Sub DetailsOf(e As Map) As Map
	Dim details As Map
	details.Initialize
	Dim obj As Object = e.GetDefault("details", Null)
	If obj <> Null And obj Is Map Then Return obj
	Return details
End Sub

Private Sub FirstText(details As Map, keys() As String) As String
	Dim i As Int
	For i = 0 To keys.Length - 1
		Dim value As String = "" & details.GetDefault(keys(i), "")
		If value <> "" And value <> "null" Then Return value
	Next
	Return ""
End Sub

Private Sub Person(names As Map, id As String) As String
	If id = "" Or id = "null" Then Return ""
	If names.ContainsKey(id) Then
		Dim name As String = names.Get(id)
		If name <> "" Then Return name
	End If
	Return id
End Sub

Private Sub MinuteText(details As Map) As String
	If details.ContainsKey("minute") = False Then Return ""
	Return "" & AsInt(details.Get("minute"))
End Sub

Private Sub IsHomeMatch(m As Map) As Boolean
	Dim v As Object = m.GetDefault("isHome", True)
	If v = False Then Return False
	If ("" & v).ToLowerCase = "false" Then Return False
	Return True
End Sub

Private Sub DateOnly(dateStr As String) As String
	Dim s As String = dateStr
	Dim ti As Int = s.IndexOf("T")
	If ti > 0 Then Return s.SubString2(0, ti)
	Return s
End Sub

Private Sub FormatMillis(v As Object) As String
	Dim ms As Long = ToLong(v)
	If ms <= 0 Then Return ""
	Dim oldFormat As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy-MM-dd HH:mm"
	Dim s As String = DateTime.Date(ms)
	DateTime.DateFormat = oldFormat
	Return s
End Sub

Private Sub AsInt(v As Object) As Int
	Try
		If v = Null Then Return 0
		Dim n As Int = v
		Return n
	Catch
		Return 0
	End Try
End Sub

Private Sub ToLong(v As Object) As Long
	Try
		If v = Null Then Return 0
		Dim n As Long = v
		Return n
	Catch
		Return 0
	End Try
End Sub
