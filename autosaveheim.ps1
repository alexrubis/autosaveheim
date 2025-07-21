# ====================
# Autosaveheim / Downloads newest save from github repo, starts Valheim, after quiting Valheim uploads save to GH repo.
# ====================
$ErrorActionPreference = "Stop"

# Start logging PowerShell output
$logPath = Join-Path $PSScriptRoot "logs\autosaveheim_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
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

# === 1. Pull save from GitHub ===
Write-Host "=====================================" -ForegroundColor Blue
Write-Host "===========DOWNLOADING SAVE==========" -ForegroundColor Blue

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
if (-not (Test-Path "$saveName.db") -or (-not (Test-Path "$saveName.fwl")) -or (-not (Test-Path "whos_hosting.txt"))) {
    [System.Windows.Forms.MessageBox]::Show("Missing save files: $saveName.db or $saveName.fwl or whos_hosting.txt", "Pull Save Error", "OK", "Error")
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

function Stop-Valheim {
    $valheimProcess = Get-Process -Name "valheim" -ErrorAction SilentlyContinue
    if ($valheimProcess) {
        Stop-Process -Id $valheimProcess.Id -Force
    }    
}

function Test-HostingReservation {
    <#
    .SYNOPSIS
    Checks is someone else is already hosting a server by checking if whos_hosting.txt file (pulled from remote) is not empty).
    If file is empty -> free to host, if it contains text (another user's name) you can't host.
    #>

    & $git pull origin main
    $whosHostingDir = Join-Path $worldDir "whos_hosting.txt"
    $hostInfo = Get-Content $whosHostingDir
    if ($hostInfo.Length -gt 0) {
        Write-Host "Can't start start Valheim as host, $hostInfo is hosting right now!!!" -ForegroundColor Blue
        $temp = [System.Windows.Forms.MessageBox]::Show("Can't start Valheim as host, $hostInfo is hosting right now!!!", "You can't host a game!", [System.Windows.Forms.MessageBoxButtons]::OK)
        # If in situation that Valheim has been started despite someone else hosting , kill the process
        Stop-Valheim
        return $false
    }

    return $true
} 

function Set-HostingReservation {
    <#
    .SYNOPSIS
    Lock or unlock possibility of others to host a server.
    Writes your username to whos_hosting.txt file to lock and erases file content to unlock.
    -mode 'lock' / 'unlock'
    #>
    param (
        [string]$mode
    )

    $whosHostingDir = Join-Path $worldDir "whos_hosting.txt"

    if ($mode -eq "lock"){
        Set-Content -Path $whosHostingDir -Value "$ENV:username"
        & $git -C $worldDir add $whosHostingDir
        & $git -C $worldDir commit -m "$ENV:username started hosting"
        & $git -C $worldDir push origin main
        if ($LASTEXITCODE -ne 0) {
            Read-Host -Prompt "While changing whos_hosting.txt file, Git failed with exit code $LASTEXITCODE. Press any key to exit"
            exit $LASTEXITCODE
        }

        return
    }
    elseif ($mode -eq "unlock") {
        Set-Content -Path $whosHostingDir -Value ""
        & $git -C $worldDir add $whosHostingDir
        if ($LASTEXITCODE -ne 0) {
            Write-Host "While pushing whos_hosting.txt file to remote, Git failed with exit code $LASTEXITCODE"  -ForegroundColor Red -BackgroundColor White
            Read-Host -Prompt "Press any key to exit"
            exit $LASTEXITCODE
        }
        
        return
    }

    throw "Error setting hosting reservation, mode ( $mode )"        
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

Write-Host "=====================================" -ForegroundColor Blue
Write-Host "===========LAUNCHING VALHEIM==========" -ForegroundColor Blue

# Check if someone is hosting a server
if (-not (Test-HostingReservation)) {
    Read-Host -Prompt "Press any key to exit"
    exit 1
}

$valheimProcess = $null
switch ($runFromSteam){
	0 {
		# Launch Valheim.exe directly
        $valheimExec = ".\valheim.exe"
		Set-Location $valheimPath 
		$valheimProcess = Start-Process -FilePath $valheimExec -PassThru -ArgumentList "-console"
	}
	1 {
		# Launch Valheim via Steam
		Start-Process "steam://rungameid/892970"
		Write-Host "Waiting for Valheim to start..."
        #Wait some time for Steam to launch Valheim
		$timeoutSeconds = 30
		$elapsedTime = 0
		while ($elapsedTime -lt $timeoutSeconds){
			$valheimProcess = Get-Process -Name "valheim" -ErrorAction SilentlyContinue
			if ($valheimProcess) {
                # Check if someone is hosting a server
                if (-not (Test-HostingReservation)) {
                    Read-Host -Prompt "Press any key to exit."
                    exit 1
                }
				Write-Host "Valheim started..."
				break
			}
			
			Start-Sleep -Seconds 5
			$elapsedTime += 5
		}
        
        if (-not $valheimProcess) {
            # Prompt user to continue waiting or quit
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Valheim did not start within $timeoutSeconds seconds.`n`n" +
                "Click 'Yes' to keep waiting, or 'No' to exit the script. If you click exit but Valheim will start, the savefiles won't be autosynced!!!",
                "Valheim Launch Warning",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($result -eq [System.Windows.Forms.DialogResult]::No) {
                Stop-Valheim
                Write-Host "User chose to quit script. Check if you have changes in game save and upload it manualy." -ForegroundColor Red
                Read-Host -Prompt "Press any key to exit"
                Stop-Transcript
                exit 1
            }

            # Keep checking every 10s and prompt again if still not started
            do {
                Start-Sleep -Seconds 10
                $valheimProcess = Get-Process -Name "valheim" -ErrorAction SilentlyContinue

                if (-not $valheimProcess) {
                    $repeat = [System.Windows.Forms.MessageBox]::Show(
                        "Valheim is still not running.`n`n" +
                        "Click 'Yes' to keep waiting, or 'No' to exit. If you click exit but Valheim will start, the savefiles won't be autosynced!!!",
                        "Still Waiting...",
                        [System.Windows.Forms.MessageBoxButtons]::YesNo,
                        [System.Windows.Forms.MessageBoxIcon]::Question
                    )

                    if ($repeat -eq [System.Windows.Forms.DialogResult]::No) {
                        Stop-Valheim
                        Write-Host "User chose to quit script during wait loop. Check if you have changes in game save and upload it manualy." -ForegroundColor Red
                        Read-Host -Prompt "Press any key to exit"
                        Stop-Transcript
                        exit 1
                    }
                }
            } while (-not $valheimProcess)

            Write-Host "Valheim finally started after extended wait."
        }
	}
}


$valheimProcess = Get-Process -Name "valheim" -ErrorAction SilentlyContinue
if ($valheimProcess) {
    if (-not (Test-HostingReservation)) {
        Stop-Valheim
        $temp = [System.Windows.Forms.MessageBox]::Show("Can't start Valheim as host, $hostInfo is hosting right now!!!", "You can't host a game! Closing Valheim.", "OK", "Error")
        exit 1
    }
    Write-Host "No one else's hosting. You can start a game as host" -ForegroundColor Blue

    Set-HostingReservation -mode "lock"

    Write-Host "Valheim started."

    $valheimProcess.WaitForExit()

    Set-HostingReservation -mode "unlock"

    Write-Host "Valheim closed."
}
else {
    Write-Host "Something's wrong with starting Valheim."  -ForegroundColor Red -BackgroundColor White 
    Read-Host -Prompt "Quiting. Press any key to exit"
        exit 1
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
& $git add "$saveName.db", "$saveName.fwl", "whos_hosting.txt"
& $git commit -m "Backup by $env:USERNAME on $timestamp"
& $git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "While pushing savefile, Git failed with exit code $LASTEXITCODE"  -ForegroundColor Red -BackgroundColor White
    Read-Host -Prompt "Press any key to exit"
    exit $LASTEXITCODE
}
Read-Host -Prompt "Script finished. Log created. Press Enter to exit"

# End logging
Stop-Transcript