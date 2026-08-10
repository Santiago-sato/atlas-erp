# JWT — Implementación — AtlasERP

> Este documento cubre la implementación real (Sprint 5). El diseño y las decisiones de arquitectura están en `flujo-jwt.md` (Sprint 4) — léelo primero para el contexto de las decisiones (por qué sin refresh token, por qué localStorage, etc).

## 1. Dependencias

```xml
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.6</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.12.6</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.12.6</version>
    <scope>runtime</scope>
</dependency>
```

`jjwt` es independiente de Spring — no forma parte del ecosistema Spring Boot, por eso necesita versión explícita (a diferencia de los starters de Spring, que la resuelven vía el BOM del `spring-boot-starter-parent`).

## 2. Configuración

```yaml
jwt:
  secret: ${JWT_SECRET:atlaserp-dev-secret-key-please-change-in-production-2026}
  expiration: 3600000
```

- **Algoritmo**: HS256 (clave simétrica), tal como se definió en el diseño.
- **Secreto**: en desarrollo tiene un default en el YAML; en producción se espera que llegue vía la variable de entorno `JWT_SECRET`, nunca hardcodeado.
- **Longitud mínima del secreto**: HS256 exige al menos 32 bytes o la librería lanza `WeakKeyException` al arrancar. El default de desarrollo cumple este mínimo.
- **Expiración**: `3600000` ms = 1 hora, según lo definido en `flujo-jwt.md`.

## 3. `JwtService` — métodos principales

```java
public String generateToken(Usuario usuario)
```
Arma el token con:
- `sub` — el username
- `rol` — nombre del rol (ej. `"ADMIN"`)
- `permisos` — array de códigos de permiso (ej. `["productos.crear", "ventas.ver", ...]`), calculados desde `usuario.getRol().getPermisos()`
- `iat` / `exp` — emisión y expiración

```java
public Claims extractAllClaims(String token)
public String extractUsername(String token)
public boolean isTokenValid(String token)
```
`isTokenValid` verifica firma (implícito en el parseo — si la firma no coincide, `parseSignedClaims` lanza excepción) y expiración explícitamente contra la hora actual.

## 4. Por qué `JOIN FETCH` en el repositorio

`Usuario.rol` y `Rol.permisos` son relaciones `LAZY`. Si `JwtService.generateToken()` intentara leer `usuario.getRol().getPermisos()` fuera de una sesión de Hibernate activa, lanzaría `LazyInitializationException`. Por eso `UsuarioRepository` tiene:

```java
@Query("SELECT u FROM Usuario u JOIN FETCH u.rol r LEFT JOIN FETCH r.permisos WHERE u.username = :username")
Optional<Usuario> findByUsernameWithRolAndPermisos(String username);
```

Una sola consulta trae usuario, rol y permisos juntos, evitando tanto el error de lazy loading como el problema N+1 (evitar una query por cada permiso).

## 5. Filtro de validación (`JwtAuthenticationFilter`)

No consulta la base de datos en cada request — arma la `Authentication` directamente desde los claims del token (rol y permisos ya vienen adentro). Esto es intencional y está documentado como trade-off en `flujo-jwt.md`: mejor performance, a cambio de que un cambio de permisos no se refleje hasta el próximo login.

## 6. Testing manual del hash BCrypt

Para generar el hash del usuario admin (`V2__seed_admin_user.sql`), se usó un test JUnit temporal que instanciaba `BCryptPasswordEncoder` directamente y imprimía el hash por consola — no quedó en el repositorio final, fue una herramienta de un solo uso para no inventar un hash a mano.
