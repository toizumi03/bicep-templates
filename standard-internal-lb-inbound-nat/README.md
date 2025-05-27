## Architecture
Configuring access to VMs via Standard SKU internal Load Balancer with inbound NAT rules.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[default:10.0.0.0/24]
        CP1("VM<br/>Name:client-vm")
        ALB{{"Azure Load Balancer<br/>Name:InternalLB<br/>SKU:Standard<br/>frontendip:10.0.0.100<br/>inboundNatRules_protocol:TCP<br/>inboundNatRules_frontendPortRange:500-510<br/>inboundNatRules_backendPort:22"}}
        CP2("VM<br/>Name:backendvm0")
        CP3("VM<br/>Name:backendvm1")
        CP4("VM<br/>Name:backendvm2")
        CP5("VM<br/>Name:backendvm3")
        CP6("VM<br/>Name:backendvm4")
      end
end
end

%% Relation for resources
CP1 ---> ALB
ALB ---> CP2
ALB ---> CP3
ALB ---> CP4
ALB ---> CP5
ALB ---> CP6

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5,CP6 SCP

classDef SVPALB fill:#76b82c,color:#000,stroke:none
class ALB SVPALB

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```

## Features of the template

- Deploys a Standard SKU internal Azure Load Balancer with private frontend IP (10.0.0.100)
- Configures inbound NAT rules with port range (500-510) mapped to backend port 22 (SSH)
- Creates 5 backend virtual machines in a backend pool
- Creates a client VM with public IP for testing the load balancer from within the VNet
- All resources are deployed in a single virtual network with appropriate subnet
- Uses a network security group to protect the subnet

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the standard-internal-lb-inbound-nat directory
3. Update the parameter.bicepparam file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location <location>
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.bicepparam
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location <location>
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.bicepparam
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The internal load balancer configuration
   - The inbound NAT rules configuration with port range
   - Backend pool with the five backend VMs
   - The client VM and its ability to connect to backend VMs via the load balancer