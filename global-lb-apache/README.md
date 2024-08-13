Configuring access to a VM with Apache installed via Global LB.

```mermaid
graph TB;
%% Groups and Services
subgraph GR3[Azure CentralUS]
  ALB3{{"Azure Load Balancer<br/>Name:GlobalLB<br/>SKU:Standard/Global"}}
end

subgraph GR1[Azure JapanEast]
  subgraph GV1[cloud_vnet1:10.0.0.0/16]
      subgraph GVS2[defalut:10.0.1.0/24]
        ALB1{{"Azure Load Balancer<br/>Name:public-LB<br/>SKU:Standard<br/>frontendip:LBFrontend-pip<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP2("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
        CP3("VM<br/>Name:backend-vm2<br/>Option:installed Apache")
      end
end
end

subgraph GR2[Azure JapanWest]
  subgraph GV2[cloud_vnet2:10.10.0.0/16]
      subgraph GVS3[defalut:10.10.1.0/24]
        ALB2{{"Azure Load Balancer<br/>Name:public-LB<br/>SKU:Standard<br/>frontendip:LBFrontend-pip<br/>balancingRules_frontendPort:80<br/>balancingRules_backendPort:80<br/>balancingRules_protocol:TCP<br/>ProbeRules_protocol:TCP<br/>ProbeRules_port:80<br/>ProbeRules_interval:5"}}
        CP4("VM<br/>Name:backend-vm1<br/>Option:installed Apache")
        CP5("VM<br/>Name:backend-vm2<br/>Option:installed Apache")
      end
end
end


%% Relation for resources
ALB3 ---> ALB1
ALB3 ---> ALB2
ALB1 ---> CP2
ALB1 ---> CP3
ALB2 ---> CP4
ALB2 ---> CP5


%% Groups style
classDef GSR fill:#fff,color:#1490df,stroke:#1490df
class GR1,GR2,GR3 GSR

classDef SGV1 fill:#c1e5f5,color:#000,stroke:#1490df
class GV1,GVS1,GVS2,GVS3,GVS4 SGV1

classDef SGV2 fill:#c1e5f5,color:#000,stroke:#1490df
class GV2 SGV2
 
%% Service Style
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP1,CP2,CP3,CP4,CP5 SCP

classDef SVPALB fill:#76b82c,color:#000,stroke:none
class ALB1,ALB2,ALB3 SVPALB

classDef SLNGW fill:#70b126,color:#fff,stroke:none
class LNGW1,LNGW2 SLNGW

```
