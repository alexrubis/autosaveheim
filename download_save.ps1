# ====================
# Manual Pull save to GitHub
# ====================
$ErrorActionPreference = "Stop"

# Start logging
$logPath = Join-Path $PSScriptRoot "logs\download_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Start-Transcript -Path $logPath -Append

Add-Type -AssemblyName System.Windows.Forms

Write-Host " ___  _   _  _____   ___   ___  ___ __   __ ___  _  _  ___  ___  __  __ " -ForegroundColor Blue
Write-Host "/   \| | | ||_   _| / _ \ / __|/   \\ \ / /| __|| || || __||_ _||  \/  |" -ForegroundColor Blue
Write-Host "| - || |_| |  | |  | (_) |\__ \| - | \   / | _| | __ || _|  | | | |\/| |" -ForegroundColor Blue
Write-Host "|_|_| \___/   |_|   \___/ |___/|_|_|  \_/  |___||_||_||___||___||_|  |_|" -ForegroundColor Blue
Write-Host""

# Check if config file exists and is not empty
$configPath = Join-Path $PSScriptRoot "config.ps1"
$fileExists = Test-Path $configPath
$fileHasContent = (Get-Content $configPath -ErrorAction SilentlyContinue | Where-Object { $_.Trim() }).Count -gt 0

if (-not $fileExists -or -not $fileHasContent) {
    [System.Windows.Forms.MessageBox]::Show("Config file error. Run SETUP to generate config file", "Pull Save Error", "OK", "Error")
    exit 1
}

$backupDir = Join-Path $worldDir "autosaveheim_backups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Go to save directory
try {
    Set-Location $worldDir
} catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to open save folder:`n$worldDir", "Pull Save Error", "OK", "Error")
    exit 1
}

# Validate files exist
if (-not (Test-Path "$saveName.db") -or -not (Test-Path "$saveName.fwl")) {
    [System.Windows.Forms.MessageBox]::Show("Missing save files: $saveName.db or $saveName.fwl", "Pull Save Error", "OK", "Error")
    exit 1
}

# Make sure backup directory exists
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# Backup existing files
Copy-Item "$saveName.db" -Destination "$backupDir\$saveName`_before_download_$timestamp.db"
Copy-Item "$saveName.fwl" -Destination "$backupDir\$saveName`_before_download_$timestamp.fwl"

# Pull from remote
& $git pull origin main
#& $git pull origin main --rebase
Read-Host -Prompt "Done. Press Enter to exit"

# End logging
Stop-Transcript