## Architecture
Configuring network traffic inspection using Azure Gateway Load Balancer with Ubuntu NVA (Network Virtual Appliance).

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
    IT((Internet))
  subgraph GV1[consumer_vnet:10.0.0.0/16]
      subgraph GVS2[defalut:10.0.1.0/24]
        CP1("VM<br/>Name:client-vm")
        ALB{{"Azure Load Balancer<br/>Name:public-LB<br/>SKU:Standard<br/>frontendip:LBFrontend-pip<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP2("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
        CP3("VM<br/>Name:backend-vm2<br/>Option:installed Apache")
      end
end
  subgraph GV2[provider_vnet:192.168.0.0/16]
   subgraph GVS3[defalut:192.168.0.0/24]
        GWLB{{"Gateway Load Balancer<br/>Name:gateway-lb<br/>frontendip:192.168.0.7"}}
        CP4("VM<br/>Name:NVA-vm<br/>Option:installed vlan configuration") 
end
end
end

%% Relation for resources
CP1 <--- IT <--- ALB
ALB --> GWLB --> CP4 --> ALB
ALB <---> CP2
ALB <---> CP3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SVPALB fill:#76b82c,color:#000,stroke:none
class ALB SVPALB

classDef SVPGWLB fill:#76b82c,color:#000,stroke:none
class GWLB SVPGWLB

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```

## Features of the template

- Deploys a Standard SKU public Azure Load Balancer with public frontend IP
- Creates a Gateway Load Balancer in a provider VNet for traffic inspection
- Configures an Ubuntu NVA (Network Virtual Appliance) with VXLAN tunneling
- Sets up 2 backend virtual machines with Apache web server installed
- Creates a client VM for testing the environment
- Establishes traffic flow through the Gateway Load Balancer for inspection
- Configures TCP load balancing rules for port 80
- Sets up health probe to monitor backend server availability

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the gateway-lb-ubuntu-nva directory
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
   - The public Load Balancer configuration
   - The Gateway Load Balancer configuration
   - The NVA VM with VXLAN configuration
   - Backend pool with the two Apache VMs
   - Health probe settings
   - Load balancing rules
