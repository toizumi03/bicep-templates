## Architecture
Simple Windows Server 2022 VM deployment in an Azure Virtual Network.

```mermaid
graph TB;
%% Groups and Services

subgraph GA[Azure]
  subgraph GV[cloud_vnet:10.0.0.0/16]
    CP("cloud-vm(windows-server2022)")
  end
end

%% Groups style
classDef SGA fill:#fff,color:#1490df,stroke:#1490df
class GA SGA

classDef SGV fill:#c1e5f5,color:#000,stroke:#1490df
class GV SGV
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP SCP

```

## Features of the template

- Deploys a Windows Server 2022 virtual machine in Azure
- Creates a virtual network with address space 10.0.0.0/16
- Configures a network security group for VM protection
- Assigns a public IP address for remote access
- Deploys the VM in a single subnet (10.0.0.0/24)

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository containing the Bicep templates
2. Navigate to the simple-windowsserver2022 directory
3. Update the parameter.json file with your own values:
   - locationSite1: Azure region for deployment (default: japaneast)
   - vmAdminUsername: Username for the Windows Server VM
   - vmAdminPassword: Password for the Windows Server VM

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
   - The virtual network configuration
   - The Windows Server 2022 VM deployment
   - The network security group settings
   - The public IP address assigned to the VM
