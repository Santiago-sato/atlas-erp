# API — Autenticación — AtlasERP

Referencia de los endpoints del módulo de autenticación. Documentación interactiva disponible en Swagger UI: `http://<host>:8080/swagger-ui/index.html`.

## `POST /api/v1/auth/login`

Autentica un usuario y devuelve un JWT.

**Autenticación requerida**: No (endpoint público).

### Request

```http
POST /api/v1/auth/login
Content-Type: application/json
```

```json
{
  "username": "admin",
  "password": "Admin123*"
}
```

| Campo | Tipo | Requerido | Notas |
|---|---|---|---|
| `username` | string | Sí | No puede estar vacío |
| `password` | string | Sí | No puede estar vacío |

### Respuesta exitosa — `200 OK`

```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzM4NCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "id": 1,
      "username": "admin",
      "email": "admin@atlaserp.local",
      "nombre": "Administrador",
      "apellido": "AtlasERP",
      "rol": "ADMIN"
    }
  },
  "meta": {
    "timestamp": "2026-08-09T16:44:39.103354896Z"
  }
}
```

`expiresIn` está en segundos (no milisegundos), pensado para que el frontend lo use directo en lógica de expiración sin conversiones.

### Respuestas de error

**`401 Unauthorized`** — credenciales incorrectas:
```json
{
  "error": {
    "code": "CREDENCIALES_INVALIDAS",
    "message": "Usuario o password incorrectos",
    "status": 401,
    "timestamp": "2026-08-09T16:44:38.630523292Z",
    "path": "/api/v1/auth/login",
    "fields": null
  }
}
```

**`400 Bad Request`** — validación fallida (ej. campos vacíos):
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Uno o mas campos son invalidos",
    "status": 400,
    "timestamp": "...",
    "path": "/api/v1/auth/login",
    "fields": [
      { "field": "username", "message": "El username es obligatorio" }
    ]
  }
}
```

### Ejemplo curl

```bash
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin123*"}'
```

## Uso del token en requests subsiguientes

Todos los endpoints protegidos (cualquier ruta fuera de `/api/v1/auth/**`, `/swagger-ui/**`, `/v3/api-docs/**`, `/actuator/health`) esperan:

```http
Authorization: Bearer <accessToken>
```

### Errores de autorización

**`401 Unauthorized`** — sin token o token invalido/expirado:
```json
{
  "error": {
    "code": "NO_AUTENTICADO",
    "message": "Se requiere autenticacion para acceder a este recurso",
    "status": 401,
    "timestamp": "...",
    "path": "/api/v1/algo-inventado"
  }
}
```

**`403 Forbidden`** — token válido pero sin el permiso requerido:
```json
{
  "error": {
    "code": "ACCESO_DENEGADO",
    "message": "No tenes permiso para realizar esta accion",
    "status": 403,
    "timestamp": "...",
    "path": "/api/v1/..."
  }
}
```

## Probar desde Swagger UI

1. Ejecutar `POST /api/v1/auth/login` con "Try it out".
2. Copiar el `accessToken` de la respuesta.
3. Click en el botón **Authorize** (candado, arriba a la derecha).
4. Pegar el token en el campo `bearerAuth` (sin la palabra `Bearer`, Swagger la agrega solo).
5. Cualquier endpoint protegido que se pruebe después ya va a incluir el header automáticamente.
