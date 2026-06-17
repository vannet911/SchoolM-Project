namespace SchoolMS.API.DTOs
{
    public class TimetableDto
    {
        public int Id { get; set; }
        public string Day { get; set; } = string.Empty;
        public int Period { get; set; }
        public int? ClassId { get; set; }
        public string? ClassName { get; set; }
        public int? SubjectId { get; set; }
        public string? SubjectName { get; set; }
        public string? SubjectCode { get; set; }
        public int? TeacherId { get; set; }
        public string? TeacherName { get; set; }
        public string? Room { get; set; }
        public string? AcademicYear { get; set; }
    }

    public class CreateTimetableDto
    {
        public string Day { get; set; } = string.Empty;
        public int Period { get; set; }
        public int? ClassId { get; set; }
        public int? SubjectId { get; set; }
        public int? TeacherId { get; set; }
        public string? Room { get; set; }
        public string? AcademicYear { get; set; }
    }

    public class UpdateTimetableDto
    {
        public string Day { get; set; } = string.Empty;
        public int Period { get; set; }
        public int? ClassId { get; set; }
        public int? SubjectId { get; set; }
        public int? TeacherId { get; set; }
        public string? Room { get; set; }
        public string? AcademicYear { get; set; }
    }
}
