using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface ITimetableService
    {
        Task<List<Timetable>> GetAllAsync();
        Task<Timetable?> GetByIdAsync(int id);
        Task<Timetable> CreateAsync(Timetable entry);
        Task<Timetable?> UpdateAsync(int id, Timetable entry);
        Task<bool> DeleteAsync(int id);
    }
}
