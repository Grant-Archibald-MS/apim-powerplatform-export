<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		export-apim.ps1

		Purpose:	Configure and deploy Azure APIM reosurces

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

$powerplatform = [PowerPlatform]::new($config)

$accessToken = $powerplatform.Login()

$swagger = [APIM]::new($config).ExportSwagger()

$powerplatform.ImportConnector($accessToken, $swagger)