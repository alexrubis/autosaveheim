# ====================
# Setup everything
# ====================

# Stop the script when a cmdlet or a native command fails
#$ErrorActionPreference = 'Stop'
#$PSNativeCommandUseErrorActionPreference = $true
# Start logging
$logPath = Join-Path $PSScriptRoot "logs\setup_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Start-Transcript -Path $logPath -Append
Write-Host " ___  _   _  _____   ___   ___  ___ __   __ ___  _  _  ___  ___  __  __ " -ForegroundColor Blue
Write-Host "/   \| | | ||_   _| / _ \ / __|/   \\ \ / /| __|| || || __||_ _||  \/  |" -ForegroundColor Blue
Write-Host "| - || |_| |  | |  | (_) |\__ \| - | \   / | _| | __ || _|  | | | |\/| |" -ForegroundColor Blue
Write-Host "|_|_| \___/   |_|   \___/ |___/|_|_|  \_/  |___||_||_||___||___||_|  |_|" -ForegroundColor Blue
Write-Host""
# === Create config file ===

function Install-PortableGit{
    <#
    .SYNOPSIS
    Downloads PortableGit and extracts it in autosaveheim/PortableGit folder.
    #>

    # Download PortableGit
    Write-Host "#################################################"
    Write-Host "Downloading PortableGit, please wait..."
    $url = "https://github.com/git-for-windows/git/releases/download/v2.50.0.windows.1/PortableGit-2.50.0-64-bit.7z.exe"
    # Progress bar makes Invoke webrequest much slower, skipping it
    $ProgressPreference = 'SilentlyContinue'

    Invoke-WebRequest $url -OutFile ".\PortableGit.exe"

    # Run PortableGit.exe    
    Write-Host "Starting PortableGit instalation"
    .\PortableGit.exe -o"PortableGit" -y

    # Wait for installer or bash.exe processes from extracted Git folder to exit
    while (
        (
            Get-Process bash -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*\PortableGit\*" }
        ) -or (
            Get-Process | Where-Object { $_.MainWindowTitle -and $_.ProcessName -eq "PortableGit" }
        )
    ) {
        Write-Host "Waiting: bash.exe or PortableGit is still running..."
        Start-Sleep -Seconds 10
    }

    # Wait until post-install.bat is deleted (Git installer does it)
    while (Test-Path "PortableGit\post-install.bat") {
        Write-Host "Waiting for post-install.bat deletion..."
        Start-Sleep -Seconds 10
    }

    Write-Host "All installation related processes finished."

    # Remove the PortableGit.exe setup file
    Remove-Item ".\PortableGit.exe" -Force
    $portableGit = Join-Path $PSScriptRoot "PortableGit\bin\git.exe"
    if (Test-Path $portableGit){
        return $portableGit
    }
    throw "PortableGit installation failed. exiting."
    Read-Host -Prompt "SETUP FAILED. No git installed. Press Enter to exit"
    exit 0
}

function Resolve-Git {
    <#
    .SYNOPSIS
    sets $git variable to either installed Git or downloaded PortableGit
    #>

    Write-Host "=================================================" -ForegroundColor Blue
    Write-Host "============RESOLVING GIT INSTALLATION===========" -ForegroundColor Blue

    # Try to find git.exe from system PATH
    $git = (Get-Command git  -ErrorAction SilentlyContinue).Source
    if ($git) {
        return $git
    }

    # Try to find PortableGit's git.exe:
    $portableGit = Join-Path $PSScriptRoot "PortableGit\bin\git.exe"
    if (Test-Path $portableGit) {
        return $portableGit
    }
    
    # If PortableGit not found ask for downloading one
    $installGit = ($response = Read-Host "Git not found, do you want to download PortableGit (app.400mb)? (Y or N)") -match '^[Yy]'
    switch ($installGit){
        $true {
            $git = Install-PortableGit
            return $git
        }
        $false {
            throw "git.exe not found in system PATH or in PortableGit folder."
            Read-Host -Prompt "SETUP FAILED. No git installed. Press Enter to exit"
            exit 1
        }
    }
}

function Set-Config {
    <#
    .SYNOPSIS
    Creates config.ps1 file in script root that will be used by all other scripts. Finds/Installs Git.
    #>
    param (
        [string]$saveName,
        [string]$remoteUrl,
        [string]$worldDir = "C:\Users\$ENV:username\AppData\LocalLow\IronGate\Valheim\worlds_local",
        [string]$gitUserEmail = "$ENV:username@example.com",
        [int]$runFromSteam = 1
    )

    Write-Host "====================================="
    Write-Host "============CREATING CONFIG FILE==========="

    $git = Resolve-Git
    if (-not $git) {
        throw "git.exe not found in system PATH or in PortableGit folder."
        Read-Host -Prompt "SETUP FAILED. No git installed. Press Enter to exit"
        exit 1
    }
    # Write to config.ps1

    # Set output file path
    $configFile = "$PSScriptRoot\config.ps1"

    # Create the file and write variable definitions to it
    # Config file contents
    $value = 
@"
    # ====================
    # Config file
    # ====================

    # Change only thoose:

    # Enter only a name of the save file (without ".db"). Save consists of 2 files: "save_name.db" and "save_name.fwl" located in "C:\Users\userName\AppData\LocalLow\IronGate\Valheim\worlds_local" folder.
    `$saveName = '$saveName'

    # URL to Github repo wth Personal Access Token (PAT) added - https://{YOUR PAT}@github.com/{GITHUB ACCOUNT NAME}/{REPO NAME}.git
    `$remoteUrl = '$remoteUrl'

    # Path to Valheim installation directory
    `$valheimPath = "C:\Program Files (x86)\Steam\steamapps\common\Valheim"  # <-- change if needed
    
    # Do you want to start Valheim  through Steam (with Steam Overlay, etc.) or directly from Valheim.exe? 1 = Steam / 0 = run directly
    `$runFromSteam = $runFromSteam



    # No need to change thoose
    `$gitUserEmail = '$gitUserEmail'
    `$worldDir = '$worldDir'
    # If you have Git installed this line should be auto changed to its path after running setup script, if not scripts will look for PortableGit in autosaveheim folder. Change manuallly if needed.
    `$git = '$git'
"@

    Set-Content -Encoding UTF8 -Path $configFile -Value $value
    Write-Host "Variables exported to $configFile"
}

# === Create config file ===
# Prompt user for required arguments
Write-Host "=================================================="
Write-Host "=============== Autosaveheim setup ==============="
$saveName = Read-Host "Enter your Valheim world save name"
$remoteUrl = Read-Host "Enter the URL to Github repo with GitHub's Personal Access Token (PAT) added - https://{YOUR PAT}@github.com/{GITHUB ACCOUNT NAME}/{REPO NAME}.git"
$gitUserEmail = Read-Host "Enter email for GitHub. Optional, press Enter to skip with default"
$runFromSteam = Read-Host "Do you want to start Valheim  through Steam (with Steam Overlay, etc.) or directly from Valheim.exe? 1 = Steam / 0 = run directly. Optional, press Enter to skip with default"
Write-Host "Check config.ps1 file for more settings"

# Call the function with or without optional args
# Build parameters dynamically
$params = @{
    saveName  = $saveName
    remoteUrl = $remoteUrl
}
if (-not [string]::IsNullOrWhiteSpace($gitUserEmail)) {
    $params.gitUserEmail = $gitUserEmail
}
if (-not [string]::IsNullOrWhiteSpace($runFromSteam)) {
    $params.runFromSteam = $runFromSteam
}
# Call the function with collected params
Set-Config @params

# Load shared variables
. "$PSScriptRoot\config.ps1"

# === Create git ignore file ===
$gitignorePath = Join-Path $worldDir ".gitignore"
$gitignoreContent = @"
*
!$saveName.fwl
!$saveName.db
!whos_hosting.txt
"@

# Before initing git repo, backup save files and delete them
$backupDir = Join-Path $worldDir "autosaveheim_backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$files = @(
    "$saveName.fwl",
    "$saveName.db",
    "whos_hosting.txt"
)
# Process each file
foreach ($file in $files) {
    $filePath = Join-Path $worldDir $file
    if (Test-Path $filePath) {
        $backupPath = Join-Path $backupDir "setup_backup_$file"
        if ($file -ne "whos_hosting.txt"){
            Copy-Item $filePath $backupPath -Force
        }        
        Remove-Item $filePath -Force
    }
}


Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8
Write-Host ".gitignore created at $gitignorePath (only $saveName.fwl and $saveName.db will be tracked)"

# === Git Config ===
# Init Git
Write-Host " Initializing Git repository in $worldDir..."
Push-Location $worldDir
# Remove existing .git folder
if (Test-Path ".\.git") {
Remove-Item ".\.git"  -Recurse -Force
}

Write-Host "============DOWNLOADING SAVEFILES==========="

& $git init
& $git -C $worldDir config user.name "$ENV:username"
& $git -C $worldDir config user.email "$gitUserEmail"
& $git -C $worldDir config credential.helper store
& $git remote add origin $remoteUrl
& $git branch -M main
& $git pull origin main --rebase
if ($LASTEXITCODE -ne 0) {
    Read-Host -Prompt "Git failed with exit code $LASTEXITCODE. Press any key to exit"
    exit $LASTEXITCODE
}
Pop-Location

# === Create Shortcuts ===
function New-Shortcut {
    param (
        [string]$name,
        [string]$scriptFile,
        [string]$iconDir,
        [string]$shortcutPath = [Environment]::GetFolderPath("Desktop")
    )
    #$desktop = [Environment]::GetFolderPath("Desktop")
    #$shortcutPath = Join-Path $desktop "$name.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $shortcutPath "$name.lnk"))
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptFile`""
    $shortcut.WorkingDirectory = $PSScriptRoot
	$shortcut.IconLocation = $iconDir
    $shortcut.Save()
    Write-Host "Created shortcut: $shortcutPath"
}

New-Shortcut -name "HOST a game" -scriptFile (Join-Path $PSScriptRoot "autosaveheim.ps1") -iconDir (Join-Path $PSScriptRoot "icons\autosaveheim.ico")
New-Shortcut -name "Manual UPLOAD savegame" -scriptFile (Join-Path $PSScriptRoot "upload_save.ps1") -iconDir (Join-Path $PSScriptRoot "icons\upload.ico") -shortcutPath $PSScriptRoot
New-Shortcut -name "Manual DOWNLOAD savegame" -scriptFile (Join-Path $PSScriptRoot "download_save.ps1") -iconDir (Join-Path $PSScriptRoot "icons\download.ico") -shortcutPath $PSScriptRoot

Write-Host "`n Setup complete!" -ForegroundColor Blue
Read-Host -Prompt "Done. Press Enter to exit"

# End logging
Stop-Transcript