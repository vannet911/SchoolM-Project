using System;
using System.ComponentModel.DataAnnotations;

namespace SchoolMS.Core.Entities
{
    public class Teacher
    {
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Code { get; set; } = String.Empty;

        [Required, MaxLength(100)]
        public string Name { get; set; } = String.Empty;

        [Required, MaxLength(100)]
        public string Gender { get; set; } = String.Empty;

        public DateTime DateOfBirth { get; set; }

        [EmailAddress, MaxLength(255)]
        public string Email { get; set; } = String.Empty;

        [Phone, MaxLength(20)]
        public string PhoneNumber { get; set; } = String.Empty;

        [MaxLength(100)]
        public string Subject { get; set; } = String.Empty;

        [Required]
        public DateTime CreateDate { get; set; }

        public bool Status { get; set; }
    }
}