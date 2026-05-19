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

            return Json(units); // retornamos el resultado en formato JSON a la vista
        }
    }
}
