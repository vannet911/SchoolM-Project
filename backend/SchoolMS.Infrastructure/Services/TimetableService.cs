using Microsoft.EntityFrameworkCore;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.Infrastructure.Data;

namespace SchoolMS.Infrastructure.Services
{
    public class TimetableService(SchoolDbContext context) : ITimetableService
    {
        public async Task<List<Timetable>> GetAllAsync() =>
            await context.Timetables
                .Include(t => t.Class)
                .Include(t => t.Subject)
                .Include(t => t.Teacher)
                .ToListAsync();

        public async Task<Timetable?> GetByIdAsync(int id) =>
            await context.Timetables
                .Include(t => t.Class)
                .Include(t => t.Subject)
                .Include(t => t.Teacher)
                .FirstOrDefaultAsync(t => t.Id == id);

        public async Task<Timetable> CreateAsync(Timetable entry)
        {
            context.Timetables.Add(entry);
            await context.SaveChangesAsync();
            return (await GetByIdAsync(entry.Id))!;
        }

        public async Task<Timetable?> UpdateAsync(int id, Timetable entry)
        {
            var existing = await context.Timetables.FindAsync(id);
            if (existing == null) return null;

            existing.Day = entry.Day;
            existing.Period = entry.Period;
            existing.ClassId = entry.ClassId;
            existing.SubjectId = entry.SubjectId;
            existing.TeacherId = entry.TeacherId;
            existing.Room = entry.Room;
            existing.AcademicYear = entry.AcademicYear;

            await context.SaveChangesAsync();
            return (await GetByIdAsync(id))!;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var existing = await context.Timetables.FindAsync(id);
            if (existing == null) return false;
            context.Timetables.Remove(existing);
            await context.SaveChangesAsync();
            return true;
        }
    }
}
