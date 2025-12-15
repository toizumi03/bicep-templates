## Architecture

Force tunneling configuration using Azure Virtual WAN Secure Hub with ExpressRoute and Route Server.

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
    subgraph GV3[virtualhub1:10.100.0.0/24]
      subgraph SECHUB1[SecureHub1<br/>RoutingIntent/PrivateTraffic:True]
        ERGW1{{"ExpressRoute Gateway<br/>Name:hubergateway1"}}
      end
    end
  end
  subgraph GonpV[onpre_vnet:172.16.0.0/16]
    subgraph GonpS1[subnet-1:172.16.0.0/24]
      CP2("VM<br/>Name:onpre-vm")
    end
    subgraph GonpS2[nva-subnet:172.16.1.0/24]
      NVA("NVA<br/>Name:NVA-FRR<br/>AS:65010<br/>Advertise:0.0.0.0/0")
    end
    subgraph GonpS3[GatewaySubnet:172.16.2.0/24]
      ERGW2{{"ExpressRoute Gateway<br/>Name:onpre-ergw"}}
    end
    subgraph GonpS4[RouteServerSubnet:172.16.3.0/24]
      RS("Route Server<br/>AS:65515")
    end
  end
end

%% Relation for resources
GV1 --Vnet to Hub <br/>Connection--- GV3
ERGW1 --ExpressRoute <br/>Connection--- ERGW2
NVA --BGP <br/>Peering--- RS
RS --BGP <br/>Peering--- ERGW2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GVS1,GVS2 SGV1

classDef SGonpV fill:#fbe3d6,color:#000,stroke:#1490df
class GonpV,GonpS1,GonpS2,GonpS3,GonpS4 SGonpV

classDef SGSH fill:#de2222,color:#fff,stroke:#1490df
class SECHUB1 SGSH
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class ERGW1,ERGW2 SVPNGW

classDef SNVA fill:#70b126,color:#fff,stroke:none
class NVA SNVA

classDef SRS fill:#ffc107,color:#000,stroke:none
class RS SRS

```

## Features of the template

- Deploys Azure Virtual WAN with a secure virtual hub
- Configures Azure Firewall in the hub with Standard tier
- Implements Routing Intent for private traffic through the firewall
- Creates ExpressRoute gateway in the virtual hub
- Deploys on-premises environment with:
  - ExpressRoute gateway for connectivity to Virtual WAN
  - Azure Route Server for BGP peering
  - Network Virtual Appliance (NVA) running FRRouting (FRR) that advertises default route (0.0.0.0/0)
- Configures force tunneling by advertising default route from on-premises NVA through BGP
- Creates cloud virtual network with VM for testing connectivity
- Implements firewall policy with network rules allowing traffic flow
- Optionally enables diagnostic logging to Log Analytics workspace
- Routes all internet-bound traffic from cloud VMs through the on-premises NVA

## Usage

### Prerequisites

- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the vwan-securehub-force-tunnel directory
3. Update the parameter.bicepparam file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Set to true/false to enable diagnostic logging

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location <location>
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.bicepparam
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location <location>
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.bicepparam
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The Virtual WAN and secure hub configuration
   - ExpressRoute gateways in both virtual hub and on-premises VNet
   - Azure Firewall settings and routing intent configuration
   - Route Server and its BGP peering with the NVA
   - NVA (FRR) configuration and default route advertisement
   - Virtual network connection between cloud VNet and virtual hub
   - The deployed VMs in both cloud and on-premises environments
   - Verify that traffic from cloud-vm1 to the internet is routed through the on-premises NVA

## How Force Tunneling Works

1. The NVA running FRRouting (FRR) is configured to advertise the default route (0.0.0.0/0) via BGP
2. Azure Route Server learns this route from the NVA and propagates it to the on-premises ExpressRoute gateway
3. The ExpressRoute gateway advertises this route to the Virtual WAN hub
4. The Virtual WAN hub's routing intent ensures that private traffic goes through the Azure Firewall
5. The default route is propagated to the cloud VNet, causing all internet-bound traffic to be routed through the ExpressRoute connection to on-premises
6. Traffic flows: Cloud VM → Virtual Hub → ExpressRoute → On-premises VNet → NVA → Internet
