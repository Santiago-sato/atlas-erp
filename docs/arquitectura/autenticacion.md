# Autenticación — AtlasERP

## 1. Resumen

El módulo de autenticación implementado en el Sprint 5 cubre: modelo de usuarios/roles/permisos, login con JWT, protección de rutas, manejo de errores 401/403, y un frontend funcional que consume todo esto de punta a punta.

Documentos relacionados:
- `spring-security.md` — configuración de Spring Security, filtros, CORS, manejo de excepciones
- `jwt.md` — detalle del `JwtService`, claims, firma, expiración
- `api-auth.md` — referencia de la API (`POST /api/v1/auth/login`)

## 2. Modelo de datos

Tres entidades JPA reflejan el modelo diseñado en el Sprint 4 (`docs/arquitectura/modelo-er.md`):

- **`Rol`** — `roles`, con relación `@ManyToMany` a `Permiso` vía `roles_permisos`.
- **`Permiso`** — `permisos`, con `codigo` en formato `modulo.accion` (ej. `productos.crear`).
- **`Usuario`** — `usuarios`, con `@ManyToOne` a `Rol`.

La tabla `usuarios_permisos` (excepciones GRANT/DENY por usuario) existe en el schema desde el Sprint 4, pero **todavía no tiene entidad JPA ni lógica asociada** — queda para un sprint posterior cuando se implementen los primeros CRUDs y se necesite resolver permisos efectivos por usuario, no solo por rol.

## 3. Seed inicial

La migración `V2__seed_admin_user.sql` (Flyway) crea:
- 48 permisos (12 módulos × 4 acciones: `ver`, `crear`, `editar`, `eliminar`)
- El rol `ADMIN` con los 48 permisos asignados
- El usuario `admin` (contraseña `Admin123*`, hasheada con BCrypt)

## 4. Flujo end-to-end verificado

```
React LoginPage
   ↓ AuthContext.login()
authService (Axios)
   ↓ POST /api/v1/auth/login
AuthController
   ↓ AuthenticationManager.authenticate()
UserDetailsServiceImpl → BCrypt valida password
   ↓
JwtService genera el token (rol + permisos en los claims)
   ↓
Respuesta { data: { accessToken, user }, meta }
   ↓
Frontend guarda token en localStorage, actualiza AuthContext
   ↓
Navigate a /dashboard (ProtectedRoute verifica isAuthenticated)
```

Verificado manualmente con `admin` / `Admin123*`, tanto desde Swagger UI como desde el frontend en el navegador.

## 5. Limitaciones conocidas (documentadas intencionalmente, no pendientes por descuido)

- **Sin refresh token** — decisión tomada en `flujo-jwt.md` (Sprint 4). El usuario re-loguea al expirar (1 hora).
- **Token en `localStorage`** — trade-off de XSS vs UX aceptado y documentado en `flujo-jwt.md`.
- **Permisos en el JWT quedan "congelados" hasta el próximo login** — si se cambia el rol o los permisos de un usuario activo, no se refleja hasta que ese usuario vuelva a loguearse.
- **`usuarios_permisos` sin implementar** — el modelo de excepciones GRANT/DENY existe en la base pero no en el código todavía.
- **CORS con origen fijo por variable de entorno** — funciona para desarrollo (una sola IP de frontend conocida); en producción con dominio propio se simplifica a un solo origen HTTPS.

## 6. Cómo probar

**Vía Swagger**: `http://<IP-erp-back>:8080/swagger-ui/index.html` → `POST /api/v1/auth/login` → "Try it out".

**Vía curl**:
```bash
curl -s -X POST http://<IP-erp-back>:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin123*"}'
```

**Vía frontend**: `http://<IP-erp-front>:5173` → formulario de login → redirige a `/dashboard`.
