function Get-RepoStats {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Repo,

        [Parameter(Mandatory=$false)]
        [string]$Highlight = ""
    )

    # Dependency Checker & Installer
    function Set-Prerequisite {
        param([string]$Name, [string]$Command, [string]$Id)
        
        if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
            Write-Host "⚠️  $Name is not installed." -ForegroundColor Yellow
            $choice = Read-Host "Would you like to install $Name via Winget? (Y/N)"
            if ($choice -eq "Y" -or $choice -eq "y") {
                Write-Host "📥 Installing $Name (forcing winget source)..." -ForegroundColor Cyan
                
                $wingetargs = "install --id $Id --source winget --silent --accept-source-agreements --accept-package-agreements"
                $process = Start-Process winget -ArgumentList $wingetargs -Wait -PassThru -NoNewWindow
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "✅ $Name installed successfully!" -ForegroundColor Green
                    return "RestartRequired"
                } else {
                    Write-Host "❌ Installation failed with Exit Code: $($process.ExitCode)" -ForegroundColor Red
                    
                    if ($process.ExitCode -eq -1978335138) {
                        Write-Host "💡 Tip: This looks like a SSL/Certificate error (0x8a15005e)." -ForegroundColor Cyan
                        Write-Host "   Try running 'winget source reset --force' in an Admin terminal." -ForegroundColor Gray
                    }
                    return "Failed"
                }
            } else {
                return "Failed"
            }
        }
        return "Exists"
    }

    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Gray
    $gitStatus = Set-Prerequisite -Name "Git" -Command "git" -Id "Git.Git"
    $ghStatus  = Set-Prerequisite -Name "GitHub CLI" -Command "gh" -Id "GitHub.cli"

    if ($gitStatus -eq "RestartRequired" -or $ghStatus -eq "RestartRequired") {
        Write-Host "`n🚀 Tools were installed, but PowerShell needs to see them." -ForegroundColor Cyan
        Write-Host "Please RESTART your terminal/PowerShell and run the command again." -ForegroundColor Yellow
        return
    }

    if ($gitStatus -eq "Failed" -or $ghStatus -eq "Failed") {
        Write-Host "❌ Missing dependencies. Please install Git and GitHub CLI manually." -ForegroundColor Red
        return
    }

    if (-not (gh auth status 2>$null)) {
        Write-Host "❌ You are not logged into GitHub CLI." -ForegroundColor Yellow
        Write-Host "Please run 'gh auth login' to authenticate, then restart the script."
        return
    }

    # Data Collection
    $limitDate = (Get-Date).AddDays(-365)
    $dateShort = $limitDate.ToString("yyyy-MM-dd")
    $rawName = ($Repo -split '/')[-1]
    $repoName = (Get-Culture).TextInfo.ToTitleCase($rawName.ToLower())

    Write-Host "`n📊 Gathering Year-in-Review for $Repo..." -ForegroundColor Cyan

    # Age Calculation
    $repoDetails = gh api repos/$Repo --jq '{created_at: .created_at, forks: .forks_count}' | ConvertFrom-Json
    $createdDate = [DateTime]$repoDetails.created_at
    $ageSpan = New-TimeSpan -Start $createdDate -End (Get-Date)
    $ageText = if ($ageSpan.Days -gt 365) { "$([Math]::Round(($ageSpan.Days / 365), 1)) years" } else { "$([Math]::Round(($ageSpan.Days / 30), 0)) months" }

    # COMMITS
    Write-Host "  > Fetching Commits..." -ForegroundColor DarkGray
    $commitsRaw = git rev-list --count --since="365 days ago" HEAD 2>$null
    if ([string]::IsNullOrWhiteSpace($commitsRaw) -or $commitsRaw -eq 0) {
        $commitsRaw = gh api "repos/$Repo/commits?since=$($limitDate.ToString("yyyy-MM-ddTHH:mm:ssZ"))" --paginate --jq "length" | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    }
    [int]$commits = $commitsRaw

    # Stars
    Write-Host "  > Fetching Community Stats..." -ForegroundColor DarkGray
    $starData = @(gh api repos/$Repo/stargazers --paginate --header "Accept: application/vnd.github.v3.star+json" --jq ".[] | .starred_at")
    $starsCount = ($starData | Where-Object { [DateTime]$_ -gt $limitDate }).Count

    # PRs and Issues
    $prsRaw = gh pr list -R $Repo --state all --limit 1000 --search "created:>=$dateShort" --json state | ConvertFrom-Json
    $issuesRaw = gh issue list -R $Repo --state closed --limit 1000 --search "closed:>=$dateShort" --json number | ConvertFrom-Json

    # Releases
    $releaseData = @(gh api repos/$Repo/releases --paginate --jq ".[] | {pub: .published_at, tag: .tag_name, name: .name}") | ConvertFrom-Json
    $newReleases = 0; $latestTag = "N/A"; $latestDateStr = ""
    if ($releaseData) {
        $newReleases = ($releaseData | Where-Object { [DateTime]$_.pub -gt $limitDate }).Count
        $latestTag = $releaseData[0].tag
        $latestDateStr = "($([DateTime]$releaseData[0].pub | Get-Date -Format 'MMM dd, yyyy'))"
    }

    $highlightBlock = if (-not [string]::IsNullOrWhiteSpace($Highlight)) { "`n**Highlight of the Year:**`n✨ $Highlight ✨`n" } else { "" }

    $msg = @"
@everyone 

🚀 **$repoName - A Year of Growth & Improvements!** 🎉
$highlightBlock
Hey everyone! **$repoName** is now about **$ageText** old.
Here's a quick look at what we've achieved together over the last 12 months:

🔧 **Development Progress:**
- **$($commits.ToString("N0"))** commits 
- **$(@($prsRaw).Count)** pull requests 
- **$(@($issuesRaw).Count)** issues closed 

🚀 **Releases & Updates:**
- **$newReleases** new versions - The latest being **$latestTag** $latestDateStr

🌟 **Community Growth:**
- **$starsCount** new stars - Thanks for the love!
- **$($repoDetails.forks)** total forks

I couldn't have done this without you! Thank you for your contributions, feedback, and support.

*Merry Christmas and a Happy New Year to you all!* 🎆
*Let's make next year even better!* 🥂

*Cheers*
"@

    Write-Host "✅ Done! Copy the text below for Discord:" -ForegroundColor Green
    Write-Host "--------------------------------------------------"
    $msg
    $msg | Set-Clipboard
    Write-Host "`n(Text has also been copied to your clipboard!)" -ForegroundColor Gray
}
