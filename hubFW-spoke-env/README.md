## Architecture
Hub and Spoke configuration with VPN Gateway via Azure Firewall. This architecture provides secure connectivity between on-premises networks, hub VNet, and multiple spoke VNets with centralized traffic inspection through Azure Firewall.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24<br/>UDR:Spoke_Vnet NextHop:AzFW_PrivateIP]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65010"}}
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
      subgraph GVS5[AzureFirewallSubnet:10.0.1.0/24]
        AzFW("AzureFirewall<br/>Name:AzureFirewall<br/>SKU:Standard")
      end
  end
  subgraph GV2[spoke_vnet1:10.10.0.0/16<br/>UDR:0.0.0.0/0 NextHop:AzFW_PrivateIP]
      subgraph GVS3[default:10.10.0.0/24]
        CP3("VM<br/>Name:spoke-vm1")
      end
end
  subgraph GV3[spoke_vnet2:10.20.0.0/16<br/>UDR:0.0.0.0/0 NextHop:AzFW_PrivateIP]
      subgraph GVS4[default:10.20.0.0/24]
        CP4("VM<br/>Name:spoke-vm2")
      end
end
end
subgraph GR2[Azure JapanWest]
  subgraph ONPV1[onpre_vnet:10.100.0.0/16]
     subgraph ONPS1[default:10.100.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65020"}}
    end
      subgraph ONPS2[default:10.100.0.0/24]
        CP2("VM<br/>Name:onpre-vm")
    end
end
end

%% Relation for resources
VPNGW1 --V2V VPN connection--- VPNGW2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GC2,GVS1,GVS2,GVS3,GVS4,GVS5 SGV1

classDef SGonpV fill:#c1e5f5,color:#000,stroke:#1490df
class ONPV1,ONPS1,ONPS2 SGonpV
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SFW fill:#ff7381,color:#000,stroke:none
class AzFW SFW

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

```

## Features of the template

- Deploys a hub virtual network (10.0.0.0/16) with Azure Firewall and VPN Gateway
- Creates two spoke virtual networks (10.10.0.0/16 and 10.20.0.0/16) connected to the hub via VNet peering
- Configures a simulated on-premises environment in a separate Azure region with VPN Gateway
- Sets up site-to-site VPN connection between on-premises and Azure hub VNet
- Implements centralized traffic inspection using Azure Firewall
- Configures User Defined Routes (UDR) to route traffic from spoke VNets through Azure Firewall
- Enables transitive routing for spoke-to-on-premises communication via the hub
- Deploys test VMs in each network segment for connectivity validation

## Usage

### Prerequisites
- Azure subscription
- Resource groups created in supported regions (JapanEast and JapanWest)
- Contributor access to the resource groups
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the hubFW-spoke-env directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for hub and spoke resources (default: japaneast)
   - locationSite2: Azure region for on-premises simulation (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group-site1> --location <location-site1>
   az group create --name <your-resource-group-site2> --location <location-site2>
   az deployment group create --resource-group <your-resource-group-site1> --template-file main.bicep --parameters parameter.json
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group-site1> -Location <location-site1>
   New-AzResourceGroup -Name <your-resource-group-site2> -Location <location-site2>
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group-site1> -TemplateFile main.bicep -TemplateParameterFile parameter.json
   ```

5. Verify the deployment in the Azure Portal by checking:
   - VNet peering configurations between hub and spoke networks
   - Azure Firewall deployment and rules
   - VPN Gateway connections between regions
   - Route tables and UDRs directing traffic through Azure Firewall
   - Connectivity between VMs in different network segments
