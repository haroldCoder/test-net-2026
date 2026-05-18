-- =========================================================================
-- PRUEBA TÉCNICA: ESTRUCTURA DE BD RELACIONAL Y PROCEDIMIENTOS ALMACENADOS
-- MOTOR: Microsoft SQL Server
-- =========================================================================

-- Usar master o la base de datos por defecto del contenedor
USE tempdb; -- tempdb es ideal para entornos de prueba, pero crearemos una BD propia si lo deseas
GO

-- Crear Base de Datos para el sistema
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SedesRecreativasDB')
BEGIN
    ALTER DATABASE SedesRecreativasDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SedesRecreativasDB;
END
GO

CREATE DATABASE SedesRecreativasDB;
GO

USE SedesRecreativasDB;
GO

-- =========================================================================
-- 1. CREACIÓN DE LA ESTRUCTURA DE TABLAS (SCHEMA RELACIONAL)
-- =========================================================================

-- Tabla de Sedes (Sitios)
CREATE TABLE Sedes (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL UNIQUE,
    Tipo VARCHAR(50) NOT NULL CHECK (Tipo IN ('Apartamento', 'Sede Recreativa')),
    Ciudad VARCHAR(100) NOT NULL
);

-- Tabla de Unidades de Alojamiento (Habitaciones / Cabañas / Apartamentos)
CREATE TABLE UnidadesAlojamiento (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SedeId INT NOT NULL FOREIGN KEY REFERENCES Sedes(Id),
    Nombre VARCHAR(100) NOT NULL, -- Ej: 'Apartamento 202', 'Cabaña 5', 'Habitación 1'
    TipoAlojamiento VARCHAR(100) NOT NULL, -- 'Apartamento', 'Habitación', 'Cabaña', 'Bloque Nuevo'
    HabitacionesInternas INT NOT NULL DEFAULT 1 CHECK (HabitacionesInternas >= 1), -- Alcobas internas (importante para tarifas)
    CapacidadMaxima INT NOT NULL CHECK (CapacidadMaxima > 0),
    EsNuevo BIT NOT NULL DEFAULT 0, -- Lógica especial de nuevos alojamientos
    DetalleCamas VARCHAR(500) NULL,
    CONSTRAINT UQ_Sede_Unidad UNIQUE(SedeId, Nombre)
);

-- Tabla de Días Festivos (Colombia) para control de tarifa especial Lunes-Jueves
CREATE TABLE Festivos (
    Fecha DATE PRIMARY KEY,
    Descripcion VARCHAR(100) NOT NULL
);

-- Tabla de Temporadas Altas parametrizadas
CREATE TABLE TemporadasAlta (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    CONSTRAINT CK_Fechas CHECK (FechaFin >= FechaInicio)
);

-- Tabla de Reservas realizadas
CREATE TABLE Reservas (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UnidadId INT NOT NULL FOREIGN KEY REFERENCES UnidadesAlojamiento(Id),
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    CantidadPersonas INT NOT NULL CHECK (CantidadPersonas > 0),
    AcompanantesDia INT NOT NULL DEFAULT 0 CHECK (AcompanantesDia >= 0),
    UsaLavanderia BIT NOT NULL DEFAULT 0,
    TotalAPagar DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT CK_RangoFechas CHECK (FechaFin > FechaInicio)
);
GO

-- =========================================================================
-- 2. SEMILLA DE DATOS (SEEDS)
-- =========================================================================

-- Inserción de Sedes (Sitios)
INSERT INTO Sedes (Nombre, Tipo, Ciudad) VALUES
('Medellín - Suramericana', 'Apartamento', 'Medellín'),
('Santa Marta - El Rodadero', 'Apartamento', 'Santa Marta'),
('Villeta', 'Sede Recreativa', 'Villeta'),
('El Placer - Fusagasugá', 'Sede Recreativa', 'Fusagasugá'),
('Gonzalo Morante - Chinchiná', 'Sede Recreativa', 'Chinchiná'),
('Tablones - Palmira', 'Sede Recreativa', 'Palmira'),
('Manguruma - Santa fe de Antioquia', 'Sede Recreativa', 'Santa fe de Antioquia'),
('Federman - Bogotá', 'Sede Recreativa', 'Bogotá');

-- Obtener IDs para asociar correctamente las unidades
DECLARE @SedeMedellin INT = (SELECT Id FROM Sedes WHERE Nombre = 'Medellín - Suramericana');
DECLARE @SedeSantaMarta INT = (SELECT Id FROM Sedes WHERE Nombre = 'Santa Marta - El Rodadero');
DECLARE @SedeVilleta INT = (SELECT Id FROM Sedes WHERE Nombre = 'Villeta');
DECLARE @SedeFusa INT = (SELECT Id FROM Sedes WHERE Nombre = 'El Placer - Fusagasugá');
DECLARE @SedeChinchina INT = (SELECT Id FROM Sedes WHERE Nombre = 'Gonzalo Morante - Chinchiná');
DECLARE @SedePalmira INT = (SELECT Id FROM Sedes WHERE Nombre = 'Tablones - Palmira');
DECLARE @SedeAntioquia INT = (SELECT Id FROM Sedes WHERE Nombre = 'Manguruma - Santa fe de Antioquia');
DECLARE @SedeBogota INT = (SELECT Id FROM Sedes WHERE Nombre = 'Federman - Bogotá');

-- INSERCIÓN DE UNIDADES DE ALOJAMIENTO

-- 1. Medellín
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedeMedellin, 'Habitación 1', 'Habitación', 1, 2, 0, '2 camas sencillas, baño privado'),
(@SedeMedellin, 'Habitación 2', 'Habitación', 1, 2, 0, '2 camas sencillas'),
(@SedeMedellin, 'Habitación 3', 'Habitación', 1, 2, 0, '2 camas sencillas'),
(@SedeMedellin, 'Habitación 4', 'Habitación', 1, 2, 0, '2 camas sencillas'),
(@SedeMedellin, 'Habitación 5', 'Habitación', 1, 1, 0, '1 cama sencilla, baño privado');

-- 2. Santa Marta
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedeSantaMarta, 'Apartamento 202', 'Apartamento', 3, 8, 0, 'Sala comedor, cocina, 2 baños, 3 habitaciones, parqueadero. Capacidad máxima: 8 personas'),
(@SedeSantaMarta, 'Apartamento 301', 'Apartamento', 2, 6, 0, 'Sala comedor, cocina, 1 baño, 2 habitaciones, parqueadero. Capacidad máxima: 6 personas'),
(@SedeSantaMarta, 'Apartamento 401', 'Apartamento', 2, 6, 0, 'Sala comedor, cocina, 1 baño, 2 habitaciones, parqueadero. Capacidad máxima: 6 personas');

-- 3. Villeta
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedeVilleta, 'Habitación 1', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta'),
(@SedeVilleta, 'Habitación 2', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta'),
(@SedeVilleta, 'Habitación 3', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta'),
(@SedeVilleta, 'Habitación 4', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta'),
(@SedeVilleta, 'Habitación 5', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta'),
(@SedeVilleta, 'Habitación 6', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta'),
(@SedeVilleta, 'Habitación 7', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta'),
(@SedeVilleta, 'Habitación 8', 'Habitación', 1, 4, 0, '1 cama doble y 1 camarote, baño, nevera, TV, terraza cubierta');

-- 4. El Placer - Fusagasugá
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedeFusa, 'Alojamiento 1', 'Alojamiento', 2, 4, 0, '2 habitaciones, baño, TV. Una con cama doble y una sencilla, otra con una sencilla'),
(@SedeFusa, 'Alojamiento 2', 'Alojamiento', 2, 6, 0, '2 habitaciones, baño, TV. Una con cama doble, la otra con 4 camas sencillas'),
(@SedeFusa, 'Alojamiento 3', 'Alojamiento', 1, 4, 0, '1 habitación con cama doble y 2 camas sencillas, baño, TV'),
(@SedeFusa, 'Alojamiento 4', 'Alojamiento', 2, 4, 0, '2 habitaciones, baño, TV. Una con cama doble y una sencilla, la otra con una sencilla'),
-- Cabañas (Marcadas como EsNuevo = 1 y HabitacionesInternas = 2 para aplicar tarifa de dos habitaciones nuevos)
(@SedeFusa, 'Cabaña 5', 'Cabaña', 2, 4, 1, 'Sala estar con sofá cama y TV, baño, habitación con cama doble y una sencilla, cocineta, nevera, terraza comedor'),
(@SedeFusa, 'Cabaña 6', 'Cabaña', 2, 4, 1, 'Sala estar con sofá cama y TV, baño, habitación con cama doble y una sencilla, cocineta, nevera, terraza comedor'),
(@SedeFusa, 'Cabaña 7', 'Cabaña', 2, 4, 1, 'Sala estar con sofá cama y TV, baño, habitación con cama doble y una sencilla, cocineta, nevera, terraza comedor'),
(@SedeFusa, 'Cabaña 8', 'Cabaña', 2, 4, 1, 'Sala estar con sofá cama y TV, baño, habitación con cama doble y una sencilla, cocineta, nevera, terraza comedor');

-- 5. Gonzalo Morante - Chinchiná
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedeChinchina, 'Alojamiento 1', 'Alojamiento', 2, 7, 0, 'Cocineta, baño, TV, 2 habitaciones. Hab 1: 2 sencillas + 2 aux. Hab 2: 1 doble + 1 sencilla'),
(@SedeChinchina, 'Alojamiento 2', 'Alojamiento', 2, 8, 0, 'Cocineta, baño, TV, 2 habitaciones. Hab 1: 1 doble + 1 aux doble. Hab 2: 2 sencillas + 2 aux'),
(@SedeChinchina, 'Alojamiento 4', 'Alojamiento', 1, 3, 0, 'Cocineta, baño, TV, 1 habitación con cama doble y una sencilla'),
-- Cabaña Tipo A
(@SedeChinchina, 'Cabaña 3 (Tipo A)', 'Cabaña', 2, 6, 0, 'Cocineta, 2 baños, sala comedor, TV, 2 habitaciones. Hab 1: cama doble. Hab 2: 2 sencillas + 2 aux'),
-- Cabañas Tipo B
(@SedeChinchina, 'Cabaña 5 (Tipo B)', 'Cabaña', 1, 3, 0, 'Cocineta, baño, sala con sofá, TV, 1 habitación con cama doble y una sencilla'),
(@SedeChinchina, 'Cabaña 6 (Tipo B)', 'Cabaña', 1, 3, 0, 'Cocineta, baño, sala con sofá, TV, 1 habitación con cama doble y una sencilla');

-- 6. Tablones - Palmira
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedePalmira, 'Alojamiento 1', 'Alojamiento', 1, 4, 0, '1 habitación con cama doble y camarote, TV, baño, cocineta con nevera, comedor'),
(@SedePalmira, 'Alojamiento 2', 'Alojamiento', 1, 4, 0, '1 habitación con cama doble y camarote, TV, baño, cocineta con nevera, comedor'),
(@SedePalmira, 'Alojamiento 3', 'Alojamiento', 2, 8, 0, '2 habitaciones. Hab 1: doble y camarote. Hab 2: 2 camarotes. Sala estar con TV, baño, cocineta'),
(@SedePalmira, 'Alojamiento 4', 'Alojamiento', 2, 8, 0, '2 habitaciones. Hab 1: doble y camarote. Hab 2: 2 camarotes. Sala estar con TV, baño, cocineta');

-- 7. Manguruma - Santa fe de Antioquia
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedeAntioquia, 'Alojamiento 1', 'Alojamiento', 1, 4, 0, 'Cama doble y camarote, baño, terraza, TV'),
(@SedeAntioquia, 'Alojamiento 2', 'Alojamiento', 1, 5, 0, 'Cama doble, camarote y sofá-cama, baño, terraza, TV'),
(@SedeAntioquia, 'Alojamiento 3', 'Alojamiento', 1, 5, 0, 'Cama doble, camarote y sofá-cama, baño, terraza, TV'),
-- Bloque Nuevo (8 Alojamientos, marcados como EsNuevo = 1 y HabitacionesInternas = 2 para tarifa especial)
(@SedeAntioquia, 'Bloque Nuevo 4', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV'),
(@SedeAntioquia, 'Bloque Nuevo 5', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV'),
(@SedeAntioquia, 'Bloque Nuevo 6', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV'),
(@SedeAntioquia, 'Bloque Nuevo 7', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV'),
(@SedeAntioquia, 'Bloque Nuevo 8', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV'),
(@SedeAntioquia, 'Bloque Nuevo 9', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV'),
(@SedeAntioquia, 'Bloque Nuevo 10', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV'),
(@SedeAntioquia, 'Bloque Nuevo 11', 'Bloque Nuevo', 2, 4, 1, 'Dos camas gemelas y camarote, baño, terraza-comedor, cocina, nevera, TV');

-- 8. Federman - Bogotá
INSERT INTO UnidadesAlojamiento (SedeId, Nombre, TipoAlojamiento, HabitacionesInternas, CapacidadMaxima, EsNuevo, DetalleCamas) VALUES
(@SedeBogota, 'Habitación 1', 'Habitación', 1, 2, 0, 'Habitación con alcoba para asociados'),
(@SedeBogota, 'Habitación 2', 'Habitación', 1, 2, 0, 'Habitación con alcoba para asociados'),
(@SedeBogota, 'Habitación 3', 'Habitación', 1, 2, 0, 'Habitación con alcoba para asociados'),
(@SedeBogota, 'Habitación 4', 'Habitación', 1, 2, 0, 'Habitación con alcoba para asociados');

-- INSERCIÓN DE FESTIVOS COLOMBIANOS (AÑO 2026)
INSERT INTO Festivos (Fecha, Descripcion) VALUES
('2026-01-01', 'Año Nuevo'),
('2026-01-12', 'Reyes Magos'),
('2026-03-23', 'Día de San José'),
('2026-04-02', 'Jueves Santo'),
('2026-04-03', 'Viernes Santo'),
('2026-05-01', 'Día del Trabajo'),
('2026-05-18', 'Ascensión del Señor'),
('2026-06-08', 'Corpus Christi'),
('2026-06-15', 'Sagrado Corazón de Jesús'),
('2026-06-29', 'San Pedro y San Pablo'),
('2026-07-20', 'Día de la Independencia'),
('2026-08-07', 'Batalla de Boyacá'),
('2026-08-17', 'Asunción de la Virgen'),
('2026-10-12', 'Día de la Raza'),
('2026-11-02', 'Todos los Santos'),
('2026-11-16', 'Independencia de Cartagena'),
('2026-12-08', 'Inmaculada Concepción'),
('2026-12-25', 'Navidad');

-- INSERCIÓN DE TEMPORADAS ALTAS (2026)
INSERT INTO TemporadasAlta (Nombre, FechaInicio, FechaFin) VALUES
('Vacaciones de Inicio de Año', '2026-01-01', '2026-01-15'),
('Semana Santa y Escolar', '2026-03-29', '2026-04-05'),
('Vacaciones de Mitad de Año', '2026-06-15', '2026-07-15'),
('Semana de Receso Escolar de Octubre', '2026-10-05', '2026-10-12'),
('Vacaciones de Fin de Año', '2026-12-15', '2026-12-31');
GO

-- =========================================================================
-- 3. FUNCIONES AUXILIARES
-- =========================================================================

-- Función para determinar si una fecha es Temporada Alta
CREATE OR ALTER FUNCTION fn_DeterminarTemporada (@Fecha DATE)
RETURNS VARCHAR(20)
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM TemporadasAlta 
        WHERE @Fecha BETWEEN FechaInicio AND FechaFin
    )
        RETURN 'Alta';
        
    RETURN 'Baja';
END;
GO

-- Función para determinar si una fecha califica para la Tarifa Especial Lunes-Jueves
-- Regla: Lunes a Jueves, excepto festivos, semana escolar (incluida en temp alta) y temporada alta.
CREATE OR ALTER FUNCTION fn_EsDiaEspecial (@Fecha DATE)
RETURNS BIT
AS
BEGIN
    -- Determinar el día de la semana de manera independiente al DATEFIRST del servidor.
    -- (DATEPART(dw, @Fecha) + @@DATEFIRST - 2) % 7
    -- Da como resultado: 0 = Lunes, 1 = Martes, 2 = Miércoles, 3 = Jueves, 4 = Viernes, 5 = Sábado, 6 = Domingo
    DECLARE @DayOfWeek INT = (DATEPART(dw, @Fecha) + @@DATEFIRST - 2) % 7;
    
    -- Si no es de lunes (0) a jueves (3), no puede ser tarifa especial
    IF @DayOfWeek < 0 OR @DayOfWeek > 3
        RETURN 0;

    -- Si es festivo colombiano, no califica
    IF EXISTS (SELECT 1 FROM Festivos WHERE Fecha = @Fecha)
        RETURN 0;

    -- Si está en temporada alta, no califica
    IF dbo.fn_DeterminarTemporada(@Fecha) = 'Alta'
        RETURN 0;

    -- Si pasa todas las validaciones, califica como día especial
    RETURN 1;
END;
GO


-- =========================================================================
-- 4. PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES)
-- =========================================================================

-- -------------------------------------------------------------------------
-- SP 1: sp_BuscarDisponibilidadFechas
-- Permite encontrar habitaciones disponibles en un rango de fechas.
-- -------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_BuscarDisponibilidadFechas
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar parámetros
    IF @FechaInicio >= @FechaFin
    BEGIN
        RAISERROR('La fecha de inicio debe ser anterior a la fecha de fin.', 16, 1);
        RETURN;
    END

    SELECT 
        u.Id AS UnidadId,
        s.Nombre AS SedeNombre,
        s.Tipo AS SedeTipo,
        s.Ciudad AS Ciudad,
        u.Nombre AS UnidadNombre,
        u.TipoAlojamiento AS TipoAlojamiento,
        u.HabitacionesInternas AS HabitacionesInternas,
        u.CapacidadMaxima AS CapacidadMaxima,
        u.EsNuevo AS EsNuevo,
        u.DetalleCamas AS DetalleCamas
    FROM UnidadesAlojamiento u
    INNER JOIN Sedes s ON u.SedeId = s.Id
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Reservas r
        WHERE r.UnidadId = u.Id
          AND r.FechaInicio < @FechaFin
          AND r.FechaFin > @FechaInicio
    )
    ORDER BY s.Nombre, u.Nombre;
END;
GO

-- -------------------------------------------------------------------------
-- SP 2: sp_BuscarDisponibilidadFechasYPersonas
-- Permite encontrar habitaciones disponibles en un rango de fechas y número de personas.
-- -------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_BuscarDisponibilidadFechasYPersonas
    @FechaInicio DATE,
    @FechaFin DATE,
    @CantidadPersonas INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar parámetros
    IF @FechaInicio >= @FechaFin
    BEGIN
        RAISERROR('La fecha de inicio debe ser anterior a la fecha de fin.', 16, 1);
        RETURN;
    END
    
    IF @CantidadPersonas <= 0
    BEGIN
        RAISERROR('La cantidad de personas debe ser mayor que 0.', 16, 1);
        RETURN;
    END

    SELECT 
        u.Id AS UnidadId,
        s.Nombre AS SedeNombre,
        s.Tipo AS SedeTipo,
        s.Ciudad AS Ciudad,
        u.Nombre AS UnidadNombre,
        u.TipoAlojamiento AS TipoAlojamiento,
        u.HabitacionesInternas AS HabitacionesInternas,
        u.CapacidadMaxima AS CapacidadMaxima,
        u.EsNuevo AS EsNuevo,
        u.DetalleCamas AS DetalleCamas
    FROM UnidadesAlojamiento u
    INNER JOIN Sedes s ON u.SedeId = s.Id
    WHERE u.CapacidadMaxima >= @CantidadPersonas
      AND NOT EXISTS (
        SELECT 1 
        FROM Reservas r
        WHERE r.UnidadId = u.Id
          AND r.FechaInicio < @FechaFin
          AND r.FechaFin > @FechaInicio
    )
    ORDER BY s.Nombre, u.Nombre;
END;
GO

-- -------------------------------------------------------------------------
-- SP 3: sp_VerTarifas
-- Permite ver las tarifas de acuerdo al sitio, la temporada, el número de personas,
-- y el alojamiento elegido. Admite indicar si es día hábil especial.
-- -------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_VerTarifas
    @UnidadId INT,
    @Temporada VARCHAR(20), -- 'Alta' o 'Baja'
    @CantidadPersonas INT,
    @EsDiaEspecial BIT = 0 -- 1 = Lunes-Jueves (no festivo/alta), 0 = Normal
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SedeNombre VARCHAR(100), @SedeTipo VARCHAR(50);
    DECLARE @UnidadNombre VARCHAR(100), @HabitacionesInternas INT, @EsNuevo BIT, @CapacidadMaxima INT;
    
    -- Obtener detalles de la unidad
    SELECT 
        @SedeNombre = s.Nombre,
        @SedeTipo = s.Tipo,
        @UnidadNombre = u.Nombre,
        @HabitacionesInternas = u.HabitacionesInternas,
        @EsNuevo = u.EsNuevo,
        @CapacidadMaxima = u.CapacidadMaxima
    FROM UnidadesAlojamiento u
    INNER JOIN Sedes s ON u.SedeId = s.Id
    WHERE u.Id = @UnidadId;
    
    IF @UnidadNombre IS NULL
    BEGIN
        RAISERROR('La unidad de alojamiento con el ID especificado no existe.', 16, 1);
        RETURN;
    END

    IF @CantidadPersonas > @CapacidadMaxima
    BEGIN
        PRINT 'ADVERTENCIA: La cantidad de personas excede la capacidad máxima de esta unidad.';
    END

    DECLARE @BaseTarifa DECIMAL(18,2) = 0;
    DECLARE @ValorAdicional DECIMAL(18,2) = 0;
    DECLARE @CantidadAdicional INT = 0;
    DECLARE @TotalNoche DECIMAL(18,2) = 0;
    DECLARE @DetalleRegla VARCHAR(500) = '';

    -- APARTAMENTOS
    IF @SedeTipo = 'Apartamento'
    BEGIN
        IF @SedeNombre LIKE '%Medellín%'
        BEGIN
            -- Medellín (Suramericana): Habitación / Noche
            IF @CantidadPersonas = 1
            BEGIN
                SET @BaseTarifa = 63000;
                SET @DetalleRegla = 'Medellín (Suramericana): Habitación por noche para 1 persona.';
            END
            ELSE
            BEGIN
                SET @BaseTarifa = 75000;
                SET @DetalleRegla = 'Medellín (Suramericana): Habitación por noche para 2 o más personas.';
            END
            SET @TotalNoche = @BaseTarifa;
        END
        ELSE IF @SedeNombre LIKE '%Santa Marta%'
        BEGIN
            -- Santa Marta (El Rodadero): Apto-noche
            IF @UnidadNombre LIKE '%202%'
            BEGIN
                IF @Temporada = 'Alta'
                BEGIN
                    SET @BaseTarifa = 143000;
                    SET @DetalleRegla = 'Santa Marta: Apto 202 en temporada ALTA (capacidad hasta 8 personas).';
                END
                ELSE
                BEGIN
                    SET @BaseTarifa = 103000;
                    SET @DetalleRegla = 'Santa Marta: Apto 202 en temporada BAJA (capacidad hasta 8 personas).';
                END
            END
            ELSE -- 301 y 401
            BEGIN
                IF @Temporada = 'Alta'
                BEGIN
                    SET @BaseTarifa = 124000;
                    SET @DetalleRegla = 'Santa Marta: Apto 301/401 en temporada ALTA (capacidad hasta 6 personas).';
                END
                ELSE
                BEGIN
                    SET @BaseTarifa = 89000;
                    SET @DetalleRegla = 'Santa Marta: Apto 301/401 en temporada BAJA (capacidad hasta 6 personas).';
                END
            END
            SET @TotalNoche = @BaseTarifa;
        END
    END
    ELSE
    -- SEDES RECREATIVAS (Villeta, El Placer, Manguruma, Gonzalo Morante, Tablones)
    BEGIN
        IF @EsDiaEspecial = 1
        BEGIN
            -- Tarifa especial (Lunes a Jueves excepto festivos, escolar y alta temporada)
            IF @HabitacionesInternas = 2 OR @EsNuevo = 1
            BEGIN
                SET @BaseTarifa = 37000;
                SET @DetalleRegla = 'Sede Recreativa: Especial Lun-Jue (2 habitaciones o nuevo, 1-4 personas).';
            END
            ELSE
            BEGIN
                SET @BaseTarifa = 27000;
                SET @DetalleRegla = 'Sede Recreativa: Especial Lun-Jue (1 habitación, 1-4 personas).';
            END
            
            IF @CantidadPersonas > 4
            BEGIN
                SET @CantidadAdicional = @CantidadPersonas - 4;
                SET @ValorAdicional = @CantidadAdicional * 11000; -- $11.000 por persona adicional
            END
            SET @TotalNoche = @BaseTarifa + @ValorAdicional;
        END
        ELSE
        BEGIN
            -- Tarifa Normal (Fin de semana, festivos, temporada alta)
            IF @HabitacionesInternas = 2 OR @EsNuevo = 1
            BEGIN
                SET @BaseTarifa = 90000;
                SET @DetalleRegla = 'Sede Recreativa: Normal (2 habitaciones o nuevo, 1-4 personas).';
            END
            ELSE
            BEGIN
                SET @BaseTarifa = 70000;
                SET @DetalleRegla = 'Sede Recreativa: Normal (1 habitación, 1-4 personas).';
            END
            
            IF @CantidadPersonas > 4
            BEGIN
                SET @CantidadAdicional = @CantidadPersonas - 4;
                SET @ValorAdicional = @CantidadAdicional * 16000; -- $16.000 por persona adicional
            END
            SET @TotalNoche = @BaseTarifa + @ValorAdicional;
        END
    END
    
    SELECT 
        @SedeNombre AS Sede,
        @SedeTipo AS SedeTipo,
        @UnidadNombre AS UnidadAlojamiento,
        @Temporada AS Temporada,
        CASE WHEN @EsDiaEspecial = 1 THEN 'SÍ' ELSE 'NO' END AS EsTarifaEspecialLunJue,
        @CantidadPersonas AS PersonasHospedadas,
        @CapacidadMaxima AS CapacidadMaximaUnidad,
        @BaseTarifa AS TarifaBaseNoche,
        @CantidadAdicional AS CantidadPersonasAdicionales,
        @ValorAdicional AS RecargoPersonasAdicionales,
        @TotalNoche AS CostoTotalPorNoche,
        @DetalleRegla AS DescripcionTarifa;
END;
GO

-- -------------------------------------------------------------------------
-- SP 4: sp_CalcularTarifaReserva
-- Calcula la tarifa total a cancelar de acuerdo al alojamiento elegido,
-- rango de fechas, número de personas, acompañantes de día y otros servicios.
-- -------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_CalcularTarifaReserva
    @UnidadId INT,
    @FechaInicio DATE,
    @FechaFin DATE,
    @CantidadPersonas INT,
    @AcompanantesDia INT = 0, -- Acompañantes por día (aplica a sedes recreativas)
    @UsaLavanderia BIT = 0   -- Específico de Santa Marta
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validaciones iniciales
    IF @FechaInicio >= @FechaFin
    BEGIN
        RAISERROR('La fecha de inicio debe ser anterior a la fecha de fin.', 16, 1);
        RETURN;
    END

    IF @CantidadPersonas <= 0
    BEGIN
        RAISERROR('La cantidad de personas debe ser mayor que 0.', 16, 1);
        RETURN;
    END

    DECLARE @SedeId INT, @SedeNombre VARCHAR(100), @SedeTipo VARCHAR(50);
    DECLARE @UnidadNombre VARCHAR(100), @HabitacionesInternas INT, @EsNuevo BIT, @CapacidadMaxima INT;

    -- Obtener detalles de la unidad y la sede
    SELECT 
        @SedeId = s.Id,
        @SedeNombre = s.Nombre,
        @SedeTipo = s.Tipo,
        @UnidadNombre = u.Nombre,
        @HabitacionesInternas = u.HabitacionesInternas,
        @EsNuevo = u.EsNuevo,
        @CapacidadMaxima = u.CapacidadMaxima
    FROM UnidadesAlojamiento u
    INNER JOIN Sedes s ON u.SedeId = s.Id
    WHERE u.Id = @UnidadId;

    IF @UnidadNombre IS NULL
    BEGIN
        RAISERROR('La unidad de alojamiento especificada no existe.', 16, 1);
        RETURN;
    END

    -- Validar si excede la capacidad máxima
    IF @CantidadPersonas > @CapacidadMaxima
    BEGIN
        DECLARE @MsgExceso NVARCHAR(200) = FORMATMESSAGE('ADVERTENCIA: La cantidad de personas (%d) excede la capacidad máxima de la unidad (%d).', @CantidadPersonas, @CapacidadMaxima);
        PRINT @MsgExceso;
    END

    -- 2. Variables de cálculo
    DECLARE @FechaActual DATE = @FechaInicio;
    DECLARE @TotalCostoNoches DECIMAL(18,2) = 0;
    DECLARE @CostoAcompanantes DECIMAL(18,2) = 0;
    DECLARE @CostoLavanderia DECIMAL(18,2) = 0;
    DECLARE @GranTotal DECIMAL(18,2) = 0;
    DECLARE @CantNoches INT = DATEDIFF(day, @FechaInicio, @FechaFin);

    -- Tabla temporal para almacenar el desglose diario (para el reporte final)
    CREATE TABLE #DesgloseDiario (
        Fecha DATE,
        DiaSemana VARCHAR(20),
        Temporada VARCHAR(10),
        EsEspecial VARCHAR(2),
        TarifaBase DECIMAL(18,2),
        RecargoPersonas DECIMAL(18,2),
        TotalDia DECIMAL(18,2)
    );

    -- 3. Iterar día a día para calcular el hospedaje (las reservas se cobran por noche)
    WHILE @FechaActual < @FechaFin
    BEGIN
        DECLARE @TemporadaActual VARCHAR(20) = dbo.fn_DeterminarTemporada(@FechaActual);
        DECLARE @EsEspecialActual BIT = dbo.fn_EsDiaEspecial(@FechaActual);

        -- Obtener la tarifa diaria llamando de manera interna a la lógica de tarifas
        DECLARE @BaseTarifaDia DECIMAL(18,2) = 0;
        DECLARE @RecargoDia DECIMAL(18,2) = 0;
        DECLARE @TotalDia DECIMAL(18,2) = 0;

        -- APARTAMENTOS
        IF @SedeTipo = 'Apartamento'
        BEGIN
            IF @SedeNombre LIKE '%Medellín%'
            BEGIN
                IF @CantidadPersonas = 1
                    SET @BaseTarifaDia = 63000;
                ELSE
                    SET @BaseTarifaDia = 75000;
            END
            ELSE IF @SedeNombre LIKE '%Santa Marta%'
            BEGIN
                IF @UnidadNombre LIKE '%202%'
                BEGIN
                    IF @TemporadaActual = 'Alta'
                        SET @BaseTarifaDia = 143000;
                    ELSE
                        SET @BaseTarifaDia = 103000;
                END
                ELSE -- 301 y 401
                BEGIN
                    IF @TemporadaActual = 'Alta'
                        SET @BaseTarifaDia = 124000;
                    ELSE
                        SET @BaseTarifaDia = 89000;
                END
            END
            SET @TotalDia = @BaseTarifaDia;
        END
        ELSE
        -- SEDES RECREATIVAS
        BEGIN
            IF @EsEspecialActual = 1
            BEGIN
                -- Tarifa especial (Lunes a Jueves no festivos / no alta)
                IF @HabitacionesInternas = 2 OR @EsNuevo = 1
                    SET @BaseTarifaDia = 37000;
                ELSE
                    SET @BaseTarifaDia = 27000;

                IF @CantidadPersonas > 4
                    SET @RecargoDia = (@CantidadPersonas - 4) * 11000;
            END
            ELSE
            BEGIN
                -- Tarifa Normal (Fin de semana, festivos, temporada alta)
                IF @HabitacionesInternas = 2 OR @EsNuevo = 1
                    SET @BaseTarifaDia = 90000;
                ELSE
                    SET @BaseTarifaDia = 70000;

                IF @CantidadPersonas > 4
                    SET @RecargoDia = (@CantidadPersonas - 4) * 16000;
            END
            SET @TotalDia = @BaseTarifaDia + @RecargoDia;
        END

        SET @TotalCostoNoches = @TotalCostoNoches + @TotalDia;

        -- Guardar desglose en la tabla temporal
        INSERT INTO #DesgloseDiario VALUES (
            @FechaActual,
            DATENAME(weekday, @FechaActual),
            @TemporadaActual,
            CASE WHEN @EsEspecialActual = 1 THEN 'SÍ' ELSE 'NO' END,
            @BaseTarifaDia,
            @RecargoDia,
            @TotalDia
        );

        -- Avanzar al siguiente día
        SET @FechaActual = DATEADD(day, 1, @FechaActual);
    END;

    -- 4. Cálculo de Visitas de Día (Acompañantes) si aplica
    -- Regla: Visitas de día en sedes recreativas. Cada acompañante a partir del 5° y hasta un máximo de 10 paga $5.500.
    -- Interpretamos que es un pago de $5.500 por cada día que asistan.
    IF @SedeTipo = 'Sede Recreativa' AND @AcompanantesDia > 4
    BEGIN
        DECLARE @CantAcompanantesCobrados INT = 0;
        
        -- Capar al máximo de 10 acompañantes para el cobro
        IF @AcompanantesDia > 10
            SET @CantAcompanantesCobrados = 10 - 4; -- Cobrar solo hasta 6 personas adicionales (5ª a la 10ª)
        ELSE
            SET @CantAcompanantesCobrados = @AcompanantesDia - 4;

        -- Costo por día de acompañantes multiplicado por la cantidad de noches (o días de estancia)
        SET @CostoAcompanantes = @CantAcompanantesCobrados * 5500 * @CantNoches;
    END

    -- 5. Cálculo de Lavandería (Específico de Santa Marta)
    -- Cargo único por estancia de $18.000 si se selecciona
    IF @SedeTipo = 'Apartamento' AND @SedeNombre LIKE '%Santa Marta%' AND @UsaLavanderia = 1
    BEGIN
        SET @CostoLavanderia = 18000;
    END

    -- 6. Gran Total
    SET @GranTotal = @TotalCostoNoches + @CostoAcompanantes + @CostoLavanderia;

    -- 7. Mostrar resultados y desglose
    SELECT 
        @SedeNombre AS Sede,
        @UnidadNombre AS UnidadAlojamiento,
        @FechaInicio AS FechaLlegada,
        @FechaFin AS FechaSalida,
        @CantNoches AS CantidadNoches,
        @CantidadPersonas AS PersonasHospedadas,
        @AcompanantesDia AS AcompanantesDia,
        @TotalCostoNoches AS SubtotalHospedaje,
        @CostoAcompanantes AS TotalAcompanantesDia,
        @CostoLavanderia AS ServicioLavanderia,
        @GranTotal AS TotalAPagar;

    -- Mostrar el desglose diario para total transparencia en el cálculo
    SELECT 
        Fecha,
        DiaSemana,
        Temporada,
        EsEspecial AS EsTarifaEspecial,
        TarifaBase,
        RecargoPersonas AS RecargoAdicionales,
        TotalDia AS TotalPorNoche
    FROM #DesgloseDiario
    ORDER BY Fecha;

    DROP TABLE #DesgloseDiario;
END;
GO

PRINT '=========================================================================';
PRINT 'BASE DE DATOS Y PROCEDIMIENTOS ALMACENADOS CREADOS CON ÉXITO';
PRINT '=========================================================================';
GO
