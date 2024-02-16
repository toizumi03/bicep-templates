VPN Transit Configuration Between 3 VNets with BGP

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[GatewaySubnet:10.0.1.0/24]
        VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw1<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65010"}}
      end
      subgraph GVS2[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
end
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS3[GatewaySubnet:10.10.1.0/24]
        VPNGW2{{"VPN Gateway<br/>Name:cloud-vpngw2<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65020"}}
      end
      subgraph GVS4[default:10.10.0.0/24]
        CP2("VM<br/>Name:cloud-vm2")
      end
end
  subgraph GV3[cloud_vnet:10.20.0.0/16]
      subgraph GVS5[GatewaySubnet:10.20.1.0/24]
        VPNGW3{{"VPN Gateway<br/>Name:cloud-vpngw3<br/>SKU:VpnGw1<br/>ActAct-Mode:false<br/>AS:65030"}}
      end
      subgraph GVS6[default:10.20.0.0/24]
        CP3("VM<br/>Name:cloud-vm3")
      end
end
end

%% Relation for resources
VPNGW1 --V2V connection--- VPNGW2
VPNGW2 --V2V connection--- VPNGW3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GVS1,GVS2,GVS3,GVS4,GVS5,GVS6 SGV1
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2,VPNGW3 SVPNGW

```
