## Architecture
Simple Virtual Network Peering configuration between two VNets.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
  end
  subgraph GV2[cloud_vnet2:10.100.0.0/16]
      subgraph GVS2[default:10.100.0.0/24]
        CP2("VM<br/>Name:cloud-vm2")
      end
  end
end

%% Relation for resources
GV1 --VNet Peering--- GV2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GVS1,GVS2 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2 SCP
```

## Features of the template

- Deploys two virtual networks in the same Azure region
- Configures VNet peering between networks to allow communication
- Deploys Ubuntu virtual machines in each network for connectivity testing
- Sets up network security groups to protect virtual networks
- Enables bidirectional communication between the peered networks
- Allows forwarded traffic between networks

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region (Japan East)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the simple-vnetpeering directory
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
   - The two virtual networks
   - VNet peering configuration between networks
   - The virtual machines in each network
   - Network connectivity between VMs