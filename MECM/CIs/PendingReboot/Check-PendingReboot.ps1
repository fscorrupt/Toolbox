function TestPendingReboot {
	[CmdletBinding()]
	param(
		[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('CN', 'Computer')]
		[String[]]
		$ComputerName = $env:COMPUTERNAME,

		[Parameter()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.CredentialAttribute()]
		$Credential,

		[Parameter()]
		[Switch]
		$Detailed,

		[Parameter()]
		[Switch]
		$SkipConfigurationManagerClientCheck,

		[Parameter()]
		[Switch]
		$SkipPendingFileRenameOperationsCheck
	)

	process
	{
		foreach ($computer in $ComputerName)
		{
			try
			{
				$invokeWmiMethodParameters = @{
					Namespace    = 'root/default'
					Class        = 'StdRegProv'
					Name         = 'EnumKey'
					ComputerName = $computer
					ErrorAction  = 'Stop'
				}

				$hklm = [UInt32] '0x80000002'

				if ($PSBoundParameters.ContainsKey('Credential'))
				{
					$invokeWmiMethodParameters.Credential = $Credential
				}

				## Query the Component Based Servicing Reg Key
				$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\')
				$registryComponentBasedServicing = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootPending'

				## Query WUAU from the registry
				$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\')
				$registryWindowsUpdateAutoUpdate = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootRequired'

				## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
				$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Services\Netlogon')
				$registryNetlogon = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames
				$pendingDomainJoin = ($registryNetlogon -contains 'JoinDomain') -or ($registryNetlogon -contains 'AvoidSpnSet')

				## Query ComputerName and ActiveComputerName from the registry and setting the MethodName to GetMultiStringValue
				$invokeWmiMethodParameters.Name = 'GetMultiStringValue'
				$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\', 'ComputerName')
				$registryActiveComputerName = Invoke-WmiMethod @invokeWmiMethodParameters

				$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\', 'ComputerName')
				$registryComputerName = Invoke-WmiMethod @invokeWmiMethodParameters

				$pendingComputerRename = $registryActiveComputerName -ne $registryComputerName -or $pendingDomainJoin

				## Query PendingFileRenameOperations from the registry
				if (-not $PSBoundParameters.ContainsKey('SkipPendingFileRenameOperationsCheck'))
				{
					$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\Session Manager\', 'PendingFileRenameOperations')
					$registryPendingFileRenameOperations = (Invoke-WmiMethod @invokeWmiMethodParameters).sValue
					$registryPendingFileRenameOperationsBool = [bool]$registryPendingFileRenameOperations
				}

				## Query ClientSDK for pending reboot status, unless SkipConfigurationManagerClientCheck is present
				if (-not $PSBoundParameters.ContainsKey('SkipConfigurationManagerClientCheck'))
				{
					$invokeWmiMethodParameters.NameSpace = 'ROOT\ccm\ClientSDK'
					$invokeWmiMethodParameters.Class = 'CCM_ClientUtilities'
					$invokeWmiMethodParameters.Name = 'DetermineifRebootPending'
					$invokeWmiMethodParameters.Remove('ArgumentList')

					try
					{
						$sccmClientSDK = Invoke-WmiMethod @invokeWmiMethodParameters
						$systemCenterConfigManager = $sccmClientSDK.ReturnValue -eq 0 -and ($sccmClientSDK.IsHardRebootPending -or $sccmClientSDK.RebootPending)
					}
					catch
					{
						$systemCenterConfigManager = $null
						Write-Verbose -Message ($script:localizedData.invokeWmiClientSDKError -f $computer)
					}
				}

				$isRebootPending = $registryComponentBasedServicing -or `
				$pendingComputerRename -or `
				$pendingDomainJoin -or `
				$registryPendingFileRenameOperationsBool -or `
				$systemCenterConfigManager -or `
				$registryWindowsUpdateAutoUpdate

				if ($PSBoundParameters.ContainsKey('Detailed'))
				{
					[PSCustomObject]@{
						ComputerName                     = $computer
						ComponentBasedServicing          = $registryComponentBasedServicing
						PendingComputerRenameDomainJoin  = $pendingComputerRename
						PendingFileRenameOperations      = $registryPendingFileRenameOperationsBool
						PendingFileRenameOperationsValue = $registryPendingFileRenameOperations
						SystemCenterConfigManager        = $systemCenterConfigManager
						WindowsUpdateAutoUpdate          = $registryWindowsUpdateAutoUpdate
						IsRebootPending                  = $isRebootPending
					}
				}
				else
				{
					[PSCustomObject]@{
						ComputerName    = $computer
						IsRebootPending = $isRebootPending
					}
				}
			}

			catch
			{
				Write-Verbose "$computer`: $_"
			}
		}
	}
}
$GetRebootPending = (TestPendingReboot -SkipPendingFileRenameOperationsCheck).IsRebootPending

if ($GetRebootPending){
	$return =  "NotCompliant"
	$return
}
Else {
	$return =  "Compliant"
	$return
}
