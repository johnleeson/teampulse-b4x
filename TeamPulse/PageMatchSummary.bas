B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' Post-match: coach summary, coach POTM, opposition POTM, fan vote tallies.
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private sv As ScrollView
	Private content As Panel
	Private match As Map
	Private club As Map
	Private edtSummary As EditText
	Private lblCoachPotm As Label
	Private lblOppPotm As Label
	Private potm As Map
	Private coachPotmIds As List
	Private oppPotmIds As List
	Private voteEdits As Map
	Private memberNames As List
	Private memberIds As List
	Private memberAvatars As Map
	Private dialog As B4XDialog
	Private potmPickIds As Map
	Private potmPickHost As Panel
End Sub

Public Sub Initialize
	voteEdits.Initialize
	memberNames.Initialize
	memberIds.Initialize
	memberAvatars.Initialize
	coachPotmIds.Initialize
	oppPotmIds.Initialize
	potmPickIds.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	dialog.Initialize(Root)
	BuildChrome
End Sub

Private Sub B4XPage_Appear
	Load
	BuildForm
End Sub

Private Sub BuildChrome
	Dim chrome As Map = modUI.AddPageChrome(Root, "Post-match", "btnBack", "btnSave", "✓", True)
	Dim top As Int = chrome.Get("ContentTop")
	sv.Initialize(3000dip)
	Root.AddView(sv, 0, top, Root.Width, Root.Height - top)
	content = sv.Panel
	content.Color = modConfig.COLOR_DARK_BG
End Sub

Private Sub Load
	match = modAppState.FindMatch(modAppState.SelectedMatchId)
	club = modAppState.FindClub(match.GetDefault("clubId", ""))
	potm = modDb.NormalizePotmVotes(match.GetDefault("potmVotes", Null))
	coachPotmIds = modDb.GetCategoryPotmPlayerIds(potm, "coach")
	oppPotmIds = modDb.GetCategoryPotmPlayerIds(potm, "opposition")
	memberNames.Initialize
	memberIds.Initialize
	memberAvatars.Initialize
	Dim members As List
	Dim memObj As Object = club.GetDefault("members", Null)
	If memObj <> Null And memObj Is List Then
		members = memObj
	Else
		members.Initialize
	End If
	Dim i As Int
	For i = 0 To members.Size - 1
		Dim mem As Map = members.Get(i)
		memberNames.Add(mem.GetDefault("name", "?"))
		memberIds.Add(mem.GetDefault("id", ""))
		memberAvatars.Put(mem.GetDefault("id", ""), mem.GetDefault("avatar", ""))
	Next
End Sub

Private Sub NameOf(playerId As String) As String
	If playerId = "" Then Return "Not set"
	Dim i As Int
	For i = 0 To memberIds.Size - 1
		If memberIds.Get(i) = playerId Then Return memberNames.Get(i)
	Next
	Return "Unknown"
End Sub

Private Sub NamesOf(ids As List) As String
	If ids.IsInitialized = False Or ids.Size = 0 Then Return "Not set"
	Dim sb As StringBuilder
	sb.Initialize
	Dim i As Int
	For i = 0 To ids.Size - 1
		If i > 0 Then sb.Append(" & ")
		sb.Append(NameOf(ids.Get(i)))
	Next
	Return sb.ToString
End Sub

Private Sub BuildForm
	content.RemoveAllViews
	voteEdits.Initialize
	Dim y As Int = 12dip
	Dim w As Int = Root.Width - 32dip
	
	Dim lblScore As Label
	lblScore.Initialize("")
	lblScore.Text = match.GetDefault("title", "Match") & "  ·  " & match.GetDefault("scoreA", 0) & "-" & match.GetDefault("scoreB", 0)
	lblScore.TextSize = 14
	lblScore.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(lblScore, 16dip, y, w, 22dip)
	y = y + 28dip
	
	y = AddSectionLabel(y, "COACH'S MATCH SUMMARY")
	edtSummary.Initialize("")
	modUI.StyleEditText(edtSummary, "How did the game go?")
	edtSummary.SingleLine = False
	edtSummary.Gravity = Bit.Or(Gravity.TOP, Gravity.LEFT)
	edtSummary.Text = match.GetDefault("aiSummary", "")
	content.AddView(edtSummary, 16dip, y, w, 120dip)
	y = y + 132dip
	
	y = AddSectionLabel(y, "COACH'S PLAYER OF THE MATCH")
	lblCoachPotm.Initialize("")
	lblCoachPotm.Text = NamesOf(coachPotmIds)
	lblCoachPotm.TextSize = 15
	lblCoachPotm.TextColor = modConfig.COLOR_DARK_TEXT
	lblCoachPotm.Typeface = Typeface.DEFAULT_BOLD
	lblCoachPotm.SingleLine = False
	content.AddView(lblCoachPotm, 16dip, y, w - 100dip, 48dip)
	Dim btnCoach As Button
	btnCoach.Initialize("btnPickCoach")
	btnCoach.Text = "Pick"
	btnCoach.Color = modConfig.COLOR_ACCENT
	btnCoach.TextColor = Colors.White
	content.AddView(btnCoach, Root.Width - 100dip, y, 84dip, 40dip)
	y = y + 52dip
	
	y = AddSectionLabel(y, "OPPOSITION PLAYER OF THE MATCH")
	lblOppPotm.Initialize("")
	lblOppPotm.Text = NamesOf(oppPotmIds)
	lblOppPotm.TextSize = 15
	lblOppPotm.TextColor = modConfig.COLOR_DARK_TEXT
	lblOppPotm.Typeface = Typeface.DEFAULT_BOLD
	lblOppPotm.SingleLine = False
	content.AddView(lblOppPotm, 16dip, y, w - 100dip, 48dip)
	Dim btnOpp As Button
	btnOpp.Initialize("btnPickOpp")
	btnOpp.Text = "Pick"
	btnOpp.Color = modConfig.COLOR_ACCENT
	btnOpp.TextColor = Colors.White
	content.AddView(btnOpp, Root.Width - 100dip, y, 84dip, 40dip)
	y = y + 52dip
	
	y = AddSectionLabel(y, "FAN PLAYER OF THE MATCH — VOTES")
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Enter how many fan votes each player received."
	hint.TextSize = 12
	hint.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(hint, 16dip, y, w, 20dip)
	y = y + 28dip
	
	Dim fanCounts As Map
	Dim fcObj As Object = potm.GetDefault("fanCounts", Null)
	If fcObj <> Null And fcObj Is Map Then
		fanCounts = fcObj
	Else
		fanCounts.Initialize
	End If
	
	Dim i As Int
	For i = 0 To memberIds.Size - 1
		Dim pid As String = memberIds.Get(i)
		Dim row As Panel
		row.Initialize("")
		row.Background = modUI.RoundedBg(modConfig.COLOR_DARK_CARD, 10dip)
		content.AddView(row, 16dip, y, w, 52dip)
		Dim lblN As Label
		lblN.Initialize("")
		lblN.Text = memberNames.Get(i)
		lblN.TextSize = 14
		lblN.TextColor = modConfig.COLOR_DARK_TEXT
		lblN.Gravity = Gravity.CENTER_VERTICAL
		row.AddView(lblN, 12dip, 0, w - 100dip, 52dip)
		Dim edt As EditText
		edt.Initialize("")
		modUI.StyleEditText(edt, "0")
		edt.InputType = edt.INPUT_TYPE_NUMBERS
		edt.Gravity = Gravity.CENTER
		Dim votes As Int = fanCounts.GetDefault(pid, 0)
		If votes > 0 Then edt.Text = "" & votes Else edt.Text = ""
		row.AddView(edt, w - 84dip, 8dip, 68dip, 36dip)
		voteEdits.Put(pid, edt)
		y = y + 60dip
	Next
	
	y = y + 24dip
	content.Height = Max(y, Root.Height)
	sv.Panel.Height = content.Height
End Sub

Private Sub AddSectionLabel(y As Int, text As String) As Int
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = text
	lbl.TextSize = 11
	lbl.Typeface = Typeface.DEFAULT_BOLD
	lbl.TextColor = modConfig.COLOR_DARK_MUTED
	content.AddView(lbl, 16dip, y, Root.Width - 32dip, 18dip)
	Return y + 22dip
End Sub

Private Sub btnPickCoach_Click
	Wait For (PickPlayers("Coach's POTM", coachPotmIds)) Complete (ids As List)
	coachPotmIds = ids
	lblCoachPotm.Text = NamesOf(coachPotmIds)
End Sub

Private Sub btnPickOpp_Click
	Wait For (PickPlayers("Opposition POTM", oppPotmIds)) Complete (ids As List)
	oppPotmIds = ids
	lblOppPotm.Text = NamesOf(oppPotmIds)
End Sub

Private Sub PickPlayers(title As String, current As List) As ResumableSub
	potmPickIds.Initialize
	Dim i As Int
	If current.IsInitialized Then
		For i = 0 To current.Size - 1
			Dim existing As String = "" & current.Get(i)
			If existing <> "" Then potmPickIds.Put(existing, True)
		Next
	End If
	Dim pnl As B4XView = xui.CreatePanel("")
	pnl.SetLayoutAnimated(0, 0, 0, 320dip, 420dip)
	pnl.Color = modConfig.COLOR_DARK_BG
	Dim hint As Label
	hint.Initialize("")
	hint.Text = "Tap everyone who shared it, then Done."
	hint.TextColor = modConfig.COLOR_DARK_MUTED
	hint.TextSize = 12
	pnl.AddView(hint, 8dip, 4dip, 304dip, 28dip)
	Dim sv As ScrollView
	sv.Initialize(800dip)
	pnl.AddView(sv, 0, 36dip, 320dip, 376dip)
	potmPickHost = sv.Panel
	potmPickHost.Color = modConfig.COLOR_DARK_BG
	DrawPotmGrid
	dialog.Title = title
	Wait For (dialog.ShowCustom(pnl, "Done", "", "Cancel")) Complete (Result As Int)
	Dim chosen As List
	chosen.Initialize
	If Result = xui.DialogResponse_Positive Then
		For Each pid As String In potmPickIds.Keys
			chosen.Add(pid)
		Next
	Else If current.IsInitialized Then
		For i = 0 To current.Size - 1
			chosen.Add(current.Get(i))
		Next
	End If
	Return chosen
End Sub

Private Sub DrawPotmGrid
	If potmPickHost.IsInitialized = False Then Return
	potmPickHost.RemoveAllViews
	Dim cols As Int = 3
	Dim size As Int = 72dip
	Dim cellW As Int = 320dip / cols
	Dim rowH As Int = size + 22dip
	Dim col As Int = 0
	Dim row As Int = 0
	Dim i As Int
	For i = 0 To memberIds.Size - 1
		Dim pid As String = memberIds.Get(i)
		Dim tag As Map
		tag.Initialize
		tag.Put("id", pid)
		Dim slot As Map = modUI.CreateRoundPlayerSlot("potmSpot", tag, size, memberNames.Get(i), memberAvatars.GetDefault(pid, ""), "", potmPickIds.ContainsKey(pid))
		Dim spot As Panel = slot.Get("panel")
		potmPickHost.AddView(spot, col * cellW + 8dip, row * rowH + 4dip, size + 16dip, size + 18dip)
		If slot.ContainsKey("imageView") Then
			Dim iv As ImageView = slot.Get("imageView")
			If iv.IsInitialized Then CallSubDelayed3(Me, "LoadPotmAvatar", iv, memberAvatars.GetDefault(pid, ""))
		End If
		col = col + 1
		If col >= cols Then
			col = 0
			row = row + 1
		End If
	Next
	Dim rows As Int = row
	If col > 0 Then rows = rows + 1
	potmPickHost.Height = rows * rowH + 12dip
End Sub

Private Sub LoadPotmAvatar(iv As ImageView, url As String)
	If url = "" Then Return
	Dim j As HttpJob
	j.Initialize("", Me)
	j.Download(url)
	Wait For (j) JobDone (job As HttpJob)
	If job.Success Then
		Try
			Dim bmp As Bitmap = job.GetBitmap
			If bmp <> Null And bmp.IsInitialized Then
				iv.Bitmap = bmp
				iv.Gravity = Gravity.FILL
			End If
		Catch
			Log("POTM avatar: " & LastException.Message)
		End Try
	End If
	job.Release
End Sub

Private Sub potmSpot_Click
	Dim pnl As Panel = Sender
	Dim tag As Map = pnl.Tag
	Dim pid As String = tag.GetDefault("id", "")
	If pid = "" Then Return
	If potmPickIds.ContainsKey(pid) Then
		potmPickIds.Remove(pid)
	Else
		potmPickIds.Put(pid, True)
	End If
	DrawPotmGrid
End Sub

Private Sub CollectFanCounts As Map
	Dim fc As Map
	fc.Initialize
	For Each pid As String In voteEdits.Keys
		Dim edt As EditText = voteEdits.Get(pid)
		Dim n As Int = 0
		Try
			If edt.Text.Trim <> "" Then n = edt.Text
		Catch
			Log("vote parse: " & LastException.Message)
			n = 0
		End Try
		If n > 0 Then fc.Put(pid, n)
	Next
	Return fc
End Sub

Private Sub btnSave_Click
	match.Put("aiSummary", edtSummary.Text.Trim)
	modDb.SetCategoryPotmPlayerIds(potm, "coach", coachPotmIds)
	modDb.SetCategoryPotmPlayerIds(potm, "opposition", oppPotmIds)
	potm.Put("fanCounts", CollectFanCounts)
	match.Put("potmVotes", potm)
	modDb.SaveMatch(match)
	modAppState.UpsertMatch(match)
	ToastMessageShow("Post-match report saved", False)
End Sub

Private Sub btnBack_Click
	btnSave_Click
	B4XPages.ShowPage("MatchHub")
End Sub
