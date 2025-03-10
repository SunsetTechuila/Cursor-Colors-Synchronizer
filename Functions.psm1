#Requires -RunAsAdministrator
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

#region Utils
function Test-File {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]$Path
	)
	process {
		[bool](Test-Path -Path $Path -PathType 'Leaf' -ErrorAction 'SilentlyContinue')
	}
}

function Test-Folder {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]$Path
	)
	process {
		[bool](Test-Path -Path $Path -PathType 'Container' -ErrorAction 'SilentlyContinue')
	}
}

function ConvertFrom-CmdPath {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]$Path
	)
	process {
		$absolutePath = $Path
		$variables = [regex]::Matches($Path, '%([^%]+)%') | ForEach-Object -Process { $PSItem.Groups[1].Value }

		foreach ($variable in $variables) {
			$absolutePath = $absolutePath.Replace("%$variable%", [System.Environment]::GetEnvironmentVariable($variable))
		}

		$absolutePath
	}
}

# Compare two cursors which differ only in colors using Unix cmp tool, save the output to a file, then use this function to get only the addresses of the differing bytes
function Get-DiffAddresses {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Diff,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$OutFile
	)
	begin {
		$Parameters = @{
			Path  = $OutFile
			Force = $true
		}
	}
	process {
		$diffContent = Get-Content -Path $Diff

		$Parameters.Value = foreach ($line in $diffContent) {
			($line.Trim() -split ' ')[0] - 1
		}
		
		Set-Content @Parameters
	}
}
#endregion Utils

#region Paths
function Initialize-PathsProvider {
	[CmdletBinding()]
	[OutputType([PathsProvider])]
	param(
		[ValidateScript({ Test-Folder -Path $PSItem })]
		[string]$Root = $PSScriptRoot
	)
	process {
		[PathsProvider]::new($Root)
	}
}

class PathsProvider {
	static        [string] $Listener
	static        [string] $Prefs
	static Hidden [string] $RecourcesFolder
	static        [string] $LocalizationsFolder
	static Hidden [string] $CursorsFolder
	static        [string] $EditedCursorsFolder
	static Hidden [string] $OriginalCursorsRootFolder
	static Hidden [string] $DiffsRootFolder
	static        [string] $BinFolder
	static        [string] $RunHidden

	PathsProvider([string]$Root) {
		if (-not (Test-Folder -Path $Root)) {
			throw "Root folder doesn't exist: $Root"
		}
		
		[PathsProvider]::Listener = "$Root\Listener.ps1"
		[PathsProvider]::Prefs = "$Root\prefs.ini"
		[PathsProvider]::RecourcesFolder = "$Root\Resources"
		[PathsProvider]::LocalizationsFolder = "$([PathsProvider]::RecourcesFolder)\Localizations"
		[PathsProvider]::CursorsFolder = "$([PathsProvider]::RecourcesFolder)\Cursors"
		[PathsProvider]::EditedCursorsFolder = "$([PathsProvider]::CursorsFolder)\Edited"
		[PathsProvider]::OriginalCursorsRootFolder = "$([PathsProvider]::CursorsFolder)\Original"
		[PathsProvider]::DiffsRootFolder = "$([PathsProvider]::RecourcesFolder)\Diffs"
		[PathsProvider]::BinFolder = "$([PathsProvider]::RecourcesFolder)\Bin"
		[PathsProvider]::RunHidden = "$([PathsProvider]::BinFolder)\run-hidden.exe"
	}

	static [hashtable] GetDynamicPaths() {
		$useTailVersion = [PrefsManager]::UseTailVersion
		$cursorSize = [PrefsManager]::CursorSize
		$cursorTheme = Get-CursorTheme

		return @{
			OriginalCursorsFolder = if ($useTailVersion) {
				"$([PathsProvider]::OriginalCursorsRootFolder)\$cursorTheme\tail"
			}
			else {
				"$([PathsProvider]::OriginalCursorsRootFolder)\$cursorTheme\default\$cursorSize"
			}

			DiffsFolder           = if ($useTailVersion) {
				"$([PathsProvider]::DiffsRootFolder)\tail"
			}
			else {
				"$([PathsProvider]::DiffsRootFolder)\default\$cursorSize"
			}
		}
	}
}
#endregion Paths

# region Preferences
function Initialize-PrefsManager {
	[CmdletBinding()]
	[OutputType([PrefsManager])]
	param()
	process {
		[PrefsManager]::new()
	}
}

class PrefsManager {
	static [bool]   $UseTailVersion = $false
	static [string] $CursorSize = 'small'
	static [bool]   $UseAlternatePrecision = $false
	static [string] $CursorTheme = 'system'

	static PrefsManager() {
		$prefs = [PrefsManager]::Read()

		foreach ($pref in $prefs.GetEnumerator()) {
			$property = [PrefsManager].GetProperty($pref.Name)
			if ($property) {
				$property.SetValue([PrefsManager], $pref.Value)
			}
		}
	}

	Hidden static [hashtable] Read() {
		$prefs = Get-Content -Path ([PathsProvider]::Prefs) -ErrorAction 'SilentlyContinue'
		$formattedPrefs = @{}

		foreach ($pref in $prefs) {
			$key, $value = $pref.Trim() -split '='
			if ($key -match '^use|is') {
				$value = [System.Convert]::ToBoolean($value)
			}
			$formattedPrefs.Add($key, $value)
		}

		return $formattedPrefs
	}

	static [void] Save() {
		$Parameters = @{
			Path  = [PathsProvider]::Prefs
			Value = $null
			Force = $true
		}

		Set-Content @Parameters

		$prefs = [PrefsManager].GetProperties()
		foreach ($pref in $prefs) {
			$Parameters.Value = "$($pref.Name)=$($pref.GetValue([PrefsManager]))"
			Add-Content @Parameters
		}
	}
}
#endregion Preferences

#region Console
function Read-Choice {
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[string]$Title = '',

		[ValidateNotNullOrEmpty()]
		[string]$Message = '',

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.Collections.Specialized.OrderedDictionary]$Variants,

		[ValidateNotNullOrEmpty()]
		$Default = ([array]$Variants.Keys)[0]
	)
	begin {
		$variantKeys = [array]$Variants.Keys
		$variantValues = [array]$Variants.Values
	}
	process {
		$formattedVariants = for ($i = 0; $i -lt $Variants.Count; $i++) {
			"&$($i + 1) $($variantValues[$i])"
		}

		$Host.UI.RawUI.Flushinputbuffer()
		$choice = $Host.UI.PromptForChoice(
			$Title,
			$Message,
			$formattedVariants,
			$variantKeys.IndexOf($Default)
		)
	}
	end {
		$variantKeys[$choice]
	}
}
#endregion Console

#region System
function Get-SystemTheme {
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	begin {
		$Parameters = @{
			Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
			Name = 'SystemUsesLightTheme'
		}
	}
	process {
		switch (Get-ItemPropertyValue @Parameters) {
			0 { 'dark' }
			1 { 'light' }
		}
	}
}

function Get-AccentColor {
	[CmdletBinding()]
	[OutputType([hashtable])]
	param ()
	begin {
		$Parameters = @{
			Path = 'HKCU:\Software\Microsoft\Windows\DWM'
			Name = 'AccentColor'
		}
	}
	process {
		$accentColor = Get-ItemPropertyValue @Parameters
		$accentColorInHex = '{0:X}' -f $accentColor
		$r = "0x$($accentColorInHex.Substring(6, 2))"
		$g = "0x$($accentColorInHex.Substring(4, 2))"
		$b = "0x$($accentColorInHex.Substring(2, 2))"
	}
	end {
		[ordered]@{
			R = $r
			G = $g
			B = $b
		}
	}
}

function Wait-ForRegistryKeyChange {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateScript({ Test-Folder -Path $PSItem })]
		[string]$Path,

		[ValidateSet('Name', 'Attributes', 'LastSet', 'Security', 'All')]
		[string]$ChangeEvent = 'All'
	)
	begin {
		$infinite = 0xFFFFFFF
		$handle = [IntPtr]::Zero
		$notifyChangeName = 0x00000001L
		$notifyChangeAttributes = 0x00000002L
		$notifyChangeLastSet = 0x00000004L
		$notifyChangeSecurity = 0x00000008L

		Add-Type -TypeDefinition @'
			using System;
			using System.Runtime.InteropServices;

			public class Regmon {
				[DllImport("advapi32.dll", CharSet = CharSet.Unicode)]
				public static extern int RegOpenKeyExW(
					int hKey,
					string lpSubKey,
					int ulOptions,
					uint samDesired,
					out IntPtr phkResult
				);

				[DllImport("advapi32.dll", CharSet = CharSet.Unicode)]
				public static extern int RegNotifyChangeKeyValue(
					IntPtr hKey,
					bool bWatchSubtree,
					int dwNotifyFilter,
					IntPtr hEvent,
					bool fAsynchronous
				);

				[DllImport("advapi32.dll", CharSet = CharSet.Unicode)]
				public static extern int RegCloseKey(
					IntPtr hKey
				);
		
				[DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
				public static extern int CloseHandle(
					IntPtr hKey
				);
		
				[DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
				public static extern IntPtr CreateEventW(
					int lpEventAttributes,
					bool bManualReset,
					bool bInitialState,
					string lpName
				);
		
				[DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
				public static extern int WaitForSingleObject(
					IntPtr hHandle,
					int dwMilliseconds
				);
			}
'@
	}
	process {
		switch -Regex ($Path) {
			'^HKCR' {
				$handle = 0x80000000
				break
			}
			'^HKCU' {
				$handle = 0x80000001
				break
			}
			'^HKLM' {
				$handle = 0x80000002
				break
			}
			'^HKU' {
				$handle = 0x80000003
				break
			}
			Default {
				throw 'Unsuported hive!'
			}
		}

		switch -Exact ($ChangeEvent) {
			'Name' {
				$notifyChange = $notifyChangeName
				break
			}
			'Attributes' {
				$notifyChange = $notifyChangeAttributes
				break
			}
			'LastSet' {
				$notifyChange = $notifyChangeLastSet
				break
			}
			'Security' {
				$notifyChange = $notifyChangeSecurity
				break
			}
			'All' {
				$notifyChange = $notifyChangeName -bor $notifyChangeAttributes -bor $notifyChangeLastSet -bor $notifyChangeSecurity
				break
			}
			Default {
				throw 'Unsuported change event!'
			}
		}

		$regEvent = [Regmon]::CreateEventW($null, $true, $false, $null)
		[Regmon]::RegOpenKeyExW($handle, ($Path -replace '^.*:\\'), 0, 0x0010, [ref]$handle) | Out-Null
		[Regmon]::RegNotifyChangeKeyValue($handle, $false, $notifyChange, $regEvent, $true) | Out-Null
		[Regmon]::WaitForSingleObject($regEvent, $infinite) | Out-Null
		[Regmon]::CloseHandle($regEvent) | Out-Null
		[Regmon]::RegCloseKey($handle) | Out-Null
	}
}
#endregion System

#region Cursors
function Get-CursorTheme {
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	process {
		if ([PrefsManager]::CursorTheme -eq 'system') {
			Get-SystemTheme
		}
		else {
			[PrefsManager]::CursorTheme
		}
	}
}

function Copy-Cursors {
	[CmdletBinding()]
	param ()
	begin {
		$editedCursorsFolder = [PathsProvider]::EditedCursorsFolder
		$alternatePrecision = "$editedCursorsFolder\precision_alt.cur"
		$defaultPrecision = "$editedCursorsFolder\precision.cur"
		$originalCursorsFolder = [PathsProvider]::GetDynamicPaths().OriginalCursorsFolder
	}
	process {
		if (-not (Test-Folder -Path $editedCursorsFolder)) {
			$Parameters = @{
				Path     = $editedCursorsFolder
				ItemType = 'Directory'
				Force    = $true
			}
			New-Item @Parameters | Out-Null
		}

		$Parameters = @{
			Path        = "$originalCursorsFolder\*"
			Destination = $editedCursorsFolder
			Force       = $true
		}
		Copy-Item @Parameters

		if ([PrefsManager]::UseTailVersion) { return }

		if ([PrefsManager]::UseAlternatePrecision) {
			$Parameters = @{
				Path  = $defaultPrecision
				Force = $true
			}
			Remove-Item @Parameters

			$Parameters = @{
				Path    = $alternatePrecision
				NewName = $defaultPrecision | Split-Path -Leaf
				Force   = $true
			}
			Rename-Item @Parameters
		}
		else {
			$Parameters = @{
				Path  = $alternatePrecision
				Force = $true
			}
			Remove-Item @Parameters
		}
	}
}

function Edit-Cursor {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateScript({ Test-File -Path $PSItem })]
		[Alias('Cursor')]
		[string]$CursorPath,

		[Parameter(Mandatory)]
		[ValidateScript({ Test-File -Path $PSItem })]
		[string]$Diff
	)
	begin {
		$addresses = [System.IO.File]::ReadAllLines($Diff)
		$cursor = [System.IO.File]::ReadAllBytes($CursorPath)
		$targetColor = Get-AccentColor
	}
	process {
		$i = 0
		foreach ($address in $addresses) {
			$i++
			switch ($i) {
				1 {
					$cursor[$address] = $targetColor.B
					break
				}
				2 {
					$cursor[$address] = $targetColor.G
					break
				}
				3 {
					$cursor[$address] = $targetColor.R
					$i = 0
				}
			}
		}
	}
	end {
		[System.IO.File]::WriteAllBytes($CursorPath, $cursor)
	}
}

function Edit-Cursors {
	[CmdletBinding()]
	param ()
	begin {
		$diffsFolder = [PathsProvider]::GetDynamicPaths().DiffsFolder
		$cursorsFolder = [PathsProvider]::EditedCursorsFolder

		$cursorTheme = Get-CursorTheme
		$cursorSize = [PrefsManager]::CursorSize
		$useTailVersion = [PrefsManager]::UseTailVersion
	}
	process {
		$busyCursor = "$cursorsFolder\busy.ani"
		$shouldUseAlternateBusyDiff = (-not($useTailVersion) -and $cursorSize -eq 'big') -and ($cursorTheme -eq 'light')
		$busyCursorDiff = if ($shouldUseAlternateBusyDiff) { "$diffsFolder\busy_alt" } else { "$diffsFolder\busy" }

		$workingCursor = "$cursorsFolder\working.ani"
		$workingCursorDiff = "$diffsFolder\working"

		Edit-Cursor -Cursor $busyCursor -Diff $busyCursorDiff
		Edit-Cursor -Cursor $workingCursor -Diff $workingCursorDiff
	}
}

function Set-Cursor {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
	
		[Parameter(Mandatory)]
		[ValidateScript({ $PSItem | ConvertFrom-CmdPath | Test-File })]
		[string]$Path
	)
	begin {
		$Parameters = @{
			Path         = 'HKCU:\Control Panel\Cursors'
			Name         = $Name
			PropertyType = 'String'
			Value        = $Path
			Force        = $true
		}
	}
	process {
		New-ItemProperty @Parameters | Out-Null
	}
}

function Install-Cursors {
	[CmdletBinding()]
	param ()
	begin {
		$knownCursors = @{
			'alternate.cur'   = 'UpArrow'
			'beam.cur'        = 'IBeam'
			'busy.ani'        = 'Wait'
			'dgn1.cur'        = 'SizeNWSE'
			'dgn2.cur'        = 'SizeNESW'
			'handwriting.cur' = 'NWPen'
			'help.cur'        = 'Help'
			'horz.cur'        = 'SizeWE'
			'link.cur'        = 'Hand'
			'move.cur'        = 'SizeAll'
			'person.cur'      = 'Person'
			'pin.cur'         = 'Pin'
			'pointer.cur'     = 'Arrow'
			'precision.cur'   = 'Crosshair'
			'unavailable.cur' = 'No'
			'vert.cur'        = 'SizeNS'
			'working.ani'     = 'AppStarting'
		}
	}
	process {
		$cursors = Get-ChildItem -Path ([PathsProvider]::EditedCursorsFolder)

		foreach ($cursor in $cursors) {
			$Parameters = @{
				Name = $knownCursors[$cursor.Name]
				Path = $cursor.FullName
			}
			if (!$Parameters.Name) {
				Write-Warning "Unsuported cursor name: $($cursor.Name)! Skipping..."
				continue
			}
			Set-Cursor @Parameters
		}

		Update-Cursor
	}
}

function Reset-Cursor {
	[CmdletBinding()]
	param ()
	begin {
		$defaultCursors = @(
			@{
				Name = 'AppStarting'
				Path = '%SystemRoot%\cursors\aero_working.ani'
			},
			@{
				Name = 'Arrow'
				Path = '%SystemRoot%\cursors\aero_arrow.cur'
			},
			@{
				Name = 'Crosshair'
				Path = '%SystemRoot%\cursors\aero_unavail.cur'
			},
			@{
				Name = 'Hand'
				Path = '%SystemRoot%\cursors\aero_link.cur'
			},
			@{
				Name = 'Help'
				Path = '%SystemRoot%\cursors\aero_helpsel.cur'
			},
			@{
				Name = 'No'
				Path = '%SystemRoot%\cursors\aero_unavail.cur'
			},
			@{
				Name = 'NWPen'
				Path = '%SystemRoot%\cursors\aero_pen.cur'
			},
			@{
				Name = 'Person'
				Path = '%SystemRoot%\cursors\aero_person.cur'
			},
			@{
				Name = 'Pin'
				Path = '%SystemRoot%\cursors\aero_pin.cur'
			},
			@{
				Name = 'SizeAll'
				Path = '%SystemRoot%\cursors\aero_move.cur'
			},
			@{
				Name = 'SizeNESW'
				Path = '%SystemRoot%\cursors\aero_nesw.cur'
			},
			@{
				Name = 'SizeNS'
				Path = '%SystemRoot%\cursors\aero_ns.cur'
			},
			@{
				Name = 'SizeNWSE'
				Path = '%SystemRoot%\cursors\aero_nwse.cur'
			},
			@{
				Name = 'SizeWE'
				Path = '%SystemRoot%\cursors\aero_ew.cur'
			},
			@{
				Name = 'UpArrow'
				Path = '%SystemRoot%\cursors\aero_up.cur'
			},
			@{
				Name = 'Wait'
				Path = '%SystemRoot%\cursors\aero_busy.ani'
			}
		)
	}
	process {
		foreach ($cursor in $defaultCursors) {
			Set-Cursor -Name $cursor.Name -Path $cursor.Path
		}

		$Parameters = @{
			Path         = 'HKCU:\Control Panel\Cursors'
			Name         = 'IBeam'
			PropertyType = 'String'
			Value        = $null
			Force        = $true
		}
		New-ItemProperty @Parameters | Out-Null

		Update-Cursor
	}
}

function Update-Cursor {
	[CmdletBinding()]
	param ()
	begin {
		Add-Type -TypeDefinition @'
			using System;
			using System.Runtime.InteropServices;

			public class Cursor {
				[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
				public static extern bool SystemParametersInfo(
					uint uiAction,
					uint uiParam,
					uint pvParam,
					uint fWinIni
				);

				public static void Update() {
					SystemParametersInfo(0x0057, 0, 0, 0x01 | 0x02);
				}
			}
'@
	}
	process {
		[Cursor]::Update()
	}
}
#endregion Cursors
