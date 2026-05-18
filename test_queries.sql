USE SedesRecreativasDB;
GO

PRINT '========================================================================';
PRINT '1. PROBANDO DISPONIBILIDAD INICIAL POR FECHAS (sp_BuscarDisponibilidadFechas)';
PRINT 'Buscando disponibilidad del 1 al 10 de Junio de 2026 (Deberían salir las 54 unidades)';
PRINT '========================================================================';
EXEC sp_BuscarDisponibilidadFechas '2026-06-01', '2026-06-10';
GO

PRINT '========================================================================';
PRINT '2. CREANDO RESERVAS MOCK PARA VALIDAR TRASLAPES (Traslapes)';
PRINT 'Reservando Medellín Hab 1 del 2026-06-01 al 2026-06-05 (4 noches)';
PRINT 'Reservando Santa Marta Apto 202 del 2026-06-03 al 2026-06-07 (4 noches)';
PRINT '========================================================================';
-- Obtener IDs
DECLARE @Hab1Medellin INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Medellín - Suramericana' AND u.Nombre = 'Habitación 1');
DECLARE @Apto202Marta INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Santa Marta - El Rodadero' AND u.Nombre = 'Apartamento 202');

INSERT INTO Reservas (UnidadId, FechaInicio, FechaFin, CantidadPersonas, AcompanantesDia, UsaLavanderia, TotalAPagar) VALUES
(@Hab1Medellin, '2026-06-01', '2026-06-05', 2, 0, 0, 300000),
(@Apto202Marta, '2026-06-03', '2026-06-07', 5, 0, 1, 430000);

PRINT 'Reservas insertadas con éxito.';
GO

PRINT '========================================================================';
PRINT '3. PROBANDO DISPONIBILIDAD CON TRASLAPES ACTIVO (sp_BuscarDisponibilidadFechas)';
PRINT 'Buscando disponibilidad del 1 al 5 de Junio de 2026 (Habitación 1 Medellín y Apto 202 no deben salir)';
PRINT '========================================================================';
EXEC sp_BuscarDisponibilidadFechas '2026-06-01', '2026-06-05';
GO

PRINT '========================================================================';
PRINT '4. PROBANDO DISPONIBILIDAD POR FECHA Y CAPACIDAD (sp_BuscarDisponibilidadFechasYPersonas)';
PRINT 'Buscando disponibilidad del 1 al 10 de Junio de 2026 para 6 personas';
PRINT 'Debería listar solo alojamientos con capacidad >= 6';
PRINT '========================================================================';
EXEC sp_BuscarDisponibilidadFechasYPersonas '2026-06-01', '2026-06-10', 6;
GO

PRINT '========================================================================';
PRINT '5. PROBANDO DESGLOSE DE TARIFAS (sp_VerTarifas)';
PRINT '========================================================================';

-- Buscar IDs de ejemplo para el test
DECLARE @Hab1Medellin INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Medellín - Suramericana' AND u.Nombre = 'Habitación 1');
DECLARE @Apto202Marta INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Santa Marta - El Rodadero' AND u.Nombre = 'Apartamento 202');
DECLARE @Hab1Villeta INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Villeta' AND u.Nombre = 'Habitación 1');
DECLARE @Aloj3Tablones INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Tablones - Palmira' AND u.Nombre = 'Alojamiento 3');

PRINT '--> Medellín - 1 Persona';
EXEC sp_VerTarifas @Hab1Medellin, 'Baja', 1;

PRINT '--> Medellín - 2 Personas';
EXEC sp_VerTarifas @Hab1Medellin, 'Baja', 2;

PRINT '--> Santa Marta Apto 202 - Temporada Baja (Hasta 8 personas)';
EXEC sp_VerTarifas @Apto202Marta, 'Baja', 5;

PRINT '--> Santa Marta Apto 202 - Temporada Alta (Hasta 8 personas)';
EXEC sp_VerTarifas @Apto202Marta, 'Alta', 5;

PRINT '--> Sede Recreativa Villeta (1 hab) - Fin de semana / Festivo / Normal';
EXEC sp_VerTarifas @Hab1Villeta, 'Baja', 3, 0;

PRINT '--> Sede Recreativa Villeta (1 hab) - Día de semana especial (Lunes-Jueves)';
EXEC sp_VerTarifas @Hab1Villeta, 'Baja', 3, 1;

PRINT '--> Sede Recreativa Villeta (1 hab) - Normal con 6 personas (2 adicionales cobrados a $16k c/u)';
EXEC sp_VerTarifas @Hab1Villeta, 'Baja', 6, 0;

PRINT '--> Sede Recreativa Villeta (1 hab) - Lunes-Jueves con 6 personas (2 adicionales cobrados a $11k c/u)';
EXEC sp_VerTarifas @Hab1Villeta, 'Baja', 6, 1;

PRINT '--> Sede Recreativa Tablones (Alojamiento 3 - 2 habs) - Fin de semana / Festivo / Normal';
EXEC sp_VerTarifas @Aloj3Tablones, 'Baja', 4, 0;

PRINT '--> Sede Recreativa Tablones (Alojamiento 3 - 2 habs) - Día de semana especial (Lunes-Jueves)';
EXEC sp_VerTarifas @Aloj3Tablones, 'Baja', 4, 1;
GO

PRINT '========================================================================';
PRINT '6. PROBANDO CÁLCULO DE RESERVAS MULTI-NOCHE (sp_CalcularTarifaReserva)';
PRINT '========================================================================';

DECLARE @Hab1Medellin INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Medellín - Suramericana' AND u.Nombre = 'Habitación 1');
DECLARE @Apto202Marta INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Santa Marta - El Rodadero' AND u.Nombre = 'Apartamento 202');
DECLARE @Hab1Villeta INT = (SELECT u.Id FROM UnidadesAlojamiento u INNER JOIN Sedes s ON u.SedeId = s.Id WHERE s.Nombre = 'Villeta' AND u.Nombre = 'Habitación 1');

PRINT '--> RESERVA 1: Medellín Hab 1 para 2 personas, del 2026-06-01 al 2026-06-04 (3 noches)';
PRINT 'Costo esperado: 3 noches * $75.000 = $225.000';
EXEC sp_CalcularTarifaReserva @Hab1Medellin, '2026-06-01', '2026-06-04', 2, 0, 0;

PRINT '--> RESERVA 2: Santa Marta Apto 202 para 5 personas, del 2026-06-01 al 2026-06-05 (4 noches) en temp baja con lavandería';
PRINT 'Costo esperado: 4 noches * $103.000 + $18.000 = $430.000';
EXEC sp_CalcularTarifaReserva @Apto202Marta, '2026-06-01', '2026-06-05', 5, 0, 1;

PRINT '--> RESERVA 3: Sede Recreativa Villeta Hab 1 para 5 personas (1 adicional), del 2026-05-14 al 2026-05-19 (5 noches)';
PRINT 'Este rango cruza un fin de semana y un lunes festivo (2026-05-18 es la Ascensión del Señor)';
PRINT 'Desglose esperado de noches:';
PRINT '- 2026-05-14 (Jueves): Día especial -> $27.000 + $11.000 = $38.000';
PRINT '- 2026-05-15 (Viernes): Fin de semana -> $70.000 + $16.000 = $86.000';
PRINT '- 2026-05-16 (Sábado): Fin de semana -> $70.000 + $16.000 = $86.000';
PRINT '- 2026-05-17 (Domingo): Fin de semana -> $70.000 + $16.000 = $86.000';
PRINT '- 2026-05-18 (Lunes Festivo): Festivo -> $70.000 + $16.000 = $86.000';
PRINT 'Total esperado: $382.000';
EXEC sp_CalcularTarifaReserva @Hab1Villeta, '2026-05-14', '2026-05-19', 5, 0, 0;
GO
