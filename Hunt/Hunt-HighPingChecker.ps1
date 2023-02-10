$ProgressPreference = 'SilentlyContinue'
$whoisDownload = "https://download.sysinternals.com/files/WhoIs.zip"
$whoispath = "C:\temp\whois\whois64.exe"

# Getting Hunt Game Exe
Write-Host "Check for hunt process..." -ForegroundColor Cyan
$id = (Get-Process HuntGame -ErrorAction SilentlyContinue).id

if ($id) {
    Write-Host "Found 'HuntGame.exe' with PID: $id" -ForegroundColor Green
    Write-Host "Running netstat and select the ip connected to port:'61088'" -ForegroundColor Cyan
    $netstatdata = netstat -ano 
    $Selectpid = $netstatdata | Select-String -Pattern $id 
    $IP = $Selectpid | Select-String -Pattern ":61088"
    if ($IP) {
        $ip = $ip.line.replace(' ', '|').Replace('|||||', '|').Replace('||||', '|').Replace('||TCP', '').split('|')[2].Split(':')[0]

        Write-Host "Start tracert for IP: '$ip'" -ForegroundColor Cyan
        $routes = (Test-NetConnection $ip -TraceRoute).TraceRoute

        # Test if file is already present
        if (!(Test-Path $whoispath)) {
            Write-Host "Starting download of WhoIs.zip (Sysinternal Tool)..." -ForegroundColor Cyan
            # Download WhoIs
            Invoke-WebRequest $whoisDownload -Method Get -OutFile "C:\temp\whois.zip"
            if (Test-Path "C:\temp\whois.zip") {
                Write-Host "Successfully downloaded whois.zip" -ForegroundColor Green
                Write-Host "Extracting zip here: 'C:\temp\whois'" -ForegroundColor Cyan
                # Unzip WhoIs
                Expand-Archive "C:\temp\whois.zip" "C:\temp\whois"
                if (Test-Path $whoispath) {
                    Write-Host "Successfully extracted whois.zip" -ForegroundColor Green
                }
                Else {
                    Write-Host "Error during extraction, exiting script now..." -ForegroundColor Red
                    exit
                }
            }
            Else {
                Write-Host "Error while downloading, exiting script now..." -ForegroundColor Red
                exit
            }
        }
    
        Write-Host "Starting Ping measurement..." -ForegroundColor Cyan
        foreach ($route in $routes) {
            if ($route -ne '0.0.0.0') {
                $test = Test-Connection $route -Count 6 -BufferSize 1024  | select Address, ResponseTime
                $AveragePing = ($test.ResponseTime | Measure-Object -Average).Average
                if ($AveragePing -gt '100') {
                    Write-Host ""
                    Write-Host "#######################################################"
                    Write-Host "IP: '$route' has an Average ping from: '$($AveragePing)'" -ForegroundColor Yellow
                    Write-Host "Getting WhoIs information for IP: '$route'" -ForegroundColor Cyan
                    Write-Host ""
                    $GetWhoIs = (& $whoispath /accepteula -v $route -nobanner | Select-String -Pattern 'Domain Name:')[0].ToString()
                    $DomainName = $GetWhoIs.Split(':').Replace(' ', '')[1].ToLower()
                    Write-Host "Domain Name of '$route' is: $domainname" -ForegroundColor Yellow
                }
                Else {
                    Write-Host "Ping is below 100ms for IP: '$route', no further action needed." -ForegroundColor Green
                }
            }
        }
    }
    Else {
        Write-Host "Could not find IP with Port: '61088'" -ForegroundColor Red
    }
}
Else {
    Write-Host "Please start hunt and load into a game before you run this script..." -ForegroundColor Red
}
