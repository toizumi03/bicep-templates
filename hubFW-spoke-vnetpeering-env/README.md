## Architecture
Hub and Spoke vnet peering configuration via Azure Firewall.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS5[AzureFirewallSubnet:10.0.1.0/24]
        AzFW("AzureFirewall<br/>Name:AzureFirewall<br/>SKU:Standard")
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
  end
  subgraph GV2[spoke_vnet1:10.10.0.0/16]
      subgraph GVS3[default:10.10.0.0/24<br/>UDR:0.0.0.0/0 NextHop:AzFW_PrivateIP]
        CP3("VM<br/>Name:spoke-vm1")
      end
end
  subgraph GV3[spoke_vnet2:10.20.0.0/16]
      subgraph GVS4[default:10.20.0.0/24<br/>UDR:0.0.0.0/0 NextHop:AzFW_PrivateIP]
        CP4("VM<br/>Name:spoke-vm2")
      end
end
end
subgraph GR2[Azure JapanWest]
  subgraph ONPV1[onpre_vnet:10.100.0.0/16]
      subgraph ONPS2[default:10.100.0.0/24<br/>UDR:spoke_vnet1,2 NextHop:AzFW_PrivateIP]
        CP2("VM<br/>Name:onpre-vm")
    end
end
end

%% Relation for resources
GV1 --Vnet Peering---ONPV1
GV1 --Vnet Peering---GV2
GV1 --Vnet Peering---GV3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GC2,GVS1,GVS2,GVS3,GVS4,GVS5 SGV1

classDef SGonpV fill:#c1e5f5,color:#000,stroke:#1490df
class ONPV1,ONPS1,ONPS2 SGonpV
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5 SCP

classDef SFW fill:#ff7381,color:#000,stroke:none
class AzFW SFW

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

```

## Features of the template

- Implements a Hub and Spoke network topology with Azure Firewall in the hub network
- Deploys resources across two Azure regions (Japan East and Japan West)
- Creates a hub virtual network (cloud_vnet) with Azure Firewall in Japan East
- Deploys two spoke virtual networks in Japan East with VNet peering to the hub
- Configures a simulated on-premises network (onpre_vnet) in Japan West with VNet peering to the hub
- Sets up user-defined routes (UDRs) to direct traffic through the Azure Firewall
- Configures Azure Firewall with a policy allowing all traffic
- Deploys Ubuntu 20.04 virtual machines in each network for connectivity testing
- Applies network security groups to protect the virtual networks
- Optionally enables diagnostic logs with a Log Analytics workspace

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions (Japan East and Japan West)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the hubFW-spoke-vnetpeering-env directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for hub and spoke networks (default: japaneast)
   - locationSite2: Azure region for on-premises simulation (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Enable diagnostic logs (true/false)

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
   - The hub virtual network with Azure Firewall
   - The two spoke virtual networks
   - VNet peering configurations between hub and spoke networks
   - The on-premises simulation network
   - The virtual machines in each network
