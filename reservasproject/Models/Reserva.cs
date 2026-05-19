using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace reservasproject.Models
{
    [Table("Reservas")]
    public class Reserva
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        public int UsuarioId { get; set; }
        
        [ForeignKey("UsuarioId")]
        public Usuario Usuario { get; set; } = null!;

        [Required]
        public int UnidadId { get; set; }
        
        // No necesitamos mapear UnidadAlojamiento completo a menos que sea estrictamente necesario para la consulta. 
        // Si queremos podemos hacerlo, pero con UnidadId basta para insertar.

        [Required]
        public DateTime FechaInicio { get; set; }

        [Required]
        public DateTime FechaFin { get; set; }

        [Required]
        public int CantidadPersonas { get; set; }

        public int AcompanantesDia { get; set; } = 0;

        public bool UsaLavanderia { get; set; } = false;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAPagar { get; set; }
    }
}
