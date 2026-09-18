B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Firebase Auth + Firestore wiring for TeamPulse.
' Requires B4A libraries: FirebaseAuth, FirebaseFirestore (or Firestore via JavaObject),
' FirebaseAnalytics (often pulled transitively), OkHttpUtils2, XUI, B4XPages.
'
' IMPORTANT: The web app uses a NAMED Firestore database:
'   ai-studio-5af61b00-360c-4924-838f-431be734b14d
' Default B4A Firestore helpers often bind to "(default)". Use GetFirestoreDb below.

Sub Process_Globals
	Private AuthJO As JavaObject
	Private DbJO As JavaObject
	Private AppJO As JavaObject
	Public Ready As Boolean
	Public LastError As String
End Sub

Public Sub Initialize
	Ready = False
	LastError = ""
	Try
		Dim firebaseApp As JavaObject
		firebaseApp.InitializeStatic("com.google.firebase.FirebaseApp")
		AppJO = firebaseApp.RunMethod("getInstance", Null)
		
		Dim authStatic As JavaObject
		authStatic.InitializeStatic("com.google.firebase.auth.FirebaseAuth")
		AuthJO = authStatic.RunMethod("getInstance", Null)
		
		DbJO = GetFirestoreDb(modConfig.FIRESTORE_DATABASE_ID)
		Ready = True
	Catch
		LastError = LastException.Message
		Log("modFirebase.Initialize failed: " & LastError)
		Ready = False
	End Try
End Sub

' Returns Firestore instance for a named database id.
Private Sub GetFirestoreDb(databaseId As String) As JavaObject
	Dim firestore As JavaObject
	firestore.InitializeStatic("com.google.firebase.firestore.FirebaseFirestore")
	Try
		' FirebaseFirestore.getInstance(FirebaseApp, String databaseId) — API 34+
		Return firestore.RunMethod("getInstance", Array(AppJO, databaseId))
	Catch
		Log("Named getInstance failed, trying default: " & LastException)
		Return firestore.RunMethod("getInstance", Array(AppJO))
	End Try
End Sub

Public Sub GetAuth As JavaObject
	Return AuthJO
End Sub

Public Sub GetDb As JavaObject
	Return DbJO
End Sub

Public Sub CurrentUid As String
	Try
		Dim user As JavaObject = AuthJO.RunMethod("getCurrentUser", Null)
		If user = Null Or user.IsInitialized = False Then Return ""
		Dim uid As Object = user.RunMethod("getUid", Null)
		If uid = Null Then Return ""
		Return uid
	Catch
		Return ""
	End Try
End Sub

Public Sub CurrentEmail As String
	Try
		Dim user As JavaObject = AuthJO.RunMethod("getCurrentUser", Null)
		If user = Null Then Return ""
		Dim email As Object = user.RunMethod("getEmail", Null)
		If email = Null Then Return ""
		Return email
	Catch
		Return ""
	End Try
End Sub

Public Sub CurrentDisplayName As String
	Try
		Dim user As JavaObject = AuthJO.RunMethod("getCurrentUser", Null)
		If user = Null Then Return ""
		Dim n As Object = user.RunMethod("getDisplayName", Null)
		If n = Null Then Return ""
		Return n
	Catch
		Return ""
	End Try
End Sub

Public Sub SignOut
	Try
		AuthJO.RunMethod("signOut", Null)
	Catch
		Log(LastException)
	End Try
	modAppState.ClearUser
End Sub

' Collection reference helper
Public Sub Collection(name As String) As JavaObject
	Return DbJO.RunMethod("collection", Array(name))
End Sub

Public Sub Document(path As String) As JavaObject
	Return DbJO.RunMethod("document", Array(path))
End Sub

Public Sub MapToJavaMap(m As Map) As JavaObject
	Dim hm As JavaObject
	hm.InitializeNewInstance("java.util.HashMap", Null)
	For Each k As String In m.Keys
		Dim v As Object = m.Get(k)
		If v Is Map Then
			hm.RunMethod("put", Array(k, MapToJavaMap(v)))
		Else If v Is List Then
			hm.RunMethod("put", Array(k, ListToJavaList(v)))
		Else
			hm.RunMethod("put", Array(k, v))
		End If
	Next
	Return hm
End Sub

Private Sub ListToJavaList(l As List) As JavaObject
	Dim al As JavaObject
	al.InitializeNewInstance("java.util.ArrayList", Null)
	For Each item As Object In l
		If item Is Map Then
			al.RunMethod("add", Array(MapToJavaMap(item)))
		Else
			al.RunMethod("add", Array(item))
		End If
	Next
	Return al
End Sub

Public Sub JavaMapToMap(jo As Object) As Map
	Dim out As Map
	out.Initialize
	If jo = Null Then Return out
	Dim jmap As JavaObject = jo
	Dim keySet As JavaObject = jmap.RunMethod("keySet", Null)
	Dim arr() As Object = keySet.RunMethod("toArray", Null)
	For Each k As Object In arr
		Dim key As String = k
		Dim v As Object = jmap.RunMethod("get", Array(k))
		out.Put(key, ConvertFirestoreValue(v))
	Next
	Return out
End Sub

Private Sub ConvertFirestoreValue(v As Object) As Object
	If v = Null Then Return ""
	Try
		Dim jo As JavaObject = v
		Dim cn As String = jo.RunMethod("getClass", Null).As(JavaObject).RunMethod("getName", Null)
		If cn = "java.util.HashMap" Or cn.Contains("Map") Then
			Return JavaMapToMap(v)
		Else If cn.Contains("List") Or cn.Contains("ArrayList") Then
			Return JavaListToList(v)
		Else If cn.Contains("Timestamp") Then
			Dim ms As Long = jo.RunMethod("toDate", Null).As(JavaObject).RunMethod("getTime", Null)
			Return ms
		End If
	Catch
		' primitive
	End Try
	Return v
End Sub

Private Sub JavaListToList(v As Object) As List
	Dim out As List
	out.Initialize
	Dim jl As JavaObject = v
	Dim size As Int = jl.RunMethod("size", Null)
	For i = 0 To size - 1
		out.Add(ConvertFirestoreValue(jl.RunMethod("get", Array(i))))
	Next
	Return out
End Sub
