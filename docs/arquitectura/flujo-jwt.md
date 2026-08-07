# Flujo de autenticación — AtlasERP

## 1. Estrategia elegida

**JWT simple, sin refresh token.** Un único token de acceso con expiración corta. Cuando expira, el usuario vuelve a loguearse manualmente. Es la opción más simple que sigue siendo defendible en producción para un sistema interno de uso empresarial (no una app pública de alto tráfico), y evita la complejidad adicional de gestionar rotación y revocación de refresh tokens en esta primera versión.

**Mejora futura documentada, no implementada en v1**: si el ERP escala a necesitar sesiones más largas sin re-login frecuente, la evolución natural es agregar un refresh token en cookie `httpOnly` — queda anotado en el roadmap como posible v2 de este módulo.

## 2. Configuración del token

| Parámetro | Valor |
|---|---|
| Algoritmo de firma | HS256 (clave simétrica — suficiente para un solo backend; RS256 sería necesario recién si hubiera múltiples servicios verificando el token de forma independiente) |
| Expiración | 1 hora |
| Secreto | Variable de entorno (`JWT_SECRET`), nunca hardcodeado ni versionado en Git |
| Claims incluidos | `sub` (username), `rol`, `permisos` (array de códigos, ej. `["productos.crear","ventas.ver"]`), `iat`, `exp` |

**Por qué se incluyen los permisos en el claim**: permite que `JwtAuthenticationFilter` construya las `GrantedAuthority` de Spring Security directamente desde el token, sin consultar la base de datos en cada request. Trade-off aceptado: un cambio de permisos a un usuario no tiene efecto hasta que ese usuario vuelva a loguearse (o expire su token actual). Con una expiración de 1 hora, el impacto de ese delay es bajo.

## 3. Flujo de login

```
Frontend
   ↓ POST /api/v1/auth/login { username, password }
AuthController
   ↓ delega
AuthenticationManager (Spring Security)
   ↓ valida password contra BCrypt hash almacenado
   ↓ si es válido, resuelve rol + permisos efectivos (roles_permisos + usuarios_permisos)
JwtService
   ↓ genera y firma el JWT con los claims descritos arriba
Frontend
   ↓ guarda el token, actualiza AuthContext (usuario logueado, rol, permisos)
```

**Respuesta del login** (formato acorde a `convenciones.md`):
```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "usuario": {
      "id": 12,
      "username": "jperez",
      "nombre": "Juan Pérez",
      "rol": "VENDEDOR",
      "permisos": ["productos.ver", "ventas.crear", "ventas.ver"]
    }
  }
}
```

## 4. Almacenamiento del token en el frontend

**Decisión: `localStorage`.**

| Alternativa | Riesgo / limitación |
|---|---|
| `localStorage` (elegida) | Vulnerable a robo vía XSS si hay una inyección de script en la app. Mitigación: sanitizar todo input renderizado, usar las protecciones por defecto de React (no usar `dangerouslySetInnerHTML` sin sanitizar), y a futuro agregar CSP headers. |
| Memoria (React state/context) | Más seguro contra XSS persistente, pero el usuario pierde la sesión con cada refresh de página — mala UX para un ERP donde se recarga seguido. |
| Cookie httpOnly | La más segura contra XSS, pero requiere backend emitiendo cookies y manejo de CSRF — complejidad que justifica postergar hasta la v2 con refresh token. |

Se documenta el trade-off explícitamente en vez de ignorarlo: para un ERP interno de portafolio, el riesgo de XSS se mitiga con buenas prácticas de React y el beneficio de simplicidad + persistencia entre recargas es mayor.

## 5. Flujo de una request autenticada

```
Frontend
   ↓ adjunta header Authorization: Bearer <token> (interceptor de Axios)
JwtAuthenticationFilter (OncePerRequestFilter)
   ↓ extrae el token, valida firma y expiración
   ↓ si es válido: construye Authentication con las authorities de los claims
SecurityContext
   ↓ usuario y permisos quedan disponibles para toda la request
Controller / Service
   ↓ @PreAuthorize("hasAuthority('productos.crear')") verifica el permiso puntual
Respuesta
   → 200 OK (autorizado)
   → 401 Unauthorized (token ausente, inválido o expirado)
   → 403 Forbidden (token válido, pero sin el permiso requerido)
```

## 6. Manejo de expiración en el frontend

El interceptor de respuesta de Axios (`services/api/axiosInstance.ts`) revisa cada respuesta:

- Si el status es `401`: limpia el token de `localStorage`, limpia el `AuthContext`, y redirige a `/login`.
- Si el status es `403`: no desloguea (el usuario sigue autenticado, solo no tiene permiso) — se muestra un mensaje de "no tenés permiso para esta acción".

Esta distinción entre 401 y 403 es importante y está documentada en `convenciones.md` — mezclar ambos casos es un error común que hace que el usuario pierda la sesión por errores de permisos que no son de autenticación.

## 7. Endpoints del módulo de autenticación

| Endpoint | Método | Descripción | Requiere token |
|---|---|---|---|
| `/api/v1/auth/login` | POST | Login, devuelve el JWT | No |
| `/api/v1/auth/me` | GET | Devuelve los datos del usuario autenticado (útil para restaurar sesión al recargar la app) | Sí |
