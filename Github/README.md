# 📊 GitHub Year in Review (PowerShell)

A PowerShell script designed to generate a beautiful "Year in Review" summary for your GitHub repositories. Perfect for sharing your project's progress on Discord, Slack, or LinkedIn.

## ✨ Features
- **Automated Dependency Setup**: Detects if Git and GitHub CLI are missing and offers to install them via Winget.
- **Auto-Authentication Check**: Ensures you are logged into `gh` before running.
- **Comprehensive Stats**:
    - Repository age calculation.
    - Commit count (last 12 months).
    - Pull Requests created & Issues closed.
    - Release tracking (latest tag & date).
    - Community growth (new stars & total forks).
- **Discord Ready**: Generates a formatted message with emojis, automatically copied to your clipboard.

## 🛠️ Quick Start (One-Liner)
You don't even need to download the script. Just run this in PowerShell:

```powershell
irm "https://raw.githubusercontent.com/fscorrupt/Toolbox/main/Github/YearInReview.ps1" | iex; Get-RepoStats -Repo "fscorrupt/posterizarr" -Highlight "Reached a stable v1.0 and improved community documentation!"
```
### Example Output:
<img width="1738" height="993" alt="image" src="https://github.com/user-attachments/assets/1c760a66-eadf-44ce-90d2-d810edd75f03" />

<img width="1396" height="1009" alt="image" src="https://github.com/user-attachments/assets/3f073ddf-8e79-461c-aa91-9e6bceb0c94a" />

