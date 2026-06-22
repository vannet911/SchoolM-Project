namespace SchoolMS.API.DTOs
{
    public class AttendanceDto
    {
        public int Id { get; set; }
        public DateTime Date { get; set; }
        public int StudentId { get; set; }
        public string? StudentCode { get; set; }
        public string? StudentName { get; set; }
        public int? ClassId { get; set; }
        public string? ClassName { get; set; }
        public int? SubjectId { get; set; }
        public string? SubjectName { get; set; }
        public int? TeacherId { get; set; }
        public string? TeacherName { get; set; }
        public int? Period { get; set; }
        public string? Code { get; set; }
        public string Status { get; set; } = "Present";
        public string? Notes { get; set; }
    }

    public class CreateAttendanceDto
    {
        public DateTime Date { get; set; }
        public int StudentId { get; set; }
        public int? ClassId { get; set; }
        public int? SubjectId { get; set; }
        public int? TeacherId { get; set; }
        public int? Period { get; set; }
        public string? Code { get; set; }
        public string Status { get; set; } = "Present";
        public string? Notes { get; set; }
    }

    public class UpdateAttendanceDto
    {
        public DateTime Date { get; set; }
        public int StudentId { get; set; }
        public int? ClassId { get; set; }
        public int? SubjectId { get; set; }
        public int? TeacherId { get; set; }
        public int? Period { get; set; }
        public string? Code { get; set; }
        public string Status { get; set; } = "Present";
        public string? Notes { get; set; }
    }
}
