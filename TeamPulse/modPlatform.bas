B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Android and iOS differences: private files, toasts, ids, ISO times, and URL encoding.

Sub Process_Globals
	Private xui As XUI
End Sub

' Private app storage. Android internal files, iOS documents.
Public Sub AppDir As String
	Return xui.DefaultFolder
End Sub

Public Sub Toast(Message As String, LongDuration As Boolean)
#if B4A
	ToastMessageShow(Message, LongDuration)
#else if B4i
	Main.hd.ToastMessageShow(Message, LongDuration)
#End If
End Sub

Public Sub ProgressShow(Message As String)
#if B4A
	ProgressDialogShow(Message)
#else if B4i
	Main.hd.ProgressDialogShow(Message)
#End If
End Sub

Public Sub ProgressShow2(Message As String, Cancelable As Boolean)
#if B4A
	ProgressDialogShow2(Message, Cancelable)
#else if B4i
	Main.hd.ProgressDialogShow(Message)
#End If
End Sub

Public Sub ProgressHide
#if B4A
	ProgressDialogHide
#else if B4i
	Main.hd.ProgressDialogHide
#End If
End Sub

' Lowercase UUID. Falls back to a local id if the platform call fails.
Public Sub NewUuid As String
	Try
#if B4A
		Dim uuid As JavaObject
		uuid.InitializeStatic("java.util.UUID")
		Return uuid.RunMethodJO("randomUUID", Null).RunMethod("toString", Null)
#else if B4i
		Dim no As NativeObject
		Dim s As String = no.Initialize("NSUUID").RunMethod("UUID", Null).RunMethod("UUIDString", Null).AsString
		Return s.ToLowerCase
#End If
	Catch
		Log("NewUuid: " & LastException)
		Return "local-" & DateTime.Now & "-" & Rnd(1000, 9999)
	End Try
End Sub

' ISO-8601 to Unix milliseconds, the same unit as DateTime.Now on B4A and B4i. Returns -1 when the text is not a timestamp.
Public Sub ParseIsoMillis(s As String) As Long
	If s = Null Or s.Trim = "" Then Return -1
	Dim unixMs As Long = -1
#if B4A
	Try
		Dim jo As JavaObject
		jo.InitializeStatic("java.time.Instant")
		Dim inst As JavaObject = jo.RunMethod("parse", Array(s))
		unixMs = inst.RunMethod("toEpochMilli", Null)
	Catch
		Log("ParseIsoMillis: " & LastException)
		unixMs = -1
	End Try
#else if B4i
	unixMs = ParseIsoNative(s)
	If unixMs = -1 Then
		Dim dot As Int = s.IndexOf(".")
		If dot > 0 Then
			Dim rest As String = s.SubString(dot + 1)
			Dim i As Int
			For i = 0 To rest.Length - 1
				Dim c As String = rest.CharAt(i)
				If c = "Z" Or c = "+" Or c = "-" Then
					unixMs = ParseIsoNative(s.SubString2(0, dot) & rest.SubString(i))
					Exit
				End If
			Next
		End If
	End If
#End If
	If unixMs < 0 Then Return -1
	Return UnixMillisToTicks(unixMs)
End Sub

Public Sub FormatIsoMillis(ms As Long) As String
	Dim unixMs As Long = TicksToUnixMillis(ms)
#if B4A
	Try
		Dim inst As JavaObject
		inst.InitializeStatic("java.time.Instant")
		Return inst.RunMethodJO("ofEpochMilli", Array(unixMs)).RunMethod("toString", Null)
	Catch
		Log("FormatIsoMillis: " & LastException)
	End Try
#else if B4i
	Try
		Return FormatIsoNative(unixMs)
	Catch
		Log("FormatIsoMillis: " & LastException)
	End Try
#End If
	DateTime.DateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
	Return DateTime.Date(ms)
End Sub

' B4A and B4i DateTime ticks are Unix milliseconds (TicksPerSecond = 1000).
' One minute is 60 of those seconds. An earlier build added the .NET year-1 offset
' (about 6.2e17). That is not this clock, and it made match minutes wildly wrong.
Public Sub MinuteTicks As Long
	Return 60 * DateTime.TicksPerSecond
End Sub

Public Sub UnixMillisToTicks(unixMs As Long) As Long
	Return NormalizeTicks(unixMs)
End Sub

' Strip the .NET offset if a previous build stored one. Real timestamps are about 1e12.
Public Sub NormalizeTicks(n As Long) As Long
	If n > 100000000000000 Then
		Dim unixMs As Long = n - 621355968000000000
		If unixMs > 100000000000 Then Return unixMs
	End If
	Return n
End Sub

Private Sub TicksToUnixMillis(ticks As Long) As Long
	Return NormalizeTicks(ticks)
End Sub

' JSON for a Map or List. Keeps maps, lists, strings, numbers, booleans, and null.
' Anything else is left out so one odd value cannot abort the whole write.
' If null itself is rejected, a second pass omits those keys and still returns text.
Public Sub JsonString(body As Object) As String
	Dim safe As Object = CopyJsonValue(body, True)
	Try
		Return GenerateJson(safe)
	Catch
		Log("JsonString: " & LastException)
	End Try
	Return GenerateJson(CopyJsonValue(body, False))
End Sub

' Replace finalName with the tmp file. On iOS the replace is atomic and the file is synced to disk.
Public Sub ReplaceFile(dir As String, tmpName As String, finalName As String)
#if B4i
	Try
		Dim no As NativeObject = Me
		Dim ok As Boolean = no.RunMethod("tpReplaceFile:tmp:dest:", Array(dir, tmpName, finalName)).AsBoolean
		If ok Then Return
		Log("ReplaceFile: native replace failed")
	Catch
		Log("ReplaceFile: " & LastException)
	End Try
#End If
	If File.Exists(dir, finalName) Then File.Delete(dir, finalName)
	File.Copy(dir, tmpName, dir, finalName)
	If File.Exists(dir, tmpName) Then File.Delete(dir, tmpName)
End Sub

' iOS only. Keeps the process alive long enough to finish the Supabase queue after leaving the app.
Public Sub BeginBackgroundTask
	SetBackgroundTask(1)
End Sub

Public Sub EndBackgroundTask
	SetBackgroundTask(0)
End Sub

Private Sub SetBackgroundTask(mode As Int)
	If mode < 0 Then Return
#if B4i
	Try
		Dim no As NativeObject = Me
		no.RunMethod("tpBackground:", Array(mode))
	Catch
		Log("SetBackgroundTask: " & LastException)
	End Try
#End If
End Sub

' Same rules as Java URLEncoder (UTF-8, space as +).
Public Sub UrlEncode(s As String) As String
#if B4A
	Try
		Dim enc As JavaObject
		enc.InitializeStatic("java.net.URLEncoder")
		Return enc.RunMethod("encode", Array(s, "UTF-8"))
	Catch
		Log("UrlEncode: " & LastException)
		Return UrlEncodeUtf8(s)
	End Try
#else if B4i
	Return UrlEncodeUtf8(s)
#End If
End Sub

' Canvas text is density-scaled on Android. iOS canvas text is already in points.
Public Sub TextScale As Float
#if B4A
	Try
		Dim jo As JavaObject
		jo.InitializeContext
		Dim res As JavaObject = jo.RunMethod("getResources", Null)
		Dim metrics As JavaObject = res.RunMethod("getDisplayMetrics", Null)
		Dim scale As Float = metrics.GetField("scaledDensity")
		If scale <= 0 Then Return 1
		Return scale
	Catch
		Log("TextScale: " & LastException)
		Return 1
	End Try
#else if B4i
	Return 1
#End If
End Sub

#if B4i
Public Sub TopPage As Page
	Dim info As B4XPageInfo = B4XPages.GetManager.GetTopPage
	If info.IsInitialized Then
		If info.Parent.IsInitialized Then Return info.Parent.NativeType
	End If
	Return B4XPages.GetNativeParent(B4XPages.MainPage)
End Sub

Private Sub ParseIsoNative(s As String) As Long
	Dim fmt As NativeObject
	fmt = fmt.Initialize("NSISO8601DateFormatter").RunMethod("new", Null)
	Dim tz As NativeObject
	tz = tz.Initialize("NSTimeZone").RunMethod("timeZoneForSecondsFromGMT:", Array(0))
	fmt.SetField("timeZone", tz)
	' Internet date-time plus fractional seconds, then without fractions.
	fmt.SetField("formatOptions", 3955)
	Dim date As Object = fmt.RunMethod("dateFromString:", Array(s))
	If date = Null Then
		fmt.SetField("formatOptions", 1907)
		date = fmt.RunMethod("dateFromString:", Array(s))
	End If
	If date = Null Then Return -1
	Dim no As NativeObject = date
	Dim secs As Double = no.RunMethod("timeIntervalSince1970", Null).AsNumber
	Return secs * 1000
End Sub

Private Sub FormatIsoNative(ms As Long) As String
	Dim date As NativeObject
	date = date.Initialize("NSDate").RunMethod("dateWithTimeIntervalSince1970:", Array(ms / 1000.0))
	Dim fmt As NativeObject
	fmt = fmt.Initialize("NSISO8601DateFormatter").RunMethod("new", Null)
	Dim tz As NativeObject
	tz = tz.Initialize("NSTimeZone").RunMethod("timeZoneForSecondsFromGMT:", Array(0))
	fmt.SetField("timeZone", tz)
	fmt.SetField("formatOptions", 3955)
	Return fmt.RunMethod("stringFromDate:", Array(date)).AsString
End Sub
#End If

Private Sub UrlEncodeUtf8(s As String) As String
	Dim bytes() As Byte = s.GetBytes("UTF8")
	Dim sb As StringBuilder
	sb.Initialize
	Dim i As Int
	For i = 0 To bytes.Length - 1
		Dim u As Int = Bit.And(bytes(i), 0xFF)
		If (u >= 65 And u <= 90) Or (u >= 97 And u <= 122) Or (u >= 48 And u <= 57) Or u = 45 Or u = 95 Or u = 46 Or u = 42 Then
			sb.Append(Chr(u))
		Else If u = 32 Then
			sb.Append("+")
		Else
			sb.Append("%")
#if B4A
			Dim hex As String = Bit.ToHexString(u).ToUpperCase
			If hex.Length < 2 Then hex = "0" & hex
#else if B4i
			Dim hex As String = ByteToHex(u)
#End If
			sb.Append(hex)
		End If
	Next
	Return sb.ToString
End Sub

#if B4i
Private Sub ByteToHex(u As Int) As String
	Dim chars As String = "0123456789ABCDEF"
	Dim hi As Int = Bit.ShiftRight(Bit.And(u, 0xF0), 4)
	Dim lo As Int = Bit.And(u, 0x0F)
	Return "" & chars.CharAt(hi) & chars.CharAt(lo)
End Sub
#End If

Private Sub GenerateJson(body As Object) As String
	Dim jg As JSONGenerator
	If body Is List Then
		Dim lst As List = body
		jg.Initialize2(lst)
	Else
		Dim mp As Map = body
		jg.Initialize(mp)
	End If
	Return jg.ToString
End Sub

Private Sub CopyJsonValue(v As Object, allowNull As Boolean) As Object
	If v = Null Then Return Null
	If v Is Map Then Return CopyJsonMap(v, allowNull)
	If v Is List Then Return CopyJsonList(v, allowNull)
	Return v
End Sub

Private Sub CopyJsonMap(src As Map, allowNull As Boolean) As Map
	Dim out As Map
	out.Initialize
	If src.IsInitialized = False Then Return out
	For Each k As String In src.Keys
		Dim raw As Object = src.Get(k)
		If raw = Null Then
			If allowNull Then out.Put(k, Null)
			Continue
		End If
		If raw Is Map Then
			out.Put(k, CopyJsonMap(raw, allowNull))
		Else If raw Is List Then
			out.Put(k, CopyJsonList(raw, allowNull))
		Else If JsonPrimitive(raw) Then
			out.Put(k, raw)
		End If
	Next
	Return out
End Sub

Private Sub CopyJsonList(src As List, allowNull As Boolean) As List
	Dim out As List
	out.Initialize
	If src.IsInitialized = False Then Return out
	Dim i As Int
	For i = 0 To src.Size - 1
		Dim raw As Object = src.Get(i)
		If raw = Null Then
			If allowNull Then out.Add(Null)
			Continue
		End If
		If raw Is Map Then
			out.Add(CopyJsonMap(raw, allowNull))
		Else If raw Is List Then
			out.Add(CopyJsonList(raw, allowNull))
		Else If JsonPrimitive(raw) Then
			out.Add(raw)
		End If
	Next
	Return out
End Sub

Private Sub JsonPrimitive(v As Object) As Boolean
	If v Is String Then Return True
	If v Is Boolean Then Return True
	If v Is Int Or v Is Long Or v Is Double Or v Is Float Then Return True
	Try
		Dim t As String = GetType(v).ToLowerCase
		If t.Contains("bool") Then Return True
		If t.Contains("number") Or t.Contains("integer") Or t.Contains("double") Or t.Contains("float") Or t.Contains("long") Then Return True
	Catch
		Log("JsonPrimitive: " & LastException)
	End Try
	Return False
End Sub

#if OBJC
- (BOOL)tpReplaceFile:(NSString*)dir tmp:(NSString*)tmp dest:(NSString*)destName {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *tmpPath = [dir stringByAppendingPathComponent:tmp];
	NSString *destPath = [dir stringByAppendingPathComponent:destName];
	NSURL *src = [NSURL fileURLWithPath:tmpPath];
	NSURL *dest = [NSURL fileURLWithPath:destPath];
	NSError *err = nil;
	BOOL moved = NO;
	if ([fm fileExistsAtPath:destPath]) {
		moved = [fm replaceItemAtURL:dest withItemAtURL:src backupItemName:nil options:0 resultingItemURL:nil error:&err];
	} else {
		moved = [fm moveItemAtURL:src toURL:dest error:&err];
	}
	if (!moved || err != nil) return NO;
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:destPath];
	if (handle != nil) {
		[handle synchronizeFile];
		[handle closeFile];
	}
	return YES;
}

- (NSNumber*)tpBackground:(int)mode {
	static UIBackgroundTaskIdentifier tpBgTask = UIBackgroundTaskInvalid;
	UIApplication *app = [UIApplication sharedApplication];
	if (mode == 1) {
		if (tpBgTask != UIBackgroundTaskInvalid) return @(tpBgTask);
		tpBgTask = [app beginBackgroundTaskWithName:@"TeamPulseSync" expirationHandler:^{
			UIApplication *expiring = [UIApplication sharedApplication];
			if (tpBgTask != UIBackgroundTaskInvalid) {
				[expiring endBackgroundTask:tpBgTask];
				tpBgTask = UIBackgroundTaskInvalid;
			}
		}];
		return @(tpBgTask);
	}
	if (tpBgTask != UIBackgroundTaskInvalid) {
		[app endBackgroundTask:tpBgTask];
		tpBgTask = UIBackgroundTaskInvalid;
	}
	return @(0);
}
#End If
