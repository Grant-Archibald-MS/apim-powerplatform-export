<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		keyvault.ps1

		Purpose:	Configure and manage key vault

		Version: 	0.1.0
		==============================================================================================

	.SYNOPSIS
        Define and provision APIM Management
        
    .DESCRIPTION
        Sample script to provision Azure Azure API Management
#>
using module '..\config.psm1'

class KeyVault {
    [Config]$Config

    KeyVault([Config] $config) {
        $this.Config = $config
    }

    [string] CreateIfNotExists() {
        $resources = (az resource list --resource-group $this.Config.resourceGroup | ConvertFrom-Json)
        return $this.CreateIfNotExists( $resources )
    }

    [string] CreateIfNotExists([Object[]] $resources) {
        $match = $resources.Where({ $_.type -eq "Microsoft.KeyVault/vaults" })
        $group = $this.Config.resourceGroup
        
        if ( -not ( $NULL -eq $this.Config.keyVault ) ) {
            
            $groupResources = $resources
            if (-not [string]::IsNullOrEmpty($this.Config.keyVault.resourceGroup)) {
                Write-Debug "Loading Key Vault resources"
                $group = $this.Config.keyVault.resourceGroup
                $groupResources = (az resource list --resource-group $group | ConvertFrom-Json)
            }
            $match = $groupResources.Where({ $_.type -eq "Microsoft.KeyVault/vaults" -and $_.id -eq $this.Config.keyVault.id -or ($_.name -eq $this.Config.keyVault.name -and $_.resourceGroup -eq $this.Config.keyVault.resourceGroup) })            
        }

        $name = ""
        Switch ($match.count) { 
            0 { 
                $id = (New-Guid).Guid.Replace("-", "").Substring(0, 23)
                $name = "K${id}"
                Write-Host "Creating Key Vault"
                az keyvault create --resource-group $group --name $name
            }
            1 { 
                Write-Host "Found KeyVault"
                $name = $match[0].name
            }
        }

        return $name
    }
}

Function New-KeyVaultManagement {
    Param(
        [Config]$config
    )
    return [KeyVault]::new($config)
}

Export-ModuleMember -Function New-KeyVaultManagement