Azure Vnet 内に Windows-Server 2022 をデプロイする bicep です。

```mermaid
graph TB;
%%グループとサービス

subgraph GA[Azure]
  subgraph GV[cloud_vnet:10.0.0.0/16]
    CP("cloud-vm(windows-server2022)")
  end
end

%%グループのスタイル 
classDef SGA fill:#fff,color:#1490df,stroke:#1490df
class GA SGA

classDef SGV fill:#c1e5f5,color:#000,stroke:#1490df
class GV SGV
 
%%サービスのスタイル
classDef SCP fill:#4466dd,color:#fff,stroke:none
class CP SCP

```
