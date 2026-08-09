-- ============================================================
-- AtlasERP - V2: Seed de permisos, rol ADMIN y usuario admin
-- ============================================================

-- ---------- permisos ----------
-- Genera el producto cartesiano modulo x accion para todos los modulos del ERP.
-- Codigo sigue la convencion modulo.accion (docs/arquitectura/convenciones.md, seccion 7).
INSERT INTO permisos (codigo, modulo, accion, descripcion)
SELECT modulo || '.' || accion,
       modulo,
       accion,
       'Permiso para ' || accion || ' en el modulo ' || modulo
FROM unnest(ARRAY[
        'usuarios', 'roles', 'clientes', 'proveedores', 'categorias',
        'productos', 'almacenes', 'inventario', 'compras', 'ventas',
        'reportes', 'auditoria'
     ]) AS modulo
CROSS JOIN unnest(ARRAY['ver', 'crear', 'editar', 'eliminar']) AS accion;

-- ---------- rol ADMIN ----------
INSERT INTO roles (nombre, descripcion, activo)
VALUES ('ADMIN', 'Administrador con acceso completo al sistema', true);

-- ---------- roles_permisos: ADMIN obtiene TODOS los permisos ----------
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT (SELECT id FROM roles WHERE nombre = 'ADMIN'), id
FROM permisos;

-- ---------- usuario admin ----------
-- Password: Admin123*  (hash BCrypt generado con el PasswordEncoder real del proyecto)
INSERT INTO usuarios (rol_id, username, email, password_hash, nombre, apellido, activo)
VALUES (
    (SELECT id FROM roles WHERE nombre = 'ADMIN'),
    'admin',
    'admin@atlaserp.local',
    '$2a$10$W51/vsgnV7P6zp66jDD1RejZfgaxX0wM1jAqNnrx0hYPc.Ph42ur.',
    'Administrador',
    'AtlasERP',
    true
);
