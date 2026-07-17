---
config:
  layout: elk
---
flowchart TB
    Internet(("Internet")) --> Router["Router<br>192.168.0.1"]
    Router --> Proxmox["Proxmox VE<br>192.168.0.200"]
    Proxmox --> Front["erp-front<br>192.168.0.101"] & Back["erp-back<br>192.168.0.102"] & DB["erp-db<br>192.168.0.103"] & Proxy["erp-proxy<br>192.168.0.104"] & Monitor["erp-monitor<br>192.168.0.105"]
    n1["Este diagrama representa la infraestructura física del laboratorio AtlasERP."]

    n1@{ shape: text}
     Internet:::internet
     Router:::infrastructure
     Proxmox:::infrastructure
     Front:::vm
     Back:::vm
     DB:::vm
     Proxy:::vm
     Monitor:::vm
    classDef internet fill:#f0f9ff,stroke:#38bdf8
    classDef infrastructure fill:#f0fdfa,stroke:#2dd4bf
    classDef vm fill:#f0fdf4,stroke:#4ade80