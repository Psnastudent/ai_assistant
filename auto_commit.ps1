# auto_commit.ps1
# This script runs silently in the background via Windows Task Scheduler.

$repo_path = "d:\desktop_assistant\ai_assistant"
Set-Location -Path $repo_path

# Create a generic automated commit message
$date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$commit_msg = "Automated daily system update and progress log: $date"

# Append to the log file
Add-Content -Path "DAILY_LOG.md" -Value "- $commit_msg"

# Stage, commit, and push automatically
git add .
git commit -m $commit_msg
git push origin main

# Show a popup notification to let the user know it worked (closes automatically after 5 seconds)
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Daily GitHub Automation completed successfully! Your contribution graph has been updated.", 5, "AI Desktop Assistant", 0x40)
