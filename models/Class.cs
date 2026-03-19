using System;
using System.ComponentModel.DataAnnotations;

namespace SchoolMAPI.Models
{
    public class Class
    {
        public int Id { get; set; }

        [Required, MaxLength(20)]
        public string Code { get; set; } = String.Empty;

        [Required, MaxLength(100)]
        public string Name { get; set; } = String.Empty;

        [MaxLength(255)]
        public string? Description { get; set; } = String.Empty;

        public int? GradeLevel { get; set; }

        public int? ClassTeacherId { get; set; }

        public int? SubjectId { get; set; }

        public DateTime CreateDate { get; set; }

        public bool Status { get; set; }

        // Navigation properties
        public Teacher? ClassTeacher { get; set; }
        public Subject? Subject { get; set; }
    }
}