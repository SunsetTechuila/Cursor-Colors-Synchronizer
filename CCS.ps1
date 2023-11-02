#Requires -RunAsAdministrator
#Requires -Version 5.1

#region Preparation
$ErrorActionPreference = 'Stop'

$previousWindowTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = 'Cursor Colors Synchronizer'

$Parameters = @{
	BindingVariable = 'Localization'
	BaseDirectory   = "$PSScriptRoot\Localizations"
	FileName        = 'Strings'
}
Import-LocalizedData @Parameters

Import-Module -Name "$PSScriptRoot\Functions.psm1" -Force
#endregion Preparation

#region Dialogs
Clear-Host

$Host.UI.RawUI.Flushinputbuffer()
$choice = $Host.UI.PromptForChoice(
	'',
	$Localization.ChooseDialogPromt,
	(
		"&1 $($Localization.Small)",
		"&2 $($Localization.Regular)",
		"&3 $($Localization.Big)"
	),
	0
)
switch ($choice) {
	0 { $cursorSize = 'small' }
	1 { $cursorSize = 'regular' }
	2 { $cursorSize = 'big' }
}


$Host.UI.RawUI.Flushinputbuffer()
$choice = $Host.UI.PromptForChoice(
	'',
	$Localization.ChoosePrecisionDialogTitle,
	(
		"&1 $($Localization.Yes)",
		"&2 $($Localization.No)"
	),
	1
)
switch ($choice) {
	0 { $useAlternatePrecision = $true }
	1 { $useAlternatePrecision = $false }
}

$Host.UI.RawUI.Flushinputbuffer()
$choice = $Host.UI.PromptForChoice(
	'',
	$Localization.ListenerDialogTitle,
	(
		"&1 $($Localization.Yes)",
		"&2 $($Localization.No)"
	),
	0
)
switch ($choice) {
	0 { $installListener = $true }
	1 { $installListener = $false }
}
#endregion Dialogs


#region Variables
$systemTheme = Get-SystemTheme
$prefsPath = "$PSScriptRoot\prefs"
$resourcesFolderPath = "$PSScriptRoot\Resources"
$diffFolder = "$resourcesFolderPath\Diffs\$cursorSize"
$cursorsFolderPath = "$resourcesFolderPath\Cursors"
$originalCursorFolderPath = "$cursorsFolderPath\Original\$systemTheme\$cursorSize"
$editedCursorFolderPath = "$cursorsFolderPath\Edited"
#endregion Variables

#region Cursor
Copy-Item -Path "$originalCursorFolderPath\default\*" -Destination $editedCursorFolderPath -Recurse -Force
if (($systemTheme -eq 'light') -and ($cursorSize -eq 'big')) {
	Edit-Cursors -Path $editedCursorFolderPath -DiffFolderPath $diffFolder -UseAlternateDiff
}
else {
	Edit-Cursors -Path $editedCursorFolderPath -DiffFolderPath $diffFolder
}

if ($useAlternatePrecision) {
	Copy-Item -Path "$originalCursorFolderPath\alternatives\precision.cur" -Destination $editedCursorFolderPath -Force
}
Install-Cursors -Path $editedCursorFolderPath
Update-Cursor
#endregion Cursor

#region Parameters
Set-Content -Path $prefsPath -Value $cursorSize
Add-Content -Path $prefsPath -Value $useAlternatePrecision
#endregion Parameters

#region Listener
if ($installListener) {
	$Parameters = @{
		TaskName    = 'CCS Listener'
		Description = $Localization.ListenerTaskDescription
		Action      = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -NoExit -WindowStyle Hidden -File `"$PSScriptRoot\Listener.ps1`""
		Trigger     = New-ScheduledTaskTrigger -AtLogOn -User (whoami)
		Settings    = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit '00:00:00'
		RunLevel    = 'Highest'
		Force       = $true
	}
	Stop-ScheduledTask -TaskName $Parameters.TaskName -ErrorAction 'SilentlyContinue'
	Register-ScheduledTask @Parameters | Out-Null
	Start-Sleep -Seconds 1
	Start-ScheduledTask -TaskName $Parameters.TaskName
}
#endregion Listener

#region Final Messages
Write-Host
Write-Host -Object $Localization.SuccessMessage -ForegroundColor 'Green'
Write-Host
Write-Host -Object $Localization.GitHubReminderMessage
Write-Host
Remove-Module -Name 'Functions'
$Host.UI.RawUI.WindowTitle = $previousWindowTitle
Pause
exit
#endregion Final Messages
