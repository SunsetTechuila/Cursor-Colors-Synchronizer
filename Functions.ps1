#Requires -RunAsAdministrator
#Requires -Version 5.1

# https://www.rapidtables.com/convert/color/rgb-to-hsv.html
# https://what-when-how.com/introduction-to-video-and-image-processing/conversion-between-rgb-and-hsv-introduction-to-video-and-image-processing/
function Convert-RGB-to-HSB {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateRange(0, 255)]
		[double]$Red,
	
		[Parameter(Mandatory)]
		[ValidateRange(0, 255)]
		[double]$Breen,
	
		[Parameter(Mandatory)]
		[ValidateRange(0, 255)]
		[double]$Blue
	)
	$red   = $red   / 255
	$green = $green / 255
	$blue  = $blue  / 255
	$max = ($red, $green, $blue | Measure -Maximum).Maximum
	$min = ($red, $green, $blue | Measure -Minimum).Minimum
	$delta = $max - $min
	$brightness = $max * 100
	if ($max -ne 0) {$saturation = ($delta / $max) * 100}
	else {$saturation = 0}
	if ($delta -eq 0) {$hue = 0}
	else {
		switch ($max) {
			{$red   -eq $_} { $hue = 60 * (     ($green - $blue ) / $delta ) }
			{$green -eq $_} { $hue = 60 * ( 2 + ($blue  - $red  ) / $delta ) }
			{$blue  -eq $_} { $hue = 60 * ( 4 + ($red   - $green) / $delta ) }
		}
	}
	return @{
		Hue        = $hue
		Saturation = $saturation
		Brightness = $brightness
	}
}

# https://www.rapidtables.com/convert/color/hsv-to-rgb.html
# https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB
function Convert-HSB-to-RGB {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateRange(0, 359)]
		[double]$Hue,
	
		[Parameter(Mandatory)]
		[ValidateRange(0, 100)]
		[double]$Saturation,
	
		[Parameter(Mandatory)]
		[ValidateRange(0, 100)]
		[double]$Brightness
	)
	$hue        = $hue        / 60
	$saturation = $saturation / 100
	$brightness = $brightness / 100
	$chroma = $saturation * $brightness
	$x = $chroma * ( 1 - [Math]::Abs($hue % 2 - 1) )
	$m = $brightness - $chroma
	# DO NOT ROUND HUE!
	switch ( [Math]::Floor($hue) ) {
		0 {$red = $chroma; $green = $x     ; $blue = 0}
		1 {$red = $x     ; $green = $chroma; $blue = 0}
		2 {$red = 0      ; $green = $chroma; $blue = $x}
		3 {$red = 0      ; $green = $x     ; $blue = $chroma}
		4 {$red = $x     ; $green = 0      ; $blue = $chroma}
		5 {$red = $chroma; $green = 0      ; $blue = $x}
	}
	$red   = ( ($red   + $m) * 255 )
	$green = ( ($green + $m) * 255 )
	$blue  = ( ($blue  + $m) * 255 )
	return @{
		Red   = $red
		Green = $green
		Blue  = $blue
	}
}

function Get-WindowsTheme {
	switch (Get-ItemPropertyValue -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme) {
		0 {return 'dark' }
		1 {return 'light'}
	}
}

function Get-WindowsAccentColor {
	[CmdletBinding()]
	# Get current accent color from the registry by channels ignoring alpha
	$b = ('{0:X}' -f (Get-ItemPropertyValue -Path HKCU:\Software\Microsoft\Windows\DWM -Name AccentColor))[2,3]
	$g = ('{0:X}' -f (Get-ItemPropertyValue -Path HKCU:\Software\Microsoft\Windows\DWM -Name AccentColor))[4,5]
	$r = ('{0:X}' -f (Get-ItemPropertyValue -Path HKCU:\Software\Microsoft\Windows\DWM -Name AccentColor))[6,7]
	# Combine lines into one string and convert to decimal
	$b = [int]('0x' + (-join ($b[0], $b[1])))
	$g = [int]('0x' + (-join ($g[0], $g[1])))
	$r = [int]('0x' + (-join ($r[0], $r[1])))
	return @{
		R = $r
		G = $g
		B = $b
	}
}

# For dev usage
# Compare two cursors which differ only in colors using Unix cmp tool, then use this funtion to get only addresses of the differing bytes
function Get-DiffAddresses {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[array]$Diff
	)
	$i = 0
	$diff | foreach {
		$diff[$i] = ($_.Trim() -split ' ')[0] - 1
		$i++
	}
	return $diff
}

function Validate-Input {
	param (
		[Parameter(Mandatory)]
		$Object,
		
		[Parameter(Mandatory)]
		[array]$Values
	)
	if ($object -in $values) {
		return $true
	}
	else {
		return $false
	}
}

function Patch-Cursor {
    [CmdletBinding()]
    param (
    	[Parameter(Mandatory)]
		[array]$Diff,
	
    	[Parameter(Mandatory)]
		[byte[]]$Cursor
    )
    $color = Get-WindowsAccentColor
    $counter = 0
    foreach ($byteAddress in $diff) {
        $counter++
        switch ($counter) {
            1 {$cursor[$byteAddress] = '0x{0:X}' -f $color.B}
            2 {$cursor[$byteAddress] = '0x{0:X}' -f $color.G}
            3 {$cursor[$byteAddress] = '0x{0:X}' -f $color.R; $counter = 0}
        }
    }
    return $cursor
}

function Create-PatchedCursorFiles {
	param (
		[Parameter(Mandatory)]
		[string]$CursorPath,
	
		[Parameter(Mandatory)]
		[string]$DiffPath,
	
		[boolean]$UseAlternateDiff
	)
	$cursor = [System.IO.File]::ReadAllBytes("$CursorPath\busy.ani")
	if ($useAlternateDiff) {
		$cursor = Patch-Cursor -Diff (Get-Content $DiffPath\busy_light) -Cursor $cursor
	}
	else {
		$cursor = Patch-Cursor -Diff (Get-Content $DiffPath\busy) -Cursor $cursor
	}
	[System.IO.File]::WriteAllBytes("$PSScriptRoot\Resources\Custom Cursor\busy.ani", $cursor)
	$cursor = [System.IO.File]::ReadAllBytes("$CursorPath\working.ani")
	$cursor = Patch-Cursor -Diff (Get-Content $DiffPath\working) -Cursor $cursor
	[System.IO.File]::WriteAllBytes("$PSScriptRoot\Resources\Custom Cursor\working.ani", $cursor)
}

function Install-Cursor {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Name,
	
		[Parameter(Mandatory)]
		[string]$Path
	)
	New-ItemProperty -Path 'HKCU:\Control Panel\Cursors' -Name $Name -PropertyType String -Value $Path -Force | Out-Null
}

function Install-CursorFromFolder {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Path
	)
	foreach ($cursor in Get-ChildItem -Path $Path) {
		switch ($cursor.Name) {
			{$_ -eq 'alternate.cur'  } {Install-Cursor -Name UpArrow     -Path $cursor.FullName}
			{$_ -eq 'beam.cur'       } {Install-Cursor -Name IBeam       -Path $cursor.FullName}
			{$_ -eq 'busy.ani'       } {Install-Cursor -Name Wait        -Path $cursor.FullName}
			{$_ -eq 'dgn1.cur'       } {Install-Cursor -Name SizeNWSE    -Path $cursor.FullName}
			{$_ -eq 'dgn2.cur'       } {Install-Cursor -Name SizeNESW    -Path $cursor.FullName}
			{$_ -eq 'handwriting.cur'} {Install-Cursor -Name NWPen       -Path $cursor.FullName}
			{$_ -eq 'help.cur'       } {Install-Cursor -Name Help        -Path $cursor.FullName}
			{$_ -eq 'horz.cur'       } {Install-Cursor -Name SizeWE      -Path $cursor.FullName}
			{$_ -eq 'link.cur'       } {Install-Cursor -Name Hand        -Path $cursor.FullName}
			{$_ -eq 'move.cur'       } {Install-Cursor -Name SizeAll     -Path $cursor.FullName}
			{$_ -eq 'person.cur'     } {Install-Cursor -Name Person      -Path $cursor.FullName}
			{$_ -eq 'pin.cur'        } {Install-Cursor -Name Pin         -Path $cursor.FullName}
			{$_ -eq 'pointer.cur'    } {Install-Cursor -Name Arrow       -Path $cursor.FullName}
			{$_ -eq 'precision.cur'  } {Install-Cursor -Name Crosshair   -Path $cursor.FullName}
			{$_ -eq 'unavailable.cur'} {Install-Cursor -Name No          -Path $cursor.FullName}
			{$_ -eq 'vert.cur'       } {Install-Cursor -Name SizeNS      -Path $cursor.FullName}
			{$_ -eq 'working.ani'    } {Install-Cursor -Name AppStarting -Path $cursor.FullName}
		}
	}
}

function Restore-DefaultCursor {
	Install-Cursor -Name AppStarting -Path %SystemRoot%\cursors\aero_working.ani
	Install-Cursor -Name Arrow       -Path %SystemRoot%\cursors\aero_arrow.cur
	Install-Cursor -Name Crosshair   -Path %SystemRoot%\cursors\aero_unavail.cur
	Install-Cursor -Name Hand        -Path %SystemRoot%\cursors\aero_link.cur
	Install-Cursor -Name Help        -Path %SystemRoot%\cursors\aero_helpsel.cur
	Install-Cursor -Name No          -Path %SystemRoot%\cursors\aero_unavail.cur
	Install-Cursor -Name NWPen       -Path %SystemRoot%\cursors\aero_pen.cur
	Install-Cursor -Name Person      -Path %SystemRoot%\cursors\aero_person.cur
	Install-Cursor -Name Pin         -Path %SystemRoot%\cursors\aero_pin.cur
	Install-Cursor -Name SizeAll     -Path %SystemRoot%\cursors\aero_move.cur
	Install-Cursor -Name SizeNESW    -Path %SystemRoot%\cursors\aero_nesw.cur
	Install-Cursor -Name SizeNS      -Path %SystemRoot%\cursors\aero_ns.cur
	Install-Cursor -Name SizeNWSE    -Path %SystemRoot%\cursors\aero_nwse.cur
	Install-Cursor -Name SizeWE      -Path %SystemRoot%\cursors\aero_ew.cur
	Install-Cursor -Name UpArrow     -Path %SystemRoot%\cursors\aero_up.cur
	Install-Cursor -Name Wait        -Path %SystemRoot%\cursors\aero_busy.ani
	New-ItemProperty -Path 'HKCU:\Control Panel\Cursors' -Name IBeam -PropertyType String -Value $null -Force | Out-Null
}

function Apply-Changes {
	# Define a C# class for calling WinAPI
	Add-Type -TypeDefinition @'
	public class SysParamsInfo {
		[System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
		public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
		public static void UpdateCursor() {
			SystemParametersInfo(0x0057, 0, 0, 0x01 | 0x02);
		}
	}
'@
[SysParamsInfo]::UpdateCursor()
}