using Microsoft.EntityFrameworkCore;
using SchoolMS.Core.Entities;

namespace SchoolMS.Infrastructure.Data
{
    public class SchoolDbContext : DbContext
    {
        public SchoolDbContext(DbContextOptions<SchoolDbContext> options) : base(options) { }

        public DbSet<Student> Students { get; set; }
        public DbSet<Teacher> Teachers { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Class> Classes { get; set; }
        public DbSet<Subject> Subjects { get; set; }
        public DbSet<TeacherSubject> TeacherSubjects { get; set; }
        public DbSet<ClassSubject> ClassSubjects { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TeacherSubject>()
                .HasKey(ts => new { ts.TeacherId, ts.SubjectId });

            modelBuilder.Entity<TeacherSubject>()
                .HasOne(ts => ts.Teacher)
                .WithMany(t => t.TeacherSubjects)
                .HasForeignKey(ts => ts.TeacherId);

            modelBuilder.Entity<TeacherSubject>()
                .HasOne(ts => ts.Subject)
                .WithMany(s => s.TeacherSubjects)
                .HasForeignKey(ts => ts.SubjectId);

            modelBuilder.Entity<ClassSubject>()
                .HasKey(cs => new { cs.ClassId, cs.SubjectId });

            modelBuilder.Entity<ClassSubject>()
                .HasOne(cs => cs.Class)
                .WithMany(c => c.ClassSubjects)
                .HasForeignKey(cs => cs.ClassId);

            modelBuilder.Entity<ClassSubject>()
                .HasOne(cs => cs.Subject)
                .WithMany(s => s.ClassSubjects)
                .HasForeignKey(cs => cs.SubjectId);

            modelBuilder.Entity<Student>()
                .HasOne(s => s.Class)
                .WithMany(c => c.Students)
                .HasForeignKey(s => s.ClassId)
                .OnDelete(DeleteBehavior.SetNull);
        }
    }
}
