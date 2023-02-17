#Requires -RunAsAdministrator
#Requires -Version 5.1

#region Preparation
$ErrorActionPreference = 'Stop'
[Console]::Title = 'Cursor Colors Synchronizer'
Remove-Module -Name Functions -ErrorAction SilentlyContinue
Clear-Variable -Name Localization, windowsTheme, cursorSize, useClassicWheel, useAlternatePrecision, originalCursorFolder, customCursorFolder, byteDiffFolder, useListener, choice -ErrorAction SilentlyContinue
Import-LocalizedData -BindingVariable Localization -BaseDirectory $PSScriptRoot\Localizations -FileName Strings
Import-Module -Name $PSScriptRoot\Functions.ps1
#endregion Preparation

#region Dialogs
do {
	Clear-Host
	Write-Host
	Write-Host -Object $Localization.ChooseSizeDialogTitle
	Write-Host
	Write-Host -Object ('1) ' + $Localization.Small)
	Write-Host -Object ('2) ' + $Localization.Regular)
	Write-Host -Object ('3) ' + $Localization.Big)
	Write-Host
	$choice = Read-Host -Prompt $Localization.ChooseDialogPromt
} until ( Validate-choice -Object $choice -Values (1..3) )
switch ($choice) {
	1 {$cursorSize = 'small'}
	2 {$cursorSize = 'regular'}
	3 {$cursorSize = 'big'}
}

do {
	Clear-Host
	Write-Host
	Write-Host -Object $Localization.ChooseWheelDialogTitle
	Write-Host
	Write-Host -Object ('1) ' + $Localization.No)
	Write-Host -Object ('2) ' + $Localization.Yes)
	Write-Host
	$choice = Read-Host -Prompt $Localization.ChooseDialogPromt
} until ( Validate-choice -Object $choice -Values (1..2) )
switch ($choice) {
	1 {$useClassicWheel = $false}
	2 {$useClassicWheel = $true}
}

do {
	Clear-Host
	Write-Host
	Write-Host -Object $Localization.ChoosePrecisionDialogTitle
	Write-Host
	Write-Host -Object ('1) ' + $Localization.Yes)
	Write-Host -Object ('2) ' + $Localization.No)
	Write-Host
	$choice = Read-Host -Prompt $Localization.ChooseDialogPromt
} until ( Validate-choice -Object $choice -Values (1..2) )
switch ($choice) {
	1 {$useAlternatePrecision = $true}
	2 {$useAlternatePrecision = $false}
}

do {
	Clear-Host
	Write-Host
	Write-Host -Object $Localization.ListenerDialogTitle
	Write-Host
	Write-Host -Object ('1) ' + $Localization.Yes)
	Write-Host -Object ('2) ' + $Localization.No)
	Write-Host
	$choice = Read-Host -Prompt $Localization.ChooseDialogPromt
} until ( Validate-choice -Object $choice -Values (1..2) )
switch ($choice) {
	1 {$useListener = $true}
	2 {$useListener = $false}
}
#endregion Dialogs


#region Variables
$windowsTheme = Get-WindowsTheme
$originalCursorFolder = "$PSScriptRoot\Resources\Original Cursors\$windowsTheme\$cursorSize"
$byteDiffFolder       = "$PSScriptRoot\Resources\Byte Diff\$cursorSize"
$customCursorFolder   = "$PSScriptRoot\Resources\Custom Cursor"
#endregion Variables

#region Cursor
Copy-Item -Path $originalCursorFolder\default\* -Destination $customCursorFolder -Recurse -Force
if ($useClassicWheel -eq $false) {
	if ( ($windowsTheme -eq 'light') -and ($cursorSize -eq 'big') ) {
		Create-PatchedCursorFiles -CursorPath $originalCursorFolder\default -DiffPath $byteDiffFolder -UseAlternateDiff $true
	}
	else {
		Create-PatchedCursorFiles -CursorPath $originalCursorFolder\default -DiffPath $byteDiffFolder
	}
}
else {
	Copy-Item -Path $originalCursorFolder\alternatives\busy.ani -Destination $customCursorFolder -Force
	Copy-Item -Path $originalCursorFolder\alternatives\working.ani -Destination $customCursorFolder -Force
}
if ($useAlternatePrecision) {
	Copy-Item -Path $originalCursorFolder\alternatives\precision.cur -Destination $customCursorFolder -Force
}
Install-CursorFromFolder -Path $customCursorFolder
Apply-Changes
#endregion Cursor

#region Parameters
Set-Content -Path $PSScriptRoot\Resources\Preferences -Value $cursorSize
Add-Content -Path $PSScriptRoot\Resources\Preferences -Value $useClassicWheel
Add-Content -Path $PSScriptRoot\Resources\Preferences -Value $useAlternatePrecision
#endregion Parameters

#region Listener
if ($useListener) {
	$name        = 'CCS Listener'
	$action      = New-ScheduledTaskAction -Execute powershell.exe -Argument ("-ExecutionPolicy Bypass -WindowStyle Hidden -File $PSScriptRoot\Listener.ps1")
	$user        = whoami
	$trigger     = New-ScheduledTaskTrigger -AtLogOn -User $user
	$description = $Localization.ListenerTaskDescription
	$settings    = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit '00:00:00'
	Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
	Register-ScheduledTask -TaskName $name -Description $description -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null
	Start-Sleep -Seconds 1
	Start-ScheduledTask -TaskName $name
}
#endregion Listener

#region Final Messages
Clear-Host
Write-Host
Write-Host -Object $Localization.SuccessMessage -ForegroundColor Green
Write-Host
Write-Host -Object $Localization.GitHubReminderMessage
Write-Host
Pause
exit
#endregion Final Messages