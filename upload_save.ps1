# ====================
# Manual Push save to GitHub
# ====================
$ErrorActionPreference = "Stop"

# Start logging
$logPath = Join-Path $PSScriptRoot "logs\upload_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
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
# Load shared variables
. "$PSScriptRoot\config.ps1"

# Go to save directory
try {
    Set-Location $worldDir
} catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to open save folder:`n$worldDir", "Push Save Error", "OK", "Error")
    exit 1
}

# Validate files exist
if (-not (Test-Path "$saveName.db") -or -not (Test-Path "$saveName.fwl")) {
    [System.Windows.Forms.MessageBox]::Show("Missing save files: $saveName.db or $saveName.fwl", "Push Save Error", "OK", "Error")
    exit 1
}

$backupDir = Join-Path $worldDir "autosaveheim_backups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Make sure backup directory exists
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# Backup files
Copy-Item "$saveName.db" -Destination "$backupDir\$saveName`_before_upload_$timestamp.db"
Copy-Item "$saveName.fwl" -Destination "$backupDir\$saveName`_before_upload_$timestamp.fwl"

# Add, commit, and push
& $git add "$saveName.db", "$saveName.fwl"
& $git commit -m "Backup by $env:USERNAME on $timestamp"
& $git push origin main

Read-Host -Prompt "Done. Press Enter to exit"

# End logging
Stop-Transcript