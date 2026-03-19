namespace SchoolMAPI.Models
{
    public class Student
    {
        public int Id { get; set; }
        public string Code { get; set; } = String.Empty;
        public string? Name { get; set; } = String.Empty;
        public string? Gender { get; set; } = String.Empty;
        public DateTime? DateOfBirth { get; set; }
        public string? Email { get; set; } = String.Empty;
        public string? PhoneNumber { get; set; } = String.Empty;
        public string? Address { get; set; } = String.Empty;
        public DateTime? CreateDate { get; set; }
        public bool? Status { get; set; }
    }
}