## Architecture
Mesh network configuration using Azure Virtual Network Manager (AVNM).

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph AVNM[Azure Virtual Network Manager]
    subgraph GV1[cloud_vnet0:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloudvm0")
      end
    end
    subgraph GV2[cloud_vnet1:10.1.0.0/16]
      subgraph GVS3[default:10.1.0.0/24]
        CP3("VM<br/>Name:cloudvm1")
      end
    end
    subgraph GV3[cloud_vnet2:10.2.0.0/16]
      subgraph GVS4[default:10.2.0.0/24]
        CP4("VM<br/>Name:cloudvm2")
      end
    end
    subgraph GV4[cloud_vnet3:10.3.0.0/16]
      subgraph GVS5[default:10.3.0.0/24]
        CP5("VM<br/>Name:cloudvm3")
      end
    end
  end
end

%% Relation for resources
GV1 --Vnet Peering---GV2
GV1 --Vnet Peering---GV3
GV1 --Vnet Peering---GV4
GV2 --Vnet Peering---GV3
GV2 --Vnet Peering---GV4
GV3 --Vnet Peering---GV4

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef GSAVNM fill:#fff,color:#146bb4,stroke:#1490df
class AVNM GSAVNM

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GVS1,GVS3,GVS4,GVS5 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP3,CP4,CP5 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW
```

## Features of the template

- Creates a full mesh network topology managed by Azure Virtual Network Manager (AVNM)
- Deploys 4 virtual networks (10.x.0.0/16) with VMs in each network
- Configures mesh connectivity through AVNM's connectivity configuration
- Enables every VNet to connect directly with all other VNets in the network group
- Enables centralized network management with AVNM network groups
- Automatically provisions the necessary identity and permissions for deployment
- Configures direct peering between all virtual networks in the mesh

## Implementation details

- Uses Bicep modules for modular and reusable deployment
- Deploys multiple VNets using a for loop with dynamic addressing (10.{i}.0.0/16)
- Provisions Ubuntu 20.04 VMs in each network with public IPs for accessibility
- Implements Azure Virtual Network Manager to centralize network governance
- Creates network groups in AVNM to organize virtual networks
- Configures mesh connectivity topology through AVNM's connectivity configuration
- Uses deployment scripts with managed identity to apply network configurations
- Assigns Contributor role to the deployment identity for network management operations

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the avnm-mesh-topology directory
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
   - Virtual networks and peering connections
   - Virtual network manager configuration
   - Network groups and connectivity configurations
