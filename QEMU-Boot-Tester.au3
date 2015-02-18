#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=1021.ico
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <String.au3>

Global $qemu_exe = @ScriptDir & '\qemu\qemu-system-i386w.exe'
Global $qemu_dir = @ScriptDir & '\qemu'
Global $stdout = @ScriptDir & '\qemu\stdout.txt'
Global $stderr = @ScriptDir & '\qemu\stderr.txt'

#region ### START GUI section ###
$Form1_1 = GUICreate("[QEMU] Boot Disk Tester v1.1 by Nomadic", 552, 318, 192, 124, Default, $WS_EX_ACCEPTFILES)
$Group1 = GUICtrlCreateGroup(" Boot options ", 16, 8, 521, 89, -1, $WS_EX_TRANSPARENT)
GUICtrlSetState(-1, $GUI_DROPACCEPTED)
$RadioImage = GUICtrlCreateRadio("Boot from image", 32, 32, 97, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
$RadioDrive = GUICtrlCreateRadio("Boot from drive", 144, 32, 97, 17)
$InputFile = GUICtrlCreateInput("", 32, 56, 465, 21)
$ButtonSelect = GUICtrlCreateButton("...", 504, 56, 27, 21, $WS_GROUP)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$ComboDrive = GUICtrlCreateCombo("", 32, 56, 497, 25, $CBS_DROPDOWNLIST)
GUICtrlSetState(-1, $GUI_HIDE)
$LabelAdmin = GUICtrlCreateLabel("Administrative privileges are required for this function", 260, 34, 250, 17)
GUICtrlSetColor(-1, 0xFF0000)
GUICtrlSetState(-1, $GUI_HIDE)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Group2 = GUICtrlCreateGroup(" Emulation options ", 16, 112, 521, 105)
$CheckboxHDD = GUICtrlCreateCheckbox("Emulate secondary HDD", 32, 136, 150, 17)
$CheckboxSnapshot = GUICtrlCreateCheckbox("Enable snapshot mode", 32, 160, 140, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
$CheckboxNoNet = GUICtrlCreateCheckbox("Disable Network", 32, 184, 97, 17)
$Label1 = GUICtrlCreateLabel("RAM: ", 387, 135, 34, 17)
$InputMem = GUICtrlCreateInput("512", 424, 132, 33, 21)
$CheckboxSound = GUICtrlCreateCheckbox("Enable Sound", 200, 136, 97, 17)
$CheckboxUSB = GUICtrlCreateCheckbox("Enable USB", 200, 160, 97, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
$CheckboxNoACPI = GUICtrlCreateCheckbox("Disable ACPI", 200, 184, 97, 17)
$Label2 = GUICtrlCreateLabel("Video card type:", 336, 162, 81, 17)
$ComboVideo = GUICtrlCreateCombo("cirrus", 424, 158, 60, 25, $CBS_DROPDOWNLIST)
GUICtrlSetData(-1, "vmware|std|none")
$Label3 = GUICtrlCreateLabel("Select CPU type:", 332, 187, 81, 17)
$ComboCPU = GUICtrlCreateCombo("", 424, 184, 90, 25, $CBS_DROPDOWNLIST)
GUICtrlSetData(-1, _GetCPUList())
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Group3 = GUICtrlCreateGroup(" QEMU " & _GetQemuVersion() & " command line: ", 16, 232, 521, 49)
$InputCmd = GUICtrlCreateInput("", 24, 249, 505, 21)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$ButtonBoot = GUICtrlCreateButton(" BOOT", 16, 288, 85, 25, BitOR(-1, $BS_ICON))
GUICtrlSetImage($ButtonBoot, "imageres.dll", 37, 0)
$ButtonExit = GUICtrlCreateButton(" EXIT", 464, 288, 75, 25, BitOR(-1, $BS_ICON))
GUICtrlSetImage($ButtonExit, "shell32.dll", 329, 0)
$LabelNotFound = GUICtrlCreateLabel("File qemu.exe not found in working directory!", 160, 296, 220, 17)
GUICtrlSetColor(-1, 0xFF0000)
GUICtrlSetState($LabelNotFound, $GUI_HIDE)
GUISetState(@SW_SHOW)
#endregion ### START GUI section ###

Dim $AccelKeys[1][2] = [["{ENTER}", $ButtonBoot]]
GUISetAccelerators($AccelKeys)

If Not FileExists($qemu_exe) Then GUICtrlSetState($LabelNotFound, $GUI_SHOW)
If Not FileExists(@ScriptDir & '\hdd-secondary.qcow2') Then FileInstall("hdd.qcow2.bak", @ScriptDir & "\hdd-secondary.qcow2")

$drive = ""
$filename = ""
$cdrom = ""
$floppy = ""
$emulatehdd = ""
$snapshot = $GUI_CHECKED
$nonet = ""
$sound = ""
$usb = $GUI_CHECKED
$noacpi = ""
$memsize = "512"
$vga = "cirrus"
$cpu = ""
$commandline = ""

_GenerateCmdline()

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

		Case $GUI_EVENT_DROPPED
			If Not StringInStr(FileGetAttrib(@GUI_DragFile), "D") Then
				$filename = @GUI_DragFile
				GUICtrlSetData($InputFile, $filename)
				_GenerateCmdline()
			EndIf

		Case $RadioImage
			$drive = ""
			$cdrom = ""
			GUICtrlSetImage($ButtonBoot, "imageres.dll", 37, 0)
			GUICtrlSetState($ComboDrive, $GUI_HIDE)
			GUICtrlSetState($LabelAdmin, $GUI_HIDE)
			GUICtrlSetData($InputFile, "")
			GUICtrlSetState($InputFile, $GUI_SHOW)
			GUICtrlSetState($ButtonSelect, $GUI_SHOW)
			_GenerateCmdline()

		Case $RadioDrive
			$filename = ""
			$drive = ""
			$cdrom = ""
			$floppy = ""
			GUICtrlSetState($InputFile, $GUI_HIDE)
			GUICtrlSetState($ButtonSelect, $GUI_HIDE)
			GUICtrlSetData($ComboDrive, "")
			$drivelist = "= REMOVABLE ="
			$drivevar = DriveGetDrive("REMOVABLE")
			If Not @error Then
				For $i = 1 To $drivevar[0]
					If DriveStatus($drivevar[$i]) = "READY" Then $drivelist = $drivelist & "|" & StringUpper($drivevar[$i])
				Next
			EndIf
			$drivelist = $drivelist & "|= CD/DVD ="
			$drivevar = DriveGetDrive("CDROM")
			If Not @error Then
				For $i = 1 To $drivevar[0]
					If DriveStatus($drivevar[$i]) = "READY" Then $drivelist = $drivelist & "|" & StringUpper($drivevar[$i])
				Next
			EndIf
			$drivelist = $drivelist & "|= HDD ="
			$drivevar = DriveGetDrive("FIXED")
			If Not @error Then
				For $i = 1 To $drivevar[0]
					If DriveStatus($drivevar[$i]) = "READY" Then $drivelist = $drivelist & "|" & StringUpper($drivevar[$i])
				Next
			EndIf
			GUICtrlSetData($ComboDrive, $drivelist)
			GUICtrlSetState($ComboDrive, $GUI_SHOW)
			_GenerateCmdline()

		Case $ComboDrive
			$drive = ""
			$cdrom = ""
			$driveletter = GUICtrlRead($ComboDrive)
			If DriveGetType($driveletter) = "CDROM" Then $cdrom = "\\.\" & $driveletter
			If DriveGetType($driveletter) = "FIXED" Then
				GUICtrlSetState($CheckboxSnapshot, $GUI_CHECKED)
				$snapshot = $GUI_CHECKED
			EndIf
			If (StringInStr($driveletter, "=") = 0) And ($cdrom = "") Then $drive = _GetDeviceID($driveletter)
			If ($drive <> "") And (Not IsAdmin()) Then
				GUICtrlSetState($LabelAdmin, $GUI_SHOW)
				GUICtrlSetImage($ButtonBoot, "imageres.dll", 78, 0)
			Else
				GUICtrlSetImage($ButtonBoot, "imageres.dll", 37, 0)
				GUICtrlSetState($LabelAdmin, $GUI_HIDE)
			EndIf
			_GenerateCmdline()

		Case $InputFile
			$filename = GUICtrlRead($InputFile)
			_GenerateCmdline()

		Case $ButtonSelect
			$filename = FileOpenDialog("Select QEMU image file...", "", _
					"All Image files (*.iso;*.img;*.vmdk;*.vdi;*.vhd;*.raw;*.cow;*.qcow;*.qcow2;*.ima;*.vfd;*.flp)|All files (*.*)")
			GUICtrlSetData($InputFile, $filename)
			_GenerateCmdline()

		Case $InputCmd
			$commandline = GUICtrlRead($InputCmd)

		Case $CheckboxHDD
			$emulatehdd = GUICtrlRead($CheckboxHDD)
			_GenerateCmdline()

		Case $CheckboxSnapshot
			$snapshot = GUICtrlRead($CheckboxSnapshot)
			_GenerateCmdline()

		Case $CheckboxNoNet
			$nonet = GUICtrlRead($CheckboxNoNet)
			_GenerateCmdline()

		Case $CheckboxSound
			$sound = GUICtrlRead($CheckboxSound)
			_GenerateCmdline()

		Case $CheckboxUSB
			$usb = GUICtrlRead($CheckboxUSB)
			_GenerateCmdline()

		Case $CheckboxNoACPI
			$noacpi = GUICtrlRead($CheckboxNoACPI)
			_GenerateCmdline()

		Case $InputMem
			$memsize = GUICtrlRead($InputMem)
			_GenerateCmdline()

		Case $ComboVideo
			$vga = GUICtrlRead($ComboVideo)
			_GenerateCmdline()

		Case $ComboCPU
			$cpu = GUICtrlRead($ComboCPU)
			_GenerateCmdline()


		Case $ButtonBoot
			If Not FileExists($qemu_exe) Then
				GUICtrlSetState($LabelNotFound, $GUI_SHOW)
			Else
				GUICtrlSetState($LabelNotFound, $GUI_HIDE)
				If (GUICtrlRead($RadioDrive) = $GUI_CHECKED) And (Not IsAdmin()) And ($cdrom = "") Then
					ShellExecuteWait($qemu_exe, '-name "Boot Disk Tester" -L . ' & $commandline, $qemu_dir, "runas")
				Else
					RunWait($qemu_exe & ' -name "Boot Disk Tester" -L . ' & $commandline, $qemu_dir)
				EndIf
				If @error <> 0 Then MsgBox(16, "Error", "Problem with execute QEMU!")
				If $snapshot = $GUI_CHECKED Then FileDelete(@TempDir & "\qem*.tmp")
				If FileExists($stderr) Then
					$stderr_msg = FileRead($stderr)
					If $stderr_msg <> "" Then MsgBox(16, "stderr log: ", $stderr_msg)
					FileDelete($stderr)
				EndIf
			EndIf

		Case $ButtonExit
			Exit

	EndSwitch
WEnd

Func _GenerateCmdline()
	$commandline = ""
	If $filename <> "" Then
		$ext = StringLower(StringRight($filename, 4))
		If $ext = ".iso" Then
			$cdrom = $filename
		Else
			$cdrom = ""
		EndIf
		If ($ext = ".ima") Or ($ext = ".vfd") Or ($ext = ".flp") Then
			$floppy = $filename
		Else
			$floppy = ""
		EndIf
	EndIf
	If $snapshot = $GUI_CHECKED Then $commandline = $commandline & " -snapshot"
	If $nonet = $GUI_CHECKED Then $commandline = $commandline & " -net none"
	If $sound = $GUI_CHECKED Then $commandline = $commandline & " -soundhw all"
	If $usb = $GUI_CHECKED Then $commandline = $commandline & " -usb"
	If $noacpi = $GUI_CHECKED Then $commandline = $commandline & " -no-acpi"
	If $memsize <> "" Then $commandline = $commandline & " -m " & $memsize
	If ($vga <> "") And ($vga <> "cirrus") Then $commandline = $commandline & " -vga " & $vga
	If $cpu <> "" Then $commandline = $commandline & " -cpu " & $cpu
	If $cdrom <> "" Then $commandline = $commandline & '  -boot d -cdrom "' & $cdrom & '"'
	If $floppy <> "" Then $commandline = $commandline & '  -boot a -fda "' & $floppy & '"'
	If ($drive <> "") And ($cdrom = "") And ($floppy = "") Then $commandline = $commandline & ' -hda "' & $drive & '"'
	If ($filename <> "") And ($cdrom = "") And ($floppy = "") Then $commandline = $commandline & ' -hda "' & $filename & '"'
	If $emulatehdd = $GUI_CHECKED Then $commandline = $commandline & ' -hdb ..\hdd-secondary.qcow2'
	GUICtrlSetData($InputCmd, $commandline)
EndFunc   ;==>_GenerateCmdline

Func _GetCPUList()
	Local $cpulist = ""
	Local $cpustr = ""
	Local $line = ""
	If FileExists($qemu_exe) Then RunWait($qemu_exe & " -cpu ?", $qemu_dir, @SW_HIDE)
	If FileExists($stdout) Then
		Local $file = FileOpen($stdout)
		While 1
			$line = FileReadLine($file)
			If (@error = -1) or ($line = "") Then ExitLoop
			$cpustr = StringStripWS(StringMid($line, 5, 16), 8)
			$cpulist = $cpulist & '|' & $cpustr
		WEnd
		FileClose($file)
		FileDelete($stdout)
		Return $cpulist
	Else
		Return ""
	EndIf
EndFunc   ;==>_GetCPUList

Func _GetQemuVersion()
	Local $ver = ""
	Local $line = ""
	If FileExists($qemu_exe) Then
		RunWait($qemu_exe & " -version", $qemu_dir, @SW_HIDE)
		$line = FileRead($stdout)
		FileDelete($stdout)
		If $line <> "" Then
			$ver = StringRegExp($line, "[0-9]+\.[0-9]+\.[0-9]+", 1)
			If $ver = '' Then $ver = StringRegExp($line, "[0-9]+\.[0-9]+", 1)
			Return "v" & $ver[0]
		EndIf
	Else
		Return ""
	EndIf
EndFunc   ;==>_GetQemuVersion

Func _GetDeviceID($drive)
	Local $objWMIService = ObjGet("winmgmts:{impersonationLevel=Impersonate}!\\.\root\cimv2")
	If Not IsObj($objWMIService) Then Return -1 ;Failed to Connect to WMI on Local Machine

	Local $colDevice = $objWMIService.ExecQuery("SELECT * from Win32_LogicalDiskToPartition")
	Local $var = ""
	For $objItem In $colDevice
		If StringInStr($objItem.Dependent, $drive) Then
			$var = StringTrimLeft($objItem.Antecedent, StringInStr($objItem.Antecedent, "="))
		EndIf
	Next
	If Not $var Then Return -2 ;Failed to Find Drive Letter
	$colDevice = $objWMIService.ExecQuery("SELECT * from Win32_DiskDriveToDiskPartition")
	Local $diskpartition = $var
	$var = ""
	For $objItem In $colDevice
		If StringInStr($objItem.Dependent, $diskpartition) Then
			$var = StringTrimLeft($objItem.Antecedent, StringInStr($objItem.Antecedent, "="))
		EndIf
	Next
	If Not $var Then Return -3 ;Failed to Find Physical Drive #
	$var = StringReplace(StringReplace(StringReplace($var, "\\", "\"), '"', ""), "PHYSICALDRIVE", "PhysicalDrive")
	Return $var
EndFunc   ;==>_GetDeviceID
