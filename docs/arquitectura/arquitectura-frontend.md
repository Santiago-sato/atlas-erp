# Arquitectura del frontend — AtlasERP

## 1. Estructura por features

```
frontend/
└── src/
    ├── features/
    │   ├── productos/
    │   │   ├── components/         # ProductoCard, ProductoForm, ProductoTable
    │   │   ├── hooks/               # useProductos, useProducto
    │   │   ├── api/                 # productoService.ts (llamadas Axios de este feature)
    │   │   └── types.ts
    │   ├── ventas/
    │   │   ├── components/
    │   │   ├── hooks/
    │   │   ├── api/
    │   │   └── types.ts
    │   ├── auth/
    │   │   ├── components/          # LoginForm
    │   │   ├── hooks/                # useAuth
    │   │   ├── api/
    │   │   └── types.ts
    │   └── dashboard/
    │       └── ...
    │
    ├── components/                  # Componentes verdaderamente compartidos (Button, Modal, DataTable)
    │   └── ui/
    │
    ├── layouts/                     # AppLayout, AuthLayout
    ├── pages/                       # Componentes de ruta, arman el layout + los features
    ├── routes/                      # Definición de rutas + rutas protegidas (PrivateRoute)
    ├── services/
    │   └── api/
    │       └── axiosInstance.ts     # instancia Axios con interceptor JWT
    ├── hooks/                       # Hooks genéricos, no atados a un feature (useDebounce, etc)
    ├── types/                       # Tipos compartidos entre features
    ├── utils/                       # formatCurrency, formatDate, etc.
    └── assets/
```

## 2. Por qué organización por features y no por tipo de archivo

Una estructura tradicional (`components/`, `pages/`, `services/` con todos los archivos mezclados) se vuelve difícil de navegar a medida que el ERP crece — compras, ventas, inventario, reportes, auditoría van a convivir en el mismo proyecto. Organizando por feature:

- Todo lo relacionado a "ventas" vive en una sola carpeta: su lógica, sus componentes, sus llamadas a la API y sus tipos.
- Si un módulo se vuelve lo bastante grande como para separarse (ej. en un micro-frontend), ya está aislado — no hay que rastrear archivos dispersos por todo el proyecto.
- Los desarrolladores nuevos entienden el dominio del negocio mirando `src/features/`, no una lista plana de componentes técnicos.

`components/ui/` queda reservado para lo genuinamente compartido entre features (botones, modales, tablas genéricas) — si un componente solo lo usa un feature, vive dentro de ese feature, no en `components/ui/`.

## 3. Flujo de datos

```
Componente de página (pages/)
    ↓ usa
Hook del feature (features/x/hooks/useX.ts)
    ↓ llama
Servicio del feature (features/x/api/xService.ts)
    ↓ usa
axiosInstance (services/api/axiosInstance.ts) — interceptor agrega el JWT automáticamente
    ↓
Backend (/api/v1/...)
```

## 4. Principios de diseño

- **Los componentes de `pages/` no llaman a Axios directamente** — siempre pasan por un hook del feature, que a su vez usa el servicio del feature. Esto mantiene la lógica de fetching reutilizable y testeable fuera del componente visual.
- **El interceptor de Axios centraliza el manejo del token**: adjunta el `Authorization: Bearer <token>` en cada request y redirige a login si la respuesta es 401.
- **Rutas protegidas** (`routes/PrivateRoute.tsx`) verifican la sesión antes de renderizar cualquier página del ERP — evita repetir esa lógica en cada componente.
- **Tipos por feature, no un archivo gigante de tipos globales** — `features/productos/types.ts` define `Producto`, `ProductoFormValues`, etc. Solo lo verdaderamente transversal (ej. `PaginatedResponse<T>`) va en `src/types/`.
