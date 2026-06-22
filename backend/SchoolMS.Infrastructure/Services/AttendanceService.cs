using Microsoft.EntityFrameworkCore;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.Infrastructure.Data;

namespace SchoolMS.Infrastructure.Services
{
    public class AttendanceService(SchoolDbContext context) : IAttendanceService
    {
        public async Task<List<Attendance>> GetAllAsync() =>
            await context.Attendances
                .Include(a => a.Student)
                .Include(a => a.Class)
                .Include(a => a.Subject)
                .Include(a => a.Teacher)
                .OrderByDescending(a => a.Date)
                .ToListAsync();

        public async Task<Attendance?> GetByIdAsync(int id) =>
            await context.Attendances
                .Include(a => a.Student)
                .Include(a => a.Class)
                .Include(a => a.Subject)
                .Include(a => a.Teacher)
                .FirstOrDefaultAsync(a => a.Id == id);

        public async Task<Attendance> CreateAsync(Attendance attendance)
        {
            context.Attendances.Add(attendance);
            await context.SaveChangesAsync();
            return (await GetByIdAsync(attendance.Id))!;
        }

        public async Task<Attendance?> UpdateAsync(int id, Attendance attendance)
        {
            var existing = await context.Attendances.FindAsync(id);
            if (existing == null) return null;

            existing.Date = attendance.Date;
            existing.StudentId = attendance.StudentId;
            existing.ClassId = attendance.ClassId;
            existing.SubjectId = attendance.SubjectId;
            existing.TeacherId = attendance.TeacherId;
            existing.Period = attendance.Period;
            existing.Code = attendance.Code;
            existing.Status = attendance.Status;
            existing.Notes = attendance.Notes;

            await context.SaveChangesAsync();
            return (await GetByIdAsync(id))!;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var existing = await context.Attendances.FindAsync(id);
            if (existing == null) return false;
            context.Attendances.Remove(existing);
            await context.SaveChangesAsync();
            return true;
        }
    }
}
