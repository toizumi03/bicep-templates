## Architecture
Configuring the NVA to advertise any route to the Azure Route Server.

By executing the provided python script on the "NVA-FRR" VM, you can advertise dummy routes of any number to Route Server/VPN Gateway.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GV2[onpre_vnet:192.168.0.0/16]
     subgraph GVS6[default:192.168.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65020"}}
    end
      subgraph GVS7[default:192.168.0.0/24]
        CP3("VM<br/>Name:onpre-vm")
    end
end
end
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS1[subnet-1:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
      subgraph GVS2[nva-subnet:10.0.1.0/24]
        CP2("NVA<br/>Name:NVA-FRR")
      end
      subgraph GVS4[RouteServerSubnet:10.0.3.0/24]
        RS("Azure Route Server<br/>Name:RouteServer")
      end
      subgraph GVS3[GatewaySubnet:10.0.2.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65515"}}
      end
end
end

%% Relation for resources
VPNGW1 --V2V connection--- VPNGW2
VPNGW1 --V2V connection--- VPNGW2
CP2 --BGP Peer<br/>Advertised Route: y.y.y.y/y---> RS
RS --BGP Peer--- VPNGW1

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4,GVS5,GVS6,GVS7 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

classDef SRS fill:#0068b7,color:#fff,stroke:none
class RS SRS

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW
```

## Features of the template

- Deploys a Network Virtual Appliance (NVA) with FRRouting (FRR) configured
- Sets up an Azure Route Server for BGP peering with the NVA
- Provides a Python script for advertising custom routes from NVA to Route Server
- Creates VPN gateways in Active-Active configuration for site-to-site connectivity
- Establishes VNet-to-VNet connections between cloud and on-premises environments
- Deploys sample VMs in both environments for connectivity testing
- Enables IP forwarding on the NVA for traffic routing

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions (japaneast and japanwest)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the nva-advertised-route-toRS directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for cloud environment (default: japaneast)
   - locationSite2: Azure region for on-premise environment (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Whether to enable diagnostic logs (default: false)

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location japaneast
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.json
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location japaneast
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.json
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The NVA configuration with FRRouting
   - Route Server BGP peering with the NVA
   - VPN gateway connections between cloud and on-premises environments

### Route Advertisement

After deployment, you can advertise custom routes from the NVA to the Route Server by executing the following script on the "NVA-FRR" VM:

```bash
wget https://raw.githubusercontent.com/toizumi03/bicep-templates/main/nva-advertised-route-toRS/bgp-route-advertised-test.py
sudo python3 bgp-route-advertised-test.py
```

The script will prompt you to enter the number of routes you want to advertise. After execution, the specified number of dummy routes will be created and advertised to the Route Server.
