$ProgressPreference = 'SilentlyContinue'
$whoisDownload = "https://download.sysinternals.com/files/WhoIs.zip"
$whoispath = "C:\temp\whois\whois64.exe"

# Getting Hunt Game Exe
Write-Host "Check for hunt process..." -ForegroundColor Cyan
$id = (Get-Process HuntGame -ErrorAction SilentlyContinue).id

if ($id) {
    Write-Host "    Found " -NoNewline  -ForegroundColor Yellow
    Write-Host "HuntGame.exe " -NoNewline -ForegroundColor Green
    Write-Host "with PID: " -NoNewline  -ForegroundColor Yellow
    Write-Host "$id" -ForegroundColor Green
    Write-Host "Running netstat and selecting the ip connected to port: " -NoNewline -ForegroundColor Cyan
    Write-Host "610xx" -ForegroundColor Green
    $netstatdata = netstat -ano 
    $Selectpid = $netstatdata | Select-String -Pattern $id 
    $IP = $Selectpid | Select-String -Pattern ":610"
    if ($IP) {
        $Temp = $ip.line.replace(' ', '|').Replace('|||||', '|').Replace('||||', '|').Replace('||TCP', '').split('|')[2].Split(':')
        $ip = $Temp[0]
        $Port = $Temp[1]
        Write-Host "Found IP: " -NoNewline -ForegroundColor Cyan
        Write-Host "$ip " -NoNewline  -ForegroundColor Green
        Write-Host "with Port: " -NoNewline -ForegroundColor Cyan
        Write-Host "$Port" -NoNewline -ForegroundColor Green
        Write-Host ", via netstat" -ForegroundColor Cyan
        Write-Host "Starting tracert now..."-ForegroundColor Cyan

        $routes = (Test-NetConnection $ip -TraceRoute).TraceRoute

        # Test if file is already present
        if (!(Test-Path $whoispath)) {
            Write-Host "Starting download of WhoIs.zip (Sysinternal Tool)..." -ForegroundColor Cyan
            # Download WhoIs
            Invoke-WebRequest $whoisDownload -Method Get -OutFile "C:\temp\whois.zip"
            if (Test-Path "C:\temp\whois.zip") {
                Write-Host "    Successfully downloaded whois.zip" -ForegroundColor Green
                Write-Host "Extracting zip here: 'C:\temp\whois'" -ForegroundColor Cyan
                # Unzip WhoIs
                Expand-Archive "C:\temp\whois.zip" "C:\temp\whois"
                if (Test-Path $whoispath) {
                    Write-Host "    Successfully extracted whois.zip" -ForegroundColor Green
                    Remove-Item "C:\temp\whois.zip" -Force -Confirm:$false
                }
                Else {
                    Write-Host "    Error during extraction, exiting script now..." -ForegroundColor Red
                    exit
                }
            }
            Else {
                Write-Host "    Error while downloading, exiting script now..." -ForegroundColor Red
                exit
            }
        }
    
        Write-Host "Starting Ping measurement..." -ForegroundColor Cyan
        foreach ($route in $routes) {
            if ($route -ne '0.0.0.0') {
                $test = Test-Connection $route -Count 6 -BufferSize 1024  | select Address, ResponseTime
                $AveragePing = ($test.ResponseTime | Measure-Object -Average).Average
                $AveragePing = [MATH]::Round($AveragePing,2)
                if ($AveragePing -gt '100') {
                    Write-Host ""
                    Write-Host "#######################################################"
                    Write-Host "IP: " -NoNewline
                    Write-Host "$route" -NoNewline -ForegroundColor Cyan
                    Write-Host " has an average ping of: " -NoNewline
                    Write-Host "$($AveragePing)ms"-ForegroundColor red
                    Write-Host "Getting WhoIs information for IP: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$route" -ForegroundColor Green
                    $GetWhoIs = (& $whoispath /accepteula -v $route -nobanner | Select-String -Pattern 'Domain Name:')[0].ToString()
                    $DomainName = $GetWhoIs.Split(':').Replace(' ', '')[1].ToLower()
                    Write-Host "    Domain Name of " -NoNewline -ForegroundColor Yellow
                    Write-Host "$route " -NoNewline -ForegroundColor Green
                    Write-Host "is: " -NoNewline -ForegroundColor Yellow
                    Write-Host "$domainname" -ForegroundColor Green
                }
                Else {
                    Write-Host "    Ping is " -NoNewline  -ForegroundColor Yellow
                    Write-Host "($($AveragePing)ms) " -NoNewline -ForegroundColor Green
                    Write-Host "and below " -NoNewline  -ForegroundColor Yellow
                    Write-Host "100ms " -NoNewline -ForegroundColor Green
                    Write-Host "for IP: " -NoNewline  -ForegroundColor Yellow
                    Write-Host "$route" -NoNewline -ForegroundColor Green
                    Write-Host ", no further action needed."  -ForegroundColor Yellow
                }
            }
        }
    }
    Else {
        Write-Host "    Could not find IP with Port: " -NoNewline -ForegroundColor Red
        Write-Host "61088" -ForegroundColor Yellow
    }
}
Else {
    Write-Host "    Please start hunt and load into a game before you run this script..." -ForegroundColor Red
}
