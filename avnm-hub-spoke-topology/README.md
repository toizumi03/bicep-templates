Hub and Spoke configuration using Azure Virtual Network Manager.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph AVNM[Azure Virtual Network Manager]
  subgraph GV1[hub_vnet:10.0.0.0/16]
      subgraph GVS2[GatewaySubnet:10.0.1.0/24]
      end
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:hub-vm")
      end
  end
  subgraph GV2[spoke_vnet:10.10.0.0/16]
      subgraph GVS3[default:10.10.0.0/24]
        CP3("VM<br/>Name:spoke-vm1")
      end
end
  subgraph GV3[spoke_vnet:10.20.0.0/16]
      subgraph GVS4[default:10.20.0.0/24]
        CP4("VM<br/>Name:spoke-vm2")
      end
end
  subgraph GV4[spoke_vnet:10.30.0.0/16]
      subgraph GVS5[default:10.30.0.0/24]
        CP5("VM<br/>Name:spoke-vm3")
      end
end
end
end

%% Relation for resources
GV1 --Vnet Peering<br/>Remote Gateway:true---GV2
GV1 --Vnet Peering<br/>Remote Gateway:true---GV3
GV1 --Vnet Peering<br/>Remote Gateway:true---GV4

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef GSAVNM fill:#fff,color:#146bb4,stroke:#1490df
class AVNM GSAVNM

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GC2,GVS1,GVS2,GVS3,GVS4,GVS5 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

```
