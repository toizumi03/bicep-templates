## Architecture
Test Configuration for transit connectivity between ExpressRoute circuits with routing intent and on-premises VNets.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GonpV1[onpre_vnet:192.168.0.0/16]
      subgraph GonpS1[default:192.168.0.0/24]
        ONPCP1("VM<br/>Name:onpre-vm1")
    end
end
  subgraph GonpV2[onpre_vnet:172.17.0.0/16]
      subgraph GonpS2[default:172.17.0.0/24]
        ONPCP2("VM<br/>Name:onpre-vm2")
    end
end
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
      ERGW1{{"ExpressRoute Gateway"}}
end
end
    subgraph GV6[virtualhub2:10.100.10.0/24]
      subgraph SECHUB2[SecureHub2]
      ERGW2{{"ExpressRoute Gateway"}}
end
end
end
end

%% Relation for resources
GV1 --Vnet to Hub <br/>Connection--- GV5
GV2 --Vnet to Hub <br/>Connection--- GV5
GV3 --Vnet to Hub <br/>Connection--- GV6
GV5 --Hub-to-hub <br/>connection--- GV6

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GV5,GV6,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGonpV fill:#fbe3d6,color:#000,stroke:#1490df
class GonpV1,GonpV2,GonpS1,GonpS2 SGonpV

classDef SGSH fill:#de2222,color:#fff,stroke:#1490df
class SECHUB1,SECHUB2 SGSH
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SonpCP fill:#4466dd,color:#fff,stroke:none
class ONPCP1,ONPCP2 SonpCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class ERGW1,ERGW2 SVPNGW

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```

## Features of the template

- Deploys a Virtual WAN environment with two secure hubs in different regions
- Configures ExpressRoute Gateways in both hubs to enable transit connectivity
- Sets up routing intent for ExpressRoute-to-ExpressRoute transit communication
- Creates multiple cloud virtual networks connected to different hubs
- Establishes simulated on-premises virtual networks in a separate region
- Deploys virtual machines in both cloud and on-premises environments for connectivity testing
- Enables hub-to-hub connectivity for cross-region communication
- Provides an environment to test global connectivity scenarios with ExpressRoute circuits

## Usage

### Prerequisites
- Azure subscription
- Resource groups created in supported regions (japaneast and japanwest)
- Contributor access to the resource groups
- Azure CLI or PowerShell installed for deployment
- Existing ExpressRoute circuits or ability to create them during deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the vwan-securehub-ER2ER-transit-add-onpre-vnet directory
3. Update the parameter.json file with your own values:
   - locationSiteEast: Azure East region for deployment (default: japaneast)
   - locationSiteWest: Azure West region for deployment (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs

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
   - The Virtual WAN and secure hubs configuration
   - ExpressRoute Gateways in each hub
   - Cloud virtual networks connected to appropriate hubs
   - On-premises virtual networks and their configuration
   - Virtual machines in both cloud and on-premises environments
   - Routing intent configuration for ExpressRoute transit

For more information about ExpressRoute routing policies, refer to:
https://learn.microsoft.com/en-us/azure/virtual-wan/how-to-routing-policies#expressroute
