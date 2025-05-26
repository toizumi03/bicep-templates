## Architecture
Configuring a Site-to-Site VPN connection between an Azure VPN Gateway and a Cisco Catalyst 8000v using APIPA BGP.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GV2[onpre_vnet:10.100.0.0/16]
     subgraph GVS4[default:10.100.0.0/24]
      CAT8000{{"Catalyst 8000v<br/>AS:65512"}}
    end
end
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
    LNGW1("Local Network Gateway<br/>Name:lng-onp1")
end

%% Relation for resources
VPNGW1 --IPSec connection--- CAT8000
VPNGW1 --IPSec connection--- CAT8000

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,CAT8000 SVPNGW

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1 SLNGW

```

## Features of the template

- Deploys a Site-to-Site VPN connection between an Azure VPN Gateway and a Cisco Catalyst 8000v
- Configures an Active-Active VPN Gateway (cloud-vpngw) in Azure JapanEast with BGP enabled (AS: 65010)
- Sets up a Cisco Catalyst 8000v in Azure JapanWest to simulate an on-premises environment
- Utilizes APIPA (Automatic Private IP Addressing) for BGP peering with custom IP addresses (169.254.21.x)
- Creates Local Network Gateway to represent the on-premises network
- Establishes IPsec connection with BGP routing between the networks
- Deploys virtual networks in two Azure regions (10.0.0.0/16 and 10.100.0.0/16)
- Includes a client VM in the cloud virtual network for testing connectivity
- Configures custom IPsec policies for the VPN connection
- Note: Requires manual configuration of the Catalyst 8000v device

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions (JapanEast and JapanWest)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment
- Knowledge of configuring Cisco Catalyst 8000v routers

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the s2s-act-act-vpn-bgp-using-lngw-connction-with-cat8000v directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for cloud network (default: japaneast)
   - locationSite2: Azure region for on-premises simulation (default: japanwest)
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

5. After deployment, manually configure the Catalyst 8000v router with appropriate settings for:
   - BGP configuration (AS: 65512)
   - IPsec connection to the Azure VPN Gateway
   - Custom BGP IP address (169.254.21.200)
   - Route advertisements between networks

6. Verify the deployment and connectivity in the Azure Portal by checking:
   - The VPN Gateway status and connections
   - BGP peers and routes
   - Virtual network connectivity
