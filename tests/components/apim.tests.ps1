<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		apim.tests.ps1

		Purpose:	Pester - PowerShell Tests

		Version: 	0.1.0 - Apr 2021
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test APIM class

	.DESCRIPTION
#>

using module ..\..\scripts\config.psm1
using module ..\..\scripts\components\apim.psm1

Describe "APIM Tests" {
    Context "Create" {
        It "Create APIM" {
            # Arrange
            $config = [Config]::new().LoadJson("{'APIMPublisherEmail':'test@microsoft.com', 'APIMPublisherName': 'Name' }")
            $apim = [APIM]::new($config)
            $resouces = @()
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")
                
                return "[]"
            }

            # Act
            $name = $apim.Create($resources)
            
            # Assert
            $commands.count | Should -Be 1
            $commands.Where( { $_.IndexOf("--publisher-email test@microsoft.com --publisher-name Name --sku-name Developer --resource-group Azure-APIM-Management-Test") -ge 0 } ).count | Should -Be 1
            $name.StartsWith("A") | Should -Be True
        }

        It "Match APIM" {
            # Arrange
            $config = [Config]::new().LoadJson("")
            $apim = [APIM]::new($config)
            $resources =  ("[{'type':'Microsoft.ApiManagement/service', 'name':'api'}]" | ConvertFrom-Json)
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")
                
                return "[]"
            }

            # Act
            $name = $apim.Create($resources)
            
            # Assert
            $commands.count | Should -Be 0
            $name | Should -Be "api"
        }
    }

    Context "Export" {
        It "No APIM" {
            # Arrange
            $config = [Config]::new().LoadJson("")
            $apim = [APIM]::new($config)
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")

                if ("$p1 $p2 $p3 $p4" -eq "apim list") {
					return "[]"
				}
                
                return "[]"
            }

            # Act
            $swagger = $apim.ExportSwagger()
            
            # Assert
            $swagger | Should -Be ""
        }

        It "APIM and API Found" {
            # Arrange
            $config = [Config]::new().LoadJson("{'resourceGroup':'Foo', 'apiToExport': 'test'}")
            $apim = [APIM]::new($config)
            $commands = New-Object System.Collections.Generic.List[System.String]
            $invokeCommands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")

                if ("$p1 $p2" -eq "apim list") {
					return "[{'name':'APIM'}]"
				}
                
                if ("$p1 $p2 $p3" -eq "apim api list") {
					return "[{'name':'test', 'id':'/api'}]"
				}

                if ("$p1 $p2" -eq "account get-access-token") {
					return "TOKEN"
				}
                
                return "[]"
            }

            Mock -CommandName Invoke-RestMethod { 
                param($Method, $Uri, $Header)
   
                $command = "$Method $Uri $Header"
                $invokeCommands.Add($command)

                Write-Host $command
               
                return ("{'value': {'link':'https://download'}}" | ConvertFrom-Json)
            }

            Mock -CommandName Invoke-WebRequest { 
                param($Method, $Uri)
   
                $command = "$Method $Uri"
                $invokeCommands.Add($command)

                Write-Host $command
               
                return "CONTENT"
            }

            # Act
            $swagger = $apim.ExportSwagger()
            
            # Assert
            $config.apiToExport | Should -Be "test"
            $swagger | Should -Be "CONTENT"
            $commands.Where( { $_.IndexOf("apim api list --resource-group Foo --service-name APIM") -ge 0 }).count | Should -Be 1
        }

        It "APIM Match and API Not Found" {
            # Arrange
            $config = [Config]::new().LoadJson("{'apiToExport': 'test'}")
            $apim = [APIM]::new($config)
            $commands = New-Object System.Collections.Generic.List[System.String]
            $invokeCommands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")

                if ("$p1 $p2" -eq "apim list") {
					return "[{'name':'APIM'}]"
				}
                
                if ("$p1 $p2 $p3" -eq "apim api list") {
					return "[{'name':'xyzzy', 'id':'/api'}]"
				}
                
                return "[]"
            }

            # Act
            $swagger = $apim.ExportSwagger()
            
            # Assert
            $config.apiToExport | Should -Be "test"
            $swagger | Should -Be ""
            $invokeCommands.count | Should -Be 0
        }

        It "Multiple APIM Found" {
            # Arrange
            $config = [Config]::new().LoadJson("{'apiToExport': 'test'}")
            $apim = [APIM]::new($config)
            $commands = New-Object System.Collections.Generic.List[System.String]
            $invokeCommands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")

                if ("$p1 $p2" -eq "apim list") {
					return "[{'name':'APIM'}, {'name':'APIM2'}]"
				}
                
                return "[]"
            }

            # Act
            $swagger = $apim.ExportSwagger()
            
            # Assert
            $swagger | Should -Be ""
            $invokeCommands.count | Should -Be 0
        }
    }
}