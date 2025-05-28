## Architecture
Configuration for Virtual WAN with route maps for route filtering.

```mermaid
graph TB;
%% Groups and Services

subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
  end
  subgraph GV2[Virtual WAN]
    subgraph VHUB1[virtualhub1:10.100.0.0/24]
      VPN1{{"VPN Gateway<br/>Name:hubs2sgateway1<br/>AS:65515"}}
      ROUTE1("Route Map<br/>Name:routemap1<br/>Rule:rule1<br/>Match:192.168.0.0/16<br/>Action:Drop")
    end
    subgraph VHUB2[virtualhub2:10.100.10.0/24]
    end
  end
end

subgraph GR2[Azure JapanWest]
  subgraph GV3[onpre_vnet1:172.16.0.0/16]
      subgraph GVS2[default:172.16.0.0/24]
        CP2("VM<br/>Name:onpre-vm1")
      end
      subgraph GVS3[GatewaySubnet:172.16.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:onpre-vpngw1<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65010"}}
      end
  end
end

%% Relation for resources
VPN1 --"S2S VPN<br/>BGP Enabled"--- VPNGW1
VHUB1 --- GV1

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GVS1,GVS2,GVS3,VHUB1,VHUB2 SGV1

%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPN1,VPNGW1 SVPNGW

classDef SROUTE fill:#70b126,color:#fff,stroke:none
class ROUTE1 SROUTE
```

## Features of the template

- Deploys a Virtual WAN with two virtual hubs for network connectivity
- Implements route filtering using route maps to control traffic flow
- Creates a cloud virtual network connected to the virtual hub
- Sets up an on-premises virtual network with VPN gateway
- Establishes site-to-site VPN connection with BGP enabled for route exchange
- Configures route maps to filter specific route prefixes (192.168.0.0/16)
- Deploys virtual machines in networks for connectivity testing
- Uses route map with drop action to block specific traffic
- Enables diagnostics logging with Log Analytics workspace (optional)

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the vwan-routemap-routefilter directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for cloud resources (default: japaneast)
   - locationSite2: Azure region for on-premises resources (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Set to true to enable diagnostic logging

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location <location>
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters @parameter.json
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location <location>
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.json
   ```