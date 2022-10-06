function get_os_bit()
{
		return (Get-WmiObject Win32_OperatingSystem).OSArchitecture
}

function get_install_path()
{
		if ($os_bit -eq "32-bit")
		{
				return (Get-ItemProperty HKLM:\SOFTWARE\Npcap -ErrorAction SilentlyContinue).'(default)'
		}
		else
		{
				return (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Npcap -ErrorAction SilentlyContinue).'(default)'
		}
}

$os_bit = get_os_bit
$install_path = get_install_path
$Service = (Get-Service npcap -ErrorAction SilentlyContinue).Status

$Path = $install_path + "\NPFInstall.exe"
if (Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue){$FileVersion = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($Path).FileVersion) }
if ($Service -and $FileVersion -eq '1.00'){Write-Host "NPCAP Install Path: '$install_path' | Service State: $Service | NPFInstall.exe File Version: $FileVersion"}
Else {Write-Host "Could not Detect NPCAP..." -ForegroundColor Red} 
pause
