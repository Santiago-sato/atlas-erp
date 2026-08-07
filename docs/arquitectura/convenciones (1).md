# Convenciones del proyecto — AtlasERP

Este documento es la referencia única de estilo para todo el proyecto. Cualquier duda de "¿cómo se llama esto?" se resuelve acá, no improvisando sobre la marcha.

## 1. Base de datos

### 1.1 Nombres de tablas
- `snake_case`, en **plural**: `productos`, `detalle_venta`, `roles_permisos`.
- Tablas puente/intermedias (N:M): concatenación de las dos entidades en singular, separadas por `_`: `roles_permisos`, `usuarios_permisos`.
- Sin prefijos (nada de `tbl_productos`).

### 1.2 Nombres de columnas
- `snake_case`: `precio_venta`, `numero_documento`, `created_at`.
- Claves foráneas: `<entidad_singular>_id` → `producto_id`, `usuario_id`, `almacen_destino_id`.
- Booleanos: prefijo implícito de estado, no `is_`/`es_`: `activo`, no `es_activo` ni `is_active`.
- Timestamps: `created_at` (toda tabla transaccional), `updated_at` (solo si el registro se edita), `fecha` (cuando representa la fecha del evento de negocio, ej. `ventas.fecha`).

### 1.3 UUID vs BIGINT
**Decisión: BIGINT (BIGSERIAL) como estrategia por defecto en todas las tablas.**

| | BIGINT | UUID |
|---|---|---|
| Tamaño de índice | Menor, más rápido en JOIN | ~2x más pesado |
| Legibilidad en debugging/logs | Alta (`id = 42`) | Baja |
| Predecible/enumerable | Sí (riesgo si se expone en URL pública) | No |
| Generación distribuida (multi-nodo) | Requiere secuencias coordinadas | Nativa |

Para un ERP interno (no expuesto públicamente, sin necesidad de generación distribuida entre múltiples bases desconectadas), BIGINT es la opción más simple y performante. Si en el futuro se expone una API pública o se sincronizan bases offline, se puede migrar puntualmente a UUID en las tablas que lo requieran.

**Excepción**: tokens de sesión, tokens de reseteo de contraseña y cualquier identificador que se exponga en una URL o email usa UUID (o un string aleatorio), nunca el BIGINT interno.

### 1.4 Constraints y checks
- Todo `CHECK` de negocio (cantidades, precios) se declara a nivel de base de datos, no solo en el backend — la BD es la última línea de defensa.
- ENUMs de dominio pequeño y estable (`estado`, `tipo`) se implementan como `VARCHAR` + `CHECK IN (...)` en vez de tipo `ENUM` nativo de PostgreSQL, porque agregar un valor nuevo a un `CHECK` es una migración simple; a un `ENUM` nativo, no.

## 2. Backend (Java / Spring Boot)

### 2.1 Paquetes
`snake_case` no aplica en Java — todo en minúsculas, sin guiones bajos:

```
com.atlaserp.config
com.atlaserp.security
com.atlaserp.controller
com.atlaserp.service
com.atlaserp.repository
com.atlaserp.entity
com.atlaserp.dto
com.atlaserp.dto.request
com.atlaserp.dto.response
com.atlaserp.mapper
com.atlaserp.exception
com.atlaserp.validation
com.atlaserp.util
```

### 2.2 Clases
- `PascalCase`, sustantivo singular: `Producto`, `DetalleVenta`, `UsuarioPermiso`.
- Sufijos obligatorios por capa:
  - Entidad JPA: sin sufijo → `Producto`
  - Repositorio: `ProductoRepository`
  - Servicio (interfaz): `ProductoService`
  - Implementación: `ProductoServiceImpl`
  - Controlador: `ProductoController`
  - DTO de entrada: `ProductoRequest` (o `CrearProductoRequest` si hay variantes por operación)
  - DTO de salida: `ProductoResponse`
  - Mapper: `ProductoMapper`
  - Excepción de negocio: `<Motivo>Exception` → `StockInsuficienteException`, `RecursoNoEncontradoException`

### 2.3 Variables y métodos
- `camelCase`: `precioVenta`, `calcularSubtotal()`.
- Booleanos: `activo`, `tieneStockSuficiente()` — nunca `esActivo` a menos que se lea mejor en un caso puntual.
- Métodos de servicio siguen verbos consistentes: `crear`, `obtener`, `obtenerPorId`, `listar`, `actualizar`, `eliminar` (lógico), `buscar` (con filtros).

## 3. Frontend (React / TypeScript)

- Componentes: `PascalCase`, archivo y componente con el mismo nombre → `ProductoCard.tsx`.
- Hooks propios: `useNombreDelHook.ts` → `useProductos.ts`, `useAuth.ts`.
- Variables, funciones, props: `camelCase`.
- Tipos e interfaces: `PascalCase`, sin prefijo `I` → `Producto`, no `IProducto`.
- Archivos que no son componentes (services, utils): `camelCase.ts` → `productoService.ts`, `formatCurrency.ts`.
- Carpetas: `kebab-case` cuando agrupan por feature → `gestion-productos/`.

## 4. Endpoints REST

### 4.1 Estructura general
```
/api/v1/<recurso-en-plural>
```

- `GET    /api/v1/productos`            → listar (con paginación y filtros por query params)
- `GET    /api/v1/productos/{id}`       → obtener uno
- `POST   /api/v1/productos`            → crear
- `PUT    /api/v1/productos/{id}`       → actualizar completo
- `PATCH  /api/v1/productos/{id}`       → actualizar parcial (ej. solo `activo`)
- `DELETE /api/v1/productos/{id}`       → baja lógica (nunca DELETE físico en catálogos)

### 4.2 Sub-recursos
```
GET /api/v1/productos/{id}/movimientos
GET /api/v1/ventas/{id}/detalle
```

### 4.3 Acciones que no encajan en CRUD puro
Verbo como sub-recurso, no como query param:
```
POST /api/v1/ventas/{id}/anular
POST /api/v1/inventario/transferencias
```

### 4.4 Filtros, paginación y orden
```
GET /api/v1/productos?page=0&size=20&sort=nombre,asc&categoriaId=3&activo=true
```
- Paginación siempre presente en listados (Spring Data `Pageable`), nunca devolver una lista completa sin límite.

## 5. Respuestas HTTP

### 5.1 Códigos de estado
| Código | Uso |
|---|---|
| 200 OK | Lectura o actualización exitosa |
| 201 Created | Creación exitosa (incluye `Location` header) |
| 204 No Content | Eliminación (baja lógica) exitosa |
| 400 Bad Request | Validación fallida |
| 401 Unauthorized | No autenticado / token inválido o ausente |
| 403 Forbidden | Autenticado pero sin permiso |
| 404 Not Found | Recurso inexistente |
| 409 Conflict | Violación de regla de negocio (ej. stock insuficiente, documento duplicado) |
| 500 Internal Server Error | Error no controlado |

### 5.2 Formato de respuesta exitosa
```json
{
  "data": { "id": 1, "nombre": "..." },
  "meta": { "timestamp": "2026-07-28T14:30:00Z" }
}
```
Listados paginados:
```json
{
  "data": [ ... ],
  "meta": {
    "page": 0,
    "size": 20,
    "totalElements": 143,
    "totalPages": 8
  }
}
```

### 5.3 Formato de error (manejo global de excepciones)
```json
{
  "error": {
    "code": "STOCK_INSUFICIENTE",
    "message": "No hay stock suficiente del producto en el almacén seleccionado",
    "status": 409,
    "timestamp": "2026-07-28T14:30:00Z",
    "path": "/api/v1/ventas"
  }
}
```
Errores de validación incluyen además el detalle por campo:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Uno o más campos son inválidos",
    "status": 400,
    "fields": [
      { "field": "precioVenta", "message": "debe ser mayor o igual a 0" }
    ]
  }
}
```

## 6. Fechas y zonas horarias

- Almacenamiento en base de datos: `TIMESTAMP` en **UTC**, siempre.
- Serialización en JSON: **ISO 8601** con offset → `2026-07-28T14:30:00Z`.
- El frontend convierte a hora local del navegador solo para mostrar; nunca se envía ni se almacena hora local.
- Fechas sin hora (si alguna vez se necesitan, ej. "fecha de nacimiento"): `YYYY-MM-DD`.

## 7. Autenticación y autorización (referencia rápida)

Detalle completo en `docs/flujo-jwt.md`. Convención de aquí: el código de permiso en `permisos.codigo` sigue siempre `modulo.accion` en minúsculas: `productos.crear`, `ventas.anular`, `reportes.ver`.

## 8. Commits y ramas (Git)

- Ramas: `feature/<descripcion-corta>`, `fix/<descripcion-corta>`, `docs/<descripcion-corta>`.
- Commits: [Conventional Commits](https://www.conventionalcommits.org/) → `feat: agregar CRUD de productos`, `fix: corregir cálculo de subtotal en detalle_venta`, `docs: agregar modelo ER`.
