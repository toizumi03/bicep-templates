## Architecture
Configuration of a storage account with private endpoint for secure access from a virtual network.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
      subgraph GVS2[PrivateEndPointSubnet:10.0.1.0/24]
        PEP("Private Endpoint<br/>Name:PrivateEndPoint1")
      end
  end
  STA("Storage Account<br/>SKU:Standard_LRS<br/>AccessTier:Hot")
end

%% Relation for resources
CP1 --> PEP --> STA

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1 SCP

classDef SVPPEP fill:#3999c6,color:#000,stroke:none
class PEP SVPPEP

classDef SVPSA fill:#a5bc4e,color:#000,stroke:none
class STA SVPSA
```

## Features of the template

- Deploys a storage account with private endpoint for secure access
- Creates a virtual network with two subnets (default and PrivateEndPointSubnet)
- Configures a private endpoint in a dedicated subnet to access storage
- Deploys a Ubuntu 20.04 VM for testing connectivity to storage
- Enables secure access to blob storage services via private network
- Applies network security group to protect the virtual network
- Eliminates exposure of storage services to the public internet
- All resources are deployed in a single Azure region (Japan East)

## Usage

### Prerequisites
- Azure subscription
- Resource group created in a supported region
- Contributor access to the resource group
- Azure CLI or PowerShell installed for deployment

### Deployment

1. Clone the repository or download the required files:
   - main.bicep
   - parameter.json

2. Modify the parameter.json file to set:
   - Storage account name (must be globally unique)
   - Virtual machine admin credentials
   - Location (default is Japan East)

3. Deploy using Azure CLI:
   ```
   az group deployment create --resource-group <your-resource-group> --template-file main.bicep --parameters parameter.json
   ```

4. After successful deployment, you will have:
   - A virtual network with two subnets
   - A storage account with private endpoint configuration
   - An Ubuntu VM that can access the storage via private endpoint
   - The private endpoint with a network interface in the PrivateEndPointSubnet