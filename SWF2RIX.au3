#include <Array.au3>
#include <GUIConstantsEx.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <String.au3>
#include <WindowsConstants.au3>

Local $fileName = ""
Local $extName = ""
Local $findHex = ""

$Form1			= Guicreate("SWF2RIX: For AG2", 332, 285, -1, -1)

$Group1			= GUICtrlCreateGroup("Input Options", 10, 10, 310, 140)

$Progressbar1	= GUICtrlCreateProgress(10, 170, 310, 20)

$btnGo			= GuiCtrlCreateButton("Go", 60, 220, 220, 50)

$Label1			= GuiCtrlCreateLabel("File:", 30, 50, 20, 20)

$Input1			= GUICtrlCreateInput("", 60, 50, 180, 20)

$btnSelect		= GuiCtrlCreateButton("Select", 260, 50, 50, 80)

$rdoRIX			= GUICtrlCreateRadio("RIX", 40, 100, 50, 20)
$rdoMIDI		= GUICtrlCreateRadio("MIDI", 120, 100, 50, 20)
$rdoVOC			= GUICtrlCreateRadio("VOC", 200, 100, 50, 20)

GUICtrlSetData($Progressbar1, 0)

GuiSetState(@SW_SHOW)

While 1
   $Msg = GUIGetMsg()
   Switch $Msg
	  Case $GUI_EVENT_CLOSE
		 Exit

	  Case $btnGo
		 GUICtrlSetData($Progressbar1, 0)
		 GUICtrlSetData($Input1, $fileName)
		 Unpack($fileName, $findHex, $extName)

	  Case $btnSelect
		 $fileName = SelectFile()
		 GUICtrlSetData($Input1, $fileName)

	  Case $rdoRIX
		 $extName = "RIX"
		 $findHex = "AA550000"

	  Case $rdoMIDI
		 $extName = "MID"
		 $findHex = "4D546864"

	  Case $rdoVOC
		 $extName = "VOC"
		 $findHex = "437265617469766520566F6963652046696C65"

   EndSwitch
Wend

Func SelectFile()
   ; Create a constant variable in Local scope of the message to display in FileOpenDialog.
   Local Const $sMessage = "Select a single file of any type."
   Local $fileName = ""

   ; Display an open dialog to select a file.
   Local $sFileOpenDialog = FileOpenDialog($sMessage, @ScriptDir & "\", "All (*.*)", $FD_FILEMUSTEXIST)
   If @error Then
	  ; Display the error message.
	  MsgBox($MB_SYSTEMMODAL, "", "No file was selected.")

	  ; Change the working directory (@WorkingDir) back to the location of the script directory as FileOpenDialog sets it to the last accessed folder.
	  FileChangeDir(@ScriptDir)
	  $fileName = ""
   Else
	  ; Change the working directory (@WorkingDir) back to the location of the script directory as FileOpenDialog sets it to the last accessed folder.
	  FileChangeDir(@ScriptDir)

	  ; Replace instances of "|" with @CRLF in the string returned by FileOpenDialog.
	  $sFileOpenDialog = StringReplace($sFileOpenDialog, "|", @CRLF)

	  ; Display the selected file.
	  ;MsgBox($MB_SYSTEMMODAL, "", "You chose the following file:" & @CRLF & $sFileOpenDialog)
	  $fileName = $sFileOpenDialog
   EndIf

   Return $fileName
EndFunc


Func Unpack($fileName, $findHex, $extName)

   If $fileName = "" Then Return False
   If $findHex = "" Then Return False
   If $extName = "" Then Return False

   Local $hFileOpen = FileOpen($fileName, $FO_BINARY )

   If $hFileOpen = -1 Then
	  MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
	  Exit
   EndIf

   ; Read the contents of the file using the handle returned by FileOpen.
   Local $sFileRead = FileRead($hFileOpen)

   ; Close the handle returned by FileOpen.
   FileClose($hFileOpen)

   ; Remove "0x"
   $sFileRead = StringMid($sFileRead, 3)

   ; Create an array of all the values between "$findHex" and "$findHex".
   Local $aArray = _StringBetween($sFileRead, $findHex, $findHex, 0, True)
   Local $iCount = UBound($aArray)
   Local $sLast = StringMid($sFileRead, StringInStr($sFileRead, $findHex, 0 , -1))

   For $i = 0 To $iCount - 1
	  $aArray[$i] = $findHex & $aArray[$i]
	  SaveHexFile(SetFileName($fileName, $i + 1, $iCount + 1, $extName), $aArray[$i])
	  GUICtrlSetData($Progressbar1, ($i + 1) / $iCount)
   Next

   If $iCount > 0 Then

	  ReDim $aArray[$iCount + 1]
	  $aArray[$iCount] = $sLast
	  SaveHexFile(SetFileName($fileName, $iCount + 1, $iCount + 1, $extName), $aArray[$iCount])
	  $iCount = $iCount + 1
	  GUICtrlSetData($Progressbar1, 100)
	  Sleep(1000)

	  ; Display the results in _ArrayDisplay.
	  _ArrayDisplay($aArray, $fileName & ": " & $extName & " File Hex Info")

   Else
	  MsgBox(64, "Input: " &$fileName, $extName & " Format (" & $findHex & ") Not Found.")
   EndIf
EndFunc

Func SetFileName($fileName, $iIndex, $iCount, $extName)

   Local $sNumStr = "00000" & String($iIndex)
   Local $iNumLen = StringLen(String($iCount))
   Local $sSaveName = StringLeft($fileName, StringInStr($fileName, ".") - 1)
   $sSaveName = $sSaveName & "_" & StringRight($sNumStr, $iNumLen) & "." & $extName

   Return $sSaveName

EndFunc

Func SaveHexFile($sFile, $sHex)

    ; Open the file for writing (append to the end of a file) and store the handle to a variable.
    Local $hFileOpen = FileOpen($sFile, $FO_OVERWRITE + $FO_BINARY)
    If $hFileOpen = -1 Then
        MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the temporary file.")
        Return False
    EndIf

    ; Write data to the file using the handle returned by FileOpen.
    FileWrite($hFileOpen, Binary("0x" & $sHex))

    ; Close the handle returned by FileOpen.
    FileClose($hFileOpen)

EndFunc
