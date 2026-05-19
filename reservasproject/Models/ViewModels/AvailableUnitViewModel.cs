namespace reservasproject.Models.ViewModels
{
    public class AvailableUnitViewModel
    {
        public int UnidadId { get; set; }
        public string SedeNombre { get; set; } = null!;
        public string SedeTipo { get; set; } = null!;
        public string Ciudad { get; set; } = null!;
        public string UnidadNombre { get; set; } = null!;
        public string TipoAlojamiento { get; set; } = null!;
        public int HabitacionesInternas { get; set; }
        public int CapacidadMaxima { get; set; }
        public bool EsNuevo { get; set; }
        public string? DetalleCamas { get; set; }
        public decimal TarifaTotalInicial { get; set; }
    }
}
