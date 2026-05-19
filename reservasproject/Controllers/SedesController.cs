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
    }
}
