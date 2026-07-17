---
config:
  layout: elk
---
flowchart LR

Usuario((Usuario))

Proxy[Nginx Reverse Proxy]

Front[Frontend React]

Back[Backend Spring Boot]

DB[(PostgreSQL)]

Monitor[Prometheus + Grafana]

Usuario --> Proxy
Proxy --> Front
Front --> Back
Back --> DB

Monitor -. Monitorea .-> Front
Monitor -. Monitorea .-> Back
Monitor -. Monitorea .-> DB
Monitor -. Monitorea .-> Proxy

classDef userNode stroke #38bdf8, fill #f0f9ff
classDef proxyNode stroke #fb923c, fill #fff7ed
classDef frontNode stroke #a78bfa, fill #f5f3ff
classDef backNode stroke #4ade80, fill #f0fdf4
classDef dbNode stroke #f87171, fill #fef2f2
classDef monitorNode stroke #facc15, fill #fefce8

class Usuario userNode
class Proxy proxyNode
class Front frontNode
class Back backNode
class DB dbNode
class Monitor monitorNode