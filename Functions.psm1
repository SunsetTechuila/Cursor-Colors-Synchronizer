#Requires -RunAsAdministrator
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# For dev usage
# Compare two cursors which differ only in colors using Unix cmp tool, save the output to a file, then use this function to get only the addresses of the differing bytes
function Get-DiffAddresses {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Path,

		[Parameter(Mandatory)]
		[string]$Destination
	)
	begin {
		$Parameters = @{
			Path  = $Destination
			Value = $null
			Force = $true
		}
		Set-Content @Parameters
	}
	process {
		Get-Content -Path $Path | ForEach-Object -Process {
			Add-Content -Path $Destination -Value (($PSItem.Trim() -split ' ')[0] - 1)
		}
	}
}

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
		$accentColorInHex = '{0:X}' -f ($accentColor)
		$b = $accentColorInHex.Substring(2, 2)
		$g = $accentColorInHex.Substring(4, 2)
		$r = $accentColorInHex.Substring(6, 2)
		$b = [int]("0x$b")
		$g = [int]("0x$g")
		$r = [int]("0x$r")
	}
	end {
		@{
			R = $r
			G = $g
			B = $b
		}
	}
}

function New-EditedCursor {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[array]$Diff,
	
		[Parameter(Mandatory)]
		[byte[]]$Cursor
	)
	begin {
		$targetColor = Get-AccentColor
		$targetColor.B = '0x{0:X}' -f $targetColor.B
		$targetColor.G = '0x{0:X}' -f $targetColor.G
		$targetColor.R = '0x{0:X}' -f $targetColor.R
		$i = 0
	}
	process {
		foreach ($address in $Diff) {
			$i++
			switch ($i) {
				1 {
					$Cursor[$address] = $targetColor.B
					break
				}
				2 {
					$Cursor[$address] = $targetColor.G
					break
				}
				3 {
					$Cursor[$address] = $targetColor.R
					$i = 0
				}
			}
		}
	}
	end {
		$Cursor
	}
}

function Edit-Cursors {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Path,

		[Parameter(Mandatory)]
		[string]$DiffFolderPath,
	
		[switch]$UseAlternateDiff
	)
	begin {
		$busyCursorFolderPath = "$Path\busy.ani"
		$workingCursorFolderPath = "$Path\working.ani"
	}
	process {
		$cursor = [System.IO.File]::ReadAllBytes($busyCursorFolderPath)
		if ($useAlternateDiff) {
			$cursor = New-EditedCursor -Diff (Get-Content -Path "$DiffFolderPath\busy_light") -Cursor $cursor
		}
		else {
			$cursor = New-EditedCursor -Diff (Get-Content -Path "$DiffFolderPath\busy") -Cursor $cursor
		}
		[System.IO.File]::WriteAllBytes($busyCursorFolderPath, $cursor)

		$cursor = [System.IO.File]::ReadAllBytes($workingCursorFolderPath)
		$cursor = New-EditedCursor -Diff (Get-Content -Path "$DiffFolderPath\working") -Cursor $cursor
		[System.IO.File]::WriteAllBytes($workingCursorFolderPath, $cursor)
	}
}

function Set-Cursor {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Name,
	
		[Parameter(Mandatory)]
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
	param (
		[Parameter(Mandatory)]
		[string]$Path
	)
	process {
		foreach ($cursor in (Get-ChildItem -Path $Path)) {
			$targetPath = $cursor.FullName
			switch -Exact ($cursor.Name) {
				'alternate.cur' {
					Set-Cursor -Name 'UpArrow' -Path $targetPath
					break
				}
				'beam.cur' {
					Set-Cursor -Name 'IBeam' -Path $targetPath
					break
				}
				'busy.ani' {
					Set-Cursor -Name 'Wait' -Path $targetPath
					break
				}
				'dgn1.cur' {
					Set-Cursor -Name 'SizeNWSE' -Path $targetPath
					break
				}
				'dgn2.cur' { 
					Set-Cursor -Name 'SizeNESW' -Path $targetPath
					break
				}
				'handwriting.cur' {
					Set-Cursor -Name 'NWPen' -Path $targetPath
					break
				}
				'help.cur' {
					Set-Cursor -Name 'Help' -Path $targetPath
					break
				}
				'horz.cur' {
					Set-Cursor -Name 'SizeWE' -Path $targetPath
					break
				}
				'link.cur' {
					Set-Cursor -Name 'Hand' -Path $targetPath
					break
				}
				'move.cur' {
					Set-Cursor -Name 'SizeAll' -Path $targetPath
					break
				}
				'person.cur' {
					Set-Cursor -Name 'Person' -Path $targetPath
					break
				}
				'pin.cur' {
					Set-Cursor -Name 'Pin' -Path $targetPath
					break
				}
				'pointer.cur' {
					Set-Cursor -Name 'Arrow' -Path $targetPath
					break
				}
				'precision.cur' {
					Set-Cursor -Name 'Crosshair' -Path $targetPath
					break
				}
				'unavailable.cur' {
					Set-Cursor -Name 'No' -Path $targetPath
					break
				}
				'vert.cur' {
					Set-Cursor -Name 'SizeNS' -Path $targetPath
					break
				}
				'working.ani' {
					Set-Cursor -Name 'AppStarting' -Path $targetPath
				}
			}
		}
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
		$defaultCursors | ForEach-Object -Process {
			Set-Cursor -Name $PSItem.Name -Path $PSItem.Path
		}
		$Parameters = @{
			Path         = 'HKCU:\Control Panel\Cursors'
			Name         = 'IBeam'
			PropertyType = 'String'
			Value        = $null
			Force        = $true
		}
		New-ItemProperty @Parameters | Out-Null
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

function Wait-RegistryKeyChange {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
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
		if (!(Test-Path -Path $Path)) { throw 'Registry key not found!' }

		switch -Wildcard ($Path) {
			'HKCR*' { $handle = 0x80000000 }
			'HKCU*' { $handle = 0x80000001 }
			'HKLM*' { $handle = 0x80000002 }
			'HKU*' { $handle = 0x80000003 }
			Default { throw 'Unsuported hive!' }
		}

		switch -Exact ($ChangeEvent) {
			'Name' { $notifyChange = $notifyChangeName }
			'Attributes' { $notifyChange = $notifyChangeAttributes }
			'LastSet' { $notifyChange = $notifyChangeLastSet }
			'Security' { $notifyChange = $notifyChangeSecurity }
			'All' { $notifyChange = $notifyChangeName -bor $notifyChangeAttributes -bor $notifyChangeLastSet -bor $notifyChangeSecurity }
		}

		$regEvent = [Regmon]::CreateEventW($null, $true, $false, $null)
		[Regmon]::RegOpenKeyExW($handle, ($Path -replace '^.*:\\'), 0, 0x0010, [ref]$handle) | Out-Null
		[Regmon]::RegNotifyChangeKeyValue($handle, $false, $notifyChange, $regEvent, $true) | Out-Null
		[Regmon]::WaitForSingleObject($regEvent, $infinite) | Out-Null
		[Regmon]::CloseHandle($regEvent) | Out-Null
		[Regmon]::RegCloseKey($handle) | Out-Null
	}
}
