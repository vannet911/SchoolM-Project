using System.ComponentModel.DataAnnotations;

namespace SchoolMS.Core.Entities
{
    public class Student
    {
        public int Id { get; set; }

        [Required]
        public string Code { get; set; } = string.Empty;

        [Required]
        public string? FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; } = string.Empty;
        public string? Gender { get; set; } = string.Empty;
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; } = string.Empty;
        public string? Address { get; set; } = string.Empty;
        public DateTime? CreateDate { get; set; }
        public bool? Status { get; set; }
        public string? PhotoUrl { get; set; }

        public int? ClassId { get; set; }

        // Backward compatibility
        public string? Name
        {
            get => string.IsNullOrEmpty(FirstName) && string.IsNullOrEmpty(LastName)
                ? string.Empty
                : $"{FirstName} {LastName}".Trim();
        }

        // Navigation
        public Class? Class { get; set; }
    }
}