Valheim Autosave Sync
Automatically share and sync Valheim save files between friends via GitHub

Overview
Helps you keep your Valheim save files in sync with friends by using a GitHub repository as a shared backup and sync point. When one friend hosts, they pull the latest save before playing and push their updated save after finishing, enabling seamless save file sharing.

Features

One script to automatically download newest save before game start and upload save after finishing the game.

Supports multiple hosts sharing the same save files

Uses Portable Git and PowerShell scripts for easy setup and usage

Creates backups of local savefiles before every download and upload

Setup
1. Create repo on GitHub for storing save files.
2. Create PAT token on GitHub.
3. Download autosaveheim folder.
4. Download git portable from here https://github.com/git-for-windows/git/releases/download/v2.50.0.windows.1/PortableGit-2.50.0-64-bit.7z.exe
5. Place extracted PortableGit folder to autosaveheim folder.
6. Fill in config file.
7. Run "Setup autosaveheim" shortcut.
	(or setup.ps1 from PowerShell with execution policy bypass enabled: powershell Set-ExecutionPolicy Bypass -Scope Process -Force .\setup.ps1)
	This initializes the git repo, configures remote, and creates shortcuts for pulling and pushing saves

Usage
If you want to host a game, run a shortcut "HOST a game" that should be created on your desktop
(Or manually run "DOWNLOAD savegame" shortcut or "UPLOAD savegame" shortcut.)
If "HOST a game" clicked, the script will download latest savefile from github repo, launch a game and after the game is finished it will upload your safe to github repo.

Useful commands:
$git = "C:\Users\$ENV:username\Desktop\autosaveheim\PortableGit\bin\git.exe"
& "$git"
