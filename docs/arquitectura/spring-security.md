# Spring Security — AtlasERP

## 1. Piezas y responsabilidades

| Clase | Rol |
|---|---|
| `SecurityConfig` | Cadena de filtros, reglas de autorización, CORS, beans de `AuthenticationManager` |
| `JwtAuthenticationFilter` | Intercepta cada request, valida el JWT, construye la `Authentication` desde los claims |
| `UserDetailsServiceImpl` | Usado **solo** durante el login, para validar la password contra la base |
| `JwtService` | Genera y valida tokens (detalle completo en `jwt.md`) |
| `JsonAuthenticationEntryPoint` | Responde 401 en JSON cuando falta autenticación |
| `JsonAccessDeniedHandler` | Responde 403 en JSON cuando el usuario está autenticado pero sin permiso |
| `GlobalExceptionHandler` | Captura excepciones dentro de los controllers (`BadCredentialsException`, validaciones, etc.) |
| `CorsConfig` | Configura los orígenes permitidos vía `app.cors.allowed-origins` |

## 2. Por qué dos manejadores de error distintos

`JsonAuthenticationEntryPoint`/`JsonAccessDeniedHandler` y `GlobalExceptionHandler` cubren momentos distintos del ciclo de una request:

- **Filtros de Spring Security** (`JwtAuthenticationFilter`, y el punto donde se decide 401/403) corren **antes** de que la request llegue al `DispatcherServlet`. Un `@RestControllerAdvice` como `GlobalExceptionHandler` no los puede interceptar, porque ese mecanismo depende de Spring MVC, que todavía no entró en juego.
- Por eso `SecurityConfig` registra `authenticationEntryPoint` y `accessDeniedHandler` explícitamente vía `.exceptionHandling(...)`, en vez de dejar que el `GlobalExceptionHandler` los resuelva.
- `GlobalExceptionHandler` sigue siendo responsable de todo lo que pasa **dentro** de un controller: `BadCredentialsException` lanzada por `AuthenticationManager.authenticate()`, errores de validación (`@Valid`), y cualquier excepción no controlada.

## 3. Por qué los JSON de error se arman a mano en los manejadores de seguridad

`JsonAuthenticationEntryPoint` y `JsonAccessDeniedHandler` originalmente intentaban inyectar un `ObjectMapper` (Jackson) para serializar el `ErrorResponse`. En Spring Boot 4 (que usa Jackson 3 internamente), el bean autoconfigurado por defecto es un `JsonMapper` inmutable, no el `ObjectMapper` clásico de Jackson 2 — inyectar `com.fasterxml.jackson.databind.ObjectMapper` directamente falla con `NoSuchBeanDefinitionException` en algunos escenarios de arranque temprano del contexto.

Como estos dos manejadores producen una estructura fija y simple (sin datos de negocio complejos), se optó por construir el JSON manualmente con un `String.formatted()`, evitando la dependencia del bean de Jackson por completo. Es una solución pragmática para este caso puntual — el `GlobalExceptionHandler`, que sí corre dentro del ciclo normal de Spring MVC, no tiene este problema y usa los DTOs (`ErrorResponse`) normalmente, serializados por el `HttpMessageConverter` que Spring ya tiene resuelto en ese punto.

## 4. Cadena de filtros (resumen)

```
Request
   ↓
CORS (verifica origen permitido)
   ↓
JwtAuthenticationFilter (antes de UsernamePasswordAuthenticationFilter)
   ↓ si hay token valido: puebla el SecurityContext
   ↓ si no: sigue sin autenticar
authorizeHttpRequests
   ↓ /api/v1/auth/**, /swagger-ui/**, /v3/api-docs/**, /actuator/health -> publico
   ↓ cualquier otra ruta -> requiere autenticacion
   ↓ sin autenticar -> JsonAuthenticationEntryPoint (401)
   ↓ autenticado sin permiso -> JsonAccessDeniedHandler (403)
Controller
```

## 5. CORS

`CorsConfig` usa `@ConfigurationProperties(prefix = "app.cors")` en vez de `@Value` para leer `app.cors.allowed-origins` — es una lista en YAML, y Spring representa las listas YAML como propiedades indexadas (`app.cors.allowed-origins[0]`, `[1]`, ...) internamente. `@Value` no reensambla esas entradas en una `List`; `@ConfigurationProperties` sí. `@Value` funciona bien para valores simples (`jwt.secret`, `jwt.expiration`), pero no para colecciones.

`allowCredentials(true)` está habilitado porque el frontend necesita poder enviar el header `Authorization` en requests cross-origin.

## 6. Notas sobre Spring Boot 4 (modularización)

Durante la implementación aparecieron dos sorpresas relacionadas a como Spring Boot 4 modularizó su autoconfiguración (separó `spring-boot-autoconfigure` en módulos más chicos por feature):

- **Flyway**: `flyway-core` + `flyway-database-postgresql` sueltos ya no alcanzan; hace falta el starter dedicado `spring-boot-starter-flyway` para que la autoconfiguración de Spring se active.
- **Jackson**: el bean por defecto es `JsonMapper` (Jackson 3), no `ObjectMapper` (Jackson 2) — ver seccion 3 arriba.

Quedan documentadas acá porque son del tipo de detalle que solo se descubre debuggeando, y le va a ahorrar tiempo a quien retome este proyecto (incluido el autor, en unos meses).
