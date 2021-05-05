<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		resources.ps1

		Purpose:	Configfure and deploy azure reosurces

		Version: 	0.1.0
		==============================================================================================

	.SYNOPSIS
        Define and provision Azure resources
        
    .DESCRIPTION
        Sample script to provision Azure Resource Group containing Azure API Management and Azure Functions
#>

using module .\config.psm1
using module .\components\apim.psm1

[Console]::ResetColor()
$config = [Config]::new().Load()

Write-Host ($config | ConvertTo-Json)

$groupExists = (az group exists --name $config.resourceGroup | ConvertFrom-Json)
$group = $config.group

if ($groupExists) {
    Write-Host "Target Resource Group $group exists"
}
else
{
    Write-Host "Creating Resource Group $group"
    (az group create --name $config.resourceGroup --location $config.location --tags $config.tags | ConvertFrom-Json)
}

Write-Host "Getting Current Resources"
$resources = (az resource list -g $config.resourceGroup | ConvertFrom-Json)

[APIM]::new($config).Create($resources)