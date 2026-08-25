# ----------------------------------------------------------
# Installing Chrome Remote Desktop Host via Chocolatey
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

    Write-Host "[OK] Chrome Remote Desktop Host already installed:"
    Write-Host $CRDExe

}
else {

    Write-Host "Installing Chrome Remote Desktop Host..."

    # Refresh Chocolatey's package information
    choco source list

    # Install explicitly from the Chocolatey Community repository
    choco install chrome-remote-desktop-host `
        --yes `
        --no-progress `
        --source="https://community.chocolatey.org/api/v2/"

    $ExitCode = $LASTEXITCODE

    Write-Host "Chocolatey exit code: $ExitCode"

    # Common successful/acceptable Windows installer exit codes
    $ValidExitCodes = @(0, 1641, 3010)

    if ($ExitCode -notin $ValidExitCodes) {
        throw "Chrome Remote Desktop Host installation failed. Chocolatey exit code: $ExitCode"
    }

    Start-Sleep -Seconds 10

    # Check again after installation
    $CRDExe = $CRDPaths |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1

    if (-not $CRDExe) {
        throw "Installation completed, but Chrome Remote Desktop Host was not found."
    }

    Write-Host "[OK] Chrome Remote Desktop Host installed:"
    Write-Host $CRDExe
}
