## Architecture
Configuration with Site-to-Site VPN connection between Secure Hub and on-premises Virtual Network.


```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GonpV[onpre_vnet:192.168.0.0/16]
     subgraph GonpS1[GatewaySubnet:192.168.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65010"}}
    end
      subgraph GonpS2[default:192.168.0.0/24]
        CP4("VM<br/>Name:onpre-vm")
    end
end
    LNGW2("Local Network Gateway *2: <br/>Name:lng-cloud1<br/>Name:lng-cloud2")
end

subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
end
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS2[default:10.10.0.0/24]
        CP2("VM<br/>Name:cloud-vm2")
      end
end
  subgraph GV3[cloud_vnet3:10.20.0.0/16]
      subgraph GVS3[default:10.20.0.0/24]
        CP3("VM<br/>Name:cloud-vm3")
      end
end
  subgraph GV4[Virtual WAN]
    subgraph GV5[virtualhub1:10.100.0.0/24]
      subgraph SECHUB1[SecureHub1]
      VPNGW3{{"S2S Gateway<br/>vpnGatewayScaleUnit:2"}}
end
end
    subgraph GV6[virtualhub2:10.100.10.0/24]
end
end
end

%% Relation for resources
GV1 --Vnet to Hub <br/>Connection--- GV5
GV2 --Vnet to Hub <br/>Connection--- GV5
GV3 --Vnet to Hub <br/>Connection--- GV6
GV5 --Hub-to-hub <br/>connection--- GV6
VPNGW3 --IPSec VPN <br/>connection---- VPNGW2
VPNGW3 --IPSec VPN <br/>connection---- VPNGW2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GV5,GV6,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGonpV fill:#fbe3d6,color:#000,stroke:#1490df
class GonpV,GonpS1,GonpS2 SGonpV

classDef SGSH fill:#de2222,color:#fff,stroke:#1490df
class SECHUB1 SGSH
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2,VPNGW3,VPNGW4 SVPNGW

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```

## Features of the template

- Deploys a Virtual WAN with multiple virtual hubs (virtualhub1, virtualhub2)
- Configures a Secure Hub with Azure Firewall for centralized security
- Creates S2S VPN Gateway for site-to-site connectivity between on-premises and cloud
- Establishes hub-to-hub connections for global network connectivity
- Configures three cloud virtual networks (cloud_vnet1, cloud_vnet2, cloud_vnet3) connected to virtual hubs
- Deploys virtual machines in both cloud and on-premises environments for testing connectivity
- Implements Azure Firewall with network filtering policies
- Supports diagnostic logging for monitoring and troubleshooting

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the vwan-securehub-collection1 directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for primary site deployment (default: japaneast)
   - locationSite2: Azure region for secondary site deployment (default: japanwest)
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
   - The Virtual WAN and virtual hubs configuration
   - Site-to-site VPN gateway connectivity
   - Azure Firewall settings and security policies
   - Virtual network connections to the hubs
   - VM connectivity across the network
