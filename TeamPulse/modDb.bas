B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=12.80
@EndOfDesignText@
' Port of services/dbService.ts — Firestore CRUD for TeamPulse.
' Callers should CallSubDelayed to UI after async completion.
' Uses Firestore Task listeners via JavaObject.

Sub Process_Globals
	Public Const COL_PROFILES As String = "profiles"
	Public Const COL_CLUBS As String = "clubs"
	Public Const COL_MEMBERS As String = "club_members"
	Public Const COL_MATCHES As String = "matches"
	Public Const COL_EVENTS As String = "feed_events"
End Sub

Public Sub MapProfile(data As Map, id As String) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", id)
	m.Put("name", data.GetDefault("name", "User"))
	m.Put("avatar", data.GetDefault("avatar", ""))
	m.Put("roles", data.GetDefault("roles", NewListFromStrings(Array As String("SPECTATOR"))))
	m.Put("age", data.GetDefault("age", ""))
	m.Put("gender", data.GetDefault("gender", ""))
	m.Put("favPosition", data.GetDefault("favPosition", ""))
	m.Put("kitSize", data.GetDefault("kitSize", ""))
	Return m
End Sub

Public Sub MapMatch(data As Map, id As String) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", id)
	m.Put("clubId", data.GetDefault("clubId", ""))
	m.Put("title", data.GetDefault("title", ""))
	m.Put("date", data.GetDefault("date", ""))
	m.Put("meetTime", data.GetDefault("meetTime", ""))
	m.Put("kickOffTime", data.GetDefault("kickOffTime", ""))
	m.Put("location", data.GetDefault("location", ""))
	m.Put("status", data.GetDefault("status", "UPCOMING"))
	m.Put("scoreA", data.GetDefault("scoreA", 0))
	m.Put("scoreB", data.GetDefault("scoreB", 0))
	m.Put("signedUpPlayerIds", data.GetDefault("signedUpPlayerIds", EmptyList))
	m.Put("availability", data.GetDefault("availability", EmptyMap))
	m.Put("opponentName", data.GetDefault("opponentName", ""))
	m.Put("isHome", data.GetDefault("isHome", True))
	m.Put("potmVotes", data.GetDefault("potmVotes", EmptyMap))
	m.Put("managerSummary", data.GetDefault("managerSummary", ""))
	m.Put("startingLineupIds", data.GetDefault("startingLineupIds", EmptyList))
	m.Put("benchIds", data.GetDefault("benchIds", EmptyList))
	m.Put("starPlayerIds", data.GetDefault("starPlayerIds", EmptyList))
	m.Put("weakerPlayerIds", data.GetDefault("weakerPlayerIds", EmptyList))
	m.Put("teamA", data.GetDefault("teamA", EmptyList))
	m.Put("teamB", data.GetDefault("teamB", EmptyList))
	m.Put("playerStats", data.GetDefault("playerStats", EmptyMap))
	m.Put("formation", data.GetDefault("formation", "4-4-2"))
	m.Put("tacticalLineup", data.GetDefault("tacticalLineup", EmptyMap))
	Return m
End Sub

Public Sub MapEvent(data As Map, id As String) As Map
	Dim m As Map
	m.Initialize
	m.Put("id", id)
	m.Put("matchId", data.GetDefault("matchId", ""))
	m.Put("userId", data.GetDefault("userId", ""))
	m.Put("userName", data.GetDefault("userName", ""))
	m.Put("type", data.GetDefault("type", "COMMENT"))
	m.Put("content", data.GetDefault("content", ""))
	m.Put("details", data.GetDefault("details", EmptyMap))
	m.Put("mediaUrl", data.GetDefault("mediaUrl", ""))
	m.Put("timestamp", data.GetDefault("timestamp", DateTime.Now))
	Return m
End Sub

Private Sub EmptyList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub EmptyMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Private Sub NewListFromStrings(arr() As String) As List
	Dim l As List
	l.Initialize
	For Each s As String In arr
		l.Add(s)
	Next
	Return l
End Sub

' --- Writes (merge set) ---

Public Sub SaveProfile(user As Map)
	Dim id As String = user.Get("id")
	Dim payload As Map
	payload.Initialize
	payload.Put("name", user.GetDefault("name", ""))
	payload.Put("avatar", user.GetDefault("avatar", ""))
	payload.Put("roles", user.GetDefault("roles", EmptyList))
	payload.Put("age", NullIfEmpty(user.GetDefault("age", "")))
	payload.Put("gender", NullIfEmpty(user.GetDefault("gender", "")))
	payload.Put("favPosition", NullIfEmpty(user.GetDefault("favPosition", "")))
	payload.Put("kitSize", NullIfEmpty(user.GetDefault("kitSize", "")))
	SetDocMerge($"${COL_PROFILES}/${id}"$, payload)
End Sub

Public Sub SaveClub(club As Map, owner As Map)
	SaveProfile(owner)
	Dim id As String = club.Get("id")
	Dim payload As Map
	payload.Initialize
	payload.Put("name", club.GetDefault("name", ""))
	payload.Put("logo", club.GetDefault("logo", ""))
	payload.Put("description", club.GetDefault("description", ""))
	payload.Put("type", club.GetDefault("type", "TEAM"))
	payload.Put("ownerId", owner.Get("id"))
	payload.Put("inviteCode", club.GetDefault("inviteCode", ""))
	payload.Put("ageGroup", NullIfEmpty(club.GetDefault("ageGroup", "")))
	payload.Put("gender", NullIfEmpty(club.GetDefault("gender", "")))
	payload.Put("teamPhoto", NullIfEmpty(club.GetDefault("teamPhoto", "")))
	SetDocMerge($"${COL_CLUBS}/${id}"$, payload)
	
	Dim roles As List = NewListFromStrings(Array As String("ADMIN", "PLAYER"))
	Dim members As List = club.GetDefault("members", EmptyList)
	For Each mem As Map In members
		If mem.GetDefault("id", "") = owner.Get("id") Then
			roles = mem.GetDefault("roles", roles)
			Exit
		End If
	Next
	Dim mid As String = id & "_" & owner.Get("id")
	Dim mp As Map
	mp.Initialize
	mp.Put("clubId", id)
	mp.Put("userId", owner.Get("id"))
	mp.Put("roles", roles)
	SetDocMerge($"${COL_MEMBERS}/${mid}"$, mp)
End Sub

Public Sub DeleteClub(clubId As String)
	DeleteDoc($"${COL_CLUBS}/${clubId}"$)
End Sub

Public Sub SaveMatch(match As Map)
	Dim id As String = match.Get("id")
	Dim payload As Map
	payload.Initialize
	payload.Put("clubId", match.GetDefault("clubId", ""))
	payload.Put("title", match.GetDefault("title", ""))
	payload.Put("date", match.GetDefault("date", ""))
	payload.Put("meetTime", match.GetDefault("meetTime", ""))
	payload.Put("kickOffTime", match.GetDefault("kickOffTime", ""))
	payload.Put("location", match.GetDefault("location", ""))
	payload.Put("status", match.GetDefault("status", "UPCOMING"))
	payload.Put("scoreA", match.GetDefault("scoreA", 0))
	payload.Put("scoreB", match.GetDefault("scoreB", 0))
	payload.Put("signedUpPlayerIds", match.GetDefault("signedUpPlayerIds", EmptyList))
	payload.Put("availability", match.GetDefault("availability", EmptyMap))
	payload.Put("opponentName", match.GetDefault("opponentName", ""))
	payload.Put("isHome", match.GetDefault("isHome", True))
	payload.Put("potmVotes", match.GetDefault("potmVotes", EmptyMap))
	payload.Put("managerSummary", match.GetDefault("managerSummary", ""))
	payload.Put("startingLineupIds", match.GetDefault("startingLineupIds", EmptyList))
	payload.Put("benchIds", match.GetDefault("benchIds", EmptyList))
	payload.Put("starPlayerIds", match.GetDefault("starPlayerIds", EmptyList))
	payload.Put("weakerPlayerIds", match.GetDefault("weakerPlayerIds", EmptyList))
	payload.Put("teamA", match.GetDefault("teamA", EmptyList))
	payload.Put("teamB", match.GetDefault("teamB", EmptyList))
	payload.Put("playerStats", match.GetDefault("playerStats", EmptyMap))
	payload.Put("formation", match.GetDefault("formation", "4-4-2"))
	payload.Put("tacticalLineup", match.GetDefault("tacticalLineup", EmptyMap))
	' Explicitly do NOT write aiSummary (AI features removed)
	SetDocMerge($"${COL_MATCHES}/${id}"$, payload)
End Sub

Public Sub DeleteMatch(matchId As String)
	DeleteDoc($"${COL_MATCHES}/${matchId}"$)
End Sub

Public Sub SaveEvent(ev As Map)
	Dim id As String = ev.Get("id")
	Dim payload As Map
	payload.Initialize
	payload.Put("matchId", ev.GetDefault("matchId", ""))
	payload.Put("userId", ev.GetDefault("userId", ""))
	payload.Put("userName", ev.GetDefault("userName", ""))
	payload.Put("type", ev.GetDefault("type", "COMMENT"))
	payload.Put("content", ev.GetDefault("content", ""))
	payload.Put("details", ev.GetDefault("details", EmptyMap))
	payload.Put("mediaUrl", NullIfEmpty(ev.GetDefault("mediaUrl", "")))
	' timestamp: use server or millis — store as Long; web uses Timestamp
	payload.Put("timestamp", FirestoreTimestamp(ev.GetDefault("timestamp", DateTime.Now)))
	SetDocMerge($"${COL_EVENTS}/${id}"$, payload)
End Sub

Public Sub DeleteEvent(eventId As String)
	DeleteDoc($"${COL_EVENTS}/${eventId}"$)
End Sub

Public Sub JoinClub(clubId As String, userId As String, roles As List)
	Dim mid As String = clubId & "_" & userId
	Dim mp As Map
	mp.Initialize
	mp.Put("clubId", clubId)
	mp.Put("userId", userId)
	mp.Put("roles", roles)
	SetDocMerge($"${COL_MEMBERS}/${mid}"$, mp)
End Sub

Public Sub UpdateMemberRoles(clubId As String, userId As String, roles As List)
	Dim mid As String = clubId & "_" & userId
	Dim mp As Map
	mp.Initialize
	mp.Put("roles", roles)
	SetDocMerge($"${COL_MEMBERS}/${mid}"$, mp)
End Sub

Public Sub RemoveMember(clubId As String, userId As String)
	DeleteDoc($"${COL_MEMBERS}/${clubId}_${userId}"$)
End Sub

Public Sub AddMember(clubId As String, member As Map)
	Try
		SaveProfile(member)
	Catch
		Log("Profile save during AddMember: " & LastException)
	End Try
	Dim mid As String = clubId & "_" & member.Get("id")
	Dim mp As Map
	mp.Initialize
	mp.Put("clubId", clubId)
	mp.Put("userId", member.Get("id"))
	mp.Put("roles", member.GetDefault("roles", NewListFromStrings(Array As String("PLAYER"))))
	SetDocMerge($"${COL_MEMBERS}/${mid}"$, mp)
End Sub

Public Sub UpdateMemberRating(clubId As String, userId As String, rating As Double)
	Dim mid As String = clubId & "_" & userId
	Dim mp As Map
	mp.Initialize
	mp.Put("abilityRating", rating)
	SetDocMerge($"${COL_MEMBERS}/${mid}"$, mp)
End Sub

Private Sub NullIfEmpty(s As String) As Object
	If s = "" Then
		Dim n As Object = Null
		Return n
	End If
	Return s
End Sub

Private Sub FirestoreTimestamp(ms As Long) As Object
	Try
		Dim ts As JavaObject
		ts.InitializeNewInstance("com.google.firebase.Timestamp", Array(ms / 1000, (ms Mod 1000) * 1000000))
		Return ts
	Catch
		Return ms
	End Try
End Sub

Private Sub SetDocMerge(path As String, payload As Map)
	Try
		Dim doc As JavaObject = modFirebase.Document(path)
		Dim data As JavaObject = modFirebase.MapToJavaMap(payload)
		Dim options As JavaObject
		options.InitializeStatic("com.google.firebase.firestore.SetOptions")
		Dim mergeOpt As Object = options.RunMethod("merge", Null)
		doc.RunMethod("set", Array(data, mergeOpt))
	Catch
		Log("SetDocMerge " & path & ": " & LastException)
	End Try
End Sub

Private Sub DeleteDoc(path As String)
	Try
		Dim doc As JavaObject = modFirebase.Document(path)
		doc.RunMethod("delete", Null)
	Catch
		Log("DeleteDoc " & path & ": " & LastException)
	End Try
End Sub

' --- Initial load (blocking-style via Tasks.await if available; else snapshot listeners from UI) ---

Public Sub FetchInitialData
	Try
		Dim clubsSnap As JavaObject = AwaitGet(modFirebase.Collection(COL_CLUBS).RunMethod("get", Null))
		Dim clubs As List
		clubs.Initialize
		Dim clubDocs As List = SnapshotDocs(clubsSnap)
		For Each cd As Map In clubDocs
			Dim club As Map
			club.Initialize
			Dim raw As Map = cd.Get("data")
			Dim cid As String = cd.Get("id")
			club.Put("id", cid)
			club.Put("name", raw.GetDefault("name", ""))
			club.Put("logo", raw.GetDefault("logo", ""))
			club.Put("description", raw.GetDefault("description", ""))
			club.Put("type", raw.GetDefault("type", "TEAM"))
			club.Put("ownerId", raw.GetDefault("ownerId", ""))
			club.Put("inviteCode", raw.GetDefault("inviteCode", ""))
			club.Put("ageGroup", raw.GetDefault("ageGroup", ""))
			club.Put("gender", raw.GetDefault("gender", ""))
			club.Put("teamPhoto", raw.GetDefault("teamPhoto", ""))
			club.Put("members", FetchMembersForClub(cid))
			clubs.Add(club)
		Next
		modAppState.Clubs = clubs
		
		Dim matchesSnap As JavaObject = AwaitGet( _
			modFirebase.Collection(COL_MATCHES).RunMethodJO("orderBy", Array("date")).RunMethod("get", Null))
		Dim matches As List
		matches.Initialize
		For Each md As Map In SnapshotDocs(matchesSnap)
			matches.Add(MapMatch(md.Get("data"), md.Get("id")))
		Next
		modAppState.Matches = matches
		
		Dim eventsSnap As JavaObject = AwaitGet( _
			modFirebase.Collection(COL_EVENTS).RunMethodJO("orderBy", Array("timestamp")).RunMethod("get", Null))
		Dim events As List
		events.Initialize
		For Each ed As Map In SnapshotDocs(eventsSnap)
			events.Add(MapEvent(ed.Get("data"), ed.Get("id")))
		Next
		modAppState.FeedEvents = events
	Catch
		Log("FetchInitialData: " & LastException)
	End Try
End Sub

Private Sub FetchMembersForClub(clubId As String) As List
	Dim members As List
	members.Initialize
	Try
		Dim q As JavaObject = modFirebase.Collection(COL_MEMBERS).RunMethod("whereEqualTo", Array("clubId", clubId))
		Dim snap As JavaObject = AwaitGet(q.RunMethod("get", Null))
		For Each md As Map In SnapshotDocs(snap)
			Dim mdata As Map = md.Get("data")
			Dim uid As String = mdata.GetDefault("userId", "")
			Dim profile As Map = GetProfile(uid)
			Dim mem As Map
			mem.Initialize
			mem.Put("id", uid)
			mem.Put("name", profile.GetDefault("name", "Unknown"))
			mem.Put("avatar", profile.GetDefault("avatar", ""))
			mem.Put("roles", mdata.GetDefault("roles", NewListFromStrings(Array As String("PLAYER"))))
			mem.Put("age", profile.GetDefault("age", ""))
			mem.Put("gender", profile.GetDefault("gender", ""))
			mem.Put("favPosition", profile.GetDefault("favPosition", ""))
			mem.Put("kitSize", profile.GetDefault("kitSize", ""))
			mem.Put("abilityRating", mdata.GetDefault("abilityRating", 0))
			members.Add(mem)
		Next
	Catch
		Log("FetchMembersForClub: " & LastException)
	End Try
	Return members
End Sub

Public Sub GetProfile(userId As String) As Map
	Dim empty As Map
	empty.Initialize
	Try
		Dim snap As JavaObject = AwaitGet(modFirebase.Document($"${COL_PROFILES}/${userId}"$).RunMethod("get", Null))
		Dim exists As Boolean = snap.RunMethod("exists", Null)
		If exists = False Then Return empty
		Dim data As Object = snap.RunMethod("getData", Null)
		Return MapProfile(modFirebase.JavaMapToMap(data), userId)
	Catch
		Return empty
	End Try
End Sub

Public Sub FindClubByInviteCode(code As String) As Map
	Dim empty As Map
	empty.Initialize
	Try
		Dim q As JavaObject = modFirebase.Collection(COL_CLUBS).RunMethod("whereEqualTo", Array("inviteCode", code))
		q = q.RunMethod("limit", Array(1))
		Dim snap As JavaObject = AwaitGet(q.RunMethod("get", Null))
		Dim docs As List = SnapshotDocs(snap)
		If docs.Size = 0 Then Return empty
		Dim md As Map = docs.Get(0)
		Dim raw As Map = md.Get("data")
		Dim club As Map
		club.Initialize
		club.Put("id", md.Get("id"))
		club.Put("name", raw.GetDefault("name", ""))
		club.Put("logo", raw.GetDefault("logo", ""))
		club.Put("description", raw.GetDefault("description", ""))
		club.Put("type", raw.GetDefault("type", "TEAM"))
		club.Put("ownerId", raw.GetDefault("ownerId", ""))
		club.Put("inviteCode", raw.GetDefault("inviteCode", ""))
		club.Put("members", EmptyList)
		Return club
	Catch
		Return empty
	End Try
End Sub

Private Sub SnapshotDocs(snap As JavaObject) As List
	Dim out As List
	out.Initialize
	Try
		Dim docs As JavaObject = snap.RunMethod("getDocuments", Null)
		Dim size As Int = docs.RunMethod("size", Null)
		For i = 0 To size - 1
			Dim d As JavaObject = docs.RunMethod("get", Array(i))
			Dim row As Map
			row.Initialize
			row.Put("id", d.RunMethod("getId", Null))
			row.Put("data", modFirebase.JavaMapToMap(d.RunMethod("getData", Null)))
			out.Add(row)
		Next
	Catch
		Log("SnapshotDocs: " & LastException)
	End Try
	Return out
End Sub

Private Sub AwaitGet(taskObj As Object) As JavaObject
	Dim tasks As JavaObject
	tasks.InitializeStatic("com.google.android.gms.tasks.Tasks")
	Return tasks.RunMethod("await", Array(taskObj))
End Sub

Public Sub GenerateInviteCode As String
	Dim chars As String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	Dim sb As StringBuilder
	sb.Initialize
	For i = 1 To 6
		Dim idx As Int = Rnd(0, chars.Length)
		sb.Append(chars.CharAt(idx))
	Next
	Return sb.ToString
End Sub
