#Requires -RunAsAdministrator
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ccsFolder = "$env:LocalAppData\CCS"

if (Test-Path -Path $ccsFolder) {
	Remove-Item -Path $ccsFolder -Recurse -Force | Out-Null
}
New-Item -ItemType Directory -Path $ccsFolder | Out-Null

$uri = 'https://github.com/SunsetTechuila/Cursor-Colors-Synchronizer/releases/latest/download/Cursor-Colors-Synchronizer.zip'
Invoke-WebRequest -Uri $uri -OutFile $ccsFolder\Cursor-Colors-Synchronizer.zip
Expand-Archive -Path $ccsFolder\Cursor-Colors-Synchronizer.zip -DestinationPath $ccsFolder
Remove-Item -Path $ccsFolder\Cursor-Colors-Synchronizer.zip -Force

Start-Process -FilePath powershell -ArgumentList "-ExecutionPolicy Bypass -NoExit -File $ccsFolder\CCS.ps1"