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

        public async Task<List<Teacher>> GetAllAsync() => await _context.Teachers.ToListAsync();
        public async Task<Teacher> GetByIdAsync(int id) 
        {
            var teacher = await _context.Teachers.FindAsync(id);
            if (teacher == null) throw new KeyNotFoundException($"Teacher with id {id} not found.");
            return teacher;
        }

        public async Task<Teacher> CreateAsync(Teacher teacher)
        {
            if (string.IsNullOrWhiteSpace(teacher.Code))
                throw new ArgumentException("Teacher Code is required.");
            if (string.IsNullOrWhiteSpace(teacher.Name))
                throw new ArgumentException("Teacher Name is required.");

            _context.Teachers.Add(teacher);
            await _context.SaveChangesAsync();
            return teacher;
        }

        public async Task<Teacher> UpdateAsync(int id, Teacher teacher)
        {
            var existing = await _context.Teachers.FindAsync(id);
            if (existing == null) throw new KeyNotFoundException($"Teacher with id {id} not found.");

            existing.Name = teacher.Name;
            existing.Gender = teacher.Gender;
            existing.DateOfBirth = teacher.DateOfBirth;
            existing.Email = teacher.Email;
            existing.PhoneNumber = teacher.PhoneNumber;
            existing.Subject = teacher.Subject;
            existing.CreateDate = teacher.CreateDate;
            existing.Status = teacher.Status;

            await _context.SaveChangesAsync();
            return existing;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var teacher = await _context.Teachers.FindAsync(id);
            if (teacher == null) return false;
            _context.Teachers.Remove(teacher);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}