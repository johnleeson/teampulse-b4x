B4A=true
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
	Private Const SESSION_FILE As String = "supabase_session.json"
	Private StrictModeReady As Boolean
End Sub

Public Sub Initialize
	Ready = False
	LastError = ""
	AccessToken = ""
	RefreshToken = ""
	UserId = ""
	UserEmail = ""
	DisplayName = ""
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
	Try
		If File.Exists(File.DirInternal, SESSION_FILE) Then
			File.Delete(File.DirInternal, SESSION_FILE)
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
		Dim jg As JSONGenerator
		jg.Initialize(m)
		File.WriteString(File.DirInternal, SESSION_FILE, jg.ToString)
	Catch
		Log("SaveSession: " & LastException.Message)
	End Try
End Sub

Private Sub LoadSession
	Try
		If File.Exists(File.DirInternal, SESSION_FILE) = False Then Return
		Dim raw As String = File.ReadString(File.DirInternal, SESSION_FILE)
		If raw.Length = 0 Then Return
		Dim jp As JSONParser
		jp.Initialize(raw)
		Dim m As Map = jp.NextObject
		AccessToken = m.GetDefault("access_token", "")
		RefreshToken = m.GetDefault("refresh_token", "")
		UserId = m.GetDefault("user_id", "")
		UserEmail = m.GetDefault("email", "")
		DisplayName = m.GetDefault("display_name", "")
	Catch
		Log("LoadSession: " & LastException.Message)
	End Try
End Sub

Public Sub ApplyAuthResponse(data As Map) As Boolean
	LastError = ""
	Try
		AccessToken = data.GetDefault("access_token", "")
		RefreshToken = data.GetDefault("refresh_token", "")
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
		SaveSession
		Return True
	Catch
		LastError = LastException.Message
		Return False
	End Try
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
	Dim jg As JSONGenerator
	jg.Initialize(body)
	Return RequestRaw("PATCH", url, jg.ToString, True, prefer)
End Sub

Public Sub RestDelete(tableAndQuery As String) As Object
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Return RequestRaw("DELETE", url, "", True, "return=minimal")
End Sub

Public Sub Rpc(fnName As String, args As Map) As Object
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/rpc/" & fnName
	Dim jg As JSONGenerator
	jg.Initialize(args)
	Return RequestRaw("POST", url, jg.ToString, True, "return=representation")
End Sub

Private Sub ObjectToJson(body As Object) As String
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

Private Sub Request(method As String, url As String, bodyMap As Map, useUserToken As Boolean, prefer As String) As Map
	Dim jg As JSONGenerator
	jg.Initialize(bodyMap)
	Dim raw As Object = RequestRaw(method, url, jg.ToString, useUserToken, prefer)
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
	Return DoHttp(method, url, body, useUserToken, prefer)
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

Private Sub DoHttp(method As String, url As String, body As String, useUserToken As Boolean, prefer As String) As Object
	LastError = ""
	Dim empty As Map
	empty.Initialize
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

Public Sub UrlEncode(s As String) As String
	Try
		Dim enc As JavaObject
		enc.InitializeStatic("java.net.URLEncoder")
		Return enc.RunMethod("encode", Array(s, "UTF-8"))
	Catch
		Return s
	End Try
End Sub
