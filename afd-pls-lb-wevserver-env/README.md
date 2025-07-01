## Architecture
This template deploys a Front Door Premium with a virtual machine web server origin. Front Door uses a private endpoint, configured with Private Link service, to access the web application.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
    IT((Internet))
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[defalut:10.0.1.0/24]
        CP1("VM<br/>Name:client-vm")
        PLS("Private Link Service")
        ALB{{"Azure Load Balancer<br/>Name:internal-LB<br/>SKU:Standard<br/>frontendip:LBFrontend-pip<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP2("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
        CP3("VM<br/>Name:backend-vm2<br/>Option:installed Apache")
        subgraph GR3 [PrivateEndPoint]
      end
end
end
subgraph GR2 [Azure Frontdoor]
end
end


%% Relation for resources
CP1 ---> IT ---> GR2 --> GR3 --> PLS --> ALB
ALB ---> CP2
ALB ---> CP3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2,GR3 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GVS1,GVS2,GVS3,GVS4 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

classDef SVPPLS fill:#3999c6,color:#000,stroke:none
class PLS SVPPLS

classDef SVPALB fill:#76b82c,color:#000,stroke:none
class ALB SVPALB

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```

## Features of the template

- Deploys Azure Front Door Premium with global endpoint for high availability and performance
- Creates a Standard SKU internal Azure Load Balancer with private frontend IP (10.0.0.100)
- Sets up Private Link Service to securely connect Front Door to internal load balancer
- Configures private endpoint for secure, private connectivity from Front Door
- Creates 2 backend virtual machines with Apache web server installed via cloud-init
- Configures TCP load balancing rules for port 80 with health probes
- Creates a client VM for internal testing of the load balancer
- All resources are deployed in a single virtual network with appropriate subnet configuration
- Optionally enables diagnostic logging with Log Analytics workspace
- Uses network security groups to protect virtual network resources

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the afd-pls-lb-wevserver-env directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the VMs
   - vmAdminPassword: Password for the VMs
   - enablediagnostics: Set to true/false to enable diagnostic logging

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
   - The Azure Front Door configuration and endpoint
   - The Private Link Service configuration
   - The internal load balancer configuration
   - Backend pool with the two Apache VMs
   - Health probe settings and load balancing rules
   - Virtual network and subnet configuration
