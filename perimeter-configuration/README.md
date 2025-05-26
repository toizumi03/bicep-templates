## Architecture
Configuration of Azure Network Security Perimeter with associated resources.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure Region]
  NSP{{"Network Security Perimeter<br/>Name:test-perimeter"}}
  subgraph PRF[Default Profile]
    AR("Access Rule<br/>Direction:Inbound<br/>AddressPrefixes:8.8.8.8/32")
  end
  subgraph GV1[Associated Resources]
    LA("Log Analytics<br/>Workspace")
    AIS("Azure AI Search")
    CDB("Cosmos DB")
    EH("Event Hubs")
    KV("Key Vault")
    SQL("SQL Database")
    SA("Storage Account")
  end
end

%% Relation for resources
NSP --- PRF
NSP --- LA
NSP --- AIS
NSP --- CDB
NSP --- EH
NSP --- KV
NSP --- SQL
NSP --- SA

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef GSNSP fill:#fff,color:#4040ff,stroke:#4040ff
class NSP GSNSP

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,PRF SGV1

%% Service Style
classDef SRA fill:#4466dd,color:#fff,stroke:none
class AR SRA

classDef SVPLA fill:#76b82c,color:#000,stroke:none
class LA SVPLA

classDef SVPAIS fill:#76b82c,color:#000,stroke:none
class AIS SVPAIS

classDef SVPCDB fill:#76b82c,color:#000,stroke:none
class CDB SVPCDB

classDef SVPEH fill:#76b82c,color:#000,stroke:none
class EH SVPEH

classDef SVPKV fill:#76b82c,color:#000,stroke:none
class KV SVPKV

classDef SVPSQL fill:#76b82c,color:#000,stroke:none
class SQL SVPSQL

classDef SVPSA fill:#76b82c,color:#000,stroke:none
class SA SVPSA

```

## Features of the template

- Deploys an Azure Network Security Perimeter with associated resources
- Creates a default profile with inbound access rules
- Optionally associates the following Azure resources with the perimeter:
  - Log Analytics Workspace
  - Azure AI Search
  - Cosmos DB
  - Event Hubs
  - Key Vault
  - SQL Database
  - Storage Account
- All resources are set to "Learning" access mode for traffic monitoring and analysis
- Parameter-driven deployment allows selecting which resources to create and associate

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the perimeter-configuration directory
3. Update the params.bicepparam file with your own values:
   - locationSite1: Azure region for deployment (default: eastus)
   - vmAdminUsername: Username for the SQL Server
   - vmAdminPassword: Password for the SQL Server
   - createLoganalytics: Set to true/false to create and associate Log Analytics
   - createAisearch: Set to true/false to create and associate Azure AI Search
   - createCosmosdb: Set to true/false to create and associate Cosmos DB
   - createEventhubs: Set to true/false to create and associate Event Hubs
   - createKeyvault: Set to true/false to create and associate Key Vault
   - createSqldb: Set to true/false to create and associate SQL Database
   - createStoragaccount: Set to true/false to create and associate Storage Account

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location <location>
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters params.bicepparam
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location <location>
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile params.bicepparam
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The Network Security Perimeter configuration
   - Associated resources and their access settings
   - Default profile and access rules