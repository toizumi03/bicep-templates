## Architecture
Configuring access to VMs with Apache installed via Global Load Balancer across multiple regions.

```mermaid
graph TB;
%% Groups and Services
subgraph GR3[Azure CentralUS]
  ALB3{{"Azure Load Balancer<br/>Name:GlobalLB<br/>SKU:Standard/Global"}}
end

subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS2[default:10.0.1.0/24]
        ALB1{{"Azure Load Balancer<br/>Name:public-LB<br/>SKU:Standard<br/>frontendip:LBFrontend-pip<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP2("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
        CP3("VM<br/>Name:backend-vm2<br/>Option:installed Apache")
      end
end
end

subgraph GR2[Azure JapanWest]
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS3[default:10.10.1.0/24]
        ALB2{{"Azure Load Balancer<br/>Name:public-LB<br/>SKU:Standard<br/>frontendip:LBFrontend-pip<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP4("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
        CP5("VM<br/>Name:backend-vm2<br/>Option:installed Apache")
      end
end
end


%% Relation for resources
ALB3 ---> ALB1
ALB3 ---> ALB2
ALB1 ---> CP2
ALB1 ---> CP3
ALB2 ---> CP4
ALB2 ---> CP5


%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2,GR3 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5 SCP

classDef SVPALB fill:#76b82c,color:#000,stroke:none
class ALB1,ALB2,ALB3 SVPALB

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```

## Features of the template

- Deploys a Standard SKU Global Load Balancer in Central US region
- Creates Standard SKU regional load balancers in Japan East and Japan West
- Configures backend virtual machines with Apache web server installed in each region
- Implements cross-region load balancing using the global load balancer
- Configures TCP load balancing rules for port 80
- Sets up health probes to monitor backend server availability
- Creates separate virtual networks for each region
- Provides high availability through regional distribution of resources

## Usage

### Prerequisites
- Azure subscription
- Resource group created in supported regions (Central US, Japan East, Japan West)
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the global-lb-apache directory
3. Update the parameter.json file with your own values:
   - locationCentralUS: Central US region for global load balancer deployment
   - locationEast: Japan East region for regional deployment
   - locationWest: Japan West region for regional deployment
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs

4. Deploy using Azure CLI:
   ```bash
   az login
   az group create --name <your-resource-group> --location centralus
   az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.json
   ```

   Or deploy using PowerShell:
   ```powershell
   Connect-AzAccount
   New-AzResourceGroup -Name <your-resource-group> -Location centralus
   New-AzResourceGroupDeployment -ResourceGroupName <your-resource-group> -TemplateFile main.bicep -TemplateParameterFile parameter.json
   ```

5. Verify the deployment in the Azure Portal by checking:
   - The global load balancer in Central US
   - Regional load balancers in Japan East and Japan West
   - Backend pool configurations
   - Health probe settings
   - Load balancing rules
   - Apache VMs in both regions
