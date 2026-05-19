using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace reservasproject.Models
{
    [Table("Usuarios")]
    public class Usuario
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [StringLength(20)]
        public string Documento { get; set; } = null!;

        [Required]
        [StringLength(150)]
        public string NombreCompleto { get; set; } = null!;

        [Required]
        [StringLength(100)]
        public string Correo { get; set; } = null!;

        [StringLength(20)]
        public string? Telefono { get; set; }

        [Required]
        [StringLength(20)]
        public string TipoUsuario { get; set; } = "Asociado"; // Default

        public ICollection<Reserva> Reservas { get; set; } = new List<Reserva>();
    }
}
