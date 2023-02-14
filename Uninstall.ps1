#Requires -RunAsAdministrator
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
[Console]::Title = 'CCS Uninstaller'
$ccsFolder = "$env:LocalAppData\CCS"

if ( -not (Test-Path -Path $ccsFolder) ) {
	Write-Host
	Write-Host 'CCS is not installed!' -ForegroundColor Red
	Write-Host
	Pause
	exit
}
	
Remove-Module -Name Functions -ErrorAction SilentlyContinue
Import-Module -Name $ccsFolder\Functions.ps1

Stop-ScheduledTask -TaskName 'CCS Listener' -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName 'CCS Listener' -Confirm:$false -ErrorAction SilentlyContinue

Restore-DefaultCursor
Apply-Changes

Remove-Module -Name Functions
Remove-Item -Path $ccsFolder -Recurse -Force | Out-Null