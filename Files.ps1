# ==========================================================
# Windows GitHub Actions - Essential Files Setup
# ==========================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ----------------------------------------------------------
# Disabling Firewall For All Profiles
# ----------------------------------------------------------

Write-Host "Disabling Windows Firewall..."

try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Write-Host "[OK] Firewall profiles updated."
}
catch {
    Write-Warning "Could not change firewall settings: $($_.Exception.Message)"
}

# ----------------------------------------------------------
# Checking Chocolatey
# ----------------------------------------------------------

Write-Host ""
Write-Host "Checking Chocolatey..."

$Choco = Get-Command choco.exe -ErrorAction SilentlyContinue

if (-not $Choco) {
    throw "Chocolatey is not available on this runner."
}

Write-Host "[OK] Chocolatey found:"
& choco --version

# ----------------------------------------------------------
# Checking / Installing DirectX
# ----------------------------------------------------------

Write-Host ""
Write-Host "Checking DirectX..."

try {
    choco install directx -y --no-progress
    $DirectXExitCode = $LASTEXITCODE

    if ($DirectXExitCode -ne 0) {
        Write-Warning "DirectX installation returned exit code: $DirectXExitCode"
        Write-Warning "Continuing because DirectX components may already exist."
    }
    else {
        Write-Host "[OK] DirectX installation completed."
    }
}
catch {
    Write-Warning "DirectX setup failed: $($_.Exception.Message)"
}

# ----------------------------------------------------------
# Checking Google Chrome
# ----------------------------------------------------------

Write-Host ""
Write-Host "Checking Google Chrome..."

$ChromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)

$ChromeExe = $ChromePaths |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if (-not $ChromeExe) {

    Write-Host "Google Chrome not found."
    Write-Host "Trying Chocolatey installation..."

    choco install googlechrome -y --no-progress

    $ChromeExitCode = $LASTEXITCODE

    if ($ChromeExitCode -ne 0) {
        Write-Warning "Google Chrome installation returned exit code: $ChromeExitCode"
    }

    Start-Sleep -Seconds 5

    $ChromeExe = $ChromePaths |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
}

if ($ChromeExe) {
    Write-Host "[OK] Google Chrome found:"
    Write-Host $ChromeExe

    try {
        & $ChromeExe --version
    }
    catch {
        Write-Warning "Could not read Chrome version."
    }
}
else {
    Write-Warning "Google Chrome was not found. Continuing."
}

# ----------------------------------------------------------
# Checking Chrome Remote Desktop Host
# ----------------------------------------------------------

Write-Host ""
Write-Host "Checking Chrome Remote Desktop Host..."

$CRDPaths = @(
    "${env:ProgramFiles(x86)}\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe",
    "$env:ProgramFiles\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe"
)

$CRDExe = $CRDPaths |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if ($CRDExe) {

    Write-Host "[OK] Chrome Remote Desktop Host already exists:"
    Write-Host $CRDExe

}
else {

    Write-Host "Chrome Remote Desktop Host is not installed."
    Write-Host "Trying Chocolatey installation..."

    try {

        choco install chrome-remote-desktop-host -y --no-progress

        $CRDInstallExitCode = $LASTEXITCODE

        Write-Host "Chocolatey exit code: $CRDInstallExitCode"

        if ($CRDInstallExitCode -ne 0) {
            Write-Warning "Chrome Remote Desktop Host installation failed."
            Write-Warning "The Chocolatey package may be outdated or unavailable."
        }

    }
    catch {
        Write-Warning "Chrome Remote Desktop Host installation exception:"
        Write-Warning $_.Exception.Message
    }

    Start-Sleep -Seconds 10

    $CRDExe = $CRDPaths |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1

    if ($CRDExe) {
        Write-Host "[OK] Chrome Remote Desktop Host found:"
        Write-Host $CRDExe
    }
    else {
        Write-Warning "Chrome Remote Desktop Host was not installed."
        Write-Warning "Checked paths:"

        foreach ($Path in $CRDPaths) {
            Write-Warning "  $Path"
        }

        Write-Warning "Continuing without Chrome Remote Desktop Host."
    }
}

# ----------------------------------------------------------
# Navigating And Downloading Essentials
# ----------------------------------------------------------

Write-Host ""
Write-Host "Preparing Documents directory..."

$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")

if ([string]::IsNullOrWhiteSpace($DocumentsPath)) {
    $DocumentsPath = Join-Path $env:USERPROFILE "Documents"
}

if (-not (Test-Path -LiteralPath $DocumentsPath)) {
    New-Item -ItemType Directory -Path $DocumentsPath -Force | Out-Null
}

Write-Host "Documents directory:"
Write-Host $DocumentsPath

$ZipPath = Join-Path $DocumentsPath "Documents.zip"
$ExtractPath = Join-Path $DocumentsPath "Documents"

# ----------------------------------------------------------
# Downloading Essential Archive
# ----------------------------------------------------------

Write-Host ""
Write-Host "Downloading essential archive..."

$DownloadUrl = "https://drive.usercontent.google.com/download?id=1Lnn5QFZRBBPn6VkzY_g1G1tX6v0DZft1&export=download&authuser=0&confirm=t&uuid=fdbceb6f-1b4d-49c1-9128-d38cf855055b&at=APZUnTVUm1AGqItiY6LCUoXfH13d%3A1716612457921"

try {

    Invoke-WebRequest `
        -Uri $DownloadUrl `
        -OutFile $ZipPath `
        -UseBasicParsing

}
catch {
    throw "Failed to download essential archive: $($_.Exception.Message)"
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    throw "The essential archive was not downloaded."
}

$ZipSize = (Get-Item -LiteralPath $ZipPath).Length

if ($ZipSize -lt 100) {
    throw "Downloaded file is unexpectedly small and may not be a valid archive."
}

Write-Host "[OK] Archive downloaded."
Write-Host "Size: $ZipSize bytes"

# ----------------------------------------------------------
# Extracting Essentials
# ----------------------------------------------------------

Write-Host ""
Write-Host "Extracting essential archive..."

if (Test-Path -LiteralPath $ExtractPath) {
    Write-Host "Removing old extracted directory..."
    Remove-Item -LiteralPath $ExtractPath -Recurse -Force
}

$SevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue

if ($SevenZip) {

    & $SevenZip.Source x $ZipPath "-o$ExtractPath" -y

    $ExtractExitCode = $LASTEXITCODE

    if ($ExtractExitCode -ne 0) {
        throw "7-Zip extraction failed with exit code: $ExtractExitCode"
    }

}
else {

    try {
        Expand-Archive `
            -LiteralPath $ZipPath `
            -DestinationPath $ExtractPath `
            -Force
    }
    catch {
        throw "Archive extraction failed: $($_.Exception.Message)"
    }
}

if (-not (Test-Path -LiteralPath $ExtractPath)) {
    throw "Extracted directory was not created."
}

Write-Host "[OK] Archive extracted successfully."

# ----------------------------------------------------------
# Start Google Chrome
# ----------------------------------------------------------

Write-Host ""
Write-Host "Starting essential applications..."

if ($ChromeExe -and (Test-Path -LiteralPath $ChromeExe)) {
    Start-Process -FilePath $ChromeExe
    Write-Host "[OK] Google Chrome started."
}
else {
    Write-Warning "Google Chrome was skipped because it was not found."
}

# ----------------------------------------------------------
# Creating Shortcuts
# ----------------------------------------------------------

Write-Host ""
Write-Host "Creating shortcuts..."

$DesktopPath = [Environment]::GetFolderPath("Desktop")

if ([string]::IsNullOrWhiteSpace($DesktopPath)) {
    $DesktopPath = Join-Path $env:USERPROFILE "Desktop"
}

$BlenderExe = Join-Path `
    $ExtractPath `
    "Blender\blender-2.93.9-windows-x64\blender.exe"

$AssetStudioExe = Join-Path `
    $ExtractPath `
    "AssetStudioGUI\AssetStudioGUI.exe"

function New-AppShortcut {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $true)]
        [string]$ShortcutName
    )

    if (-not (Test-Path -LiteralPath $Target)) {
        Write-Warning "Application not found: $Target"
        return
    }

    $ShortcutPath = Join-Path $DesktopPath "$ShortcutName.lnk"

    try {

        $Shell = New-Object -ComObject WScript.Shell
        $Shortcut = $Shell.CreateShortcut($ShortcutPath)

        $Shortcut.TargetPath = $Target
        $Shortcut.WorkingDirectory = Split-Path -Path $Target -Parent

        $Shortcut.Save()

        Write-Host "[OK] Created shortcut: $ShortcutPath"

    }
    catch {
        Write-Warning "Could not create shortcut '$ShortcutName': $($_.Exception.Message)"
    }
}

New-AppShortcut `
    -Target $BlenderExe `
    -ShortcutName "Blender"

New-AppShortcut `
    -Target $AssetStudioExe `
    -ShortcutName "AssetStudioGUI"

# ----------------------------------------------------------
# Final Verification
# ----------------------------------------------------------

Write-Host ""
Write-Host "=========================================="
Write-Host "Files.ps1 completed successfully."
Write-Host "=========================================="