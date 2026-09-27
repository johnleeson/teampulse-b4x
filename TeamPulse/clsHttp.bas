B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Async OkHttp helper for B4XPages (StaticCode cannot Wait For).
Sub Class_Globals
	Public LastError As String
End Sub

Public Sub Initialize
	LastError = ""
End Sub

' Returns Map with keys: ok (Boolean), data (Object), error (String), status (Int)
Public Sub Request(method As String, url As String, body As String, useUserToken As Boolean, prefer As String) As ResumableSub
	Wait For (RequestAttempt(method, url, body, useUserToken, prefer, True)) Complete (res As Map)
	Return res
End Sub

Private Sub RequestAttempt(method As String, url As String, body As String, useUserToken As Boolean, prefer As String, allowRefresh As Boolean) As ResumableSub
	LastError = ""
	Dim out As Map
	out.Initialize
	out.Put("ok", False)
	out.Put("data", Null)
	out.Put("error", "")
	out.Put("status", 0)
	If useUserToken And allowRefresh Then
		Dim tokenState As String = modSupabase.EnsureFreshToken
		If tokenState = "rejected" Then
			LastError = "Session expired"
			out.Put("error", LastError)
			out.Put("status", 401)
			Return out
		End If
	End If
	Dim j As HttpJob
	j.Initialize("", Me)
	Try
		Dim m As String = method.ToUpperCase
		If m = "GET" Then
			j.Download(url)
		Else If m = "DELETE" Then
			j.Delete(url)
		Else
			j.PostString(url, body)
			j.GetRequest.SetContentType("application/json")
		End If
		j.GetRequest.SetHeader("apikey", modConfig.SUPABASE_ANON_KEY)
		Dim bearer As String = modConfig.SUPABASE_ANON_KEY
		If useUserToken And modSupabase.AccessToken <> "" Then bearer = modSupabase.AccessToken
		j.GetRequest.SetHeader("Authorization", "Bearer " & bearer)
		j.GetRequest.SetHeader("Accept", "application/json")
		If prefer <> "" Then j.GetRequest.SetHeader("Prefer", prefer)
		j.GetRequest.Timeout = 20000
	Catch
		LastError = LastException.Message
		out.Put("error", LastError)
		j.Release
		Return out
	End Try
	Wait For (j) JobDone (job As HttpJob)
	Dim status As Int = StatusOf(job)
	out.Put("status", status)
	If job.Success Then
		out.Put("ok", True)
		out.Put("data", ParseBody(job.GetString))
		job.Release
		Return out
	End If
	LastError = "HTTP " & status & ": " & job.ErrorMessage
	out.Put("error", LastError)
	Log(LastError)
	job.Release
	If status = 401 And useUserToken And allowRefresh Then
		Dim refreshed As String = modSupabase.RefreshSession
		If refreshed = "ok" Then
			Wait For (RequestAttempt(method, url, body, useUserToken, prefer, False)) Complete (retry As Map)
			Return retry
		End If
	End If
	Return out
End Sub

Private Sub StatusOf(job As HttpJob) As Int
	Try
		Return job.Response.StatusCode
	Catch
		Return 0
	End Try
End Sub

Public Sub AuthPost(pathAndQuery As String, bodyMap As Map) As ResumableSub
	Dim url As String = modConfig.SUPABASE_URL & "/auth/v1/" & pathAndQuery
	Dim jg As JSONGenerator
	jg.Initialize(bodyMap)
	Wait For (Request("POST", url, jg.ToString, False, "return=representation")) Complete (res As Map)
	Return res
End Sub

Public Sub RestGet(tableAndQuery As String) As ResumableSub
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Wait For (Request("GET", url, "", True, "")) Complete (res As Map)
	Return res
End Sub

Public Sub RestDelete(tableAndQuery As String) As ResumableSub
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Wait For (Request("DELETE", url, "", True, "return=minimal")) Complete (res As Map)
	Return res
End Sub

Public Sub RestPost(tableAndQuery As String, body As Object, prefer As String) As ResumableSub
	Dim url As String = modConfig.SUPABASE_URL & "/rest/v1/" & tableAndQuery
	Dim bodyText As String
	Dim jg As JSONGenerator
	If body Is List Then
		Dim lst As List = body
		jg.Initialize2(lst)
	Else
		Dim mp As Map = body
		jg.Initialize(mp)
	End If
	bodyText = jg.ToString
	Wait For (Request("POST", url, bodyText, True, prefer)) Complete (res As Map)
	Return res
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
