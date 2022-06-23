$adusers=Get-ADUser -Properties * -Filter  {Enabled -eq $false -and thumbnailphoto -like '*' }
foreach ($user in $adusers)
{
	Set-ADUser $User -Clear thumbnailPhoto -ErrorAction SilentlyContinue -ErrorVariable SetError 
	if($SetError){Write-Host "Access denied on: $($user.samaccountname)"}
}

