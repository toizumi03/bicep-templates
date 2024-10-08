Configuration with S2S VPN connection between Virtual WAN and Vnet.

```mermaid
graph TB;
%% Groups and Services
subgraph GR2[Azure JapanWest]
  subgraph GonpV2[onpre_vnet2:172.17.0.0/16]
     subgraph GonpS3[GatewaySubnet:172.17.1.0/24]
      VPNGW2{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65020"}}
    end
      subgraph GonpS4[default:172.17.0.0/24]
        CP5("VM<br/>Name:onpre-vm2")
    end
    LNGW2("Local Network Gateway *2: <br/>Name:lng-cloud3<br/>Name:lng-cloud4")
end
subgraph GonpV1[onpre_vnet1:172.16.0.0/16]
     subgraph GonpS1[GatewaySubnet:172.16.1.0/24]
      VPNGW1{{"VPN Gateway<br/>Name:onpre-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65010"}}
    end
      subgraph GonpS2[default:172.16.0.0/24]
        CP4("VM<br/>Name:onpre-vm1")
    end
    LNGW1("Local Network Gateway *2: <br/>Name:lng-cloud1<br/>Name:lng-cloud2")
end
end

subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS1[default:10.0.0.0/24]
        CP1("VM<br/>Name:cloud-vm1")
      end
  end
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS2[default:10.10.0.0/24]
        CP2("VM<br/>Name:cloud-vm2")
      end
  end
  subgraph GV4[Virtual WAN]
      subgraph GV5[virtualhub1:10.100.0.0/24]
        VPNGW3{{"S2S Gateway<br/>vpnGatewayScaleUnit:2"}}
      end
  end
end

subgraph GR3[Azure JapanWest]
  subgraph GV6[virtualhub2:10.100.10.0/24]
    VPNGW4{{"S2S Gateway<br/>vpnGatewayScaleUnit:2"}}
end
    subgraph GV3[cloud_vnet3:10.20.0.0/16]
      subgraph GVS3[default:10.20.0.0/24]
        CP3("VM<br/>Name:cloud-vm3")
      end
end
end

%% Relation for resources
GV1 --Vnet to Hub <br/>Connection--- GV5
GV2 --Vnet to Hub <br/>Connection--- GV5
GV3 --Vnet to Hub <br/>Connection--- GV6
GV5 --Hub-to-hub <br/>connection--- GV6
VPNGW1 --IPSec VPN <br/>connection---- VPNGW3
VPNGW1 --IPSec VPN <br/>connection---- VPNGW3
VPNGW2 --IPSec VPN <br/>connection---- VPNGW4
VPNGW2 --IPSec VPN <br/>connection---- VPNGW4

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2,GR3 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2,GV3,GV4,GV5,GV6,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGonpV fill:#fbe3d6,color:#000,stroke:#1490df
class GonpV1,GonpV2,GonpS1,GonpS2,GonpS3,GonpS4 SGonpV
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2,VPNGW3,VPNGW4,VPNGW5 SVPNGW

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```
