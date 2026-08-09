-- ============================================================
-- AtlasERP - V1: Schema inicial
-- Basado en docs/arquitectura/modelo-er.md
-- ============================================================

-- ---------- roles ----------
CREATE TABLE roles (
    id          BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    activo      BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMP NOT NULL DEFAULT now()
);

-- ---------- permisos ----------
CREATE TABLE permisos (
    id          BIGSERIAL PRIMARY KEY,
    codigo      VARCHAR(100) NOT NULL UNIQUE,
    modulo      VARCHAR(50) NOT NULL,
    accion      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255)
);

-- ---------- roles_permisos ----------
CREATE TABLE roles_permisos (
    rol_id     BIGINT NOT NULL REFERENCES roles(id),
    permiso_id BIGINT NOT NULL REFERENCES permisos(id),
    PRIMARY KEY (rol_id, permiso_id)
);

-- ---------- usuarios ----------
CREATE TABLE usuarios (
    id            BIGSERIAL PRIMARY KEY,
    rol_id        BIGINT NOT NULL REFERENCES roles(id),
    username      VARCHAR(50) NOT NULL UNIQUE,
    email         VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    apellido      VARCHAR(100) NOT NULL,
    activo        BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMP NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP
);

-- ---------- usuarios_permisos (excepciones GRANT/DENY) ----------
CREATE TABLE usuarios_permisos (
    usuario_id BIGINT NOT NULL REFERENCES usuarios(id),
    permiso_id BIGINT NOT NULL REFERENCES permisos(id),
    tipo       VARCHAR(10) NOT NULL CHECK (tipo IN ('GRANT', 'DENY')),
    PRIMARY KEY (usuario_id, permiso_id)
);

-- ---------- clientes ----------
CREATE TABLE clientes (
    id               BIGSERIAL PRIMARY KEY,
    tipo_documento   VARCHAR(10) NOT NULL,
    numero_documento VARCHAR(20) NOT NULL UNIQUE,
    nombre           VARCHAR(150) NOT NULL,
    email            VARCHAR(150),
    telefono         VARCHAR(20),
    direccion        VARCHAR(255),
    activo           BOOLEAN NOT NULL DEFAULT true,
    created_at       TIMESTAMP NOT NULL DEFAULT now()
);

-- ---------- proveedores ----------
CREATE TABLE proveedores (
    id               BIGSERIAL PRIMARY KEY,
    tipo_documento   VARCHAR(10) NOT NULL,
    numero_documento VARCHAR(20) NOT NULL UNIQUE,
    nombre           VARCHAR(150) NOT NULL,
    email            VARCHAR(150),
    telefono         VARCHAR(20),
    direccion        VARCHAR(255),
    activo           BOOLEAN NOT NULL DEFAULT true,
    created_at       TIMESTAMP NOT NULL DEFAULT now()
);

-- ---------- categorias ----------
CREATE TABLE categorias (
    id          BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    activo      BOOLEAN NOT NULL DEFAULT true
);

-- ---------- almacenes ----------
CREATE TABLE almacenes (
    id        BIGSERIAL PRIMARY KEY,
    nombre    VARCHAR(100) NOT NULL UNIQUE,
    direccion VARCHAR(255),
    activo    BOOLEAN NOT NULL DEFAULT true
);

-- ---------- productos ----------
CREATE TABLE productos (
    id             BIGSERIAL PRIMARY KEY,
    categoria_id   BIGINT REFERENCES categorias(id),
    codigo         VARCHAR(50) NOT NULL UNIQUE,
    nombre         VARCHAR(150) NOT NULL,
    descripcion    TEXT,
    precio_compra  NUMERIC(12,2) NOT NULL CHECK (precio_compra >= 0),
    precio_venta   NUMERIC(12,2) NOT NULL CHECK (precio_venta >= 0),
    stock_minimo   INT NOT NULL DEFAULT 0,
    imagen_url     VARCHAR(255),
    activo         BOOLEAN NOT NULL DEFAULT true,
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP
);

-- ---------- producto_stock (stock por almacen) ----------
CREATE TABLE producto_stock (
    producto_id BIGINT NOT NULL REFERENCES productos(id),
    almacen_id  BIGINT NOT NULL REFERENCES almacenes(id),
    cantidad    INT NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
    PRIMARY KEY (producto_id, almacen_id)
);

-- ---------- inventario_movimientos (kardex) ----------
CREATE TABLE inventario_movimientos (
    id                 BIGSERIAL PRIMARY KEY,
    producto_id        BIGINT NOT NULL REFERENCES productos(id),
    almacen_id         BIGINT NOT NULL REFERENCES almacenes(id),
    almacen_destino_id BIGINT REFERENCES almacenes(id),
    usuario_id         BIGINT NOT NULL REFERENCES usuarios(id),
    tipo               VARCHAR(15) NOT NULL CHECK (tipo IN ('ENTRADA', 'SALIDA', 'TRANSFERENCIA', 'AJUSTE')),
    cantidad           INT NOT NULL CHECK (cantidad > 0),
    motivo             VARCHAR(255),
    referencia_tipo    VARCHAR(20),
    referencia_id      BIGINT,
    fecha              TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT chk_transferencia CHECK (
        (tipo = 'TRANSFERENCIA' AND almacen_destino_id IS NOT NULL AND almacen_destino_id <> almacen_id)
        OR (tipo <> 'TRANSFERENCIA' AND almacen_destino_id IS NULL)
    )
);

-- ---------- compras ----------
CREATE TABLE compras (
    id             BIGSERIAL PRIMARY KEY,
    proveedor_id   BIGINT NOT NULL REFERENCES proveedores(id),
    almacen_id     BIGINT NOT NULL REFERENCES almacenes(id),
    usuario_id     BIGINT NOT NULL REFERENCES usuarios(id),
    numero_factura VARCHAR(50) NOT NULL,
    subtotal       NUMERIC(12,2) NOT NULL,
    impuesto       NUMERIC(12,2) NOT NULL DEFAULT 0,
    total          NUMERIC(12,2) NOT NULL,
    estado         VARCHAR(15) NOT NULL CHECK (estado IN ('PENDIENTE', 'COMPLETADA', 'ANULADA')),
    fecha          TIMESTAMP NOT NULL DEFAULT now()
);

-- ---------- detalle_compra ----------
CREATE TABLE detalle_compra (
    id              BIGSERIAL PRIMARY KEY,
    compra_id       BIGINT NOT NULL REFERENCES compras(id),
    producto_id     BIGINT NOT NULL REFERENCES productos(id),
    cantidad        INT NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal        NUMERIC(12,2) NOT NULL
);

-- ---------- ventas ----------
CREATE TABLE ventas (
    id             BIGSERIAL PRIMARY KEY,
    cliente_id     BIGINT NOT NULL REFERENCES clientes(id),
    almacen_id     BIGINT NOT NULL REFERENCES almacenes(id),
    usuario_id     BIGINT NOT NULL REFERENCES usuarios(id),
    numero_factura VARCHAR(50) NOT NULL,
    subtotal       NUMERIC(12,2) NOT NULL,
    impuesto       NUMERIC(12,2) NOT NULL DEFAULT 0,
    total          NUMERIC(12,2) NOT NULL,
    estado         VARCHAR(15) NOT NULL CHECK (estado IN ('PENDIENTE', 'COMPLETADA', 'ANULADA')),
    fecha          TIMESTAMP NOT NULL DEFAULT now()
);

-- ---------- detalle_venta ----------
CREATE TABLE detalle_venta (
    id              BIGSERIAL PRIMARY KEY,
    venta_id        BIGINT NOT NULL REFERENCES ventas(id),
    producto_id     BIGINT NOT NULL REFERENCES productos(id),
    cantidad        INT NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal        NUMERIC(12,2) NOT NULL
);

-- ---------- auditoria ----------
CREATE TABLE auditoria (
    id          BIGSERIAL PRIMARY KEY,
    usuario_id  BIGINT REFERENCES usuarios(id),
    accion      VARCHAR(50) NOT NULL,
    entidad     VARCHAR(50) NOT NULL,
    entidad_id  BIGINT,
    detalle     JSONB,
    ip_address  VARCHAR(45),
    fecha       TIMESTAMP NOT NULL DEFAULT now()
);

-- ============================================================
-- Indices recomendados (docs/arquitectura/modelo-er.md, seccion 5)
-- ============================================================
CREATE INDEX idx_productos_codigo ON productos(codigo);
CREATE INDEX idx_inv_mov_producto_almacen_fecha ON inventario_movimientos(producto_id, almacen_id, fecha);
CREATE INDEX idx_ventas_fecha ON ventas(fecha);
CREATE INDEX idx_compras_fecha ON compras(fecha);
CREATE INDEX idx_auditoria_entidad ON auditoria(entidad, entidad_id);
