Configuring access to a VM with Apache installed via Basic SKU internal ALB.

```mermaid
graph TB;
%% Groups and Services
subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet:10.0.0.0/16]
      subgraph GVS2[defalut:10.0.1.0/24]
        CP1("VM<br/>Name:client-vm")
        ALB{{"Azure Load Balancer<br/>Name:internal-LB<br/>SKU:Basic<br/>frontendip:10.0.0.100<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP2("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
        CP3("VM<br/>Name:backend-vm2<br/>Option:installed Apache")
      end
end
end

%% Relation for resources
CP1 ---> ALB
ALB ---> CP2
ALB ---> CP3

%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

classDef SVPALB fill:#76b82c,color:#000,stroke:none
class ALB SVPALB

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```
