#Requires -RunAsAdministrator
#Requires -Version 5.1

#region Preparation
$ErrorActionPreference = 'Stop'

$previousWindowTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = 'Cursor Colors Synchronizer'

Import-Module -Name "$PSScriptRoot\Functions.psm1" -Force
$PathsProvider = Initialize-PathsProvider
$PrefsManager = Initialize-PrefsManager

$Parameters = @{
	BindingVariable = 'Localization'
	BaseDirectory   = $PathsProvider::LocalizationsFolder
	FileName        = 'Strings'
}
Import-LocalizedData @Parameters
#endregion Preparation

#region Preferences
Clear-Host

$Parameters = @{
	Message  = $Localization.TailVersionDialogTitle
	Variants = [ordered]@{
		$true  = $Localization.Yes
		$false = $Localization.No
	}
	Default  = $false
}
$PrefsManager::UseTailVersion = Read-Choice @Parameters

if (-not ($PrefsManager::UseTailVersion)) {
	$Parameters = @{
		Message  = $Localization.ChooseSizeDialogTitle
		Variants = [ordered]@{
			small   = $Localization.Small
			regular = $Localization.Regular
			big     = $Localization.Big
		}
	}
	$PrefsManager::CursorSize = Read-Choice @Parameters

	$Parameters = @{
		Message  = $Localization.ChoosePrecisionDialogTitle
		Variants = [ordered]@{
			$true  = $Localization.Yes
			$false = $Localization.No
		}
		Default  = $false
	}
	$PrefsManager::UseAlternatePrecision = Read-Choice @Parameters
}

$Parameters = @{
	Message  = $Localization.ListenerDialogTitle
	Variants = [ordered]@{
		$true  = $Localization.Yes
		$false = $Localization.No
	}
}
$installListener = Read-Choice @Parameters

$PrefsManager::Save()
#endregion Preferences

#region Cursor
Copy-Cursors
Edit-Cursors
Install-Cursors
#endregion Cursor

#region Listener
if ($installListener) {
	$Parameters = @{
		TaskName    = 'CCS Listener'
		Description = $Localization.ListenerTaskDescription
		Action      = New-ScheduledTaskAction -Execute $PathsProvider::RunHidden -Argument "powershell -ExecutionPolicy Bypass -NoExit -File `"$($PathsProvider::Listener)`""
		Trigger     = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
		Settings    = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit '00:00:00'
		RunLevel    = 'Highest'
		Force       = $true
	}
	Stop-ScheduledTask -TaskName $Parameters.TaskName -ErrorAction 'SilentlyContinue'
	Register-ScheduledTask @Parameters | Out-Null
	Start-Sleep -Seconds 1
	Start-ScheduledTask -TaskName $Parameters.TaskName
}
#endregion Listener

#region Final Messages
Write-Host
Write-Host -Object $Localization.SuccessMessage -ForegroundColor 'Green'
Write-Host
Write-Host -Object $Localization.GitHubReminderMessage
Write-Host
Remove-Module -Name 'Functions'
$Host.UI.RawUI.WindowTitle = $previousWindowTitle
Pause
exit
#endregion Final Messages
