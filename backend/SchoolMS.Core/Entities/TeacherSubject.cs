namespace SchoolMS.Core.Entities
{
    public class TeacherSubject
    {
        public int TeacherId { get; set; }
        public int SubjectId { get; set; }
        public Teacher Teacher { get; set; } = null!;
        public Subject Subject { get; set; } = null!;
    }
}
