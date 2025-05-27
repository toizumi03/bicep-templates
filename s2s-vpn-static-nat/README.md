## Architecture
Site-to-Site VPN Configuration with Static NAT for Overlapping IP Address Spaces.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure Region]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS1[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>NAT Rules:<br/>- Egress: 10.0.0.0/16→10.10.0.0/16<br/>- Ingress: 10.0.0.0/16→10.20.0.0/16"}}
      end
      subgraph GVS2[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
  end
  
  subgraph GV2[onpre_vnet:10.0.0.0/16]
      subgraph GVS3[GatewaySubnet:10.0.1.0/24]
        VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>NAT Rules:<br/>- Egress: 10.0.0.0/16→10.20.0.0/16<br/>- Ingress: 10.0.0.0/16→10.10.0.0/16"}}
      end
      subgraph GVS4[default:10.0.0.0/24]
        CP2("VM<br/>Name:onpre-vm")
      end
  end
end

%% Relation for resources
VPNGW1 --"S2S VPN Connection<br/>with NAT Rules"--- VPNGW2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GVS1,GVS2,GVS3,GVS4 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

```

## Features of the template

- Implements Site-to-Site VPN connections between two virtual networks with overlapping IP address spaces
- Configures static NAT rules on both VPN gateways to translate traffic between networks:
  - Cloud VPN Gateway: Egress (10.0.0.0/16 → 10.10.0.0/16) and Ingress (10.0.0.0/16 → 10.20.0.0/16)
  - Onpre VPN Gateway: Egress (10.0.0.0/16 → 10.20.0.0/16) and Ingress (10.0.0.0/16 → 10.10.0.0/16)
- Deploys Ubuntu 20.04 virtual machines in each network for connectivity testing
- Applies network security groups to protect the virtual networks
- Enables communication between networks with identical IP address ranges using address translation
- Optionally enables diagnostic logging via Log Analytics

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region (JapanEast by default)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the s2s-vpn-static-nat directory
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
   - The two virtual networks with their respective VPN Gateways
   - The NAT rules configured on each VPN gateway
   - The site-to-site VPN connections with NAT rules applied
   - The virtual machines in each network
   - If enabled, the Log Analytics workspace for diagnostics