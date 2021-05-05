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
    [string]$powerPlatformClientSecret = "%POWER_PLATFORM_CLIENT_SECRET%"

    [string[]]$tags = @('"Workload name"="Development APIM"',
         '"Data Classification"="Non-business"',
         '"Business criticality"="Low"',
         '"Business Unit"="Unknown"'
         '"Operations commitment"="Baseline Only"',
         '"Operations Team"="None"',
         '"Expected Usage"="Unknown time"')

    [Config] Load([string]$file) {
        if ( [string]::IsNullOrEmpty($file) ) {
            $file = 'config.json'
        }
        if (Test-Path -Path $file -PathType leaf) {
            return $this.LoadJson( (Get-Content $file | Out-String))    
        }
        return $this.LoadJson( "" ) 
    }

    [Config] LoadJson([string] $json) {
        if ( $json.length -eq 0) {
            $data =  [Config]::new() | ConvertTo-Json
            return  ( ([System.Environment]::ExpandEnvironmentVariables($data) -replace "\%(.*?)\%", "") | ConvertFrom-Json)
        }

        $rawConfig = ( ([System.Environment]::ExpandEnvironmentVariables($json) -replace "\%(.*?)\%", "") | ConvertFrom-Json)

        $config = [Config]::new()

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
                        "System.String" {
                            $property.SetValue($config, $rawValue, $NULL)
                        }
                        "System.String[]" {
                            $stringArray = [string[]] $rawValue
                            $property.SetValue($config, $stringArray, $NULL)
                        }
                        "System.Boolean" {
                            $out = $NULL
                            if ([bool]::TryParse($rawValue, [ref]$out)) {
                                $property.SetValue($config, $out, $NULL)
                            }
                        }
                    }
                }
            }
        }

        return $config
    }
}

Function New-Config {
    Param(
        [string]$file,
        [string]$json
    )

    if ( ![string]::IsNullOrEmpty($json) ) {
        return [Config]::new().LoadJson($json)
    }

    if ( ![string]::IsNullOrEmpty($file) ) {
        return [Config]::new().Load($file)
    }

    return [Config]::new().Load()
}

Export-ModuleMember -Function New-Config