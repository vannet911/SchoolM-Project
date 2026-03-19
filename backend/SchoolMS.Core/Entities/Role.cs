namespace SchoolMS.Core.Entities
{
    public class Role
    {
        public int Id { get; set; }
        public string Code { get; set; } = String.Empty;
        public string Name { get; set; } = String.Empty;
        public string? Description { get; set; } = String.Empty;
        public DateTime CreateDate { get; set; }
        public bool Status { get; set; }
    }
}