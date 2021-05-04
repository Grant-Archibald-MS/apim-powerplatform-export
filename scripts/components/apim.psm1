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

class APIM {
    [string] Create($resources, $config) {
        $apimMatch = $resources.Where({ $_.type -eq "Microsoft.ApiManagement/service"})

        $apiName = ""
        Switch ($apimMatch.Count) { 
            0 { 
                $name = (New-Guid).Guid.Replace("-", "").Substring(0, 23)
                $apiName = "A${name}"
                Write-Host "Creating API Management"
                az apim create --name $apiName --publisher-email $config.APIMPublisherEmail --publisher-name $config.APIMPublisherName --sku-name $config.apiSku --resource-group $config.resourceGroup
            }
            1 { 
                $apiName = $apimMatch[0].name
            }
        }

        return $apiName
    }

    [string] ExportSwagger($config) {
        Write-Host "Searching for APIM"
        
        $apim = (az apim list -g $config.resourceGroup | ConvertFrom-Json)

        if ( $apim.count -eq 1 ) {
            Write-Host "Found APIM"
            $serviceName = $apim[0].name

            Write-Host "Searching for API"
            $apis = (az apim api list --resource-group Azure-APIM-Management-Test --service-name $serviceName | ConvertFrom-Json)

            $match = $apis | Where-Object { $_.name -eq $config.apiToExport }

            if ($match.length -eq 1) {
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

            }
        } else {
            $apiCount = $apim.count 
            Write-Host "Found $apiCount APIM instances, searhing for single"
        }
        return ""
    }
}