$OnPremUsers = Get-Mailbox -ResultSize unlimited

# O365 credentials  
$adminUPN = 'user@contoso.com'

$objTemplate = '' | Select-Object -Property User, Calender, Permission
$OnPremobjResult = @()
$OnLineobjResult = @()

foreach ($Onpremuser in $OnPremUsers){
		$objTemp = $objTemplate | Select-Object *
		$alias = $Onpremuser.Alias
		$Name = (Get-MailboxFolderStatistics -Identity $alias -FolderScope Calendar -ErrorAction SilentlyContinue | select -First 1).Name
		$FolderName = $alias+":\"+$Name
		$Permission = Get-MailboxFolderPermission -Identity $FolderName -ErrorAction SilentlyContinue | where {$_.User -match "Default"} | select FolderName,User,@{N="AccessRights";E={$_.AccessRights -join ','}}
		if ($Permission.AccessRights -ne 'LimitedDetails'){
				#Set-MailboxFolderPermission -Identity $FolderName -User Default -AccessRights LimitedDetails
				$objTemp.User = $alias
				$objTemp.Calender = $Permission.FolderName
				$objTemp.Permission = $Permission.AccessRights
				$OnPremobjResult += $objTemp
		}
}
$OnPremobjResult | Export-Csv -Path C:\temp\CalenderPermissionReport_OnPrem.csv

Connect-ExchangeOnline -UserPrincipalName $adminUPN -ShowBanner:$false
$OnlineUsers = Get-Mailbox -ResultSize unlimited

foreach ($Onlineuser in $OnlineUsers){
		$objTemp = $objTemplate | Select-Object *
		$alias = $Onlineuser.Alias
		$Name = (Get-MailboxFolderStatistics -Identity $alias -FolderScope Calendar -ErrorAction SilentlyContinue | select -First 1).Name
		$FolderName = $alias+":\"+$Name
		$Permission = Get-MailboxFolderPermission -Identity $FolderName -ErrorAction SilentlyContinue | where {$_.User -match "Default"} | select FolderName,User,@{name="AccessRights";expression={ [string]::join(",",@($_.accessrights)) }}
		if ($Permission.AccessRights -ne 'LimitedDetails'){
				#Set-MailboxFolderPermission -Identity $FolderName -User Default -AccessRights LimitedDetails
				$objTemp.User = $alias
				$objTemp.Calender = $Permission.FolderName
				$objTemp.Permission = $Permission.AccessRights
				$OnLineobjResult += $objTemp
		}
}

$OnLineobjResult | Export-Csv -Path C:\temp\CalenderPermissionReport_OnLine.csv