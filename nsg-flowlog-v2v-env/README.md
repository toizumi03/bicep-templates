## Architecture
VNet Peering configuration with NSG Flow Log for network traffic monitoring.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
end
  subgraph GV2[cloud_vnet2:10.100.0.0/16]
      subgraph GVS3[default:10.100.0.0/24]
        CP2("VM<br/>Name:cloud-vm2")
      end
end
end

subgraph GR3[Setting:NSG Flow Log]
  LogAnalytics("Log Analytics<br/>Workspace")
  Storage("Storage Account<br/>for Flow Logs")
end

%% Relation for resources
GV1 --Vnet Peering--- GV2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2,GR3 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GVS1,GVS2,GVS3,GVS4 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class ERGW1 SVPNGW

classDef SVLogAnalytics fill:#8dc6f4,color:#000,stroke:none
class LogAnalytics SVLogAnalytics

classDef SVStorage fill:#a5bc4e,color:#000,stroke:none
class Storage SVStorage

```

## Features of the template

- Deploys two virtual networks with VNet peering between them
- Configures NSG Flow Logs for monitoring network traffic
- Creates a storage account to store the flow logs data
- Sets up Log Analytics workspace for traffic analytics
- Deploys virtual machines in both networks for connectivity testing
- Applies network security groups to protect virtual networks
- Enables traffic analytics with a 10-minute analytics interval
- Uses Flow Logs version 2 for enhanced logging capabilities

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- NetworkWatcherRG resource group available in your subscription (created automatically when Network Watcher is enabled in your region)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the nsg-flowlog-v2v-env directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location <location>
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.json
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location <location>
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.json
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The virtual networks and their peering configuration
   - The NSG Flow Logs settings in Network Watcher
   - The storage account used for flow logs
   - Log Analytics workspace with traffic analytics
   - The virtual machines in each network
