namespace SchoolMS.Core.Entities
{
    public class ClassSubject
    {
        public int ClassId { get; set; }
        public int SubjectId { get; set; }
        public Class Class { get; set; } = null!;
        public Subject Subject { get; set; } = null!;
    }
}
