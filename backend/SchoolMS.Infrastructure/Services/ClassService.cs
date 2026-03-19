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

        public async Task<List<Class>> GetAllClassesAsync()
        {
            return await _context.Classes
                .Include(c => c.ClassTeacher)
                .Include(c => c.Subject)
                .ToListAsync();
        }

        public async Task<Class?> GetClassByIdAsync(int id)
        {
            return await _context.Classes
                .Include(c => c.ClassTeacher)
                .Include(c => c.Subject)
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<Class> CreateClassAsync(Class @class)
        {
            @class.CreateDate = DateTime.UtcNow;
            _context.Classes.Add(@class);
            await _context.SaveChangesAsync();
            return @class;
        }

        public async Task<Class?> UpdateClassAsync(int id, Class @class)
        {
            var existingClass = await _context.Classes.FindAsync(id);
            if (existingClass == null) return null;

            existingClass.Code = @class.Code;
            existingClass.Name = @class.Name;
            existingClass.Description = @class.Description;
            existingClass.GradeLevel = @class.GradeLevel;
            existingClass.ClassTeacherId = @class.ClassTeacherId;
            existingClass.SubjectId = @class.SubjectId;
            existingClass.Status = @class.Status;

            await _context.SaveChangesAsync();
            return existingClass;
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