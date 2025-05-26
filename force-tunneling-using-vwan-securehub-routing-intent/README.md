## Architecture

Azure Firewall forced tunneling configuration using Virtual WAN Routing Intent (Internet-Traffic).

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GonpV[cloud_vnet:192.168.0.0/16]
    subgraph GonpS2[default:192.168.0.0/24]
    CP1("VM<br/>Name:cloud-vm1")
  end
      subgraph GonpS3[AzureFirewallSubnet:192.168.1.0/24]
      AzFW("AzureFirewall<br/>Name:AzureFirewall<br/>SKU:Standard<br/>Enable:Forcetunnel Mode")
    end
      subgraph GonpS4[AzureFirewallManagementSubnet:192.168.2.0/24]
  end
end
end
subgraph GR1[Azure JapanEast]
  subgraph GV1[Virtual WAN]
    subgraph GV2[virtualhub1:10.100.0.0/24]
      subgraph SECHUB1[SecureHub1<br/>RoutingIntent/InternetTraffic:True]
end
end
end
end

%% Relation for resources
GonpV --Vnet<br/>connection---- GV2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2 SGV1

classDef SGonpV fill:#fbe3d6,color:#000,stroke:#1490df
class GonpV,GonpS1,GonpS2,GonpS3,GonpS4 SGonpV

classDef SGSH fill:#de2222,color:#fff,stroke:#1490df
class SECHUB1 SGSH
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1 SLNGW

classDef SFW fill:#ff7381,color:#000,stroke:none
class AzFW SFW

```

## Features of the template

- Deploys Azure Firewall in force tunnel mode with a standard SKU
- Creates a Virtual WAN with a virtual hub
- Configures Routing Intent for Internet traffic through the secure hub
- Sets up a virtual network with appropriate subnets (default, AzureFirewallSubnet, AzureFirewallManagementSubnet)
- Creates a virtual network connection between the VNet and the virtual hub
- Deploys a VM in the default subnet for testing
- Configures firewall policy with network rules
- Optional diagnostic logging to Log Analytics

## Usage

### Prerequisites

- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the force-tunneling-using-vwan-securehub-routing-intent directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the VM
   - vmAdminPassword: Password for the VM
   - enablediagnostics: Set to true if you want to enable diagnostic logs

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
   - The Azure Firewall configuration with force tunnel mode
   - Virtual WAN and virtual hub with routing intent enabled
   - Virtual network connection between the VNet and virtual hub
   - The VM deployment and network connectivity
