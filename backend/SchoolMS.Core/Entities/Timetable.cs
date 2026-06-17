using System.ComponentModel.DataAnnotations;

namespace SchoolMS.Core.Entities
{
    public class Timetable
    {
        public int Id { get; set; }

        [Required]
        public string Day { get; set; } = string.Empty;  // e.g. "Monday"

        public int Period { get; set; }                   // 1–10

        public int? ClassId { get; set; }
        public int? SubjectId { get; set; }
        public int? TeacherId { get; set; }

        public string? Room { get; set; }
        public string? AcademicYear { get; set; }

        // Navigation
        public Class? Class { get; set; }
        public Subject? Subject { get; set; }
        public Teacher? Teacher { get; set; }
    }
}
