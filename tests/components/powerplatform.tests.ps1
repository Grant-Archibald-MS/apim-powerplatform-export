<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		config.Tests.ps1

		Purpose:	Pester - PowerShell Tests

		Version: 	0.1.0 - Apr 2021
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Config class

	.DESCRIPTION
#>

using module ..\..\scripts\config.psm1
using module ..\..\scripts\components\powerplatform.psm1

Describe "Power Platform Tests" {
    Context "Import Module" {
        It "Create" {
            Import-Module "$PSScriptRoot\..\..\scripts\components\powerplatform.psm1" -Force
            $config = [Config]::new()

            $pp  = (New-PowerPlatformManagement -config $config)
        }
    }
    Context "Login" {
        It "Happy Path" {
            # Arrange
            $config = [Config]::new().LoadJson("{'powerPlatformEnvironment':'https://test.crm.dynamics.com', 'powerPlatformTenantId': 'GUID1', 'powerPlatformClientId': 'GUID2', 'powerPlatformClientSecret': 'SECRET' }")
            $pp = [PowerPlatform]::new($config)
            $urls = New-Object System.Collections.Generic.List[System.String]
            $invokeCommands = New-Object System.Collections.Generic.List[System.String]

            Mock -CommandName Invoke-RestMethod { 
                param($Method, $Uri, $Body)
   
                $urls.Add([string]$Uri)
                $invokeCommands.Add(($Body | ConvertTo-Json -Compress))
               
                return ("{'access_token': 'VALUE'}" | ConvertFrom-Json)
            }

            # Act
            $token = $pp.Login()
            
            # Assert
            $token | Should -Be "VALUE"
            $urls.count | Should -Be 1
            $urls[0] | Should -Be "https://login.windows.net/GUID1/oauth2/token?api-version=1.0"
            $invokeCommands.count | Should -Be 1

            $expectedJson = '{"resource":"https://test.crm.dynamics.com","grant_type":"client_credentials","client_id":"GUID2","client_secret":"SECRET"}' | ConvertFrom-Json | ConvertTo-Json -Compress
            Compare-Object -ReferenceObject ($invokeCommands[0] | ConvertFrom-Json) -DifferenceObject ( $expectedJson | ConvertFrom-Json)
        }
    }

    Context "ImportConnector" {
        It "Happy Path" {
            # Arrange
            $config = [Config]::new().LoadJson("{'powerPlatformEnvironment':'https://test.crm.dynamics.com', 'powerPlatformTenantId': 'GUID1', 'powerPlatformClientId': 'GUID2', 'powerPlatformClientSecret': 'SECRET' }")
            $pp = [PowerPlatform]::new($config)
            $urls = New-Object System.Collections.Generic.List[System.String]
            $invokeCommands = New-Object System.Collections.Generic.List[System.String]

            Mock -CommandName Invoke-WebRequest { 
                param($Method, $Uri, $Headers, $Body)
   
                $urls.Add([string]$Uri)
                $invokeCommands.Add($Body)
               
                return "[]"
            }

            # Act
            $pp.ImportConnector('VALUE', '{"info":{"title":"Test API"}}')
            
            # Assert
            $urls[0] | Should -Be "https://test.crm.dynamics.com/api/data/v9.0/connectors"

            $expectedJson = '{"name":"new_5Ftestapi","openapidefinition":"{\"info\":{\"title\":\"Test API\"}}","displayname":"TestAPI","connectortype":1}' | ConvertFrom-Json | ConvertTo-Json -Compress
            Compare-Object -ReferenceObject ($invokeCommands[0] | ConvertFrom-Json) -DifferenceObject ( $expectedJson | ConvertFrom-Json)
        }
    }
}