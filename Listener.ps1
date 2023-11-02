#Requires -RunAsAdministrator
#Requires -Version 5.1

#region Preparation
$ErrorActionPreference = 'Stop'
Remove-Job -Name 'CursorThemeSync' -Force -ErrorAction 'SilentlyContinue'
Remove-Job -Name 'CursorColorSync' -Force -ErrorAction 'SilentlyContinue'
#endregion Preparation

#region Variables
$RootPath = $PSScriptRoot

$prefsPath = "$RootPath\prefs"
$resourcesFolderPath = "$RootPath\Resources"
$cursorsFolderPath = "$resourcesFolderPath\Cursors"
$editedCursorFolderPath = "$cursorsFolderPath\Edited"

$cursorSize = Get-Content -Path $prefsPath -First 1
$useAlternatePrecision = [System.Convert]::ToBoolean($(Get-Content -Path $prefsPath -Last 1))
$diffFolderPath = "$resourcesFolderPath\Diffs\$cursorSize"

$themeSubKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$accentColorSubKey = 'HKCU:\Software\Microsoft\Windows\DWM'
#endregion Variables

#region Theme
$cursorThemeSyncScriptBlock = {
	[CmdletBinding()]
	param()
	begin {
		$ErrorActionPreference = 'Stop'
		Import-Module -Name "$using:RootPath\Functions.psm1" -Force
	}
	process {
		while (1) {
			$lastTheme = Get-SystemTheme
			Wait-RegistryKeyChange -Path $using:themeSubKey
			$currentTheme = Get-SystemTheme

			if ($lastTheme -ne $currentTheme) {
				$originalCursorFolderPath = "$using:cursorsFolderPath\Original\$currentTheme\$using:cursorSize"

				Copy-Item -Path "$originalCursorFolderPath\default\*" -Destination $using:editedCursorFolderPath -Recurse -Force
				if ($using:useAlternatePrecision) {
					Copy-Item -Path "$originalCursorFolderPath\alternatives\precision.cur" -Destination $using:editedCursorFolderPath -Force
				}

				if (($currentTheme -eq 'light') -and ($using:cursorSize -eq 'big')) {
					Edit-Cursors -Path $using:editedCursorFolderPath -DiffFolderPath $using:diffFolderPath -UseAlternateDiff
				}
				else {
					Edit-Cursors -Path $using:editedCursorFolderPath -DiffFolderPath $using:diffFolderPath
				}

				Install-Cursors -Path $using:editedCursorFolderPath
				Update-Cursor
			}
		}
	}
}
Start-Job -ScriptBlock $cursorThemeSyncScriptBlock -Name 'CursorThemeSync' | Out-Null
#endregion Theme

#region Accent Color
$cursorColorSyncScriptBlock = {
	[CmdletBinding()]
	param()
	begin {
		$ErrorActionPreference = 'Stop'
		Import-Module -Name "$using:RootPath\Functions.psm1" -Force
		$currentTheme = Get-SystemTheme
	}
	process {
		while (1) {
			$lastAccentColor = Get-AccentColor
			Wait-RegistryKeyChange -Path $using:accentColorSubKey
			Start-Sleep -Seconds 1
			$currentAccentColor = Get-AccentColor
			
			if (($lastAccentColor | ConvertTo-Json) -ne ($currentAccentColor | ConvertTo-Json)) {
				if (($currentTheme -eq 'light') -and ($using:cursorSize -eq 'big')) {
					Edit-Cursors -Path $using:editedCursorFolderPath -DiffFolderPath $using:diffFolderPath -UseAlternateDiff
				}
				else {
					Edit-Cursors -Path $using:editedCursorFolderPath -DiffFolderPath $using:diffFolderPath
				}
				
				Install-Cursors -Path $using:editedCursorFolderPath
				Update-Cursor
			}
		}
	}
}
Start-Job -ScriptBlock $cursorColorSyncScriptBlock -Name 'CursorColorSync' | Out-Null
#endregion Accent Color
