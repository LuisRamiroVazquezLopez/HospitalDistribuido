-- ESQUEMA DE LA BASE DE DATOS MySQL DEL HOSPITAL DISTRIBUIDO

-- Tabla de especialidad
CREATE TABLE especialidad (
    especialidad_id   SMALLINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(80)  NOT NULL,
    descripcion       VARCHAR(255) NULL,
    PRIMARY KEY (especialidad_id),
    UNIQUE (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabla de consultorio
CREATE TABLE consultorio (
    consultorio_id  SMALLINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    sucursal_id      SMALLINT UNSIGNED  NOT NULL,
    numero   VARCHAR(10) NOT NULL,
    piso    TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (consultorio_id),
    -- PARA QUE NO SE REPITAN EL NUMERO Y LA SUCURSAL EN LA MISMA SEDE
    UNIQUE (sucursal_id, numero)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- Esta tabla no tiene llave foranea de la sede pues esas viven en PostgreSQL y una FK solo puede apuntar a una tabla de la misma base, para verificar la existencia de la sucursal y la sede, se usa la API

-- Tabla de medico
CREATE TABLE medico (
    medico_id   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(60)  NOT NULL,
    apellido_paterno   VARCHAR(60)  NOT NULL,
    apellido_materno   VARCHAR(60)  NULL,
    cedula_profesional  VARCHAR(20)  NOT NULL,
    especialidad_id SMALLINT UNSIGNED NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (medico_id),
    FOREIGN KEY (especialidad_id) REFERENCES especialidad(especialidad_id),
    UNIQUE (cedula_profesional)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabla de paciente (Fragmentación vertical, primera parte de la tabla de paciente)
CREATE TABLE paciente_datos (
    paciente_id   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(60)  NOT NULL,
    apellido_paterno   VARCHAR(60)  NOT NULL,
    apellido_materno   VARCHAR(60)  NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo ENUM('M', 'F', 'O') NOT NULL,
    tipo_sangre ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (paciente_id),
    INDEX (apellido_paterno, nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de paciente (Fragmentación vertical, segunda parte de la tabla de paciente)
CREATE TABLE paciente_sensible (
    paciente_id   INT UNSIGNED  NOT NULL,
    curp          CHAR(18)  NOT NULL,
    direccion     VARCHAR(200)  NOT NULL,
    telefono      VARCHAR(15)   NOT NULL,
    correo_electronico VARCHAR(120)  NULL,
    aseguradora VARCHAR(80) NULL,
    numero_poliza VARCHAR(30) NULL,
    UNIQUE (curp),
    PRIMARY KEY (paciente_id),
    -- ON DELETE CASCADE para que si se elimina un paciente de la tabla paciente_datos, también se elimine su información sensible
    FOREIGN KEY (paciente_id) REFERENCES paciente_datos(paciente_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de cita
CREATE TABLE cita (
    cita_id   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    paciente_id   INT UNSIGNED  NOT NULL,
    medico_id   INT UNSIGNED  NOT NULL,
    consultorio_id   SMALLINT UNSIGNED  NOT NULL,
    fecha_hora DATETIME NOT NULL,
    estado ENUM('programada', 'cancelada', 'completada', 'en_espera') NOT NULL DEFAULT 'programada',
    motivo VARCHAR(255) NULL,
    creada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (paciente_id) REFERENCES paciente_datos(paciente_id),
    FOREIGN KEY (medico_id) REFERENCES medico(medico_id),
    FOREIGN KEY (consultorio_id) REFERENCES consultorio(consultorio_id),
    PRIMARY KEY (cita_id),
    INDEX (medico_id, fecha_hora)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
