using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using Microsoft.EntityFrameworkCore;
using SchoolMS.Infrastructure.Data;

namespace SchoolMS.Infrastructure.Services
{
    public class TeacherService : ITeacherService
    {
        private readonly SchoolDbContext _context;

        public TeacherService(SchoolDbContext context)
        {
            _context = context;
        }

        public async Task<List<Teacher>> GetAllAsync() =>
            await _context.Teachers
                .Include(t => t.TeacherSubjects)
                    .ThenInclude(ts => ts.Subject)
                .ToListAsync();

        public async Task<Teacher?> GetByIdAsync(int id) =>
            await _context.Teachers
                .Include(t => t.TeacherSubjects)
                    .ThenInclude(ts => ts.Subject)
                .FirstOrDefaultAsync(t => t.Id == id);

        public async Task<Teacher> CreateAsync(Teacher teacher, List<int> subjectIds)
        {
            teacher.CreateDate = DateTime.UtcNow;
            _context.Teachers.Add(teacher);
            await _context.SaveChangesAsync();

            foreach (var subjectId in subjectIds)
                _context.TeacherSubjects.Add(new TeacherSubject { TeacherId = teacher.Id, SubjectId = subjectId });
            await _context.SaveChangesAsync();

            return (await GetByIdAsync(teacher.Id))!;
        }

        public async Task<Teacher?> UpdateAsync(int id, Teacher teacher, List<int> subjectIds)
        {
            var existing = await _context.Teachers
                .Include(t => t.TeacherSubjects)
                .FirstOrDefaultAsync(t => t.Id == id);
            if (existing == null) return null;

            existing.Code = teacher.Code;
            existing.Name = teacher.Name;
            existing.Gender = teacher.Gender;
            existing.DateOfBirth = teacher.DateOfBirth;
            existing.Email = teacher.Email;
            existing.PhoneNumber = teacher.PhoneNumber;
            existing.Address = teacher.Address;
            existing.Status = teacher.Status;

            // Replace subject assignments
            _context.TeacherSubjects.RemoveRange(existing.TeacherSubjects);
            foreach (var subjectId in subjectIds)
                _context.TeacherSubjects.Add(new TeacherSubject { TeacherId = id, SubjectId = subjectId });

            await _context.SaveChangesAsync();
            return (await GetByIdAsync(id))!;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var teacher = await _context.Teachers.FindAsync(id);
            if (teacher == null) return false;
            _context.Teachers.Remove(teacher);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<Teacher?> UpdatePhotoAsync(int id, string photoUrl)
        {
            var teacher = await _context.Teachers.FindAsync(id);
            if (teacher == null) return null;
            teacher.PhotoUrl = photoUrl;
            await _context.SaveChangesAsync();
            return (await GetByIdAsync(id))!;
        }
    }
}
