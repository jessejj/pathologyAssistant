Say "Starting script..."
script = WScript.Arguments(0)

If script = "Cassettes" Then Cassettes
If script = "CaseFinder" Then CaseFinder
If script = "DuplicateBlock" Then DuplicateBlock
WScript.Quit

Sub CaseFinder
	Set shell = CreateObject("Wscript.Shell")
	If Not GetPowerPath() Then Exit Sub
	
	shell.SendKeys("^{F3}"), True

	For Index = 0 to 5
		Wait 1
		If shell.AppActivate("Case Finder") Then Exit For
	Next

	If shell.AppActivate("Case Finder") Then
		shell.SendKeys"%p", True
		'Clipboard "bob"
		shell.SendKeys"PATIENTS NAME", True
		shell.SendKeys "{tab 9}", True
		shell.SendKeys "2020-01-01", True
	End If

	Set shell = Nothing
End Sub

Sub DuplicateBlock
	Set shell = CreateObject("Wscript.Shell")

	If GetCaseWindow() Then
		shell.SendKeys "%a", True
		shell.SendKeys "^3", True
		shell.SendKeys "%m", True
		shell.SendKeys "{tab}{home}", True
		shell.SendKeys "sp{down}^u~%y",True

	End If

	Set shell = Nothing
End Sub

Function GetCaseWindow()
If Not GetPowerPath() Then Exit Function
	Set shell = CreateObject("Wscript.Shell")

	For Index = 0 to 3
		If shell.AppActivate("PowerPath Client (Test System) - [Case Information - " ) Then
			GetCaseWindow = True
			Exit For
		Else
			shell.SendKeys"^{F6}", True
		End If
		Wait 1
	Next
	Set shell = Nothing
End Function

Function GetPowerPath()
	Set shell = CreateObject("Wscript.Shell")
	If shell.AppActivate("PowerPath Client (Test System) - ") Then
		Maximized = True
	End If

	If shell.AppActivate("PowerPath Client (Test System)") Then
		If Not Maximized Then shell.SendKeys"%-x", True
		GetPowerPath = True
	Else
		msgbox "Can't find PowerPath Client. Is it running?"
	End If
	Set shell = Nothing
End Function

Function Clipboard(text)
	Set objHTML = CreateObject("htmlfile")
	'Clipboard = objHTML.ParentWindow.ClipboardData.GetData("text")
	objHTML.ParentWindow.ClipboardData.SetData "text", text
	set objHTML = Nothing
End Function

Function Say(message)
	On Error Resume Next
	WScript.StdOut.Write message
	If Err.Number <> 0 Then
		Msgbox "This is the script file for the Pathology Assistant App."
		WScript.Quit
	End If
	On Error Goto 0
	WScript.StdOut.WriteLine
End Function

Function Wait(seconds)
	WScript.Sleep seconds * 1000
End Function

Sub Cassettes
	If WScript.Arguments(1) = "ExitBin2" Then ExitBin = 2
	If WScript.Arguments(1) = "ExitBin3" Then ExitBin = 3

	Set shell = CreateObject("Wscript.Shell")
	Dim ThisPC
	ThisPC = shell.ExpandEnvironmentStrings("%COMPUTERNAME%")
	'ThisPC = "OH182236"	'for testing

	Dim casArr(0, 4)	'2 dimensional array of cassette printers and the PCs that print to it
	casArr(0, 0) = "CIV-GRO-CAS1"
	casArr(0, 1) = "OH182236"	'wide bench
	casArr(0, 2) = "OH181525"	'right handed bench
	casArr(0, 3) = "OH163934"	'left handed bench
	casArr(0, 4) = "OH182644"	'labelase

	For Index = 0 to UBound(casArr, 2)
		If ThisPC = casArr(0, Index) Then ChangeEnabled = True
	Next

	If Not ChangeEnabled Then 
		Say "This script cannot change the cassette exit bin for this PC"
		Wait 3
		WScript.Quit
	End If

	Say "Changing cassette exit bin to Bin " & ExitBin
	CassetteDir = "C:\Cassettes\"
	PrinterDir = "\\CLPATHIF01\DIS_SHARE\"
	Set FSO = CreateObject("Scripting.FileSystemObject")
	If Not FSO.FolderExists(CassetteDir) Then FSO.CreateFolder(CassetteDir)

	shell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\IMPAC\PseudoDriver\CIV-GRO-CAS1\v1.0\Directory Path", CassetteDir, "REG_SZ" 

	Do
		If Not shell.RegRead("HKLM\SOFTWARE\Wow6432Node\IMPAC\PseudoDriver\CIV-GRO-CAS1\v1.0\Directory Path") = CassetteDir Then Exit Do
		Set Folder = FSO.GetFolder(CassetteDir)
		Set Files = Folder.Files
		If Files.Count = 0 Then
			Wait 1
		Else
			CassetteCount = 0
			TotalCassettes = Files.Count
			If TotalCassettes > 4 Then LargeBatch = True Else LargeBatch = False 

			For Each file in Files
				CassetteCount = CassetteCount + 1
				Set ReadFile = FSO.OpenTextFile(file.path, 1)
					text = ReadFile.ReadAll
					ReadFile.close

					If instr(text, "<DEVCOMMENT>Cassette Labels for Delimited Value type devices.") = 0 Then 
						Say file.path & " does not appear to be a cassette text file. Ending script..."
						Exit Do
					End If
				
					Set WriteFile = FSO.OpenTextFile(file.path, 2)
						text = Replace(text, "<STORE>1<>", "<STORE>" & ExitBin & "<>")
						WriteFile.Write text
						WriteFile.close
					
					file.move PrinterDir
					Say "(" & CassetteCount & "/" & TotalCassettes & ") cassettes sent to the printer."
					If CassetteCount = TotalCassettes Then Say "Now safe to stop script."
				
				If LargeBatch Then
					For Index = 1 to 11 'seconds (change this value to control how long it takes for the queue to be processed)
						Wait 1
					Next
				End If
			Next
		End If
	Loop
		
	Set FSO = Nothing
	Set shell = Nothing
End Sub