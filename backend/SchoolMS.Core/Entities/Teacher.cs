using System.ComponentModel.DataAnnotations;

namespace SchoolMS.Core.Entities
{
    public class Teacher
    {
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Code { get; set; } = string.Empty;

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Gender { get; set; } = string.Empty;

        public DateTime? DateOfBirth { get; set; }

        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [MaxLength(20)]
        public string PhoneNumber { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Address { get; set; } = string.Empty;

        [Required]
        public DateTime CreateDate { get; set; }

        public bool Status { get; set; }

        public string? PhotoUrl { get; set; }

        // Navigation
        public ICollection<TeacherSubject> TeacherSubjects { get; set; } = [];
    }
}
