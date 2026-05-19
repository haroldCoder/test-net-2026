using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using reservasproject.Data;
using reservasproject.Models;

namespace reservasproject.Controllers
{
    [Authorize]
    public class BookingsController : Controller
    {
        private readonly ApplicationDbContext _context;

        public BookingsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> Book(int unitId, DateTime startDate, DateTime endDate, int guests, int companions = 0, bool laundry = false)
        {
            if (startDate >= endDate)
            {
                return RedirectToAction("Index", "Sedes");
            }

            try
            {
                var connection = _context.Database.GetDbConnection();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "sp_CalcularTarifaReserva";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@UnidadId", unitId));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaInicio", startDate));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@FechaFin", endDate));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@CantidadPersonas", guests));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@AcompanantesDia", companions));
                    command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@UsaLavanderia", laundry));

                    if (connection.State != System.Data.ConnectionState.Open)
                    {
                        await connection.OpenAsync();
                    }

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            var model = new reservasproject.Models.ViewModels.ReservaViewModel
                            {
                                UnidadId = unitId,
                                SedeNombre = reader.GetString(reader.GetOrdinal("Sede")),
                                UnidadNombre = reader.GetString(reader.GetOrdinal("UnidadAlojamiento")),
                                FechaInicio = startDate,
                                FechaFin = endDate,
                                CantidadPersonas = guests,
                                AcompanantesDia = companions,
                                UsaLavanderia = laundry,
                                SubtotalHospedaje = reader.GetDecimal(reader.GetOrdinal("SubtotalHospedaje")),
                                TotalAcompanantesDia = reader.GetDecimal(reader.GetOrdinal("TotalAcompanantesDia")),
                                ServicioLavanderia = reader.GetDecimal(reader.GetOrdinal("ServicioLavanderia")),
                                TotalAPagar = reader.GetDecimal(reader.GetOrdinal("TotalAPagar")),
                                CantidadNoches = reader.GetInt32(reader.GetOrdinal("CantidadNoches"))
                            };
                            return View(model);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error al calcular tarifa en Reservar: {ex.Message}");
            }

            return RedirectToAction("Index", "Sedes");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ConfirmBooking(reservasproject.Models.ViewModels.ReservaViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View("Book", model);
            }

            var email = User.Identity?.Name;
            if (string.IsNullOrEmpty(email))
            {
                return Unauthorized();
            }

            // Buscar usuario en tabla Usuarios o crearlo
            var user = await _context.Usuarios.FirstOrDefaultAsync(u => u.Correo == email);
            if (user == null)
            {
                user = new Usuario
                {
                    Documento = Guid.NewGuid().ToString().Substring(0, 8),
                    NombreCompleto = email.Split('@')[0],
                    Correo = email,
                    TipoUsuario = "Asociado"
                };
                _context.Usuarios.Add(user);
                await _context.SaveChangesAsync();
            }

            // Insertar la reserva
            var reservation = new Reserva
            {
                UsuarioId = user.Id,
                UnidadId = model.UnidadId,
                FechaInicio = model.FechaInicio,
                FechaFin = model.FechaFin,
                CantidadPersonas = model.CantidadPersonas,
                AcompanantesDia = model.AcompanantesDia,
                UsaLavanderia = model.UsaLavanderia,
                TotalAPagar = model.TotalAPagar
            };

            _context.Reservas.Add(reservation);
            await _context.SaveChangesAsync();

            return View("BookingSuccess", reservation);
        }

        [HttpGet]
        public async Task<IActionResult> MyBookings()
        {
            var email = User.Identity?.Name;
            if (string.IsNullOrEmpty(email))
            {
                return Unauthorized();
            }

            var user = await _context.Usuarios.FirstOrDefaultAsync(u => u.Correo == email);
            if (user == null)
            {
                // Si no existe el usuario en la tabla Usuarios, no tiene reservas
                return View(new List<reservasproject.Models.ViewModels.MyBookingViewModel>());
            }

            var bookings = new List<reservasproject.Models.ViewModels.MyBookingViewModel>();

            var connection = _context.Database.GetDbConnection();
            using (var command = connection.CreateCommand())
            {
                // Unimos Reservas con UnidadesAlojamiento y Sedes para obtener nombres
                command.CommandText = @"
                    SELECT 
                        r.Id AS ReservaId,
                        s.Nombre AS SedeNombre,
                        u.Nombre AS UnidadNombre,
                        r.FechaInicio,
                        r.FechaFin,
                        r.CantidadPersonas,
                        r.AcompanantesDia,
                        r.TotalAPagar
                    FROM Reservas r
                    INNER JOIN UnidadesAlojamiento u ON r.UnidadId = u.Id
                    INNER JOIN Sedes s ON u.SedeId = s.Id
                    WHERE r.UsuarioId = @UsuarioId
                    ORDER BY r.FechaInicio DESC
                ";
                command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@UsuarioId", user.Id));

                if (connection.State != System.Data.ConnectionState.Open)
                {
                    await connection.OpenAsync();
                }

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        var fechaInicio = reader.GetDateTime(reader.GetOrdinal("FechaInicio"));
                        var fechaFin = reader.GetDateTime(reader.GetOrdinal("FechaFin"));
                        
                        string status = "Finalizada";
                        if (DateTime.Now.Date < fechaInicio.Date)
                        {
                            status = "Próxima";
                        }
                        else if (DateTime.Now.Date >= fechaInicio.Date && DateTime.Now.Date <= fechaFin.Date)
                        {
                            status = "En Curso";
                        }

                        bookings.Add(new reservasproject.Models.ViewModels.MyBookingViewModel
                        {
                            BookingId = reader.GetInt32(reader.GetOrdinal("ReservaId")),
                            SedeName = reader.GetString(reader.GetOrdinal("SedeNombre")),
                            UnitName = reader.GetString(reader.GetOrdinal("UnidadNombre")),
                            StartDate = fechaInicio,
                            EndDate = fechaFin,
                            Guests = reader.GetInt32(reader.GetOrdinal("CantidadPersonas")),
                            AcompanantesDia = reader.GetInt32(reader.GetOrdinal("AcompanantesDia")),
                            TotalPaid = reader.GetDecimal(reader.GetOrdinal("TotalAPagar")),
                            Status = status
                        });
                    }
                }
            }

            return View(bookings);
        }
    }
}
