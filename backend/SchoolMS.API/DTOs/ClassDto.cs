namespace SchoolMS.API.DTOs
{
    public class ClassDto
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? GradeLevel { get; set; }
        public int? ClassTeacherId { get; set; }
        public string? ClassTeacherName { get; set; }
        public List<SubjectDto> Subjects { get; set; } = [];
        public DateTime CreateDate { get; set; }
        public bool Status { get; set; }
    }

    public class CreateClassDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? GradeLevel { get; set; }
        public int? ClassTeacherId { get; set; }
        public List<int> SubjectIds { get; set; } = [];
        public bool Status { get; set; } = true;
    }

    public class UpdateClassDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? GradeLevel { get; set; }
        public int? ClassTeacherId { get; set; }
        public List<int> SubjectIds { get; set; } = [];
        public bool Status { get; set; }
    }
}
