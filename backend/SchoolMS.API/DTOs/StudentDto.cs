namespace SchoolMS.API.DTOs
{
    public class StudentDto
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public int? ClassId { get; set; }
        public string? ClassName { get; set; }
        public DateTime? CreateDate { get; set; }
        public bool? Status { get; set; } = true;
    }

    public class CreateStudentDto
    {
        public string Code { get; set; } = string.Empty;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public int? ClassId { get; set; }
        public bool? Status { get; set; } = true;
    }

    public class UpdateStudentDto
    {
        public string Code { get; set; } = string.Empty;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public int? ClassId { get; set; }
        public bool? Status { get; set; }
    }
}
