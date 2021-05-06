<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		keryvault.tests.ps1

		Purpose:	Pester - PowerShell Tests

		Version: 	0.1.0 - Apr 2021
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Keyvault class

	.DESCRIPTION
#>

using module ..\..\scripts\config.psm1
using module ..\..\scripts\components\keyvault.psm1

Describe "KeyVault Tests" {
    Context "Exists" {
        It "Not Exist" {
            # Arrange
            $config = [Config]::new().LoadJson("{'resourceGroup':'A' }")
            $kv = [KeyVault]::new($config)
            $resouces = @()
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $command = "$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14"
                $commands.Add($command)
               
                return "[]"
            }

            # Act
            $result = $kv.Exists()
            
            # Assert
            $result | Should -Be $NULL
        }

        It "Exist" {
            # Arrange
            $config = [Config]::new().LoadJson("{'resourceGroup':'A' }")
            $kv = [KeyVault]::new($config)
            $resouces = @()
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $command = "$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14"
                $commands.Add($command)

                return "[{'id':'1','name':'kv','resourceGroup':'A','type':'Microsoft.KeyVault/vaults'}]"
            }

            # Act
            $result = $kv.Exists()
            
            # Assert
            $result.id | Should -Be '1'
            $result.name | Should -Be 'kv'
            $result.resourceGroup | Should -Be 'A'
        }
    }
    Context "Create" {
        It "Create KeyVault - Default" {
            # Arrange
            $config = [Config]::new().LoadJson("{'resourceGroup':'A' }")
            $kv = [KeyVault]::new($config)
            $resouces = @()
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $command = "$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14"
                $commands.Add($command)

                if ("$p1 $p2" -eq "keyvault create") {
                    return "{'id':1,'name':'$p6','resourceGroup':'$p4'}"
                }
                
                return "[]"
            }

            # Act
            $result = $kv.CreateIfNotExists()
            
            # Assert
            $commands.count | Should -Be 2
            $commands.Where( { $_.IndexOf("resource list --resource-group A") -ge 0 } ).count | Should -Be 1
            $commands.Where( { $_.IndexOf("keyvault create --resource-group A --name K") -ge 0 } ).count | Should -Be 1
            $result.name.StartsWith("K") | Should -Be True
            $result.name.length | Should -BeGreaterThan 1
        }


        It "Create KeyVault" {
            # Arrange
            $config = [Config]::new().LoadJson("{'resourceGroup':'A' }")
            $kv = [KeyVault]::new($config)
            $resouces = @()
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")

                if ("$p1 $p2" -eq "keyvault create") {
                    return "{'id':1,'name':'$p6','resourceGroup':'$p4'}"
                }
                
                return "[]"
            }

            # Act
            $result = $kv.CreateIfNotExists($resources)
            
            # Assert
            $commands.count | Should -Be 1
            $commands.Where( { $_.IndexOf("keyvault create --resource-group A --name K") -ge 0 } ).count | Should -Be 1
            $result.name.StartsWith("K") | Should -Be True
            $result.name.length | Should -BeGreaterThan 1
        }

        It "Create KeyVault in resource group" {
            # Arrange
            $config = [Config]::new().LoadJson("{'resourceGroup':'A', keyVault: {'resourceGroup':'B'} }")
            $kv = [KeyVault]::new($config)
            $resouces = @()
            $commands = New-Object System.Collections.Generic.List[System.String]

            if ("$p1 $p2" -eq "keyvault create") {
                return "{'id':1,'name':'$p6','resourceGroup':'$p4'}"
            }

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")

                if ("$p1 $p2" -eq "keyvault create") {
                    return "{'id':1,'name':'$p6','resourceGroup':'$p4'}"
                }
                
                return "[]"
            }

            # Act
            $result = $kv.CreateIfNotExists($resources)
            
            # Assert
            $commands.count | Should -Be 2
            $commands.Where( { $_.IndexOf("resource list --resource-group B") -ge 0 } ).count | Should -Be 1
            $commands.Where( { $_.IndexOf("keyvault create --resource-group B --name K") -ge 0 } ).count | Should -Be 1
            $result.name.StartsWith("K") | Should -Be True
            $result.name.length | Should -BeGreaterThan 1
        }

        It "Match KeyVault - Single" {
            # Arrange
            $config = [Config]::new().LoadJson("")
            $kv = [KeyVault]::new($config)
            [Object[]] $resources =  ("[{'type':'Microsoft.KeyVault/vaults', 'name':'kv'}]" | ConvertFrom-Json)
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")
                
                return "[]"
            }

            # Act
            $result = $kv.CreateIfNotExists($resources)
            
            # Assert
            $commands.count | Should -Be 0
            $result.name | Should -Be "kv"
        }

        It "Match KeyVault - Multiple" {
            # Arrange
            $config = [Config]::new().LoadJson("{'keyVault': {'name':'kv2','resourceGroup':'B'}}")
            $kv = [KeyVault]::new($config)
            $resources =  ("[{'type':'Microsoft.KeyVault/vaults', 'name':'kv1', 'resourceGroup': 'B'}, {'type':'Microsoft.KeyVault/vaults', 'name':'kv2', 'resourceGroup': 'B'}]" | ConvertFrom-Json)
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")
                
                if ("$p1 $p2" -eq "resource list") {
                    return ($resources | ConvertTo-Json)
                }

                return "[]"
            }

            # Act
            $result = $kv.CreateIfNotExists($resources)
            
            # Assert
            $commands.count | Should -Be 1
            $commands.Where( { $_.IndexOf("resource list --resource-group B") -ge 0 } ).count | Should -Be 1
            $result.name | Should -Be "kv2"
        }
    }

    Context "Secrets" {
        It "Add" {
            # Arrange
            $config = [Config]::new().LoadJson("")
            $kv = [KeyVault]::new($config)
            [ConfigResource] $kvRessource =  [ConfigResource]("{'id':1, 'name':'kv', 'resourceGroup':'A'}" | ConvertFrom-Json)
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")
                
                return "[]"
            }

            # Act
            $kv.AddSecret($kvRessource, "test", "value")
            
            # Assert
            $commands.count | Should -Be 1
            $commands.Where( { $_.IndexOf("keyvault secret set --vault-name kv --name test") -ge 0 } ).count | Should -Be 1
        }

        It "Get" {
            # Arrange
            $config = [Config]::new().LoadJson("")
            $kv = [KeyVault]::new($config)
            [ConfigResource] $kvRessource =  [ConfigResource]("{'id':1, 'name':'kv', 'resourceGroup':'A'}" | ConvertFrom-Json)
            $commands = New-Object System.Collections.Generic.List[System.String]

            Mock az { 
                param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
                $commands.Add("$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14")

                if ( "$p1 $p2 $p3 $p4 $p5 $p6 $p7" -eq "keyvault secret show --name test --vault-name kv") {
                    return """test-value"""
                }
                
                return ""
            }

            # Act
            $secret = $kv.GetSecureSecret($kvRessource, "test")

            $binaryString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
            $unsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($binaryString)
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($binaryString)
            
            # Assert
            $commands.count | Should -Be 1
            $commands.Where( { $_.IndexOf("keyvault secret show") -ge 0 } ).count | Should -Be 1
            $unsecureSecret | Should -Be "test-value"
        }
    }
}