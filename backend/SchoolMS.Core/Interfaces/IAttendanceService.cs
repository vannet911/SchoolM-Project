using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface IAttendanceService
    {
        Task<List<Attendance>> GetAllAsync();
        Task<Attendance?> GetByIdAsync(int id);
        Task<Attendance> CreateAsync(Attendance attendance);
        Task<Attendance?> UpdateAsync(int id, Attendance attendance);
        Task<bool> DeleteAsync(int id);
    }
}
