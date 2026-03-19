namespace SchoolMS.Core.Entities
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; } = String.Empty;
        public string Email { get; set; } = String.Empty;
        public string PasswordHash { get; set; } = String.Empty;
        public int RoleId { get; set; }
        public DateTime CreateDate { get; set; }
        public bool Status { get; set; }

        // Navigation property
        public Role? Role { get; set; }
    }
}