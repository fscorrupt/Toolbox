$users = get-aduser -Filter * -Properties c,co,countrycode,preferredLanguage
foreach ($user in $users){
	$Country = switch ($user.c){
		'AT' {'40','Austria','de-AT'}
		'AE' {'784','United Arab Emirates','ar-AE'}
		'BA' {'70','Bosnia and Herzegovina','hr-HR'}
		'BE' {'56','Belgium','nl-BE'}
		'BG' {'100','Bulgaria','bg-BG'}
		'BY' {'112','Belarus','be-BY'}
		'CH' {'756','Switzerland','de-CH'}
		'CN' {'156','China','zh-CN'}
		'CZ' {'203','Czech Republic','cs-CZ'}
		'DE' {'276','Germany','de-DE'}
		'DZ' {'12','Algeria','ar-DZ'}
		'ES' {'724','Spain','es-ES'}
		'FR' {'250','France','fr-FR'}
		'GB' {'826','United Kingdom','en-GB'}
		'HR' {'191','Croatia','hr-HR'}
		'HU' {'348','Hungary','hu-HU'}
		'IT' {'380','Italy','it-IT'}
		'LT' {'440','Lithuania','lt-LT'}
		'NL' {'528','Netherlands','nl-NL'}
		'PL' {'616','Poland','pl-PL'}
		'RO' {'642','Romania','ro-RO'}
		'RS' {'688','Serbia','Lt-sr-SP'}
		'RU' {'643','Russia','ru-RU'}
		'SG' {'702','Singapore','zh-SG'}
		'SI' {'705','Slovenia','sl-SI'}
		'SK' {'703','Slovakia','sk-SK'}
		'TR' {'792','Turkey','tr-TR'}
		'UA' {'804','Ukraine','uk-UA'}
		default {'empty'}
	}
	if ($country -ne 'empty'){
		$UserParams = @{
				c = $($user.c)
				co = $Country[1]
				countrycode = $Country[0]
				preferredLanguage = $Country[2]
		}
		$user | Set-ADUser -replace $UserParams
	}
}