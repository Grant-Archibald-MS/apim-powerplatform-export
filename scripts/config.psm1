<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		config.ps1

		Purpose:	Get configuration settings for components

		Version: 	0.1.0
		==============================================================================================

	.SYNOPSIS
        Read configuration values from config file, environmeny
        
    .DESCRIPTION
        Strongly type Powershell class that defines common configuration setttings used by modules
#>

class ConfigResource {
    [string]$resourceGroup = ""
    [string]$id = ""
    [string]$name = ""
}

class Config {
    [string]$account = "%ACCOUNT%"
    [string]$resourceGroup = "Azure-APIM-Management-Test"
    [string]$location = "WestUS"
    [string]$apiSku = "Developer"
    [string]$apiToExport = "echo-api"
    [string]$APIMPublisherEmail = "%APIM_PUBLISHER_EMAIL%"
    [string]$APIMPublisherName = "%APIM_PUBLISHER_NAME%"
    [string]$powerPlatformEnvironment = "%POWER_PLATFORM_ENVIRONMENT%"
    [string]$powerPlatformTenantId = "%POWER_PLATFORM_TENANT_ID%"
    [string]$powerPlatformClientId = "%POWER_PLATFORM_CLIENT_ID%"
    [SecureString]$powerPlatformClientSecret
    [string]$powerPlatformClientSecretKey = "KV_PP-CLIENT-SECRET"
    [bool]$loadFromKeyVault = $FALSE
    [ConfigResource]$keyVault = $NULL

    [string[]]$tags = @('"Workload name"="Development APIM"',
         '"Data Classification"="Non-business"',
         '"Business criticality"="Low"',
         '"Business Unit"="Unknown"'
         '"Operations commitment"="Baseline Only"',
         '"Operations Team"="None"',
         '"Expected Usage"="Unknown time"')

    [Config] Load() {
        return $this.Load("")
    }

    <#
    .Description
    Load configuration from file
    .PARAMETER file
    The name of the file to read from. If empty will read from config.json
    #>
    [Config] Load([string]$file) {
        if ( [string]::IsNullOrEmpty($file) ) {
            $file = 'config.json'
        }
        if (Test-Path -Path $file -PathType leaf) {
            return $this.LoadJson( (Get-Content $file | Out-String))    
        }
        return $this.LoadJson( "" ) 
    }

     <#
    .Description
    Load configuration from json string
    .PARAMETER json
    The json object to read from
    .NOTES
    Supports expansion of environment variables using %NAME% syntax
    #>
    [Config] LoadJson([string] $json) {
        if ( $json.length -eq 0) {
            $data =  [Config]::new() | ConvertTo-Json
            return  ( ([System.Environment]::ExpandEnvironmentVariables($data) -replace "\%(.*?)\%", "") | ConvertFrom-Json)
        }

        $rawConfig = ( ([System.Environment]::ExpandEnvironmentVariables($json) -replace "\%(.*?)\%", "") | ConvertFrom-Json)

        $config = [Config]::new()

        $kv = $NULL
        $keyInstance = $NULL
        $keyVaultExists = $FALSE

       

        $configProperties = $config.GetType().GetProperties()
        if (-not ($NULL -eq $configProperties) -and $configProperties.Count -gt 0)
        {
            foreach ($property in $configProperties) {
                if(Get-Member -inputobject $rawConfig -name $property.Name -Membertype Properties) {
                    $rawValue = $rawConfig | Select-Object -ExpandProperty $property.Name
                    
                    $property = $config.GetType().GetProperty($property.Name)
                    $existingValue = ""

                    switch ($property.PropertyType.ToString()) {
                        "System.String" {
                            $existingValue = $property.GetValue($config, $NULL) 
                            $existingValue = ([System.Environment]::ExpandEnvironmentVariables($existingValue))
                            $property.SetValue($config, $existingValue, $NULL)
                            $existingValue = $property.GetValue($config, $NULL) -replace "\%(.*?)\%", ""
                            $property.SetValue($config, $existingValue, $NULL)
                        }
                    }
                
                    if ($NULL -eq $rawValue -or  ($existingValue.length -gt 0 -and $rawValue.length -eq 0)) {
                        continue
                    }
                    
                    switch ($property.PropertyType.ToString()) {
                        "System.Security.SecureString" {
                            $newValue = (ConvertTo-SecureString $rawValue -AsPlainText -Force)
                            $property.SetValue($config, $newValue, $NULL)
                        }
                        "System.String" {
                            $property.SetValue($config, $rawValue, $NULL)
                        }
                        "System.String[]" {
                            $stringArray = [string[]] $rawValue
                            $property.SetValue($config, $stringArray, $NULL)
                        }
                        "System.Boolean" {
                            $out = $False
                            if ([bool]::TryParse($rawValue, [ref]$out)) {
                                $property.SetValue($config, $out, $NULL)
                            }
                        }
                        "ConfigResource" {
                            $property.SetValue($config, [ConfigResource]$rawValue, $NULL)
                        }
                    }
                }
            }

            if ($config.loadFromKeyVault) {
                Import-Module "$PSScriptRoot\components\keyvault.psm1"
                $kv = New-KeyVaultManagement -config ($config | ConvertTo-Json | ConvertFrom-Json)
                $keyInstance = $kv.Exists()
                $keyVaultExists = -not ( $NULL -eq $keyInstance )

                foreach ($property in $configProperties) {
                    $rawValue = $NULL
                    try {
                        $rawValue = $rawConfig | Select-Object -ExpandProperty $property.Name
                    } catch {

                    }

                    switch ($property.PropertyType.ToString()) {
                        "System.Security.SecureString" {
                            try {
                                $rawValue = $rawConfig | Select-Object -ExpandProperty $property.Name                           
                            } catch {

                            }
           
                            if ($NULL -eq $rawValue) {
                                $rawValue = $config | Select-Object -ExpandProperty ($property.Name + "Key")
                            }

                            if ($NULL -eq $rawValue) {
                                continue
                            }

                            if ($rawValue.StartsWith("KV_")) {
                                $newValue = $kv.GetSecureSecret($keyInstance, $rawValue.Replace("KV_",""))
                                $property.SetValue($config, $newValue, $NULL)
                            }
                        }
                    }
                }
            }
        }

       

        return $config
    }
}

 <#
    .Description
    Creates a new configuraion object instance
    .PARAMETER file
    The json file to read config from
    .PARAMETER json
    The json object to read settings from
    .PARAMETER resourceGroup
    The resource group to read configuration from
    .PARAMETER keyVaultName
    The keyvault name to read settings from
#>
Function New-Config {
    Param(
        [string]$file,
        [string]$json
    )

    $config = [Config]::new()

    if ( ![string]::IsNullOrEmpty($json) ) {
        $config = $config.LoadJson($json)
    } else {
        if ( ![string]::IsNullOrEmpty($file) ) {
            $config = $config.Load($file)
        } else {
            $config = $config.Load()
        }
    }
    
    return $config
}

Export-ModuleMember -Function New-Config