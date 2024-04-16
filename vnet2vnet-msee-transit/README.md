Transit configuration of Vnet2Vnet using ExpressRoute Circuit.(Excludes ExpressRoute resources)
To testing the forced tunneling configuration, I also prepared a VNet to advertise the default route from the NVA.

```mermaid
graph RL;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[subnet-1:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm")
      end
      subgraph GVS2[nva-subnet:10.0.1.0/24]
        CP2("NVA<br/>Name:NVA-FRR")
      end
      subgraph GVS4[RouteServerSubnet:10.0.3.0/24]
        RS("Azure Route Server<br/>Name:RouteServer")
      end
      subgraph GVS3[GatewaySubnet:10.0.2.0/24]
        ERGW1{{"ExpressRoute Gateway<br/>Name:cloud-ergw1<br/>SKU:Standard"}}
      end
  end
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS5[default:10.10.0.0/24]
      CP3("VM<br/>Name:cloud-vm2")
      end
      subgraph GVS6[GatewaySubnet:10.10.1.0/24]
      ERGW2{{"ExpressRoute Gateway<br/>Name:cloud-ergw2<br/>SKU:Standard"}}
      end
  end
  subgraph GV3[cloud_vnet3:10.20.0.0/16]
      subgraph GVS7[default:10.20.0.0/24]
      CP4("VM<br/>Name:cloud-vm3")
      end
      subgraph GVS8[GatewaySubnet:10.20.1.0/24]
      ERGW3{{"ExpressRoute Gateway<br/>Name:cloud-ergw2<br/>SKU:Standard"}}
      end
end
end

%% Relation for resources
CP2 --BGP Peer<br/>Advertised Route: 0.0.0.0/0<br/>---> RS
RS --BGP Peer<br/>Advertised Route: 0.0.0.0/0<br/>--- ERGW1

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4,GVS5,GVS6,GVS7,GVS8 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4 SCP

classDef SERGW fill:#57d1ed,color:#000,stroke:none
class ERGW1,ERGW2,ERGW3 SERGW

classDef SRS fill:#0068b7,color:#fff,stroke:none
class RS SRS

```
