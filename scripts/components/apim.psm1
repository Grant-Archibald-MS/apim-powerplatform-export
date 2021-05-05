<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		apim.ps1

		Purpose:	Configure and deploy azure APIM Management

		Version: 	0.1.0
		==============================================================================================

	.SYNOPSIS
        Define and provision APIM Management
        
    .DESCRIPTION
        Sample script to provision Azure Azure API Management
#>
using module '..\config.psm1'

class APIM {
    [Config]$Config

    APIM([Config] $config){
        $this.Config = $config
    }

    [string] Create($resources) {
        $apimMatch = $resources.Where({ $_.type -eq "Microsoft.ApiManagement/service"})

        $apiName = ""
        Switch ($apimMatch.Count) { 
            0 { 
                $name = (New-Guid).Guid.Replace("-", "").Substring(0, 23)
                $apiName = "A${name}"
                Write-Host "Creating API Management"
                az apim create --name $apiName --publisher-email $this.Config.APIMPublisherEmail --publisher-name $this.Config.APIMPublisherName --sku-name $this.Config.apiSku --resource-group $this.Config.resourceGroup
            }
            1 { 
                $apiName = $apimMatch[0].name
            }
        }

        return $apiName
    }

    [string] ExportSwagger() {
        Write-Host "Searching for APIM"
        
        $apim = (az apim list -g $this.Config.resourceGroup | ConvertFrom-Json)

        if ( $apim.count -eq 1 ) {
            Write-Host "Found APIM"
            $serviceName = $apim[0].name

            Write-Host "Searching for API"
            $apis = (az apim api list --resource-group $this.Config.resourceGroup --service-name $serviceName | ConvertFrom-Json)

            $match = $apis.Where({ $_.name -eq $this.Config.apiToExport })

            if ($match.count -eq 1) {
                Write-Host "Found api"

                $token = (az account get-access-token --resource="https://management.azure.com" --query accessToken --output tsv)
                $headers = @{
                    "Authorization" = "Bearer $token"
                    "Content-Type" = "application/json"
                }

                $apiId = $match[0].id
                $url = [Uri]"https://management.azure.com${apiId}?format=swagger-link&export=true&api-version=2021-01-01-preview"

                $apiDefinition = (Invoke-RestMethod -Method GET -Uri $url -Header $headers)
                $downloadUrl = [Uri]$apiDefinition.value.link

                $swagger = (Invoke-WebRequest -Uri $downloadUrl -Method GET)

                return $swagger

            } else {
                $apiName = $this.Config.apiToExport
                $apiCount = $apis.count
                Write-Host $match | ConvertTo-Json
                Write-Host "Unable to find api $apiName from api with $apiCount apis"
            }
        } else {
            $apiCount = $apim.count 
            Write-Host "Found $apiCount APIM instances, searching for single"
        }
        return ""
    }
}

Function New-APIManagement {
    Param(
        [Config]$config
    )
    return [APIM]::new($config)
}

Export-ModuleMember -Function New-APIManagement