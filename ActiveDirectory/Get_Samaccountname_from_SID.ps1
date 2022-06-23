$cSID = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value
Write-Host "SID of current user ($env:USERNAME) is: " -NoNewline 
Write-Host $cSID -ForegroundColor Cyan
Write-Host ''
Write-Host "Enter SID (to get sammacountname): " -NoNewline -ForegroundColor Yellow

$sid= Read-Host 
Write-Host ''

$User = $([adsi]"LDAP://<SID=$sid>").samaccountname
Write-Host "Username is: " -NoNewline
Write-Host $User -ForegroundColor Cyan
