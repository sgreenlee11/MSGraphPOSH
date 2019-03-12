function Get-AADToken
{
	param(
		[String[]]$Scopes,
		$ClientID,
		#$MSALPath,
		$AppName,
		$UserName,
		$Credential,
		$ClientSecret,
		$RedirectUri,
		$TenantID,
		$Resource
	)
	#Load MSAL DLL
	#Add-Type -Path $msalpath
	#Use Organizations endpoint when sending credentials as part of request, otherwise common
	If($username -or $Credential)
	{
		[uri]$authority = "https://login.microsoftonline.com/organizations/oauth2/authorize"
	}
	ElseIf($ClientSecret)
	{
		[uri]$authority = "https://login.microsoftonline.com/" + $TenantID

	}
	else
	{
		[uri]$authority = "https://login.microsoftonline.com/common/oauth2/authorize"
	}
	if($ClientSecret)
	{
		
		$clientcred = [Microsoft.Identity.Client.ClientCredential]::new($ClientSecret)
		$clientapp = [Microsoft.Identity.Client.ConfidentialClientApplication]::new($clientid,$authority,$RedirectUri,$clientcred,$null,$null)
		Write-Warning "Changing scope to https://graph.microsoft.com/.default for Client Credentials Flow. Will not work for other APIs"
		if($Resource)
		{
			$scopes = $resource + "/.default"
		}
		else{
			Write-Warning "Changing scope to https://graph.microsoft.com/.default for Client Credentials Flow. Will not work for other APIs. Use Resource Parameter if not using Graph"
			$scopes = "https://graph.microsoft.com/.default"
		}

	}
	else{
		$clientapp = [Microsoft.Identity.Client.PublicClientApplication]::new($clientid,$authority)
	}
	#Build scopes array
	$appscopes = New-Object System.Collections.ObjectModel.Collection["string"]
	foreach($s in $scopes)
	{
		$appscopes.Add($s)
	}
	#If Username parameter is specified, use WIA authentication with logged on account
	If($username)
	{
		$authresult = $clientapp.AcquireTokenByIntegratedWindowsAuthAsync($appscopes,$username)
	}
	elseif ($Credential) {
		$authresult = $clientapp.AcquireTokenByUsernamePasswordAsync($appscopes,$Credential.Username,(ConvertTo-SecureString ($Credential.GetNetworkCredential().Password) -AsPlainText -Force))
	}
	elseif($ClientSecret)
	{
		$authresult = $clientapp.AcquireTokenForClientAsync($appscopes)
	}
	else{
		$authresult = $clientapp.AcquireTokenAsync($appscopes)
	}
	
	return $authresult.Result

	
}
