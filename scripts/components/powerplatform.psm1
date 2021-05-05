<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		powerplaform.ps1

		Purpose:	Configure and deploy Power Platform resources

		Version: 	0.1.0
		==============================================================================================

	.SYNOPSIS
        Configure and deploy Power Platform resources
        
    .DESCRIPTION
        Sample script to provision Power Platform connectors
#>
using module '..\config.psm1'

class PowerPlatform {
    [Config]$Config

    PowerPlatform([Config] $config){
        $this.Config = $config
    }

    [string] Login() {
        $resourceName = $this.Config.powerPlatformEnvironment
        $tenantId = $this.Config.powerPlatformTenantId
        $clientId = $this.Config.powerPlatformClientId
        $clientSecret = $this.Config

        $body = @{grant_type="client_credentials";resource=$resourceName;client_id=$ClientID;client_secret=$clientSecret}
        
        $loginURL = 'https://login.windows.net'

        $url = [Uri]"$loginURL/$tenantId/oauth2/token?api-version=1.0"

        $result = (Invoke-RestMethod -Method Post -Uri $url -Body $body)

        return $result.access_token
    }

    ImportConnector([string] $accessToken, [string]$swagger) {
        $headers = @{
            "Authorization" = "Bearer $accessToken"
            "OData-Version" = "4.0"
            "Content-Type" = "application/json"
        }

        # https://docs.microsoft.com/en-us/dynamics365/customer-engagement/web-api/connector?view=dynamics-ce-odata-9

        $swaggerData = ($swagger | ConvertFrom-Json)

        $displayName = $swaggerData.info.title -replace " ", "" 

        #TODO - Add to a solution
        $name = "new_5F" + $displayName.ToLower()

        $body = @{
            "name" = $name
            "displayname" = $displayName
            "connectortype" = 1
            "openapidefinition" = $swagger
        }

        $json = ($body | ConvertTo-Json)

        $Failure = $NULL

        $url = $this.Config.powerPlatformEnvironment
        if ( !$url.endsWith("/") ) {
            $url += "/"
        }
        $url += "api/data/v9.0/connectors"

        $url = [Uri]$url

        $resp = try { Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body $json } catch { $Failure = $_.Exception.Response }

        Write-Host $resp
        Write-Host $Failure
    }
}

Function New-PowerPlatformManagement {
    Param(
        [Config]$config
    )
    return [PowerPlatform]::new($config)
}

Export-ModuleMember -Function New-PowerPlatformManagement
