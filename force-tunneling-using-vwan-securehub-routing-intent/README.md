Azure Firewall forced tunneling configuration using Virtual WAN Routing Intent (Internet-Traffic).

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GonpV[cloud_vnet:192.168.0.0/16]
     subgraph GonpS1[GatewaySubnet:192.168.1.0/24]
      VPNGW1{{"VPN Gateway<br/>Name:cloud-vpngw<br/>SKU:VpnGw1<br/>ActAct-Mode:true<br/>AS:65020"}}
    end
      subgraph GonpS3[AzureFirewallSubnet:192.168.2.0/24]
      AzFW("AzureFirewall<br/>Name:AzureFirewall<br/>SKU:Standard<br/>Enable:Forcetunnel Mode")
    end
      subgraph GonpS4[AzureFirewallManagementSubnet:192.168.3.0/24]
  end
    subgraph GonpS2[default:192.168.0.0/24<br/>UDR:0.0.0.0/0 NextHop:AzFW_PrivateIP]
    CP1("VM<br/>Name:onpre-vm")
  end
    LNGW1("Local Network Gateway: <br/>Name:lng-cloud1")
end
end
subgraph GR1[Azure JapanEast]
  subgraph GV1[Virtual WAN]
    subgraph GV2[virtualhub1:10.100.0.0/24]
      subgraph SECHUB1[SecureHub1<br/>RoutingIntent/InternetTraffic:True]
      VPNGW2{{"S2S Gateway<br/>vpnGatewayScaleUnit:2"}}
end
end
end
end

%% Relation for resources
VPNGW1 --IPSec VPN <br/>connection---- VPNGW2

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GV2 SGV1

classDef SGonpV fill:#fbe3d6,color:#000,stroke:#1490df
class GonpV,GonpS1,GonpS2,GonpS3,GonpS4 SGonpV

classDef SGSH fill:#de2222,color:#fff,stroke:#1490df
class SECHUB1 SGSH
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1 SCP

classDef SVPNGW fill:#57d1ed,color:#000,stroke:none
class VPNGW1,VPNGW2 SVPNGW

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1 SLNGW

classDef SFW fill:#ff7381,color:#000,stroke:none
class AzFW SFW

```
