## Architecture
Configuration of subnet-level peering between two virtual networks in Azure.

```mermaid
graph LR;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16, 172.16.0.0/16]
      subgraph GVS2[subnet-2:10.0.1.0/24]
        CP2("VM<br/>Name:cloud-vm2")
      end
      subgraph GVS1[subnet-1:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
      subgraph GVS6[subnet-3:172.16.0.0/24]
        CP6("VM<br/>Name:cloud-vm3")
      end
end
  subgraph GV2[cloud_vnet2:10.100.0.0/16, 172.16.0.0/16]
      subgraph GVS3[subnet-6:172.16.0.0/24]
        CP3("VM<br/>Name:cloud-vm6")
      end
      subgraph GVS4[subnet-5:10.100.1.0/24]
        CP4("VM<br/>Name:cloud-vm5")
      end
      subgraph GVS5[subnet-4:10.100.0.0/24]
        CP5("VM<br/>Name:cloud-vm4")
      end
end
end

%% Relation for resources
GVS1 --Subnet Peering--- GVS4
GVS1 --Subnet Peering--- GVS5
GVS2 --Subnet Peering--- GVS4
GVS2 --Subnet Peering--- GVS5

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GVS1,GVS2,GVS3,GVS4,GVS5,GVS6 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5,CP6 SCP
```

## Features of the template

- Deploys two virtual networks (VNets) with multiple subnets in each
- Creates subnet-level peering between selected subnets across VNets
- Deploys Ubuntu 20.04 virtual machines in each subnet for connectivity testing
- Configures Network Security Groups to protect the virtual networks
- Enables selective subnet connectivity without exposing all resources
- All resources are deployed in a single Azure region (Japan East)
- Uses Azure's standard virtual network peering with subnet-level restrictions

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the simple-subnetpeering directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
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
   - The virtual networks and their subnet configurations
   - The subnet peering connections between VNets
   - The virtual machines in each subnet
   - Network security groups applied to the subnets
