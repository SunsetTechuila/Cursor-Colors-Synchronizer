#Requires -RunAsAdministrator
#Requires -Version 5.1

#region Preparation
$ErrorActionPreference = 'Stop'
Remove-Module -Name Functions -ErrorAction SilentlyContinue
Clear-Variable -Name lastTheme, currentTheme, lastAccentColor, currentAccentColor, useClassicWheel, useAlternatePrecision, originalCursorFolder, customCursorFolder -ErrorAction SilentlyContinue
Import-Module -Name $PSScriptRoot\Functions.ps1
#endregion Preparation

#region Variables
$cursorSize            = Get-Content -Path $PSScriptRoot\Resources\Preferences -First 1
$useClassicWheel       = Get-Content -Path $PSScriptRoot\Resources\Preferences -First 2 | Select-Object -Skip 1
$useAlternatePrecision = Get-Content -Path $PSScriptRoot\Resources\Preferences -Last 1
$byteDiffFolder        = "$PSScriptRoot\Resources\Byte Diff\$cursorSize"
$customCursorFolder    = "$PSScriptRoot\Resources\Custom Cursor"
$lastTheme             = Get-WindowsTheme
$lastAccentColor       = Get-WindowsAccentColor
#endregion Variables

while (1) {
	#region Theme
	$currentTheme = Get-WindowsTheme
	if ($lastTheme -ne $currentTheme) {
		$originalCursorFolder = "$PSScriptRoot\Resources\Original Cursors\$currentTheme\$cursorSize"
		Copy-Item -Path $originalCursorFolder\default\* -Destination $customCursorFolder -Recurse -Force
		if ($useAlternatePrecision -eq $true) {
			Copy-Item -Path $originalCursorFolder\alternatives\precision.cur -Destination $customCursorFolder -Force
		}
		if ($useClassicWheel -eq $false) {
			if ( ($windowsTheme -eq 'light') -and ($cursorSize -eq 'big') ) {
				Create-PatchedCursorFiles -CursorPath $customCursorFolder -DiffPath $byteDiffFolder -UseAlternateDiff $true
			}
			else {
				Create-PatchedCursorFiles -CursorPath $customCursorFolder -DiffPath $byteDiffFolder
			}
		}
		else {
			Copy-Item -Path $originalCursorFolder\alternatives\busy.ani -Destination $customCursorFolder -Force
			Copy-Item -Path $originalCursorFolder\alternatives\working.ani -Destination $customCursorFolder -Force
		}
		Install-CursorFromFolder -Path $customCursorFolder
		Apply-Changes
		$lastTheme = $currentTheme
	}
	#endregion Theme
	
	#region Accent Color
	$currentAccentColor = Get-WindowsAccentColor
	if ( ($lastAccentColor.R -ne $currentAccentColor.R) -or ($lastAccentColor.G -ne $currentAccentColor.G) -or ($lastAccentColor.B -ne $currentAccentColor.B) ) {
		if ($useClassicWheel -eq $false) {
			if ( ($windowsTheme -eq 'light') -and ($cursorSize -eq 'big') ) {
				Create-PatchedCursorFiles -CursorPath $customCursorFolder -DiffPath $byteDiffFolder -UseAlternateDiff $true
			}
			else {
				Create-PatchedCursorFiles $customCursorFolder $byteDiffFolder
			}
			Install-CursorFromFolder -Path $customCursorFolder
			Apply-Changes
		}
		$lastAccentColor = $currentAccentColor
	}
	#endregion Accent Color
	
	Start-Sleep -Seconds 1
}