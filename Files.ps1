# Disabling Firewall For All Profiles
& {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
}

# Installing CRD Host, Chrome And DirectX Via Chocolatey
$ErrorActionPreference = 'Stop'
 
[array]$key = Get-UninstallRegistryKey -SoftwareName "Chrome Remote Desktop Host"
$alreadyInstalled = $false
$version = '152.0.7977.9'

if ($key.Count -ne 0) {
  $key | ForEach-Object {
    if ($_.DisplayVersion -eq $version) {
      $alreadyInstalled = $true
    }
  }
}

$packageArgs = @{
  packageName            = 'chrome-remote-desktop-host'
  fileType               = 'msi'
  url                    = 'https://dl.google.com/dl/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi'
  checksum               = 'e059ef22e5dbddc5b5dc65fdd916ff8e682c106d48ff430f7498147a923783b1'
  checksumType           = 'sha256'
  silentArgs             = '/qn /norestart'
  validExitCodes         = @(0)
  softwareName           = 'Chrome Remote Desktop Host'
}

if ($alreadyInstalled) {
  Write-Host "Chrome Remote Desktop Host $version is already installed."
} else {
  Install-ChocolateyPackage @packageArgs
} -y
choco install directx -y
choco install googlechrome -y

# Navigating And Downloading Essentials To The Documents Directory
cd C:\Users\$Env:USERNAME\Documents
Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1Lnn5QFZRBBPn6VkzY_g1G1tX6v0DZft1&export=download&authuser=0&confirm=t&uuid=fdbceb6f-1b4d-49c1-9128-d38cf855055b&at=APZUnTVUm1AGqItiY6LCUoXfH13d%3A1716612457921" -Outfile Documents.zip
7z x Documents.zip -y

# Start Essential Applications
Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"
Start-Process "C:\Users\runneradmin\Documents\Documents\Telegram Desktop\Telegram.exe"
Start-Process "C:\Users\runneradmin\Documents\Documents\Adobe Media Encoder 2024 (Lofix)\Adobe 2024\Set-up.exe"
Start-Process "C:\Users\runneradmin\Documents\Documents\Adobe.After.Effects.2024.Multilingual\autoplay.exe"
Start-Process "C:\Users\runneradmin\Documents\Documents\BorisFX\BCC 2024\Boris FX Continuum 2024\Continuum_2024_Adobe_17_0_2_Windows.exe"
Start-Process "C:\Users\runneradmin\Documents\Documents\BorisFX\Sapphire 2024(lofix)\sapphire-ae-install-2024.01.exe"
Start-Process .

# Creating Shortcuts
New-Item -ItemType SymbolicLink -Target "C:\Users\$Env:USERNAME\Documents\Documents\Blender\blender-2.93.9-windows-x64\blender.exe" -Path "C:\Users\$Env:USERNAME\Desktop\Blender.lnk"
New-Item -ItemType SymbolicLink -Target "C:\Users\$Env:USERNAME\Documents\Documents\AssetStudioGUI\AssetStudioGUI.exe" -Path "C:\Users\$Env:USERNAME\Desktop\AssetStudioGUI.lnk"
