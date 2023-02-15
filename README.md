# Cursor Colors Synchronizer

![CCS Banner](https://user-images.githubusercontent.com/115353812/218801534-51e90ae7-9867-488e-afc0-3002867662cb.png)

## Description
A tiny PowerShell tool which will synchronize your cursor accent color and theme with the Windows ones. Uses paid version of
[Windows 11 Cursors Concept v2 pack](https://www.deviantart.com/jepricreations/art/Windows-11-Cursors-Concept-v2-886489356).

#### Best match with:
- [Windows Auto Night Mode](https://github.com/AutoDarkMode/Windows-Auto-Night-Mode)
- [Light Switch](https://github.com/joakimmag/Light-Switch)
- Automatic accent color with:
  - [WinDynamicDesktop](https://github.com/t1m0thyj/WinDynamicDesktop)
  - [Bing Wallpaper](https://www.microsoft.com/en-us/bing/bing-wallpaper)
  - Windows spotlight
  - A slideshow

## How to

- ### Install
Run PowerShell as Administrator, paste this command and press Enter
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IWR -UseB 'https://raw.githubusercontent.com/SunsetTechuila/Cursor-Colors-Synchronizer/main/Install.ps1' | IEX
```

- ### Use
Just read the installer prompts and choose what you want.

- ### Uninstall
Run PowerShell as Administrator, paste this command and press Enter
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IWR -UseB 'https://raw.githubusercontent.com/SunsetTechuila/Cursor-Colors-Synchronizer/main/Uninstall.ps1' | IEX
```

## Requirements:
- Windows 7 or higher
- PowerShell 5.1 or higher
- Last Windows updates installed

## Credits
- [farag2](https://github.com/farag2) for a lot of help

- [Jepri Creations](https://jepricreations.com) for the cursors

## Legal
I don't have a licence or permission from author to use that pack in this way. You can buy it on [ko-fi](https://ko-fi.com/s/d9f85e6821) for personal use.

Due to illegal status of the repository I can't add a licence, but you can use my code for any purposes.
