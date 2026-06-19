namespace SchoolMS.Core.Entities
{
    public class Attendance
    {
        public int Id { get; set; }
        public DateTime Date { get; set; }
        public int StudentId { get; set; }
        public int? ClassId { get; set; }
        public int? SubjectId { get; set; }
        public string Status { get; set; } = "Present"; // Present | Absent | Late | Excused
        public string? Notes { get; set; }

        // Navigation
        public Student? Student { get; set; }
        public Class? Class { get; set; }
        public Subject? Subject { get; set; }
    }
}
