## Architecture
Site-to-Site VPN connection between two Azure regions using Active-Active BGP configuration and Local Network Gateway.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GV2[onpre_vnet:10.100.0.0/16]
     subgraph GVS4[default:10.100.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65020"}}
    end
      subgraph GVS3[default:10.100.0.0/24]
        CP2("VM<br/>Name:onpre-vm")
    end
end
    LNGW2("Local Network Gateway * 2: <br/>Name:lng-cloud1<br/>Name:lng-cloud2")
end
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65010"}}
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
end
    LNGW1("Local Network Gateway * 2<br/>Name:lng-onp1<br/>Name:lng-onp2")
end

%% Relation for resources
VPNGW1 --IPSec connection--- VPNGW2
VPNGW1 --IPSec connection--- VPNGW2

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

- Deploys two Azure VPN Gateways in different regions with Active-Active configuration
- Configures BGP for dynamic routing between the VPN gateways (AS: 65010 for cloud, AS: 65020 for on-premises)
- Creates Local Network Gateways to represent the remote networks in each region
- Establishes dual IPsec connections with BGP enabled between the networks for high availability
- Deploys virtual networks in two Azure regions (10.0.0.0/16 in JapanEast and 10.100.0.0/16 in JapanWest)
- Includes a VM in each network for connectivity testing
- Provides option to enable diagnostic logs for the VPN gateways
- Sets up necessary network security groups for secure communication
- Configures appropriate subnet structures including GatewaySubnet for VPN gateways

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions (JapanEast and JapanWest)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the s2s-act-act-vpn-bgp-using-lngw-connction directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for first network (default: japaneast)
   - locationSite2: Azure region for second network (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Set to true to enable diagnostic logs

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
   - The VPN Gateway status and connections in both regions
   - BGP peers and routes in the VPN Gateway configuration
   - Virtual network connectivity between the two regions
   - The VMs in each network can communicate with each other
