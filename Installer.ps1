#region Preparation
$ErrorActionPreference = 'Stop'

$previousWindowTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = 'Cursor Colors Synchronizer Installer'
#endregion Preparation

#region Variables
$ccsFolder = "$env:LOCALAPPDATA\CCS"
$archivePath = "$env:TEMP\Cursor-Colors-Synchronizer.zip"
#endregion Variables

#region Cleanup
Remove-Item -Path $ccsFolder -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
Remove-Item -Path $archivePath -Force -ErrorAction 'SilentlyContinue' | Out-Null
#endregion Cleanup

#region Download
$Parameters = @{
	Uri             = 'https://github.com/SunsetTechuila/Cursor-Colors-Synchronizer/releases/latest/download/Cursor-Colors-Synchronizer.zip'
	OutFile         = $archivePath
	UseBasicParsing = $true
}
Invoke-WebRequest @Parameters
#endregion Download

#region Extraction
Expand-Archive -Path $archivePath -DestinationPath $env:LOCALAPPDATA -Force

Remove-Item -Path $archivePath -Force
#endregion Extraction

#region End
$Host.UI.RawUI.WindowTitle = $previousWindowTitle

Start-Process -FilePath 'powershell' -ArgumentList "-ExecutionPolicy Bypass -NoExit -File $ccsFolder\CCS.ps1"
#endregion End
