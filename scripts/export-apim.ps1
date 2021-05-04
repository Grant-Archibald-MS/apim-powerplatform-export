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
using module .\components\powerplatform.psm1 

[Console]::ResetColor()
$config = [Config]::new().Load()

$powerplatform = [PowerPlatform]::new()

$accessToken = $powerplatform.Login($config)

$swagger = [APIM]::new().ExportSwagger($config)

$powerplatform.ImportConnector($config, $accessToken, $swagger)


