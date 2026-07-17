---
config:
  layout: elk
  theme: redux-color
---
flowchart TB
    Router[Router<br/>192.168.0.1]
    Bridge[vmbr0]
    PVE[Proxmox<br/>192.168.0.200]
    Front[erp-front<br/>192.168.0.101]
    Back[erp-back<br/>192.168.0.102]
    DB[erp-db<br/>192.168.0.103]
    Proxy[erp-proxy<br/>192.168.0.104]
    Monitor[erp-monitor<br/>192.168.0.105]
    
    Router --> PVE
    PVE --> Bridge
    Bridge --> Front
    Bridge --> Back
    Bridge --> DB
    Bridge --> Proxy
    Bridge --> Monitor
    
    classDef router stroke:#38bdf8,fill:#f0f9ff
    classDef hypervisor stroke:#a78bfa,fill:#f5f3ff
    classDef bridge stroke:#2dd4bf,fill:#f0fdfa
    classDef frontend stroke:#facc15,fill:#fefce8
    classDef backend stroke:#a3e635,fill:#f7fee7
    classDef database stroke:#f87171,fill:#fef2f2
    classDef proxy stroke:#e879f9,fill:#fdf4ff
    classDef monitoring stroke:#fb923c,fill:#fff7ed
    
    class Router router
    class PVE hypervisor
    class Bridge bridge
    class Front frontend
    class Back backend
    class DB database
    class Proxy proxy
    class Monitor monitoring