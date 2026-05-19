using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using reservasproject.Data;
using reservasproject.Models;

namespace reservasproject.Controllers
{
    [Authorize] // solo los usuarios autenticados pueden acceder a esta ruta
    public class SedesController : Controller
    {
        private readonly ApplicationDbContext _context;

        public SedesController(ApplicationDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            return View(); // retorna la vista Index.cshtml
        }

        [HttpGet] // metodo que devuelve los datos de las sedes en formato JSON
        public async Task<IActionResult> GetSedes()
        {
            var sedes = await _context.Sedes.ToListAsync(); // obtenemos todas las sedes de la base de datos
            return Json(sedes);
        }

        [HttpGet]
        public async Task<IActionResult> GetAvailableSedes(DateTime fechaInicio, DateTime fechaFin, int? personas)
        {
            if (fechaInicio >= fechaFin)
            {
                return BadRequest("La fecha de inicio debe ser anterior a la fecha de fin.");
            }

            var units = new List<reservasproject.Models.ViewModels.AvailableUnitViewModel>();

            var connection = _context.Database.GetDbConnection();
            using (var command = connection.CreateCommand())
            {
                if (personas.HasValue && personas.Value > 0)
                {
                    command.CommandText = "sp_BuscarDisponibilidadFechasYPersonas"; // nombre del procedimiento almacenado
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaInicio", fechaInicio));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaFin", fechaFin));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@CantidadPersonas", personas.Value));
                }
                else
                {
                    command.CommandText = "sp_BuscarDisponibilidadFechas"; // nombre del procedimiento almacenado
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaInicio", fechaInicio));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaFin", fechaFin));
                }

                if (connection.State != System.Data.ConnectionState.Open) // si la conexion no esta abierta, la abrimos
                {
                    await connection.OpenAsync(); // abrimos la conexion de forma asincrona para no bloquear el hilo principal
                }

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        // mapeamos los resultados del procedimiento almacenado a nuestro ViewModel
                        units.Add(new reservasproject.Models.ViewModels.AvailableUnitViewModel
                        {
                            UnidadId = reader.GetInt32(reader.GetOrdinal("UnidadId")),
                            SedeNombre = reader.GetString(reader.GetOrdinal("SedeNombre")),
                            SedeTipo = reader.GetString(reader.GetOrdinal("SedeTipo")),
                            Ciudad = reader.GetString(reader.GetOrdinal("Ciudad")),
                            UnidadNombre = reader.GetString(reader.GetOrdinal("UnidadNombre")),
                            TipoAlojamiento = reader.GetString(reader.GetOrdinal("TipoAlojamiento")),
                            HabitacionesInternas = reader.GetInt32(reader.GetOrdinal("HabitacionesInternas")),
                            CapacidadMaxima = reader.GetInt32(reader.GetOrdinal("CapacidadMaxima")),
                            EsNuevo = reader.GetBoolean(reader.GetOrdinal("EsNuevo")),
                            DetalleCamas = reader.IsDBNull(reader.GetOrdinal("DetalleCamas")) ? null : reader.GetString(reader.GetOrdinal("DetalleCamas"))
                        });
                    }
                }
            }

            // Calcular e inyectar la tarifa base inicial para cada unidad
            int personasDefault = personas.HasValue && personas.Value > 0 ? personas.Value : 1;
            foreach (var unit in units)
            {
                unit.TarifaTotalInicial = await GetBaselineTariff(unit.UnidadId, fechaInicio, fechaFin, personasDefault);
            }

            return Json(units); // retornamos el resultado en formato JSON a la vista
        }

        private async Task<decimal> GetBaselineTariff(int unidadId, DateTime inicio, DateTime fin, int personas)
        {
            try
            {
                var connection = _context.Database.GetDbConnection();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "sp_CalcularTarifaReserva";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@UnidadId", unidadId));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaInicio", inicio));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaFin", fin));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@CantidadPersonas", personas));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@AcompanantesDia", 0));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@UsaLavanderia", false));

                    if (connection.State != System.Data.ConnectionState.Open)
                    {
                        await connection.OpenAsync();
                    }

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            return reader.GetDecimal(reader.GetOrdinal("TotalAPagar"));
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error al calcular tarifa base para unidad {unidadId}: {ex.Message}");
            }
            return 0;
        }

        [HttpGet]
        public async Task<IActionResult> GetCalculatedTariff(int unidadId, DateTime fechaInicio, DateTime fechaFin, int personas, int acompanantes = 0, bool lavanderia = false)
        {
            if (fechaInicio >= fechaFin)
            {
                return BadRequest("La fecha de inicio debe ser anterior a la fecha de fin.");
            }
            if (personas <= 0)
            {
                return BadRequest("La cantidad de personas debe ser mayor que 0.");
            }

            try
            {
                var connection = _context.Database.GetDbConnection();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "sp_CalcularTarifaReserva";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@UnidadId", unidadId));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaInicio", fechaInicio));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaFin", fechaFin));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@CantidadPersonas", personas));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@AcompanantesDia", acompanantes));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@UsaLavanderia", lavanderia));

                    if (connection.State != System.Data.ConnectionState.Open)
                    {
                        await connection.OpenAsync();
                    }

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            var result = new reservasproject.Models.ViewModels.CalculatedTariffViewModel
                            {
                                Sede = reader.GetString(reader.GetOrdinal("Sede")),
                                UnidadAlojamiento = reader.GetString(reader.GetOrdinal("UnidadAlojamiento")),
                                FechaLlegada = reader.GetDateTime(reader.GetOrdinal("FechaLlegada")),
                                FechaSalida = reader.GetDateTime(reader.GetOrdinal("FechaSalida")),
                                CantidadNoches = reader.GetInt32(reader.GetOrdinal("CantidadNoches")),
                                PersonasHospedadas = reader.GetInt32(reader.GetOrdinal("PersonasHospedadas")),
                                AcompanantesDia = reader.GetInt32(reader.GetOrdinal("AcompanantesDia")),
                                SubtotalHospedaje = reader.GetDecimal(reader.GetOrdinal("SubtotalHospedaje")),
                                TotalAcompanantesDia = reader.GetDecimal(reader.GetOrdinal("TotalAcompanantesDia")),
                                ServicioLavanderia = reader.GetDecimal(reader.GetOrdinal("ServicioLavanderia")),
                                TotalAPagar = reader.GetDecimal(reader.GetOrdinal("TotalAPagar"))
                            };
                            return Json(result);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno al calcular la tarifa: {ex.Message}");
            }

            return NotFound("No se pudo calcular la tarifa.");
        }
    }
}
