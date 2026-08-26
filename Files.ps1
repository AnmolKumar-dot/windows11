# ==========================================================
# Files.ps1
# Chrome Remote Desktop Host Setup
# ==========================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "=========================================="
Write-Host " Windows Setup - Starting"
Write-Host "=========================================="

# ----------------------------------------------------------
# Check Chocolatey
# ----------------------------------------------------------

Write-Host ""
Write-Host "[1/3] Checking Chocolatey..."

$Choco = Get-Command choco.exe -ErrorAction SilentlyContinue

if (-not $Choco) {
    throw "Chocolatey was not found on this runner."
}

Write-Host "[OK] Chocolatey found:"
& choco --version

# ----------------------------------------------------------
# Install Chrome Remote Desktop Host
# ----------------------------------------------------------

Write-Host ""
Write-Host "[2/3] Installing Chrome Remote Desktop Host..."

choco install chrome-remote-desktop-host `
    --version="152.0.7977.9" `
    --yes `
    --no-progress `
    --source="https://community.chocolatey.org/api/v2/"

$ChocoExitCode = $LASTEXITCODE

# Accept normal success/reboot-required exit codes.
$ValidExitCodes = @(0, 1641, 3010)

if ($ChocoExitCode -notin $ValidExitCodes) {
    throw "Chrome Remote Desktop Host installation failed with exit code: $ChocoExitCode"
}

Write-Host "[OK] Chocolatey installation completed."

# ----------------------------------------------------------
# Verify installation
# ----------------------------------------------------------

Write-Host ""
Write-Host "[3/3] Verifying Chrome Remote Desktop Host..."

$CRDPaths = @(
    "${env:ProgramFiles(x86)}\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe",
    "$env:ProgramFiles\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe"
)

$CRDExe = $null

foreach ($Path in $CRDPaths) {
    if (Test-Path -LiteralPath $Path) {
        $CRDExe = $Path
        break
    }
}

if (-not $CRDExe) {
    Write-Host ""
    Write-Host "Installation completed, but the expected host executable was not found."
    Write-Host "Checked:"

    foreach ($Path in $CRDPaths) {
        Write-Host " - $Path"
    }

    throw "Chrome Remote Desktop Host verification failed."
}

Write-Host "[OK] Chrome Remote Desktop Host found:"
Write-Host $CRDExe

Write-Host ""
Write-Host "=========================================="
Write-Host " Files.ps1 completed successfully"
Write-Host "=========================================="
