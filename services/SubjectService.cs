using SchoolMAPI.Models;
using Microsoft.EntityFrameworkCore;
using SchoolMAPI.Data;

namespace SchoolMAPI.Services
{
    public interface ISubjectService
    {
        Task<List<Subject>> GetAllSubjectsAsync();
        Task<Subject?> GetSubjectByIdAsync(int id);
        Task<Subject> CreateSubjectAsync(Subject subject);
        Task<Subject?> UpdateSubjectAsync(int id, Subject subject);
        Task<bool> DeleteSubjectAsync(int id);
    }

    public class SubjectService : ISubjectService
    {
        private readonly SchoolDbContext _context;

        public SubjectService(SchoolDbContext context)
        {
            _context = context;
        }

        public async Task<List<Subject>> GetAllSubjectsAsync()
        {
            return await _context.Subjects.ToListAsync();
        }

        public async Task<Subject?> GetSubjectByIdAsync(int id)
        {
            return await _context.Subjects.FindAsync(id);
        }

        public async Task<Subject> CreateSubjectAsync(Subject subject)
        {
            subject.CreateDate = DateTime.UtcNow;
            _context.Subjects.Add(subject);
            await _context.SaveChangesAsync();
            return subject;
        }

        public async Task<Subject?> UpdateSubjectAsync(int id, Subject subject)
        {
            var existingSubject = await _context.Subjects.FindAsync(id);
            if (existingSubject == null) return null;

            existingSubject.Code = subject.Code;
            existingSubject.Name = subject.Name;
            existingSubject.Description = subject.Description;
            existingSubject.Status = subject.Status;

            await _context.SaveChangesAsync();
            return existingSubject;
        }

        public async Task<bool> DeleteSubjectAsync(int id)
        {
            var subject = await _context.Subjects.FindAsync(id);
            if (subject == null) return false;

            _context.Subjects.Remove(subject);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}