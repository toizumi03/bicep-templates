## Architecture
Secure hub configuration with routing intent and BGP peering enabled in Azure Virtual WAN topology. This template demonstrates advanced routing scenarios where an NVA (Network Virtual Appliance) establishes BGP peering with the Virtual WAN hub to advertise custom routes.

```mermaid
graph TB;
%% Groups and Services

subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
  end
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS2[default:10.10.0.0/24]
        NVA("NVA<br/>Name:NVA-FRR<br/>IP:10.10.0.4<br/>AS:65001")
      end
  end
  subgraph GV3[cloud_vnet3:10.20.0.0/16]
      subgraph GVS3[default:10.20.0.0/24]
        CP3("VM<br/>Name:cloud-vm2<br/>RouteTable: toVnet1 via 10.10.0.4")
      end
  end
  subgraph GV4[Virtual WAN]
    subgraph GV5[virtualhub1:10.100.0.0/24]
      subgraph SECHUB1[SecureHub1]
        AZF1("Azure Firewall<br/>Name:vhubFW1")
        RI1("Routing Intent<br/>PrivateTraffic")
        BGP1("BGP Connection<br/>Peer:10.10.0.4<br/>Remote AS:65001")
      end
    end
  end
end

%% Relation for resources
GV1 --Vnet to Hub<br/>Connection--- GV5
GV2 --Vnet to Hub<br/>Connection--- GV5
GV2 --VNet Peering--- GV3
NVA --BGP Peering<br/>Advertises: 10.20.0.0/16--- BGP1
CP3 --Static Route<br/>10.0.0.0/16 via 10.10.0.4--- NVA

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GV5,GVS1,GVS2,GVS3 SGV1

classDef SGSH fill:#de2222,color:#fff,stroke:#1490df
class SECHUB1 SGSH
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP3 SCP

classDef SNVA fill:#ff6b35,color:#fff,stroke:none
class NVA SNVA

classDef SAZF fill:#ff4444,color:#fff,stroke:none
class AZF1 SAZF

classDef SRI fill:#66cc66,color:#fff,stroke:none
class RI1 SRI

classDef SBGP fill:#9966cc,color:#fff,stroke:none
class BGP1 SBGP

```

## Features of the template

- Deploys Azure Virtual WAN with a secure virtual hub
- Configures Azure Firewall in the hub with Standard tier
- Implements Routing Intent for private traffic through the firewall
- Creates three virtual networks: two connected to the hub and one peered to an NVA network
- Deploys an NVA (Network Virtual Appliance) running FRRouting in cloud_vnet2
- Establishes BGP peering between the NVA and the Virtual WAN hub
- Configures custom routing where traffic from vnet3 to vnet1 goes through the NVA
- Sets up VNet peering between cloud_vnet2 and cloud_vnet3 for direct connectivity
- Implements advanced routing scenarios for traffic steering and inspection
- Configures firewall policies with network rules allowing traffic flow
- Optionally enables diagnostic logging to Log Analytics workspace
- Deploys Ubuntu VMs for connectivity testing in each virtual network

## BGP Configuration Details

### NVA Configuration (FRRouting)
- **ASN**: 65001
- **BGP Neighbors**: 10.100.0.69, 10.100.0.70 (Virtual Hub Route Server)
- **Advertised Routes**: Static route for 10.20.0.0/16
- **Route Maps**: Configured to filter Azure ASNs and bogon ASNs

### Virtual Hub BGP Connection
- **Connection Name**: bgp-connection-1
- **Peer IP**: 10.10.0.4 (NVA IP address)
- **Remote ASN**: 65001
- **Hub ASN**: 65515 (Azure default)

## Routing Scenarios

This template demonstrates several advanced routing scenarios:

1. **Hub-Spoke Connectivity**: cloud_vnet1 connects to virtualhub1 for standard hub-spoke routing
2. **BGP Route Advertisement**: NVA advertises routes to the hub via BGP
3. **Custom Traffic Steering**: Traffic from cloud_vnet3 to cloud_vnet1 is directed through the NVA using static routes
4. **VNet Peering**: Direct connectivity between cloud_vnet2 and cloud_vnet3 via VNet peering
5. **Firewall Integration**: Routing Intent ensures private traffic flows through Azure Firewall

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the vwan-securehub-routing-intent-bgp-peer-env directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs (must meet Azure complexity requirements)
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

5. The deployment will take approximately 30-45 minutes to complete

### Post-Deployment Verification

1. **Verify BGP Peering Status**:
   - Check the Virtual Hub BGP connections in Azure Portal
   - Verify BGP peer status is "Connected"

2. **Test Connectivity Scenarios**:
   - SSH to cloud-vm1 and test connectivity to cloud-vm2
   - SSH to cloud-vm2 and verify it can reach both other VMs
   - Check routing tables on the VMs to understand traffic paths

3. **Verify Routing**:
   - Check effective routes on VM network interfaces
   - Verify that traffic from vnet3 to vnet1 uses the NVA as next hop
   - Confirm BGP route advertisements in the Virtual Hub

4. **Monitor Traffic Flow**:
   - Use Azure Firewall logs to monitor traffic flow through the hub
   - Check NSG flow logs for traffic patterns
   - Verify BGP route propagation using Azure Route Server diagnostics

### Testing Commands

Once deployed, you can test the routing scenarios:

```bash
# SSH to cloud-vm2 (in vnet3) and trace route to cloud-vm1
ssh vmAdminUsername@<cloud-vm2-public-ip>
traceroute 10.0.0.4  # Should show path through NVA (10.10.0.4)

# SSH to NVA and check BGP status
ssh vmAdminUsername@<nva-public-ip>
sudo vtysh -c "show bgp summary"
sudo vtysh -c "show ip route"
```
