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

    [ConfigResource] CreateIfNotExists() {
        $resources = (az resource list --resource-group $this.Config.resourceGroup | ConvertFrom-Json)
        return $this.CreateIfNotExists( $resources )
    }

    [ConfigResource] CreateIfNotExists([Object[]] $resources) {
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
        $keyVault = $NULL
        Switch ($match.count) { 
            0 { 
                $id = (New-Guid).Guid.Replace("-", "").Substring(0, 23)
                $name = "K${id}"
                Write-Host "Creating Key Vault"
                $keyVault = (az keyvault create --resource-group $group --name $name | ConvertFrom-Json)
            }
            1 { 
                Write-Host "Found KeyVault"
                $keyVault = $match[0]
            }
        }

        $result = $NULL
        if ( -not $NULL -eq $keyVault ) {
            if ( $NULL -eq $this.Config.keyVault ) {
                $this.Config.keyVault = [ConfigResource]::new()
            }
            $this.Config.keyVault.id = $keyVault.id
            $this.Config.keyVault.name = $keyVault.name
            $this.Config.keyVault.resourceGroup = $keyVault.resourceGroup
            $result = $this.Config.keyVault
        }

        return $result
    }

    [ConfigResource] Exists() {
        $group = $this.Config.resourceGroup      
        if ( -not ( $NULL -eq $this.Config.keyVault ) ) {
            if (-not [string]::IsNullOrEmpty($this.Config.keyVault.resourceGroup)) {
                $group = $this.Config.keyVault.resourceGroup
            }
            $groupResources = (az resource list --resource-group $group | ConvertFrom-Json)
            $match = $groupResources.Where({ $_.type -eq "Microsoft.KeyVault/vaults" -and $_.id -eq $this.Config.keyVault.id -or ($_.name -eq $this.Config.keyVault.name -and $_.resourceGroup -eq $this.Config.keyVault.resourceGroup) })            
        } else {
            $groupResources = (az resource list --resource-group $group | ConvertFrom-Json)
            $match = $groupResources.Where({ $_.type -eq "Microsoft.KeyVault/vaults" })           
        }

        Switch ($match.count) {
            0 { 
                return [ConfigResource]$NULL
            }
            1 { 
                $result = [ConfigResource]::new()
                $result.id = $match.id
                $result.name = $match.name
                $result.resourceGroup = $match.resourceGroup
                return $result
            }
        }

        return [ConfigResource]$NULL
    }

    AddSecret([ConfigResource] $instance, [string] $name, [string] $value) {
        if ($NULL -eq $instance) {
            throw "KeyVault instance not set. Check it exists"
        }
        az keyvault secret set --vault-name $instance.name --name $name --value $value
    }

    [SecureString] GetSecureSecret([ConfigResource] $instance, [string] $name) {
        if ($NULL -eq $instance) {
            throw "KeyVault instance not set. Check it exists"
        }
        return (az keyvault secret show --name $name --vault-name $instance.name --query "value" | ConvertFrom-Json | ConvertTo-SecureString -AsPlainText -Force)
    }
}

Function New-KeyVaultManagement {
    Param(
        [Config]$config
    )
    return [KeyVault]::new($config)
}

Export-ModuleMember -Function New-KeyVaultManagement