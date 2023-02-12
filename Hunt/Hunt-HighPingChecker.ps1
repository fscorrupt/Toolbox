$ProgressPreference = 'SilentlyContinue'
$whoisDownload = "https://download.sysinternals.com/files/WhoIs.zip"

###############################################
# You can Edit those Lines to fit your needs! #
###############################################
$whoispath = "C:\temp\whois"
$ExeToMonitor = "HuntGame.exe"
# For Hunt it could be '61068/61088/61089' - thats why im looking for port '610xx'.
$PortToMonitor = "610"
$MaxPing = '100'
$Buffersize = '1024'
########################################################
# Only Edit below this, if you know what you are doing #
########################################################

# Getting Exe
Write-Host "Check for $ExeToMonitor process..." -ForegroundColor Cyan
$id = (Get-Process $ExeToMonitor.split('.')[0] -ErrorAction SilentlyContinue).id

if ($id) {
    Write-Host "    Found " -NoNewline  -ForegroundColor Yellow
    Write-Host "$ExeToMonitor " -NoNewline -ForegroundColor Green
    Write-Host "with PID: " -NoNewline  -ForegroundColor Yellow
    Write-Host "$id" -ForegroundColor Green
    Write-Host "Running netstat and selecting the ip connected to port beginning with: " -NoNewline -ForegroundColor Cyan
    Write-Host "$PortToMonitor" -ForegroundColor Green
    $netstatdata = netstat -ano 
    $Selectpid = $netstatdata | Select-String -Pattern $id 
    $IP = $Selectpid | Select-String -Pattern ":$PortToMonitor"
    if ($IP) {
        $Temp = $ip.line.replace(' ', '|').Replace('|||||', '|').Replace('||||', '|').Replace('||TCP', '').split('|')[2].Split(':')
        $ip = $Temp[0]
        $Port = $Temp[1]
        Write-Host "    Found IP: " -NoNewline -ForegroundColor Yellow  
        Write-Host "$ip " -NoNewline  -ForegroundColor Green
        Write-Host "with Port: " -NoNewline -ForegroundColor Yellow
        Write-Host "$Port" -NoNewline -ForegroundColor Green
        Write-Host ", via netstat" -ForegroundColor Yellow
        Write-Host "Starting tracert now..."-ForegroundColor Cyan

        $routes = (Test-NetConnection $ip -TraceRoute).TraceRoute
        Write-Host "    Tracert finished..."-ForegroundColor Yellow

        # Test if file is already present
        if (!(Test-Path $whoispath\whois64.exe)) {
            Write-Host "Starting download of WhoIs.zip (Sysinternal Tool)..." -ForegroundColor Cyan
            # Download WhoIs
            if (!(Test-Path $whoispath )){New-Item $whoispath -ItemType Directory | Out-Null}
            Invoke-WebRequest $whoisDownload -Method Get -OutFile "$whoispath.zip"
            if (Test-Path "$whoispath.zip") {
                Write-Host "    Successfully downloaded " -NoNewline -ForegroundColor Green
                Write-Host "whois.zip" -ForegroundColor Yellow
                Write-Host "Extracting zip here: " -NoNewline -ForegroundColor Cyan
                Write-Host "$whoispath" -ForegroundColor Yellow
                # Unzip WhoIs
                Expand-Archive "$whoispath.zip" "$whoispath"
                if (Test-Path $whoispath) {
                    Write-Host "    Successfully extracted " -NoNewline -ForegroundColor Green
                    Write-Host "whois.zip" -ForegroundColor Yellow
                    Write-Host "Removing zip file now" -ForegroundColor Cyan
                    # Remove Zip File
                    Remove-Item "$whoispath.zip" -Force -Confirm:$false
                    Write-Host "    Zip file removed" -ForegroundColor Green
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
                $test = Test-Connection $route -Count 6 -BufferSize $Buffersize  | select Address, ResponseTime
                $AveragePing = ($test.ResponseTime | Measure-Object -Average).Average
                $AveragePing = [MATH]::Round($AveragePing,2)
                if ($AveragePing -gt $MaxPing) {
                    Write-Host ""
                    Write-Host "#######################################################"
                    Write-Host "IP: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$route" -NoNewline -ForegroundColor Green
                    Write-Host " has an average ping of: " -NoNewline -ForegroundColor Cyan
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
                    Write-Host "($AveragePing`ms) " -NoNewline -ForegroundColor Green
                    Write-Host "and below " -NoNewline  -ForegroundColor Yellow
                    Write-Host "$MaxPing`ms " -NoNewline -ForegroundColor Green
                    Write-Host "for IP: " -NoNewline  -ForegroundColor Yellow
                    Write-Host "$route" -NoNewline -ForegroundColor Green
                    Write-Host ", no further action needed."  -ForegroundColor Yellow
                }
            }
        }
    }
    Else {
        Write-Host "    Could not find IP with Port: " -NoNewline -ForegroundColor Red
        Write-Host "$Port" -ForegroundColor Yellow
    }
}
Else {
    Write-Host "    Please start $ExeToMonitor before you run this script..." -ForegroundColor Red
}

pause
