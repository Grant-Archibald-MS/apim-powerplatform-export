<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		config.tests.ps1

		Purpose:	Pester - PowerShell Tests

		Version: 	0.1.0 - Apr 2021
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Config class

	.DESCRIPTION
#>

using module ..\scripts\config.psm1

Describe "Config Tests" {
    It "Import Config Json" {
        Import-Module "$PSScriptRoot\..\scripts\config.psm1" -Force

        $config = (New-Config -json "{'resourceGroup':'Foo'}")

        $config.resourceGroup | Should -Be "Foo"
    }

    It "Load Default Resource Group" {
        $config = [Config]::new().Load()

        $config.resourceGroup | Should -Be "Azure-APIM-Management-Test"
    }

    It "Override resource group" {
        $config = [Config]::new().LoadJson("{'resourceGroup':'Test'}")

        $config.resourceGroup | Should -Be "Test"
    }

    It "Set Environment Value" {
        [Environment]::SetEnvironmentVariable("ACCOUNT", "Foo");
        $config = [Config]::new().LoadJson("")

        $config.account | Should -Be "Foo"
    }

    It "Set SecureString" {
        $config = [Config]::new().LoadJson("{'powerPlatformClientSecret':'ABC'}")

        $binaryString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($config.powerPlatformClientSecret)
        $unsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($binaryString)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($binaryString)

        $unsecureSecret | Should -Be "ABC"
    }

    It "Set loadFromKeyVault False" {
        $config = [Config]::new().LoadJson("{'loadFromKeyVault':'false'}")

        $config.loadFromKeyVault | Should -Be $FALSE
    }

    It "Load secret from KeyVault" {
        # Arrange
        $commands = New-Object System.Collections.Generic.List[System.String]

        Mock az { 
            param($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14)
            $command = "$p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14"
            $commands.Add($command)

            if ("$p1 $p2 $p3 $p4" -eq "resource list --resource-group A") {
                return "[{'id':'1','name':'kv','resourceGroup':'A','type':'Microsoft.KeyVault/vaults'}]"
            }

            if ("$p1 $p2 $p3 $p4 $p5 $p6 $p7" -eq "keyvault secret show --name TEST --vault-name kv") {
                return """VALUE"""
            }
           
            return "[]"
        }

        # Act
        $config = [Config]::new().LoadJson("{'resourceGroup':'A', 'loadFromKeyVault':'true', 'powerPlatformClientSecretKey':'KV_TEST'}")

        # Assert
        $config.loadFromKeyVault | Should -Be $TRUE

        $binaryString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($config.powerPlatformClientSecret)
        $unsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($binaryString)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($binaryString)

        $unsecureSecret | Should -be "VALUE"
    }

    It "Key Vault config resource" {
        $config = [Config]::new().LoadJson("{'keyVault':{id:'1',name:'2','resourceGroup':'3'}}")

        $config.keyVault.id | Should -Be "1"
        $config.keyVault.name | Should -Be "2"
        $config.keyVault.resourceGroup | Should -Be "3"
    }

    It "Override Environment Value" {
        [Environment]::SetEnvironmentVariable("ACCOUNT1", "Foo1");
        $config = [Config]::new().LoadJson("{'account':'%ACCOUNT1%'}")

        $config.account | Should -Be "Foo1"
    }

    It "Update Tags" {
        $config = [Config]::new().LoadJson("{'tags':['Test=1','Other=2']}")

        $config.tags.count | Should -Be 2
        $config.tags[0] | Should -Be "Test=1"
        $config.tags[1] | Should -Be "Other=2"
    }
}