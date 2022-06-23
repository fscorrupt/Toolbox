Import-Module grouppolicy 
$date = get-date -format dd.MM.yyyy
$Path = "C:\GPO_Backup\$date"
New-Item -Path $Path -ItemType directory -Force
Backup-Gpo -All -Path $Path\ -Confirm:$false