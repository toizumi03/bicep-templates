## Architecture

S2S VPN configuration using BGP and connection monitor between virtual machines in different regions.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GV2[onpre_vnet:10.100.0.0/16]
     subgraph GVS4[default:10.100.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65020"}}
    end
      subgraph GVS3[default:10.100.0.0/24]
        CP2("VM<br/>Name:onpre-vm")
    end
end
end
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65010"}}
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
end
end

subgraph GR3[Setting:connection monitor]
end

%% Relation for resources
VPNGW1 --V2V connection--- VPNGW2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2,GR3 GSR

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

- Sets up a Site-to-Site VPN connection between two virtual networks in different Azure regions (JapanEast and JapanWest)
- Configures BGP (Border Gateway Protocol) routing between the VPN gateways
- Deploys VpnGw1 SKU VPN gateways in both regions
- Creates virtual machines in each region for connectivity testing
- Implements Azure Network Watcher Connection Monitor to track connectivity between VMs
- Configures necessary NSGs (Network Security Groups) for secure communication
- Provides diagnostic logging capabilities when enabled

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions (JapanEast and JapanWest)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment
- Azure Network Watcher enabled in the regions you plan to deploy to

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the connection-monitor-azureToOnpre directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for the cloud site (default: japaneast)
   - locationSite2: Azure region for the on-premises simulation site (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Set to true/false to enable/disable diagnostic logs

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location <primary-location>
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.json
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location <primary-location>
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.json
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The S2S VPN connection between the two virtual networks
   - BGP routing configuration on both VPN gateways
   - Connection Monitor setup in Network Watcher
   - Connectivity between the cloud-vm and onpre-vm virtual machines
