# Overview

This repository expands on [Export APIs from Azure API Management to the Power Platform](https://docs.microsoft.com/en-us/azure/api-management/export-api-power-platform) article, discussing the following use content:

1. [Why is this important](#why-is-this-important)

2. [Export of API between different Azure Active Directory Tenants](#export-api-between-different-azure-active-directory-tenants)

3. [Sample](#sample) Provides sample scripts that can automate the end to end process of automating the deployment of an API from Azure to the Power Platform.
   - [Setup and Deploy Release Scripts](#setup-and-deploy-release-scripts)
   - [Provisioning Azure Resources](#provisioning-azure-resources)
   - [Configure Azure API](#configure-azure-api)
   - [Deploy your API to power platform](#deploy-your-api-to-power-platform)

3. [ALM automation of export process](#alm-automation)
4. [Notes](#notes)
    - [O365 User License Context](#o365-licence-context)
    - [Fusion Development Teams](#fusion-development-teams)
    - [PowerShell Automation](#powershell-automation)
    - [Configuration Management](#configuration-management)

## Why Is This Important

Azure API Management API Export feature makes it easy to take advantage of pro code APIs that you have written in Azure or want to create and expose them to citizen developers so they can leverage them inside their low code Power Platform solutions.

The published [docs API export document](https://docs.microsoft.com/en-us/azure/api-management/export-api-power-platform) works well when the user manually wants to export the the Azure API Management API to a power platform as a custom connector. This guide looks at automating this process and covering scenarios like when you need to publish to APIs between multiple Azure Active Directory tenants.
    
## Export API Between Different Azure Active Directory Tenants

The article assumes that the Azure subscription and the power platform environment are in the same Azure Active directory tenant. The are various cases where this may  not be the case for example:
- You are using your MSDN benefits [https://my.visualstudio.com/benefits](https://my.visualstudio.com/benefits) to use your Azure and Microsoft 365
Developer subscription (E5) benefits
- You are using your Development or Test Azure subscriptions which are not part of your main organization tenant
- You are deploying to trial subscription https://docs.microsoft.com/en-us/partner-center/advisors-create-a-trial-invitation and a separate pay as you go Azure subscription.

If scenarios like this apply to you then when you look to publish your API to your Power Apps environment then you will receive an empty list. to work around this gap you can use the [Sample](#sample) section below 

## Sample

### Setup and Deploy Release Scripts

To run this sample download the latest [release](https://github.com/Grant-Archibald-MS/apim-powerplatform-export/releases) from GitHub. Upload the apim-export-release.zip to [https://shell.azure.com](https://shell.azure.com) or Azure Cloud Shell in [https://portal.azure.com](https://portal.azure.com).

Once uploaded perform thew following steps

1. unzip the release.zip

```bash
unzip apim-export-release.zip
```

2. Change config.json to include your settings replacing TODO values with your settings

```json
{
    "APIMPublisherEmail": "TODO",
    "APIMPublisherName": "TODO2",
    "powerPlatformEnvironment": "https://TODO3.crm.dynamics.com",
    "powerPlatformTenantId": "TODO4",
    "powerPlatformClientId": "TODO5",
    "powerPlatformClientSecret": "%PP_CLIENT_SECRET%", 
    "tags": [
        "\"Workload name\"=\"Development APIM\"",
        "\"Data Classification\"=\"Non-business\"",
        "\"Business criticality\"=\"Low\"",
        "\"Business Unit\"=\"Unknown\"",
        "\"Operations commitment\"=\"Baseline Only\"",
        "\"Operations Team\"=\"None\"",
        "\"Expected Usage\"=\"Unknown time\""
    ]
}
```

3. The following example builds on the previous example by loading values from Azure Key Vault

```json
{
    "APIMPublisherEmail": "TODO",
    "APIMPublisherName": "TODO2",
    "powerPlatformEnvironment": "https://TODO3.crm.dynamics.com",
    "powerPlatformTenantId": "TODO4",
    "powerPlatformClientId": "TODO5",
    "loadFromKeyVault": true,
    "powerPlatformClientSecretKey": "KV_PP-CLIENT-SECRET%", 
    "tags": [
        "\"Workload name\"=\"Development APIM\"",
        "\"Data Classification\"=\"Non-business\"",
        "\"Business criticality\"=\"Low\"",
        "\"Business Unit\"=\"Unknown\"",
        "\"Operations commitment\"=\"Baseline Only\"",
        "\"Operations Team\"=\"None\"",
        "\"Expected Usage\"=\"Unknown time\""
    ]
}
```

### Provisioning Azure Resources

In [https://shell.azure.com](https://shell.azure.com) or Azure Cloud Shell of [https://portal.azure.com](https://portal.azure.com) choosing powershell script environment

1. ./resources.ps1

### Configure Azure API

TODO: To be updated include Azure Function example into APIM

### Deploy your API to power platform

#### Azure AD Service Principal

Ensure that you have created an Azure Active directory with the following
1. API Permissions for Dynamics CRM.
2. Admin granted permissions for Dynamics CRM
3. A secret allocated to the application

Ensure to that application user has been granted rights (System Customizer) in the power platform environment 

#### Create Connector

In [https://shell.azure.com](https://shell.azure.com) or Azure Cloud Shell of [https://portal.azure.com](https://portal.azure.com) choosing powershell script environment

1. ./export-apim.ps1

## ALM Automation

You can use the sample scripts above to include them in your build process

## Notes

## Dependencies

To run this sample you will need access to or the following components installed

1. System administrator rights in Power Platform Environment
2. Access to [https://shell.azure.com](https://shell.azure.com) or Azure Portal [https://portal.azure.com](https://portal.azure.com) 
3. Local install of PowerShell (verion 5.0 or greater) and Azure CLI

### O356 License Context

As at April 2021 as covered in [Licensing overview for Microsoft Power Platform](https://docs.microsoft.com/en-us/power-platform/admin/pricing-billing-skus) Power Apps include limited use rights included with Office 365 licenses to Export Azure API Management APIs to the Power platform.

This feature enable Customers to publish their Azure backend service as APIs and export these APIs to the Power Platform as custom connectors via Azure API Management. Customers with eligible Office 365 licenses that include Dataverse for Teams can use these connectors for custom applications, flows, and chatbots running in Teams and to connect Azure backend services. [Source](https://download.microsoft.com/download/9/5/6/9568EFD0-403D-4AE4-95F0-7FACA2CCB2E4/Power%20Apps,%20Power%20Automate%20and%20Power%20Virtual%20Agents%20Licensing%20Guide%20-%20Apr%202021.pdf). Appendix B in this guide includes specific O365 licenses that are eligible for this for this feature.

### Fusion Development Teams

You can use this feature as a first step to help integrate the concept of building fusion development teams including business, development and IT teams to build a solution. Using this base you can then expand into other premium connectors to accelerate and nurture fusion team development to build and deliver solutions in our organization.

### PowerShell Automation

This sample makes use of [Classes](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7.1) to encapsulate related functionality. This approach allows functionality to be managed and combined to automate the process.

Each class can be created using a exported PowerShell Module functions to allow easy creation of classes via Import Module. For example to create an Azure Key Vault using the default configuration

```powershell
Import-Module './scripts/config.psm1' -Force
Import-Module './scripts/components/keyvault.psm1' -Force
$config = New-Config
$kv = New-KeyVaultManagement -config $config
$kv.CreateIfNotExists()
```

### Configuration Management

The [config.psm](./scripts/config.psm1) can be updated using following approaches:

1. Json configuration file e.g. 

```powershell
Import-Module './scripts/config.psm1' -Force
$config = New-Config -file 'scripts/config.json'
```

2. String json parameter e.g.

```powershell
Import-Module './scripts/config.psm1' -Force
$config = New-Config -json '{"resourceGroup":"Delete Me"}'
```

3. Using Environment variables

```powershell
Import-Module './scripts/config.psm1' -Force
$env:AZ_RESOURCE_GROUP="Delete Me"
$config = New-Config -json '{"resourceGroup":"%AZ_RESOURCE_GROUP%"}'
$config.resourceGroup
```
