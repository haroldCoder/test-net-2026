using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace reservasproject.Models
{
    [Table("Sedes")] // traemos la tabla sedes de SQL server
    public class Sede
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Nombre { get; set; } = null!;

        [Required]
        [StringLength(50)]
        public string Tipo { get; set; } = null!;

        [Required]
        [StringLength(100)]
        public string Ciudad { get; set; } = null!;
    }
}
