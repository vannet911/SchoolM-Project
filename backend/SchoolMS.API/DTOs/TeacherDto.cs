namespace SchoolMS.API.DTOs
{
    public class TeacherDto
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Gender { get; set; } = string.Empty;
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public List<SubjectDto> Subjects { get; set; } = [];
        public DateTime? CreateDate { get; set; }
        public bool Status { get; set; }
    }

    public class CreateTeacherDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Gender { get; set; } = string.Empty;
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public List<int> SubjectIds { get; set; } = [];
        public bool Status { get; set; } = true;
    }

    public class UpdateTeacherDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Gender { get; set; } = string.Empty;
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public List<int> SubjectIds { get; set; } = [];
        public bool Status { get; set; }
    }
}
