    # ====================
    # Config file
    # ====================

    # Change only thoose:

    # Enter only a name of the save file (without ".db"). Save consists of 2 files: "save_name.db" and "save_name.fwl" located in "C:\Users\userName\AppData\LocalLow\IronGate\Valheim\worlds_local" folder.
    $saveName = 'save_name'

    # URL to Github repo wth Personal Access Token (PAT) added - https://{YOUR PAT}@github.com/{GITHUB ACCOUNT NAME}/{REPO NAME}.git
    $remoteUrl = 'https://github_pat_123456abcd@github.com/example/example.git'

    # Path to Valheim installation directory
    $valheimPath = "C:\Program Files (x86)\Steam\steamapps\common\Valheim"  # <-- change if needed
    
    #Do you want to start Valheim  through Steam (with Steam Overlay, etc.) or directly from Valheim.exe? 1 = Steam / 0 = run directly
    $runFromSteam = 1



    # No need to change thoose
    $gitUserEmail = "$ENV:username@example.com"
    $worldDir = "C:\Users\$ENV:username\AppData\LocalLow\IronGate\Valheim\worlds_local"
    # If you have Git installed this line should be auto changed to its path after running setup script, if not scripts will look for PortableGit in autosaveheim folder. Change manuallly if needed.
    $git = 'C:\Program Files\Git\cmd\git.exe'
