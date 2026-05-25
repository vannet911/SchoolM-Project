using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using Microsoft.EntityFrameworkCore;
using SchoolMS.Infrastructure.Data;

namespace SchoolMS.Infrastructure.Services
{
    public class ClassService : IClassService
    {
        private readonly SchoolDbContext _context;

        public ClassService(SchoolDbContext context)
        {
            _context = context;
        }

        public async Task<List<Class>> GetAllClassesAsync() =>
            await _context.Classes
                .Include(c => c.ClassTeacher)
                .Include(c => c.ClassSubjects)
                    .ThenInclude(cs => cs.Subject)
                .ToListAsync();

        public async Task<Class?> GetClassByIdAsync(int id) =>
            await _context.Classes
                .Include(c => c.ClassTeacher)
                .Include(c => c.ClassSubjects)
                    .ThenInclude(cs => cs.Subject)
                .FirstOrDefaultAsync(c => c.Id == id);

        public async Task<Class> CreateClassAsync(Class @class, List<int> subjectIds)
        {
            @class.CreateDate = DateTime.UtcNow;
            _context.Classes.Add(@class);
            await _context.SaveChangesAsync();

            foreach (var subjectId in subjectIds)
                _context.ClassSubjects.Add(new ClassSubject { ClassId = @class.Id, SubjectId = subjectId });
            await _context.SaveChangesAsync();

            return (await GetClassByIdAsync(@class.Id))!;
        }

        public async Task<Class?> UpdateClassAsync(int id, Class @class, List<int> subjectIds)
        {
            var existing = await _context.Classes
                .Include(c => c.ClassSubjects)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (existing == null) return null;

            existing.Code = @class.Code;
            existing.Name = @class.Name;
            existing.Description = @class.Description;
            existing.GradeLevel = @class.GradeLevel;
            existing.ClassTeacherId = @class.ClassTeacherId;
            existing.Status = @class.Status;

            // Replace subject assignments
            _context.ClassSubjects.RemoveRange(existing.ClassSubjects);
            foreach (var subjectId in subjectIds)
                _context.ClassSubjects.Add(new ClassSubject { ClassId = id, SubjectId = subjectId });

            await _context.SaveChangesAsync();
            return (await GetClassByIdAsync(id))!;
        }

        public async Task<bool> DeleteClassAsync(int id)
        {
            var @class = await _context.Classes.FindAsync(id);
            if (@class == null) return false;
            _context.Classes.Remove(@class);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
