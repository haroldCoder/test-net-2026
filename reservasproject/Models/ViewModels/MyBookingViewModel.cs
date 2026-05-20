using System;

namespace reservasproject.Models.ViewModels
{
    public class MyBookingViewModel
    {
        public int BookingId { get; set; }
        public string SedeName { get; set; } = string.Empty;
        public string UnitName { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int Guests { get; set; }
        public int AcompanantesDia { get; set; }
        public bool UsaLavanderia { get; set; }
        public decimal TotalPaid { get; set; }
        public string Status { get; set; } = string.Empty; // "Próxima", "En Curso", "Finalizada"
    }
}
