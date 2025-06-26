# ====================
# Autosaveheim / Downloads newest save from github repo, starts Valheim, after quiting Valheim uploads save to GH repo.
# ====================

# Start logging PowerShell output
$logPath = Join-Path $PSScriptRoot "logs\autosaveheim_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Start-Transcript -Path $logPath -Append

Add-Type -AssemblyName System.Windows.Forms

# === 1. Pull save from GitHub ===
Write-Host "====================================="
Write-Host "===========DOWNLOADING SAVE=========="
# Load shared variables
. "$PSScriptRoot\config.ps1"

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
#Read-Host -Prompt "Done. Press Enter to exit"

# === 2. START VALHEIM ===
Write-Host "====================================="
Write-Host "===========STARTING VALHEIM=========="
#$valheimPath = "C:\Program Files (x86)\Steam\steamapps\common\Valheim"  # moved to config
Write-Host "Launching Valheim..."
$valheimExec = ".\valheim.exe"
cd $valheimPath 
$valheimProcess = Start-Process -FilePath $valheimExec -PassThru
$valheimProcess.WaitForExit()
Write-Host "Valheim closed."

# === 3. PUSH SAVE ===
Add-Type -AssemblyName System.Windows.Forms

# Push save to GitHub
Write-Host "====================================="
Write-Host "============UPLOADING SAVE==========="
# Load shared variables
. "$PSScriptRoot\config.ps1"

$backupDir = Join-Path $worldDir "autosaveheim_backups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

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

Read-Host -Prompt "Script finished. Log created. Press Enter to exit"

# End logging
Stop-Transcript