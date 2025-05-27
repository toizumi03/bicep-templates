## Architecture
Transit configuration of VNet-to-VNet connectivity using ExpressRoute Circuit with forced tunneling through NVA. This template deploys the Azure-side resources only (excludes ExpressRoute circuit resources).

```mermaid
graph RL;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
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
        ERGW1{{"ExpressRoute Gateway<br/>Name:cloud-ergw1<br/>SKU:Standard"}}
      end
  end
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS5[default:10.10.0.0/24]
      CP3("VM<br/>Name:cloud-vm2")
      end
      subgraph GVS6[GatewaySubnet:10.10.1.0/24]
      ERGW2{{"ExpressRoute Gateway<br/>Name:cloud-ergw2<br/>SKU:Standard"}}
      end
  end
  subgraph GV3[cloud_vnet3:10.20.0.0/16]
      subgraph GVS7[default:10.20.0.0/24]
      CP4("VM<br/>Name:cloud-vm3")
      end
      subgraph GVS8[GatewaySubnet:10.20.1.0/24]
      ERGW3{{"ExpressRoute Gateway<br/>Name:cloud-ergw2<br/>SKU:Standard"}}
      end
end
end

%% Relation for resources
CP2 --BGP Peer<br/>Advertised Route: 0.0.0.0/0<br/>---> RS
RS --BGP Peer<br/>Advertised Route: 0.0.0.0/0<br/>--- ERGW1

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4,GVS5,GVS6,GVS7,GVS8 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SERGW fill:#57d1ed,color:#000,stroke:none
class ERGW1,ERGW2,ERGW3 SERGW

classDef SRS fill:#0068b7,color:#fff,stroke:none
class RS SRS
```

## Features of the template

- Deploys three virtual networks with ExpressRoute gateways for transit connectivity
- Configures a Network Virtual Appliance (NVA) using FRRouting for traffic control
- Sets up Azure Route Server for BGP route propagation
- Configures forced tunneling by advertising a default route (0.0.0.0/0) from the NVA
- Deploys virtual machines in each VNet for connectivity testing
- Creates appropriate subnets for gateway, NVA, and VM deployments
- Applies network security groups to protect virtual networks

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- ExpressRoute circuit (not included in this template)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the vnet2vnet-msee-transit directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the VMs and NVA
   - vmAdminPassword: Password for the VMs and NVA
   - enablediagnostics: Boolean to enable/disable diagnostics

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
   - The three virtual networks and their subnets
   - The ExpressRoute gateways in each VNet
   - The NVA in the first VNet
   - Azure Route Server configuration
   - The virtual machines in each network
