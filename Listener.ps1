#Requires -RunAsAdministrator
#Requires -Version 5.1

#region Preparation
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$functionsModule = "$root\Functions.psm1" 

Remove-Job -Name 'CursorThemeSync' -Force -ErrorAction 'SilentlyContinue'
Remove-Job -Name 'CursorColorSync' -Force -ErrorAction 'SilentlyContinue'
#endregion Preparation

#region Theme
$cursorThemeSync = {
	[CmdletBinding()]
	param()
	begin {
		$ErrorActionPreference = 'Stop'
		Import-Module -Name $using:functionsModule -Force
		Initialize-PathsProvider -Root $using:root
		Initialize-PrefsManager
		$themeSubKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
	}
	process {
		while (1) {
			$lastTheme = Get-SystemTheme
			Wait-ForRegistryKeyChange -Path $themeSubKey
			Start-Sleep -Seconds 1
			$currentTheme = Get-SystemTheme

			if ($lastTheme -ne $currentTheme) {
				Copy-Cursors
				Edit-Cursors
				Install-Cursors
			}
		}
	}
}
Start-Job -ScriptBlock $cursorThemeSync -Name 'CursorThemeSync'
#endregion Theme

#region Accent Color
$cursorColorSync = {
	[CmdletBinding()]
	param()
	begin {
		$ErrorActionPreference = 'Stop'
		Import-Module -Name $using:functionsModule -Force
		Initialize-PathsProvider -Root $using:root
		Initialize-PrefsManager
		$accentColorSubKey = 'HKCU:\Software\Microsoft\Windows\DWM'
	}
	process {
		while (1) {
			$lastAccentColor = Get-AccentColor
			Wait-ForRegistryKeyChange -Path $accentColorSubKey
			Start-Sleep -Seconds 1
			$currentAccentColor = Get-AccentColor
			
			if (($lastAccentColor | ConvertTo-Json) -ne ($currentAccentColor | ConvertTo-Json)) {
				Edit-Cursors
				Install-Cursors
			}
		}
	}
}
Start-Job -ScriptBlock $cursorColorSync -Name 'CursorColorSync'
#endregion Accent Color
