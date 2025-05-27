## Architecture
Hub-Spoke network configuration with VNet Flow Logs for network traffic monitoring.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest Optionnal]
    subgraph GV50[onpre_vnet:192.168.0.0/16]
      subgraph GVS51[GatewaySubnet:192.168.1.0/24]
        VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1"}}
      end
      subgraph GVS50[default:192.168.0.0/24]
        CP51("onpre-vm")
      end
end
end
subgraph GR1[Azure JapanEast]
  subgraph AVNM[Azure Virtual Network Manager]
  subgraph GV1[hub_vnet:10.0.0.0/16  Enable:Vnet Flowlog]
      subgraph GVS3[AzureBastionSubnet:10.0.2.0/24]
        Bastion(AzureBastion:Optional)
      end
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:hub-vnet-vpngw<br/>SKU:VpnGw1<br/>Optional"}}
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("hub-vm")
      end
  end
  subgraph GV2[spoke_vnet1:10.10.0.0/16 Enable:Vnet Flowlog]
      subgraph GVS4[default:10.10.0.0/24]
        CP2("spoke1-vm0")
        CP3("spoke1-vm1")
      end
end
  subgraph GV3[spoke_vnet2:10.20.0.0/16 Enable:Vnet Encryption,Vnet Flowlog]
      subgraph GVS5[default:10.20.0.0/24]
        CP4("spoke2-vm0")
        CP5("spoke2-vm1")
      end
end
  subgraph GV4[spoke_vnet3:10.30.0.0/16 Enable:Vnet Flowlog]
  APPGW{{"Application Gateway<br/>Name:appgw-wafv2<br/>SKU:WAF_v2"}}
      subgraph GVS6[default:10.30.0.0/24]
        CP6("VM<br/>Name:spoke-vm3")
      end
      subgraph GVS7[appgwsubnet:10.30.1.0/24]
      end
      subgraph GVS8[backendsubnet:10.30.2.0/24]
        CP7("backend-vm0")
        CP8("backend-vm1")
      end
end
end
  LogAnalyticsWorkspaces/forVnetFlowLog
  StorageAccount/forVnetFlowLog
end

%% Relation for resources
VPNGW1 --S2S Connection<br/>Optional--- VPNGW2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV3
GV1 --Vnet Peering<br/>Remote Gateway:true---GV4
APPGW ---> CP7
APPGW ---> CP8

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef GSR2 fill:#fff,color:#e97132,stroke:#e97132
class GR2 GSR2

classDef GSAVNM fill:#fff,color:#146bb4,stroke:#1490df
class AVNM GSAVNM

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GC2,GVS1,GVS2,GVS3,GVS4,GVS5,GVS6,GVS7,GVS8 SGV1

classDef SGV50 fill:#fff,color:#e97132,stroke:#e97132
class GV50,GVS50,GVS51 SGV50
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5,CP6,CP7,CP8,Bastion SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

classDef SVPAPPGW fill:#68a528,color:#000,stroke:none
class APPGW SVPAPPGW

```

## Features of the template

- Deploys a hub-spoke network architecture with VNet Flow Logs
- Creates a hub VNet with three spoke VNets connected via VNet peering
- Configures VNet Flow Logs for network traffic monitoring
- Integrates with Azure Virtual Network Manager
- Deploys a WAF v2 Application Gateway in spoke_vnet3
- Enables VNet encryption on spoke_vnet2 for enhanced security
- Sets up Log Analytics Workspace to analyze flow logs data
- Creates a Storage Account for storing flow logs
- Provides optional VPN Gateway configuration for site-to-site connectivity
- Includes optional Azure Bastion for secure VM access
- Deploys multiple VMs across different networks for testing connectivity

## Usage

### Prerequisites

- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the vnetflowlog-env directory
3. Update the parameter file with your own values:
   - locationSite1: Primary Azure region for deployment (default: japaneast)
   - locationSite2: Secondary Azure region for deployment (default: japanwest)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - deployBastion: Set to true/false to deploy Azure Bastion
   - deployVpnGateway: Set to true/false to deploy VPN Gateways

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
   - The hub and spoke virtual networks and their peering configurations
   - VNet Flow Logs settings on the virtual networks
   - The Application Gateway deployment in spoke_vnet3
   - The storage account for flow logs
   - The Log Analytics workspace for flow log analysis
   - The virtual machines across different networks
