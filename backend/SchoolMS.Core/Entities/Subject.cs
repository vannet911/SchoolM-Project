using System;
using System.ComponentModel.DataAnnotations;

namespace SchoolMS.Core.Entities
{
    public class Subject
    {
        public int Id { get; set; }

        [Required, MaxLength(20)]
        public string Code { get; set; } = String.Empty;

        [Required, MaxLength(100)]
        public string Name { get; set; } = String.Empty;

        [MaxLength(255)]
        public string? Description { get; set; } = String.Empty;

        public DateTime CreateDate { get; set; }

        public bool Status { get; set; }
    }
}