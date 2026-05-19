using System;
using System.ComponentModel.DataAnnotations;

namespace reservasproject.Models.ViewModels
{
    public class ReservaViewModel
    {
        [Required]
        public int UnidadId { get; set; }

        public string UnidadNombre { get; set; } = string.Empty;
        public string SedeNombre { get; set; } = string.Empty;

        [Required]
        public DateTime FechaInicio { get; set; }

        [Required]
        public DateTime FechaFin { get; set; }

        [Required]
        [Range(1, 100)]
        public int CantidadPersonas { get; set; }

        public int AcompanantesDia { get; set; } = 0;

        public bool UsaLavanderia { get; set; } = false;

        // Propiedades de solo lectura (calculadas en el backend para mostrar en la vista)
        public decimal SubtotalHospedaje { get; set; }
        public decimal TotalAcompanantesDia { get; set; }
        public decimal ServicioLavanderia { get; set; }
        public decimal TotalAPagar { get; set; }
        public int CantidadNoches { get; set; }
    }
}
