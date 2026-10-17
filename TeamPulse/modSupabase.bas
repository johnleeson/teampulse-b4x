B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Supabase REST + Auth client (OkHttpUtils2 for async; StrictMode for legacy sync callers).
' Requires libraries: JavaObject, JSON, OkHttpUtils2.

Sub Process_Globals
	Public Ready As Boolean
	Public LastError As String
	Public AccessToken As String
	Public RefreshToken As String
	Public UserId As String
	Public UserEmail As String
	Public DisplayName As String
	' Access token expiry in DateTime ticks. 0 means refresh on the next call.
	Public ExpiresAt As Long
	Private Const SESSION_FILE As String = "supabase_session.json"
#if B4A
	Private StrictModeReady As Boolean
#End If
End Sub

Public Sub Initialize
	Ready = False
	LastError = ""
	AccessToken = ""
	RefreshToken = ""
	UserId = ""
	UserEmail = ""
	DisplayName = ""
	ExpiresAt = 0
	Try
		AllowNetworkOnMainThread
		If modConfig.SUPABASE_URL = "" Or modConfig.SUPABASE_ANON_KEY = "" Then
			LastError = "SUPABASE_URL / SUPABASE_ANON_KEY missing in modConfig"
			Return
		End If
		LoadSession
		Ready = True
	Catch
		LastError = LastException.Message
		Log("modSupabase.Initialize failed: " & LastError)
		Ready = False
	End Try
End Sub

' Avoid NetworkOnMainThreadException for sync Rest* callers (saves, polls).
Private Sub AllowNetworkOnMainThread
#if B4A
	If StrictModeReady Then Return
	Try
		Dim builder As JavaObject
		builder.InitializeNewInstance("android.os.StrictMode$ThreadPolicy$Builder", Null)
		Dim policy As Object = builder.RunMethodJO("permitAll", Null).RunMethod("build", Null)
		Dim sm As JavaObject
		sm.InitializeStatic("android.os.StrictMode")
		sm.RunMethod("setThreadPolicy", Array(policy))
		StrictModeReady = True
	Catch
		Log("StrictMode: " & LastException.Message)
	End Try
#End If
End Sub

Public Sub IsLoggedIn As Boolean
	Return AccessToken <> "" And UserId <> ""
End Sub

Public Sub SignOut
	AccessToken = ""
	RefreshToken = ""
	UserId = ""
	UserEmail = ""
	DisplayName = ""
	ExpiresAt = 0
	Try
		If File.Exists(modPlatform.AppDir, SESSION_FILE) Then
			File.Delete(modPlatform.AppDir, SESSION_FILE)
		End If
	Catch
		Log(LastException.Message)
	End Try
	modAppState.ClearUser
End Sub

Private Sub SaveSession
	Try
		Dim m As Map
		m.Initialize
		m.Put("access_token", AccessToken)
		m.Put("refresh_token", RefreshToken)
		m.Put("user_id", UserId)
		m.Put("email", UserEmail)
		m.Put("display_name", DisplayName)
		m.Put("expires_at", ExpiresAt)
		Dim jg As JSONGenerator
		jg.Initialize(m)
		File.WriteString(modPlatform.AppDir, SESSION_FILE, jg.ToString)
	Catch
		Log("SaveSession: " & LastException.Message)
	End Try
End Sub

Private Sub LoadSession
	Try
		If File.Exists(modPlatform.AppDir, SESSION_FILE) = False Then Return
		Dim raw As String = File.ReadString(modPlatform.AppDir, SESSION_FILE)
		If raw.Length = 0 Then Return
		Dim jp As JSONParser
		jp.Initialize(raw)
		Dim m As Map = jp.NextObject
		AccessToken = m.GetDefault("access_token", "")
		RefreshToken = m.GetDefault("refresh_token", "")
		UserId = m.GetDefault("user_id", "")
		UserEmail = m.GetDefault("email", "")
		DisplayName = m.GetDefault("display_name", "")
		ExpiresAt = AsLong(m.GetDefault("expires_at", 0))
	Catch
		Log("LoadSession: " & LastException.Message)
	End Try
End Sub

Public Sub ApplyAuthResponse(data As Map) As Boolean
	LastError = ""
	Try
		AccessToken = data.GetDefault("access_token", "")
		Dim nextRefresh As String = data.GetDefault("refresh_token", "")
		If nextRefresh <> "" Then RefreshToken = nextRefresh
		Dim userObj As Object = data.Get("user")
		If userObj <> Null And userObj Is Map Then
			Dim u As Map = userObj
			UserId = u.GetDefault("id", "")
			UserEmail = u.GetDefault("email", "")
			Dim metaObj As Object = u.Get("user_metadata")
			If metaObj <> Null And metaObj Is Map Then
				Dim metaMap As Map = metaObj
				DisplayName = metaMap.GetDefault("full_name", "")
			End If
		End If
		If AccessToken = "" Or UserId = "" Then
			LastError = "Auth response missing token or user"
			Return False
		End If
		Dim secs As Long = AsLong(data.GetDefault("expires_in", 3600))
		If secs < 60 Then secs = 3600
		ExpiresAt = DateTime.Now + secs * DateTime.TicksPerSecond
		SaveSession
		Return True
	Catch
		LastError = LastException.Message
		Return False
	End Try
End Sub

' "ok" when the access token is usable, "offline" when refresh could not reach
' the server, "rejected" when the refresh token itself was refused.
Public Sub EnsureFreshToken As String
	If AccessToken = "" And RefreshToken = "" Then Return "rejected"
	If RefreshToken = "" Then Return "ok"
	If ExpiresAt > DateTime.Now + 60 * DateTime.TicksPerSecond Then Return "ok"
	Return RefreshSession
End Sub

Public Sub RefreshSession As String
	If RefreshToken = "" Then Return "rejected"
	Dim body As Map
	body.Initialize
	body.Put("refresh_token", RefreshToken)
	Dim data As Map = AuthPost("token?grant_type=refresh_token", body)
	If data.ContainsKey("access_token") Then
		If ApplyAuthResponse(data) Then Return "ok"
	End If
	Dim err As String = LastError
	If err.StartsWith("HTTP 400") Or err.StartsWith("HTTP 401") Or err.StartsWith("HTTP 403") Then
		Return "rejected"
	End If
	Return "offline"
End Sub

Public Sub AuthPost(pathAndQuery As String, bodyMap As Map) As Map
	Dim url As String = modConfig.SUPABASE_URL & "/auth/v1/" & pathAndQuery
	Return Request("POST", url, bodyMap, False, "return=representation")
End Sub

Public Sub RestGet(tableAndQuery As String) As Object
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Return RequestRaw("GET", url, "", True, "")
End Sub

Public Sub RestPost(tableAndQuery As String, body As Object, prefer As String) As Object
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Dim bodyText As String = ObjectToJson(body)
	Return RequestRaw("POST", url, bodyText, True, prefer)
End Sub

Public Sub RestPatch(tableAndQuery As String, body As Map, prefer As String) As Object
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Return RequestRaw("PATCH", url, ObjectToJson(body), True, prefer)
End Sub

Public Sub RestDelete(tableAndQuery As String) As Object
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Return RequestRaw("DELETE", url, "", True, "return=minimal")
End Sub

Public Sub Rpc(fnName As String, args As Map) As Object
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/rpc/" & fnName
	Return RequestRaw("POST", url, ObjectToJson(args), True, "return=representation")
End Sub

Private Sub ObjectToJson(body As Object) As String
	Return modPlatform.JsonString(body)
End Sub

Private Sub Request(method As String, url As String, bodyMap As Map, useUserToken As Boolean, prefer As String) As Map
	Dim raw As Object = RequestRaw(method, url, ObjectToJson(bodyMap), useUserToken, prefer)
	If raw Is Map Then
		Dim m As Map = raw
		Return m
	End If
	Dim empty As Map
	empty.Initialize
	Return empty
End Sub

' Sync HTTP for StaticCode callers. StrictMode.permitAll avoids NetworkOnMainThreadException.
Public Sub RequestRaw(method As String, url As String, body As String, useUserToken As Boolean, prefer As String) As Object
	AllowNetworkOnMainThread
	Return HttpOnce(method, url, body, useUserToken, prefer, True)
End Sub

Private Sub ParseBody(text As String) As Object
	Dim empty As Map
	empty.Initialize
	If text = "" Or text = "null" Then Return empty
	Try
		Dim jp As JSONParser
		jp.Initialize(text)
		If text.Trim.StartsWith("[") Then
			Return jp.NextArray
		Else
			Return jp.NextObject
		End If
	Catch
		Return empty
	End Try
End Sub

Private Sub HttpOnce(method As String, url As String, body As String, useUserToken As Boolean, prefer As String, allowRefresh As Boolean) As Object
	LastError = ""
	Dim empty As Map
	empty.Initialize
	If useUserToken And allowRefresh Then
		Dim tokenState As String = EnsureFreshToken
		If tokenState = "rejected" Then
			LastError = "Session expired"
			Return empty
		End If
	End If
	Try
		Dim raw As Map = RawHttp(method, url, body, useUserToken, prefer)
		Dim code As Int = raw.GetDefault("status", -1)
		Dim text As String = "" & raw.GetDefault("body", "")
		If code < 0 Then
			LastError = "" & raw.GetDefault("error", "Request failed")
			Log("DoHttp " & method & " " & url & ": " & LastError)
			Return empty
		End If
		
		If code = 401 And useUserToken And allowRefresh Then
			LastError = "HTTP " & code & ": " & text
			Log(LastError)
			Dim refreshed As String = RefreshSession
			If refreshed = "ok" Then Return HttpOnce(method, url, body, useUserToken, prefer, False)
			Return empty
		End If
		If code < 200 Or code >= 300 Then
			LastError = "HTTP " & code & ": " & text
			Log(LastError)
			Return empty
		End If
		Return ParseBody(text)
	Catch
		LastError = LastException.Message
		Log("DoHttp " & method & " " & url & ": " & LastError)
		Return empty
	End Try
End Sub

' TextReader is B4A. The iOS request path does not use this.
#if B4A
Private Sub ReadStreamToString(streamObj As Object) As String
	Try
		Dim tr As TextReader
		tr.Initialize(streamObj)
		Dim s As String = tr.ReadAll
		tr.Close
		Return s
	Catch
		Log("ReadStreamToString: " & LastException.Message)
		Return ""
	End Try
End Sub
#End If

Private Sub AsLong(v As Object) As Long
	If v = Null Then Return 0
	Try
		Dim n As Long = v
		Return n
	Catch
		Try
			Dim d As Double = v
			Return d
		Catch
			Return 0
		End Try
	End Try
End Sub

Public Sub UrlEncode(s As String) As String
	Return modPlatform.UrlEncode(s)
End Sub

' status, body, error. status -1 means the request did not complete.
Private Sub RawHttp(method As String, url As String, body As String, useUserToken As Boolean, prefer As String) As Map
	Dim result As Map
	result.Initialize
	result.Put("status", -1)
	result.Put("body", "")
	result.Put("error", "")
#if B4A
	Dim joNull As Object = Null
	Try
		Dim jurl As JavaObject
		jurl.InitializeNewInstance("java.net.URL", Array(url))
		Dim conn As JavaObject = jurl.RunMethod("openConnection", Null)
		conn.RunMethod("setRequestMethod", Array(method))
		conn.RunMethod("setConnectTimeout", Array(10000))
		conn.RunMethod("setReadTimeout", Array(20000))
		conn.RunMethod("setRequestProperty", Array("apikey", modConfig.SUPABASE_ANON_KEY))
		Dim bearer As String = modConfig.SUPABASE_ANON_KEY
		If useUserToken And AccessToken <> "" Then bearer = AccessToken
		conn.RunMethod("setRequestProperty", Array("Authorization", "Bearer " & bearer))
		conn.RunMethod("setRequestProperty", Array("Content-Type", "application/json"))
		conn.RunMethod("setRequestProperty", Array("Accept", "application/json"))
		If prefer <> "" Then
			conn.RunMethod("setRequestProperty", Array("Prefer", prefer))
		End If
		If method <> "GET" And method <> "DELETE" And body <> "" Then
			conn.RunMethod("setDoOutput", Array(True))
			Dim os As JavaObject = conn.RunMethod("getOutputStream", Null)
			Dim bytes() As Byte = body.GetBytes("UTF8")
			os.RunMethod("write", Array(bytes, 0, bytes.Length))
			os.RunMethod("flush", Null)
			os.RunMethod("close", Null)
		End If
		Dim code As Int = conn.RunMethod("getResponseCode", Null)
		Dim streamObj As Object
		If code >= 200 And code < 300 Then
			streamObj = conn.RunMethod("getInputStream", Null)
		Else
			streamObj = conn.RunMethod("getErrorStream", Null)
		End If
		Dim text As String = ""
		If streamObj <> Null And streamObj <> joNull Then
			text = ReadStreamToString(streamObj)
		End If
		result.Put("status", code)
		result.Put("body", text)
		Return result
	Catch
		result.Put("error", LastException.Message)
		Return result
	End Try
#else if B4i
	Try
		Dim headers As Map
		headers.Initialize
		headers.Put("apikey", modConfig.SUPABASE_ANON_KEY)
		Dim bearer As String = modConfig.SUPABASE_ANON_KEY
		If useUserToken And AccessToken <> "" Then bearer = AccessToken
		headers.Put("Authorization", "Bearer " & bearer)
		headers.Put("Content-Type", "application/json")
		headers.Put("Accept", "application/json")
		If prefer <> "" Then headers.Put("Prefer", prefer)
		' B4i Map is not an NSDictionary. ToDictionary is the native one the request can read.
		Dim no As NativeObject = Me
		Dim got As Object = no.RunMethod("tpSyncHttp:method:body:headers:timeout:", Array(url, method, body, headers.ToDictionary, 20000))
		' The native method returns JSON text. A returned NSDictionary is not a B4X Map.
		Dim payload As String = ""
		If got <> Null Then payload = "" & got
		If payload <> "" Then
			Dim jp As JSONParser
			jp.Initialize(payload)
			Dim parsed As Map = jp.NextObject
			Return parsed
		End If
		result.Put("error", "Request failed")
		Return result
	Catch
		result.Put("error", LastException.Message)
		Return result
	End Try
#End If
End Sub

#if OBJC
- (NSString*)tpJson:(NSDictionary*)out {
	NSData *json = [NSJSONSerialization dataWithJSONObject:out options:0 error:nil];
	if (json == nil) return @"{\"status\":-1,\"body\":\"\",\"error\":\"Encode failed\"}";
	NSString *text = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
	if (text == nil) return @"{\"status\":-1,\"body\":\"\",\"error\":\"Encode failed\"}";
	return text;
}
- (NSString*)tpSyncHttp:(NSString*)url method:(NSString*)method body:(NSString*)body headers:(NSDictionary*)headers timeout:(int)timeoutMs {
	NSMutableDictionary *out = [NSMutableDictionary dictionary];
	out[@"status"] = @(-1);
	out[@"body"] = @"";
	out[@"error"] = @"Request failed";
	NSURL *nsurl = [NSURL URLWithString:url];
	if (nsurl == nil) {
		out[@"error"] = @"Bad URL";
		return [self tpJson:out];
	}
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:nsurl];
	req.HTTPMethod = method;
	req.timeoutInterval = MAX(1, timeoutMs) / 1000.0;
	if (body != nil && body.length > 0 && ![method isEqualToString:@"GET"] && ![method isEqualToString:@"DELETE"]) {
		req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
	}
	for (NSString *key in headers) {
		id value = headers[key];
		if (value != nil) [req setValue:[value description] forHTTPHeaderField:key];
	}
	__block NSData *data = nil;
	__block NSHTTPURLResponse *resp = nil;
	__block NSError *err = nil;
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);
	NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
		data = d;
		if ([r isKindOfClass:[NSHTTPURLResponse class]]) resp = (NSHTTPURLResponse*)r;
		err = e;
		dispatch_semaphore_signal(sem);
	}];
	[task resume];
	int64_t waitNs = (int64_t)(timeoutMs + 2000) * (int64_t)NSEC_PER_MSEC;
	long waited = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, waitNs));
	if (waited != 0) {
		[task cancel];
		out[@"error"] = @"Request timed out";
		return [self tpJson:out];
	}
	if (err != nil && resp == nil) {
		out[@"error"] = err.localizedDescription != nil ? err.localizedDescription : @"Request failed";
		return [self tpJson:out];
	}
	NSInteger code = resp != nil ? resp.statusCode : -1;
	out[@"status"] = @(code);
	NSString *text = @"";
	if (data != nil) {
		text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (text == nil) text = @"";
	}
	out[@"body"] = text;
	out[@"error"] = @"";
	return [self tpJson:out];
}
#End If
