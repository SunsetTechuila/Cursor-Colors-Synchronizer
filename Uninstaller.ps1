#region Preparation
$ErrorActionPreference = 'Stop'
$ccsFolder = "$env:LOCALAPPDATA\CCS"
#endregion Preparation

#region Stop Scheduled Task
Stop-ScheduledTask -TaskName 'CCS Listener' -ErrorAction 'SilentlyContinue'
Unregister-ScheduledTask -TaskName 'CCS Listener' -Confirm $false -ErrorAction 'SilentlyContinue'
#endregion Stop Scheduled Task

#region Check Installation
if (-not (Test-Path -Path $ccsFolder -PathType 'Container')) {
	Clear-Host
	Write-Warning -Message "Can't find CCS files!"
	Pause
	exit
}
#endregion Check Installation

#region Restore Cursor
Import-Module -Name "$ccsFolder\Functions.psm1" -Force

Reset-Cursor
Update-Cursor
#endregion Restore Cursor

#region Cleanup
Remove-Module -Name 'Functions' -Force
Remove-Item -Path $ccsFolder -Recurse -Force
#endregion Cleanup
