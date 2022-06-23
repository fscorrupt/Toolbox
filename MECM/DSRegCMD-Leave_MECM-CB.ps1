$Pattern = 'Third party updates workload not enabled for ConfigMgr. Deployment/Installation of software updates is disabled.'
$pattern2 = 'This device is enrolled to an unexpected vendor, it will be set in co-existence mode.'
$LogContent = 'C:\Windows\CCM\Logs\UpdatesDeployment.log'
$RegPath = 'HKLM:\SOFTWARE\DsRegLeave'

$WorloadsDisabled = select-string -Path $LogContent -Pattern $Pattern -ErrorAction SilentlyContinue | select -last 1
$CoExistenceMode = select-string -Path $LogContent -Pattern $Pattern2 -ErrorAction SilentlyContinue | select -last 1
$DSRegcmdLeave = if((Get-ItemProperty -path $RegPath -Name DSRegcmdLeave -ea SilentlyContinue).DSRegcmdLeave -eq 'OK') { $true } else { $false }

if(!($WorloadsDisabled) -and !($CoExistenceMode)){
	$DSRegcmdLeave = $true
}

Else {
	if(!$DSRegcmdLeave){
		if (!(Test-Path $RegPath)){
				New-Item -path $RegPath -Name 'DsRegLeave' -ErrorAction SilentlyContinue
		}
		if ($WorloadsDisabled -or $CoExistenceMode){
				dsregcmd /debug /leave
				New-ItemProperty -Path $RegPath -Name 'DSRegcmdLeave' -Value 'OK' -PropertyType "String" -ErrorAction SilentlyContinue
				$DSRegcmdLeave = $true
		}	
	}
}
if($DSRegcmdLeave){Write-Host 'Installed'}