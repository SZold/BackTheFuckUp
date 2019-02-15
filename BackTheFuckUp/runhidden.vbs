Dim objShell,objFSO,objFile,selfFile

Set objShell=CreateObject("WScript.Shell")
Set objFSO=CreateObject("Scripting.FileSystemObject")
Set selfFile = objFSO.GetFile(Wscript.ScriptFullName)
strFolder = objFSO.GetParentFolderName(selfFile) 

'enter the path for your PowerShell Script
 strPath= strFolder & "\BackTheFuckUp.ps1"

'verify file exists
 If objFSO.FileExists(strPath) Then
   'return short path name
   set objFile=objFSO.GetFile(strPath)
   strCMD="powershell -nologo -command " & Chr(34) & "&{.'" &_
    objFile.ShortPath & "'" & WScript.Arguments(0) & "}" & Chr(34)
   'Uncomment next line for debugging
   'WScript.Echo strCMD

  'use 0 to hide window
   objShell.Run strCMD,0

Else

  'Display error message
   WScript.Echo "Failed to find " & strPath
   WScript.Quit

End If