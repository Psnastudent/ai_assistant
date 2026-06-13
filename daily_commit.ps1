# daily_commit.ps1
# This script automates daily logging and GitHub commits.

$repo_path = "d:\desktop_assistant\ai_assistant"
Set-Location -Path $repo_path

Write-Host "Checking git status..." -ForegroundColor Cyan
git status

# Ask for the daily task description
$task_description = Read-Host "What did you work on today? (This will be added to DAILY_LOG.md and used as commit message)"

if ([string]::IsNullOrWhiteSpace($task_description)) {
    Write-Host "No task description provided. Exiting..." -ForegroundColor Yellow
    exit
}

# Append to DAILY_LOG.md
$log_entry = "- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $task_description"
Add-Content -Path "DAILY_LOG.md" -Value $log_entry
Write-Host "Appended to DAILY_LOG.md" -ForegroundColor Green

# Show changes to be committed
git diff

# Ask for confirmation before proceeding
$confirmation = Read-Host "Do you want to stage all changes, commit, and push to GitHub? (y/n)"

if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    Write-Host "Staging changes..." -ForegroundColor Cyan
    git add .
    
    Write-Host "Committing changes..." -ForegroundColor Cyan
    git commit -m "Daily Update: $task_description"
    
    Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
    git push origin main
    
    Write-Host "Done! Keep up the great work!" -ForegroundColor Green
} else {
    Write-Host "Commit cancelled by user. Changes to DAILY_LOG.md are saved locally but not committed." -ForegroundColor Yellow
}
