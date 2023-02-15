#Requires -RunAsAdministrator
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (Test-Path -Path $env:LocalAppData\CCS) {
	Remove-Item -Path $env:LocalAppData\CCS -Recurse -Force | Out-Null
}

$uri = 'https://github.com/SunsetTechuila/Cursor-Colors-Synchronizer/releases/latest/download/Cursor-Colors-Synchronizer.zip'
Invoke-WebRequest -Uri $uri -OutFile $env:LocalAppData\Cursor-Colors-Synchronizer.zip
Expand-Archive -Path $env:LocalAppData\Cursor-Colors-Synchronizer.zip -DestinationPath $env:LocalAppData
Remove-Item -Path $env:LocalAppData\Cursor-Colors-Synchronizer.zip -Force

Start-Process -FilePath powershell -ArgumentList "-ExecutionPolicy Bypass -NoExit -File $env:LocalAppData\CCS\CCS.ps1"