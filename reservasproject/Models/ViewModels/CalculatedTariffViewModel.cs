using System;

namespace reservasproject.Models.ViewModels
{
    public class CalculatedTariffViewModel
    {
        public string Sede { get; set; } = null!;
        public string UnidadAlojamiento { get; set; } = null!;
        public DateTime FechaLlegada { get; set; }
        public DateTime FechaSalida { get; set; }
        public int CantidadNoches { get; set; }
        public int PersonasHospedadas { get; set; }
        public int AcompanantesDia { get; set; }
        public decimal SubtotalHospedaje { get; set; }
        public decimal TotalAcompanantesDia { get; set; }
        public decimal ServicioLavanderia { get; set; }
        public decimal TotalAPagar { get; set; }
    }
}
