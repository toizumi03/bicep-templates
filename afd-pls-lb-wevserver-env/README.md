## Architecture
This template deploys Azure Front Door Premium with a virtual machine web server origin. Front Door uses a private endpoint, configured with Private Link service, to access the web application hosted on backend VMs via an internal Standard Load Balancer.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
    IT((Internet))
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[default:10.0.0.0/24]
        CP1("VM<br/>Name:client-vm")
        PLS("Private Link Service")
        ALB{{"Azure Load Balancer<br/>Name:internal-LB<br/>SKU:Standard<br/>frontendip:10.0.0.100<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP2("VM<br/>Name:backend-vm0<br/>Option:installed Apache")
        CP3("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
      end
  end
end

subgraph GR2[Azure Front Door Premium]
  AFD("Front Door<br/>Endpoint")
  subgraph GR3[Private Endpoint]
    PE("Private Endpoint")
  end
end

%% Relation for resources
IT --> AFD
AFD --> PE
PE --> PLS
PLS --> ALB
ALB --> CP2
ALB --> CP3
CP1 -.-> ALB

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2,GR3 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS2 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

classDef SVPPLS fill:#3999c6,color:#000,stroke:none
class PLS SVPPLS

classDef SVPALB fill:#76b82c,color:#000,stroke:none
class ALB SVPALB

classDef SVPAFD fill:#ff6600,color:#fff,stroke:none
class AFD SVPAFD

classDef SVPPE fill:#9900cc,color:#fff,stroke:none
class PE SVPPE

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
