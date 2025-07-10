# ====================
# Autosaveheim / Downloads newest save from github repo, starts Valheim, after quiting Valheim uploads save to GH repo.
# ====================

# Start logging PowerShell output
$logPath = Join-Path $PSScriptRoot "logs\autosaveheim_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Start-Transcript -Path $logPath -Append

Add-Type -AssemblyName System.Windows.Forms

Write-Host " ___  _   _  _____   ___   ___  ___ __   __ ___  _  _  ___  ___  __  __ "
Write-Host "/   \| | | ||_   _| / _ \ / __|/   \\ \ / /| __|| || || __||_ _||  \/  |"
Write-Host "| - || |_| |  | |  | (_) |\__ \| - | \   / | _| | __ || _|  | | | |\/| |"
Write-Host "|_|_| \___/   |_|   \___/ |___/|_|_|  \_/  |___||_||_||___||___||_|  |_|"
Write-Host""


# === 1. Pull save from GitHub ===
Write-Host "=====================================" -ForegroundColor Blue
Write-Host "===========DOWNLOADING SAVE==========" -ForegroundColor Blue
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
Write-Host "=====================================" -ForegroundColor Blue
Write-Host "===========LAUNCHING VALHEIM==========" -ForegroundColor Blue
switch ($runFromSteam){
	0 {
		# Launch Valheim.exe directly
		#$valheimPath = "C:\Program Files (x86)\Steam\steamapps\common\Valheim"
		$valheimExec = ".\valheim.exe"
		cd $valheimPath 
		$valheimProcess = Start-Process -FilePath $valheimExec -PassThru -ArgumentList "-console"
		$valheimProcess.WaitForExit()
        Write-Host "Valheim closed."
	}
	1 {
		# Launch Valheim via Steam
		Start-Process "steam://rungameid/892970"
		Write-Host "Waiting for Valheim to start..."
		$timeoutSeconds = 15
		$elapsedTime = 0
		while ($elapsedTime -lt $timeoutSeconds){
			$valheimProcess = Get-Process -Name "valheim" -ErrorAction SilentlyContinue
			if ($valheimProcess) {
				Write-Host "Valheim started..." 
				# Waiting until valheim.exe process exits
				$valheimProcess.WaitForExit()
				Write-Host "Valheim closed."
				break
			}
			
			Start-Sleep -Seconds 1
			$elapsedTime += 1
			
			if ($elapsedTime -ge $timeoutSeconds -and -not $valheimProcess) {
				Write-Host "Valheim didn't start. Terminating script"
                Write-Host "IF VALHEIM STARTED REGARDLESS THIS MESSAGE, SAVES WHERE NOT UPLOADED. USE MANUAL UPLOAD AND CHECK REMOTE REPO!!!"  -ForegroundColor Red -BackgroundColor White 
				# End logging
				Stop-Transcript
				exit 1
			}
		}
	}
}
# === 3. PUSH SAVE ===

# Push save to GitHub
Write-Host "=====================================" -ForegroundColor Blue
Write-Host "============UPLOADING SAVE===========" -ForegroundColor Blue
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

Read-Host -Prompt "Script finished. Log created. Press Enter to exit"  -ForegroundColor Blue

# End logging
Stop-Transcript