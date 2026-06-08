using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using Microsoft.EntityFrameworkCore;
using SchoolMS.Infrastructure.Data;

namespace SchoolMS.Infrastructure.Services
{
    public class StudentService : IStudentService
    {
        private readonly SchoolDbContext _context;

        public StudentService(SchoolDbContext context)
        {
            _context = context;
        }

        public async Task<List<Student>> GetAllStudentsAsync() =>
            await _context.Students
                .Include(s => s.Class)
                .ToListAsync();

        public async Task<Student?> GetStudentByIdAsync(int id) =>
            await _context.Students
                .Include(s => s.Class)
                .FirstOrDefaultAsync(s => s.Id == id);

        public async Task<Student> CreateStudentAsync(Student student)
        {
            _context.Students.Add(student);
            await _context.SaveChangesAsync();
            return (await GetStudentByIdAsync(student.Id))!;
        }

        public async Task<Student?> UpdateStudentAsync(int id, Student student)
        {
            var existingStudent = await _context.Students.FindAsync(id);
            if (existingStudent == null) return null;

            existingStudent.FirstName = student.FirstName;
            existingStudent.LastName = student.LastName;
            existingStudent.Code = student.Code;
            existingStudent.Gender = student.Gender;
            existingStudent.DateOfBirth = student.DateOfBirth;
            existingStudent.Email = student.Email;
            existingStudent.PhoneNumber = student.PhoneNumber;
            existingStudent.Address = student.Address;
            existingStudent.ClassId = student.ClassId;
            existingStudent.Status = student.Status;

            await _context.SaveChangesAsync();
            return (await GetStudentByIdAsync(id))!;
        }

        public async Task<bool> DeleteStudentAsync(int id)
        {
            var student = await _context.Students.FindAsync(id);
            if (student == null) return false;
            _context.Students.Remove(student);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<Student?> UpdatePhotoAsync(int id, string photoUrl)
        {
            var student = await _context.Students.FindAsync(id);
            if (student == null) return null;
            student.PhotoUrl = photoUrl;
            await _context.SaveChangesAsync();
            return (await GetStudentByIdAsync(id))!;
        }
    }
}
