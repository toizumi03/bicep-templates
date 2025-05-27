## Architecture
Site-to-Site VPN configuration (Not BGP) using VNet-to-VNet connections.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GV2[onpre_vnet:10.100.0.0/16]
     subgraph GVS4[default:10.100.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false"}}
    end
      subgraph GVS3[default:10.100.0.0/24]
        CP2("VM<br/>Name:onpre-vm")
    end
end
end
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false"}}
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
end
end

%% Relation for resources
VPNGW1 --V2V connection--- VPNGW2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```

## Features of the template

- Deploys Site-to-Site VPN connectivity between two Azure regions
- Creates virtual networks in two different regions (JapanEast and JapanWest)
- Configures VPN gateways in each virtual network (SKU: VpnGw1)
- Uses VNet-to-VNet connections for direct connectivity (no BGP routing)
- Creates Ubuntu virtual machines in each VNet for connectivity testing
- Applies network security groups to protect the virtual networks
- Optional diagnostic logging for VPN gateways
- Uses IPsec with pre-shared key for secure communication

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions (JapanEast and JapanWest)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the s2s-single-vpn-nobgp-using-v2v-connction directory
3. Update the parameter.json file with your own values:
   - locationSite1: First Azure region for deployment (default: japaneast)
   - locationSite2: Second Azure region for deployment (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Set to true/false to enable diagnostic logging

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
   - Virtual networks in both regions
   - VPN gateways and their VNet-to-VNet connections
   - Virtual machines in each network
   - Network security group configurations
