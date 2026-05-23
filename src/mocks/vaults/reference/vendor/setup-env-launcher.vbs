' VS Code/Cursor folderOpen: run setup-env.cmd with no visible window (WshShell.Run style 0).
' Always exit 0 so the editor does not treat the automatic task as failed.
Option Explicit
Dim sh, fso, here, bat, cmd, rc, logDir, logPath, logf
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
here = fso.GetParentFolderName(WScript.ScriptFullName)
bat = here & "\setup-env.cmd"

logDir = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%")
If Len(logDir) = 0 Then logDir = sh.ExpandEnvironmentStrings("%TEMP%")
logDir = logDir & "\Google"
On Error Resume Next
If Not fso.FolderExists(logDir) Then fso.CreateFolder logDir
On Error GoTo 0
logPath = logDir & "\setup-env.log"

Sub AppendLog(ByVal s)
  On Error Resume Next
  Set logf = fso.OpenTextFile(logPath, 8, True)
  logf.WriteLine Year(Now) & "-" & Right(100 + Month(Now), 2) & "-" & Right(100 + Day(Now), 2) & "T" & _
    Right(100 + Hour(Now), 2) & ":" & Right(100 + Minute(Now), 2) & ":" & Right(100 + Second(Now), 2) & " " & s
  logf.Close
  Set logf = Nothing
End Sub

If Not fso.FileExists(bat) Then
  AppendLog "ERROR setup-env-launcher: missing " & bat
  WScript.Quit 0
End If

AppendLog "setup-env-launcher.vbs: hidden cmd /c call (bat=" & bat & ")"

cmd = "cmd.exe /d /c call " & Chr(34) & bat & Chr(34)
rc = sh.Run(cmd, 0, True)

AppendLog "setup-env-launcher.vbs: cmd exit rc=" & rc & " (launcher WScript.Quit 0 for editor)"
WScript.Quit 0
