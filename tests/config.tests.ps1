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