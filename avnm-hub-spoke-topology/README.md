## Architecture
Hub and Spoke configuration using Azure Virtual Network Manager.
```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph AVNM[Azure Virtual Network Manager]
  subgraph GV1[hub_vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:hub-vm")
      end
  end
  subgraph GV2[spoke_vnet:10.10.0.0/16]
      subgraph GVS3[default:10.10.0.0/24]
        CP3("VM<br/>Name:spoke-vm1")
      end
end
  subgraph GV3[spoke_vnet:10.20.0.0/16]
      subgraph GVS4[default:10.20.0.0/24]
        CP4("VM<br/>Name:spoke-vm2")
      end
end
  subgraph GV4[spoke_vnet:10.30.0.0/16]
      subgraph GVS5[default:10.30.0.0/24]
        CP5("VM<br/>Name:spoke-vm3")
      end
end
end
end

%% Relation for resources
GV1 --Vnet Peering<br/>Remote Gateway:true---GV2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV3
GV1 --Vnet Peering<br/>Remote Gateway:true---GV4

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef GSAVNM fill:#fff,color:#146bb4,stroke:#1490df
class AVNM GSAVNM

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GC2,GVS1,GVS2,GVS3,GVS4,GVS5 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

```

## Features of the template

- Sets up a hub-spoke network topology managed by Azure Virtual Network Manager (AVNM)
- Creates a central hub virtual network (10.0.0.0/16) with a VM
- Deploys multiple spoke virtual networks (3 by default: 10.x.0.0/16) with VMs in each
- Configures hub-spoke connectivity through AVNM's connectivity configuration
- Enables centralized network management with AVNM network groups
- Automatically provisions the necessary identity and permissions for deployment
- Configures peering between the hub and spoke networks with remote gateway transit option

## Implementation details

- Uses Bicep modules for modular and reusable deployment
- Creates a hub VNet with default subnet (10.0.0.0/24)
- Deploys multiple spoke VNets using a for loop with dynamic addressing (10.{i}.0.0/16)
- Provisions Ubuntu 20.04 VMs in each network with public IPs for accessibility
- Implements Azure Virtual Network Manager to centralize network governance
- Establishes network groups in AVNM to organize virtual networks
- Configures hub-spoke connectivity through AVNM's connectivity configuration
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
2. Navigate to the avnm-hub-spoke-topology directory
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

