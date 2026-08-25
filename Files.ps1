# ==========================================================
# Chrome Remote Desktop Host Setup
# Put this section inside: Files.ps1
# ==========================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host ""
Write-Host "=========================================="
Write-Host " Checking Chrome Remote Desktop Host"
Write-Host "=========================================="

# ----------------------------------------------------------
# Possible locations of the CRD host executable
# ----------------------------------------------------------

$CRDPaths = @(
    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe"),
    (Join-Path $env:ProgramFiles "Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe")
)

$CRDExe = $null

foreach ($Path in $CRDPaths) {
    if (Test-Path -LiteralPath $Path) {
        $CRDExe = $Path
        break
    }
}

# ----------------------------------------------------------
# CRD already installed
# ----------------------------------------------------------

if ($CRDExe) {

    Write-Host "[OK] Chrome Remote Desktop Host found:"
    Write-Host $CRDExe

}
else {

    Write-Host "[INFO] Chrome Remote Desktop Host was not found."
    Write-Host "[INFO] Downloading installer..."

    # Temporary installer location
    $CRDInstaller = Join-Path `
        $env:TEMP `
        "chromeremotedesktophost.msi"

    # Remove an old/incomplete installer
    if (Test-Path -LiteralPath $CRDInstaller) {
        Remove-Item -LiteralPath $CRDInstaller -Force
    }

    # Download installer
    try {

        Invoke-WebRequest `
            -Uri "https://dl.google.com/dl/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi" `
            -OutFile $CRDInstaller

    }
    catch {

        throw @"
Failed to download Chrome Remote Desktop Host.

Error:
$($_.Exception.Message)
"@
    }

    # Verify download
    if (-not (Test-Path -LiteralPath $CRDInstaller)) {
        throw "Chrome Remote Desktop installer was not downloaded."
    }

    $InstallerSize = (Get-Item -LiteralPath $CRDInstaller).Length

    if ($InstallerSize -lt 1000000) {
        throw "The downloaded installer appears to be invalid or incomplete."
    }

    Write-Host "[OK] Installer downloaded."
    Write-Host "Installer: $CRDInstaller"
    Write-Host "Size: $InstallerSize bytes"

    # ------------------------------------------------------
    # Install Chrome Remote Desktop Host
    # ------------------------------------------------------

    Write-Host ""
    Write-Host "[INFO] Installing Chrome Remote Desktop Host..."

    $InstallProcess = Start-Process `
        -FilePath "msiexec.exe" `
        -ArgumentList @(
            "/i",
            "`"$CRDInstaller`"",
            "/qn",
            "/norestart"
        ) `
        -Wait `
        -PassThru

    $InstallExitCode = $InstallProcess.ExitCode

    Write-Host ""
    Write-Host "Installer exit code: $InstallExitCode"

    # Windows Installer success codes
    if (
        $InstallExitCode -ne 0 -and
        $InstallExitCode -ne 3010
    ) {

        throw @"
Chrome Remote Desktop Host installation failed.

Windows Installer exit code: $InstallExitCode
"@
    }

    if ($InstallExitCode -eq 3010) {
        Write-Warning "Installation completed but Windows requested a restart."
    }

    # Give Windows time to finish registering files
    Write-Host "Waiting for installation to complete..."
    Start-Sleep -Seconds 10

    # ------------------------------------------------------
    # Search for CRD executable again
    # ------------------------------------------------------

    $CRDExe = $null

    foreach ($Path in $CRDPaths) {

        if (Test-Path -LiteralPath $Path) {
            $CRDExe = $Path
            break
        }
    }

    # ------------------------------------------------------
    # Final verification
    # ------------------------------------------------------

    if ($CRDExe) {

        Write-Host ""
        Write-Host "=========================================="
        Write-Host "[OK] Chrome Remote Desktop Host installed!"
        Write-Host "=========================================="
        Write-Host "Host executable:"
        Write-Host $CRDExe

    }
    else {

        Write-Warning ""
        Write-Warning "Chrome Remote Desktop Host installer completed,"
        Write-Warning "but the expected executable was not found."

        Write-Warning ""
        Write-Warning "Checked locations:"

        foreach ($Path in $CRDPaths) {
            Write-Warning " - $Path"
        }

        throw "Chrome Remote Desktop Host verification failed."
    }
}
