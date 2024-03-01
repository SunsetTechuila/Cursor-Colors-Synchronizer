#region Preparation
$ErrorActionPreference = 'Stop'
$ccsFolder = "$env:LOCALAPPDATA\CCS"
$functionsModule = "$ccsFolder\Functions.psm1"
$listenerTask = 'CCS Listener'
#endregion Preparation

#region Scheduled Task
Stop-ScheduledTask -TaskName $listenerTask -ErrorAction 'SilentlyContinue'
Unregister-ScheduledTask -TaskName $listenerTask -Confirm $false -ErrorAction 'SilentlyContinue'
#endregion Scheduled Task

#region Check Installation
if (-not (Test-Path -Path $ccsFolder -PathType 'Container')) {
	Clear-Host
	Write-Warning -Message "Can't find CCS files!"
	Pause
	exit
}
#endregion Check Installation

#region Restore Cursor
Import-Module -Name $functionsModule -Force
Reset-Cursor
#endregion Restore Cursor

#region Cleanup
Remove-Module -Name 'Functions' -Force
Remove-Item -Path $ccsFolder -Recurse -Force
#endregion Cleanup
