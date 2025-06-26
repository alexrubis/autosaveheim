# ====================
# Config file
# ====================

# Change only thoose 3:

# Enter only a name of the save file (without ".db"). Save consists of 2 files: "save_name.db" and "save_name.fwl" located in "C:\Users\userName\AppData\LocalLow\IronGate\Valheim\worlds_local" folder.
$saveName = "save_name"

# URL to Github repo wth Personal Access Token (PAT) added - https://{YOUR PAT}@github.com/{GITHUB ACCOUNT NAME}/{REPO NAME}.git
$remoteUrl = "https://github_pat_123456abcd@github.com/example/example.git"

# Path to Valheim installation directory
$valheimPath = "C:\Program Files (x86)\Steam\steamapps\common\Valheim"  # <-- change if needed



# No need to change thoose

$userName = $ENV:username
$userEmail = $ENV:username@example.com
$worldDir = "C:\Users\$userName\AppData\LocalLow\IronGate\Valheim\worlds_local"
$scriptRoot = $PSScriptRoot

# If you have Git installed this line should be auto changed to its path after running setup script, if not scripts will look for PortableGit in autosaveheim folder. Change manuallly if needed.
$git = Join-Path $scriptRoot "PortableGit\bin\git.exe"
