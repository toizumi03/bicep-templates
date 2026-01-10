## Architecture
Hub and Spoke configuration with subnet-level peering and VPN Gateway. This architecture provides a central hub virtual network that connects to on-premises networks via VPN Gateway, with a spoke virtual network using selective subnet peering to the hub.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud-hub-vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65010"}}
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
  end
  subgraph GV2[spoke-vnet1:10.10.0.0/16, 192.168.0.0/20]
      subgraph GVS3[subnet-1:10.10.0.0/24]
        CP3("VM<br/>Name:spoke-vm1")
      end
      subgraph GVS4[subnet-2:192.168.0.0/24]
        CP4("Not Peered")
      end
  end
end
subgraph GR2[Azure JapanWest]
  subgraph ONPV1[onpre-vnet:192.168.0.0/16]
     subgraph ONPS1[GatewaySubnet:192.168.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65020"}}
    end
      subgraph ONPS2[default:192.168.0.0/24]
        CP2("VM<br/>Name:onpre-vm")
    end
  end
end

%% Relation for resources
VPNGW1 --V2V VPN connection<br/>BGP Enabled--- VPNGW2
GVS1 -.Subnet Peering<br/>Remote Gateway:true.-GVS3
GVS2 -.Subnet Peering<br/>Remote Gateway:true.-GVS3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGonpV fill:#c1e5f5,color:#000,stroke:#1490df
class ONPV1,ONPS1,ONPS2 SGonpV
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

```

## Features of the template

- Implements a Hub and Spoke network topology with **subnet-level peering** instead of full VNet peering
- Creates a hub virtual network with a VPN Gateway for connecting to on-premises networks
- Deploys a spoke virtual network with multiple subnets
- Configures selective subnet peering between hub and spoke (only specific subnets are peered)
- Enables remote gateway usage from spoke to hub with subnet-level granularity
- Connects two Azure regions (JapanEast and JapanWest) via site-to-site VPN
- Deploys Ubuntu 20.04 virtual machines in hub, spoke, and on-premises networks for connectivity testing
- Applies network security groups to protect the virtual networks
- Configures BGP routing between VPN gateways with different ASNs (65010 and 65020)
- Optionally enables diagnostic logs with a Log Analytics workspace
- Demonstrates advanced peering scenarios where not all subnets need connectivity

## Key Differences from Standard Hub-Spoke
- Uses `peerCompleteVnets: false` with `localSubnetNames` and `remoteSubnetNames` properties
- Provides granular control over which subnets can communicate across peering
- Useful for security isolation scenarios where only specific workloads should communicate

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the hub-spoke-subnetpeering-env directory
3. Update the parameter.bicepparam file with your own values:
   - locationSite1: Azure region for hub and spoke (default: japaneast)
   - locationSite2: Azure region for simulated on-premises (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs (must be secure)
   - enablediagnostics: Enable diagnostic logs (default: false)

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location japaneast
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.bicepparam
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location japaneast
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.bicepparam
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The hub virtual network with VPN Gateway in JapanEast
   - The spoke virtual network with multiple subnets
   - The subnet-level peering configurations (check peering properties for subnet names)
   - The simulated on-premises network with VPN Gateway in JapanWest
   - VPN connection between the two regions
   - The virtual machines in each network

## Network Details

### Hub Network (cloud-hub-vnet)
- Address Space: 10.0.0.0/16
- Subnets:
  - default: 10.0.0.0/24 (peered with spoke subnet-1)
  - GatewaySubnet: 10.0.1.0/24 (peered with spoke subnet-1)

### Spoke Network (spoke-vnet1)
- Address Space: 10.10.0.0/16, 192.168.0.0/20
- Subnets:
  - subnet-1: 10.10.0.0/24 (peered with hub)
  - subnet-2: 192.168.0.0/24 (NOT peered, isolated)

### On-Premises Network (onpre-vnet)
- Address Space: 192.168.0.0/16
- Subnets:
  - default: 192.168.0.0/24
  - GatewaySubnet: 192.168.1.0/24
