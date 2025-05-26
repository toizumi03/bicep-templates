## Architecture
Hub and Spoke configuration with VPN Gateway. This architecture provides a central hub virtual network that connects to on-premises networks via VPN Gateway, with multiple spoke virtual networks connected to the hub.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65010"}}
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
  end
  subgraph GV2[spoke_vnet1:10.10.0.0/16]
      subgraph GVS3[default:10.10.0.0/24]
        CP3("VM<br/>Name:spoke-vm1")
      end
end
  subgraph GV3[spoke_vnet2:10.20.0.0/16]
      subgraph GVS4[default:10.20.0.0/24]
        CP4("VM<br/>Name:spoke-vm2")
      end
end
end
subgraph GR2[Azure JapanWest]
  subgraph ONPV1[onpre_vnet:10.100.0.0/16]
     subgraph ONPS1[default:10.100.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65020"}}
    end
      subgraph ONPS2[default:10.100.0.0/24]
        CP2("VM<br/>Name:onpre-vm")
    end
end
end

%% Relation for resources
VPNGW1 --V2V VPN connection--- VPNGW2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GC2,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGonpV fill:#c1e5f5,color:#000,stroke:#1490df
class ONPV1,ONPS1,ONPS2 SGonpV
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

```

## Features of the template

- Implements a Hub and Spoke network topology with VPN Gateway connectivity
- Creates a hub virtual network with a VPN Gateway for connecting to on-premises networks
- Deploys two spoke virtual networks peered to the hub network
- Configures VNet peering to allow gateway transit from hub to spokes
- Enables remote gateway usage for spoke networks
- Connects two Azure regions (JapanEast and JapanWest) via site-to-site VPN
- Deploys Ubuntu 20.04 virtual machines in each network for connectivity testing
- Applies network security groups to protect the virtual networks
- Configures BGP routing between VPN gateways with different ASNs

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the hub-spoke-env directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for hub and spokes (default: japaneast)
   - locationSite2: Azure region for simulated on-premises (default: japanwest)
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
   - The hub virtual network with VPN Gateway in JapanEast
   - The two spoke virtual networks connected to the hub
   - The simulated on-premises network with VPN Gateway in JapanWest
   - VNet peering configurations between hub and spoke networks
   - VPN connection between the two regions
   - The virtual machines in each network
