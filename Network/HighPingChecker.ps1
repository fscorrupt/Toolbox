$ProgressPreference = 'SilentlyContinue'
$whoisDownload = "https://download.sysinternals.com/files/WhoIs.zip"

###############################################
# You can Edit those Lines to fit your needs! #
###############################################
$whoispath = "C:\temp\whois"
$ExeToMonitor = "MyExe.exe" 
$PortToMonitor = "11111"
$MaxPing = '100'
$PublicIp = Invoke-RestMethod http://ipinfo.io/json
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
    $IPv6 = $IP | Select-String -NotMatch -Pattern "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
    if ($IP) {
        if ($IPv6) {
            $Temp = $IPv6.line.replace('[','').replace(' ', '|').Replace('|||||', '|').Replace('||||', '|').Replace('||TCP', '').split('|')[1].Split(']')
            $ip = $Temp[0]
            $Port = $Temp[1].Replace(':','')
        }
        Else {
            $Temp = $ip.line.replace(' ', '|').Replace('|||||', '|').Replace('||||', '|').Replace('||TCP', '').split('|')[2].Split(':')
            $ip = $Temp[0]
            $Port = $Temp[1]
        }
        Write-Host "    Found IP: " -NoNewline -ForegroundColor Yellow  
        Write-Host "$ip " -NoNewline  -ForegroundColor Green
        Write-Host "with Port: " -NoNewline -ForegroundColor Yellow
        Write-Host "$Port" -NoNewline -ForegroundColor Green
        Write-Host ", via netstat" -ForegroundColor Yellow
        Write-Host "########################################################"
        Write-Host "Your External IP is: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($PublicIp.ip)" -ForegroundColor Yellow
        Write-Host "Your ISP is: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($PublicIp.org)" -ForegroundColor Yellow
        Write-Host "########################################################"   
        Write-Host "Starting tracert now..."-ForegroundColor Cyan

        $routes = (Test-NetConnection $ip -TraceRoute).TraceRoute
        Write-Host "    Tracert finished..."-ForegroundColor Yellow

        # Test if file is already present
        if (!(Test-Path $whoispath\whois64.exe)) {
            Write-Host "Starting download of WhoIs.zip (Sysinternal Tool)..." -ForegroundColor Cyan
            # Download WhoIs
            if (!(Test-Path $whoispath )){New-Item $whoispath -ItemType Directory | Out-Null}
            Invoke-WebRequest $whoisDownload -Method Get -OutFile "$whoispath\whois.zip"
            if (Test-Path "$whoispath\whois.zip") {
                Write-Host "    Successfully downloaded " -NoNewline -ForegroundColor Green
                Write-Host "whois.zip" -ForegroundColor Yellow
                Write-Host "Extracting zip here: " -NoNewline -ForegroundColor Cyan
                Write-Host "$whoispath" -ForegroundColor Yellow
                # Unzip WhoIs
                Expand-Archive "$whoispath\whois.zip" "$whoispath"
                if (Test-Path "$whoispath\whois64.exe") {
                    Write-Host "    Successfully extracted " -NoNewline -ForegroundColor Green
                    Write-Host "whois.zip" -ForegroundColor Yellow
                    Write-Host "Removing zip file now" -ForegroundColor Cyan
                    # Remove Zip File
                    Remove-Item "$whoispath\whois.zip" -Force -Confirm:$false
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
                try {
                    $test = (Test-Connection $route -Count 6 -BufferSize '1024' -ErrorAction SilentlyContinue).ResponseTime
                }
                catch {
                    Write-Host "Error occured using " -NoNewline -ForegroundColor Red
                    Write-Host "Test-Connection" -NoNewline -ForegroundColor Yellow
                    Write-Host "using " -NoNewline -ForegroundColor Red
                    Write-Host "Test-NetConnection " -NoNewline -ForegroundColor Yellow
                    Write-Host "instead." -ForegroundColor Red
                }
                if ($Error){
                    $test = (Test-NetConnection $route -Hops 6 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingReplyDetails.RoundtripTime
                    $resolveDNSName = (Resolve-DNSName $route).NameHost
                }
                if ($test.count -eq '1'){
                    $AveragePing = $test
                }
                Else {
                    $AveragePing = ($test | Measure-Object -Average).Average
                    $AveragePing = [MATH]::Round($AveragePing,2)
                    $resolveDNSName = (Resolve-DNSName $route).NameHost
                }
                
                if ($AveragePing -gt $MaxPing) {
                    Write-Host ""
                    Write-Host "    #######################################################"
                    Write-Host "    IP: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$route" -NoNewline -ForegroundColor Green
                    Write-Host " has an average ping of: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$($AveragePing)ms"-ForegroundColor red
                    Write-Host "    Getting WhoIs information for IP: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$route" -ForegroundColor Green
                    $GetWhoIs = (& "$whoispath\whois64.exe" /accepteula -v $route -nobanner | Select-String -Pattern 'Domain Name:')[0].ToString()
                    $DomainName = $GetWhoIs.Split(':').Replace(' ', '')[1].ToLower()
                    Write-Host "        Domain Name of " -NoNewline -ForegroundColor Yellow
                    Write-Host "$route " -NoNewline -ForegroundColor Green
                    Write-Host "is: " -NoNewline -ForegroundColor Yellow
                    Write-Host "$domainname" -ForegroundColor Green
                }
                Else {
                    Write-Host "    Ping is " -NoNewline -ForegroundColor Cyan
                    Write-Host "($AveragePing`ms) " -NoNewline -ForegroundColor Green
                    Write-Host "and below " -NoNewline -ForegroundColor Cyan
                    Write-Host "$MaxPing`ms " -NoNewline -ForegroundColor Green
                    Write-Host "for IP: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$route" -NoNewline -ForegroundColor Green
                    Write-Host ", no further action needed." -ForegroundColor Cyan
                    if ($resolveDNSName.count -eq 1){
                        Write-Host "        DNS Name is: " -NoNewline -ForegroundColor Yellow
                        Write-Host "$resolveDNSName"-ForegroundColor Green
                    }
                    if ($resolveDNSName.count -gt 1){
                        Write-Host "        Found multible DNS Names for IP: " -NoNewline -ForegroundColor Cyan
                        Write-Host "$route" -ForegroundColor Green
                        Write-Host "            DNS Names are:" -ForegroundColor Yellow
                        Foreach ($dnsname in $resolveDNSName){
                            Write-Host "            $resolveDNSName"-ForegroundColor Green
                        }
                    }
                    Write-Host ""
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
