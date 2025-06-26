# ====================
# Setup everything
# ====================

# Start logging
$logPath = Join-Path $PSScriptRoot "logs\setup_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Start-Transcript -Path $logPath -Append

# Load shared variables
. "$PSScriptRoot\config.ps1"

# === Check if Git Exists ===

# Check if Git is installed
$gitInstallationPath = (Get-Command git -ErrorAction SilentlyContinue).Path

if ($gitInstallationPath) {
    Write-Host "Git found. Setting its path in config file"
	

} else {
    Write-Host "Git is NOT installed, checking for PortableGit..."
	# Check PortableGit Exists 
	if (-not (Test-Path $git)) {
		Write-Error " PortableGit not found at $git"
		exit 1
	}
	Write-Host "PortableGit found"
}

# === Create git ignore file ===
$gitignorePath = Join-Path $worldDir ".gitignore"
$gitignoreContent = @"
*
!$saveName.fwl
!$saveName.db
"@

Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8
Write-Host ".gitignore created at $gitignorePath (only $saveName.fwl and $saveName.db will be tracked)"

# === Git Config ===
# Init Git if needed
Write-Host " Initializing Git repository in $worldDir..."
Push-Location $worldDir
& $git init
& $git -C $worldDir config user.name "$userName"
& $git -C $worldDir config user.email "$userEmail"
& $git -C $worldDir config credential.helper store
& $git remote add origin $remoteUrl
& $git branch -M main
& $git pull origin main --rebase
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
    $shortcut.WorkingDirectory = $scriptRoot
	$shortcut.IconLocation = $iconDir
    $shortcut.Save()
    Write-Host "Created shortcut: $shortcutPath"
}

New-Shortcut -name "HOST a game" -scriptFile (Join-Path $scriptRoot "autosaveheim.ps1") -iconDir (Join-Path $scriptRoot "icons\autosaveheim.ico")
New-Shortcut -name "UPLOAD savegame" -scriptFile (Join-Path $scriptRoot "upload_save.ps1") -iconDir (Join-Path $scriptRoot "icons\upload.ico") -shortcutPath $scriptRoot
New-Shortcut -name "DOWNLOAD savegame" -scriptFile (Join-Path $scriptRoot "download_save.ps1") -iconDir (Join-Path $scriptRoot "icons\download.ico") -shortcutPath $scriptRoot

Write-Host "`n Setup complete!"
Read-Host -Prompt "Done. Press Enter to exit"

# End logging
Stop-Transcript