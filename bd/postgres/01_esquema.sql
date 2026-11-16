-- ESQUEMA DE LA BASE DE DATOS PostgreSQL DEL HOSPITAL DISTRIBUIDO
-- Tabla sucursal 
CREATE TABLE sucursal (
    sucursal_id  SMALLINT  NOT NULL CHECK (sucursal_id > 0),
    nombre       VARCHAR(80)  NOT NULL,
    ciudad    VARCHAR(60)  NOT NULL,
    direccion VARCHAR(200)  NOT NULL,
    telefono     VARCHAR(15)    NULL,
    activa BOOLEAN  NOT NULL DEFAULT TRUE,
    PRIMARY KEY (sucursal_id),
    UNIQUE (nombre)
);

-- Tabla inventario_farmacia
CREATE TABLE inventario_farmacia (
    inventario_id  INT  NOT NULL  GENERATED ALWAYS AS IDENTITY,
    sucursal_id    SMALLINT  NOT NULL,
    medicamento VARCHAR(100)  NOT NULL,
    presentacion VARCHAR(60) NOT NULL,
    existencia INT NOT NULL DEFAULT 0 CHECK (existencia >= 0),
    stock_minimo INT NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (sucursal_id, medicamento, presentacion),
    UNIQUE (inventario_id, sucursal_id),
    PRIMARY KEY (inventario_id),
    FOREIGN KEY (sucursal_id) REFERENCES sucursal(sucursal_id)
);

-- Tabla movimiento_inventario
CREATE TABLE movimiento_inventario (
    movimiento_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    sucursal_id SMALLINT NOT NULL,
    inventario_id INT NOT NULL,
    tipo VARCHAR(15) NOT NULL CHECK (tipo IN ('surtido', 'reabasto', 'ajuste')),
    cantidad INT NOT NULL CHECK (cantidad <> 0),
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (movimiento_id, sucursal_id),
    FOREIGN KEY (inventario_id, sucursal_id) REFERENCES inventario_farmacia(inventario_id, sucursal_id)
) PARTITION BY LIST (sucursal_id);

-- Particiones de la tabla movimiento_inventario por sucursal_id
CREATE TABLE movimiento_inventario_s1 PARTITION OF movimiento_inventario FOR VALUES IN (1);
CREATE TABLE movimiento_inventario_s2 PARTITION OF movimiento_inventario FOR VALUES IN (2);
CREATE TABLE movimiento_inventario_s3 PARTITION OF movimiento_inventario FOR VALUES IN (3);
CREATE TABLE movimiento_inventario_s4 PARTITION OF movimiento_inventario FOR VALUES IN (4);
CREATE TABLE movimiento_inventario_s5 PARTITION OF movimiento_inventario FOR VALUES IN (5);

-- Creamos un índice para optimizar las consultas por inventario_id y fecha_hora
CREATE INDEX ON movimiento_inventario (inventario_id, fecha_hora);

-- Tabla receta
CREATE TABLE receta (
    receta_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    sucursal_id SMALLINT NOT NULL,
    inventario_id INT NOT NULL,
    cita_id BIGINT NOT NULL,
    paciente_id INT NOT NULL,
    medico_id INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    indicaciones VARCHAR(255) NOT NULL,
    estado VARCHAR(12) NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'surtida', 'cancelada')),
    emitida_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    surtida_en TIMESTAMPTZ NULL,
    FOREIGN KEY (inventario_id, sucursal_id) REFERENCES inventario_farmacia(inventario_id, sucursal_id), 
    PRIMARY KEY (receta_id)
);

-- Indice en cita_id para optimizar consultas por cita
CREATE INDEX idx_receta_cita_id ON receta (cita_id);

-- Tabla de cama
CREATE TABLE cama (
    cama_id INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    sucursal_id SMALLINT NOT NULL,
    numero VARCHAR(10) NOT NULL,
    area VARCHAR(20) NOT NULL CHECK (area IN ('urgencias', 'hospitalizacion', 'terapia_intensiva', 'pediatria')),
    piso SMALLINT NOT NULL CHECK (piso >= 0),   
    estado VARCHAR(15) NOT NULL DEFAULT 'disponible' CHECK (estado IN ('disponible', 'ocupada', 'limpieza', 'mantenimiento')),
    paciente_id INT NULL,
    actualizada_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (cama_id),
    UNIQUE (sucursal_id, numero),
    FOREIGN KEY (sucursal_id) REFERENCES sucursal(sucursal_id),
    CHECK ((estado = 'ocupada') = (paciente_id IS NOT NULL))
);

-- Tabla de personal_turno
CREATE TABLE personal_turno (
    turno_id INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    sucursal_id SMALLINT NOT NULL,
    empleado VARCHAR(120) NOT NULL,
    puesto VARCHAR(20) NOT NULL CHECK (puesto IN ('medico', 'enfermeria', 'farmacia', 'camillero', 'administrativo')),
    medico_id INT NULL,
    fecha DATE NOT NULL,
    turno VARCHAR(10) NOT NULL CHECK (turno IN ('matutino', 'vespertino', 'nocturno')),
    registrado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (turno_id),
    UNIQUE (sucursal_id, fecha, turno, empleado),
    FOREIGN KEY (sucursal_id) REFERENCES sucursal(sucursal_id),
    CHECK ((puesto = 'medico') = (medico_id IS NOT NULL))
);

