## Architecture
VPN Transit Configuration Between 3 VNets with BGP.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw1<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65010"}}
      end
      subgraph GVS2[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
end
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS3[GatewaySubnet:10.10.1.0/24]
        VPNGW2{{"VPN Gateway<br/>Name:cloud-vpngw2<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65020"}}
      end
      subgraph GVS4[default:10.10.0.0/24]
        CP2("VM<br/>Name:cloud-vm2")
      end
end
  subgraph GV3[cloud_vnet3:10.20.0.0/16]
      subgraph GVS5[GatewaySubnet:10.20.1.0/24]
        VPNGW3{{"VPN Gateway<br/>Name:cloud-vpngw3<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65030"}}
      end
      subgraph GVS6[default:10.20.0.0/24]
        CP3("VM<br/>Name:cloud-vm3")
      end
end
end

%% Relation for resources
VPNGW1 --V2V connection--- VPNGW2
VPNGW2 --V2V connection--- VPNGW3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GVS1,GVS2,GVS3,GVS4,GVS5,GVS6 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2,VPNGW3 SVPNGW

```

## Features of the template

- Implements a VNet transit topology with three virtual networks connected via VPN Gateways
- Configures site-to-site VPN connections using VNet-to-VNet connections
- Enables BGP routing between VPN gateways with different ASNs:
  - VNet1 Gateway: AS 65010
  - VNet2 Gateway: AS 65020
  - VNet3 Gateway: AS 65030
- Deploys Ubuntu 20.04 virtual machines in each VNet for connectivity testing
- Applies network security groups to protect the virtual networks
- Optionally enables diagnostic logging via Log Analytics
- Creates transit routing through the middle VNet (VNet2) to allow communication between all VNets

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region (JapanEast by default)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the s2s-single-vpn-bgp-using-v2v-connction-3vnet-transition directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
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
   - The three virtual networks with their respective VPN Gateways
   - The VNet-to-VNet connections between the gateways
   - The BGP configuration on each gateway
   - The virtual machines in each network
   - If enabled, the Log Analytics workspace for diagnostics
