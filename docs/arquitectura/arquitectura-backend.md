# Arquitectura del backend — AtlasERP

## 1. Estructura de paquetes

```
backend/
└── src/main/java/com/atlaserp/
    ├── AtlasErpApplication.java
    │
    ├── config/                    # Configuración de Spring: CORS, OpenAPI/Swagger, beans generales
    │   ├── SecurityConfig.java
    │   ├── OpenApiConfig.java
    │   └── CorsConfig.java
    │
    ├── security/                  # Todo lo relacionado a JWT y autenticación
    │   ├── JwtService.java
    │   ├── JwtAuthenticationFilter.java
    │   ├── UserDetailsServiceImpl.java
    │   └── SecurityUtils.java
    │
    ├── controller/                # Solo reciben la request, delegan al service y devuelven ResponseEntity
    │   ├── ProductoController.java
    │   ├── VentaController.java
    │   └── AuthController.java
    │
    ├── service/                   # Lógica de negocio. Interfaz + implementación
    │   ├── ProductoService.java
    │   └── impl/
    │       └── ProductoServiceImpl.java
    │
    ├── repository/                # Interfaces JpaRepository, sin lógica
    │   └── ProductoRepository.java
    │
    ├── entity/                    # Entidades JPA — reflejan 1:1 el modelo-er.md
    │   ├── Producto.java
    │   ├── ProductoStock.java
    │   └── ...
    │
    ├── dto/
    │   ├── request/                # Lo que el cliente envía
    │   │   └── ProductoRequest.java
    │   └── response/               # Lo que la API devuelve
    │       └── ProductoResponse.java
    │
    ├── mapper/                    # Entity <-> DTO (MapStruct)
    │   └── ProductoMapper.java
    │
    ├── exception/                  # Excepciones custom + GlobalExceptionHandler
    │   ├── GlobalExceptionHandler.java
    │   ├── RecursoNoEncontradoException.java
    │   └── StockInsuficienteException.java
    │
    ├── validation/                 # Validadores custom (@Constraint) si los hay
    │
    └── util/                       # Helpers puros, sin estado ni dependencias de Spring
```

**Regla de oro**: cada capa solo conoce a la de abajo. `Controller` nunca toca `Repository` directamente. `Service` nunca devuelve una `Entity` al controller — siempre un DTO vía `Mapper`. Esto evita que un cambio en la base de datos rompa la API pública.

## 2. Flujo de una request

```
Cliente (React + Axios)
    ↓
Controller — recibe request, valida DTO
    ↓
Service — lógica de negocio
    ↓
Repository — Spring Data JPA
    ↓
PostgreSQL — persistencia
```

## 3. Cross-cutting concerns (atraviesan varias capas)

- **Security (JWT filter)**: se ejecuta antes del Controller. Filtro de Spring Security que valida el token e inyecta el usuario autenticado en el `SecurityContext`. Si el token es inválido, la request nunca llega al Controller.
- **DTO / Mapper**: la conversión Entity ↔ DTO ocurre en el límite Service–Controller. El Controller nunca ve una `Entity` JPA directamente; el Service nunca devuelve un objeto pensado para la respuesta HTTP.
- **GlobalExceptionHandler** (`@RestControllerAdvice`): captura cualquier excepción lanzada en Controller, Service o Repository y la traduce al formato de error definido en `convenciones.md` (sección 5.3).

## 4. Principios de diseño

- **Separación de responsabilidades estricta**: un Controller no contiene lógica de negocio; un Service no conoce detalles de HTTP (códigos de estado, headers).
- **Inyección de dependencias por constructor**, nunca por campo (`@Autowired` en field), para facilitar testing y dejar explícitas las dependencias.
- **Interfaces para los Services**: permite mockear en tests unitarios sin levantar el contexto de Spring completo.
- **Transacciones (`@Transactional`) a nivel de Service**, nunca en Controller ni Repository — el Service es quien conoce el alcance real de la unidad de trabajo (ej. una venta que descuenta stock y crea el detalle debe ser atómica).
