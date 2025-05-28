## Application Gateway (WAFv2) with Apache Backends

Configure Application Gateway (WAFv2) using Ubuntu VM (Apache) backend. Diagnostic logs and bastion are optionally deployable.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:client-ubuntu-vm")
      end
      APPGW{{"Application Gateway<br/>Name:appgw-wafv2<br/>SKU:WAF_v2"}}
      subgraph GVS4[appgwsubnet:10.0.1.0/24]
      end
      subgraph GVS3[AzureBastionSubnet:10.0.3.0/24]
        CP3("Azure Bastion")
      end
      subgraph GVS2[backendsubnet:10.0.2.0/24]
        CP4("VM<br/>Name:backend-vm0<br/>Option:installed Apache")
        CP5("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
      end
end
end

%% Relation for resources
CP1 --> APPGW
APPGW --> CP4
APPGW --> CP5

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP3,CP4,CP5 SCP

classDef SVPAPPGW fill:#68a528,color:#000,stroke:none
class APPGW SVPAPPGW
```

## Features of the template

- Deploys a WAF_v2 SKU Azure Application Gateway
- Creates 2 backend virtual machines with Apache web server installed
- Configures HTTP routing rules to direct traffic to the backend pool
- Sets up health probe to monitor backend server availability
- Creates a client VM for testing the application gateway
- All resources are deployed in a single virtual network with appropriate subnets
- Optional: Enables diagnostic logs with Log Analytics Workspace
- Optional: Deploys Azure Bastion for secure VM access

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment
1. Clone this repository:
   ```
   git clone https://github.com/toizumi03/bicep-templates.git
   ```
   
2. Navigate to the directory:
   ```
   cd bicep-templates/appgw-wafv2-backend-vm-installed-apache-env1
   ```
   
3. Update the parameter file with your own values:
   - Set a secure password for vmAdminPassword
   - Modify other parameters as needed

4. Deploy using Azure CLI:
   ```
   az login
   az group deployment create --resource-group <your-resource-group> --template-file main.bicep --parameters parameters.json
   ```
   
5. Verify the deployment in the Azure Portal by checking:
   - Application Gateway configuration
   - Backend pool with Apache VMs
   - Health probe settings
   - Routing rules
   - Client VM connectivity