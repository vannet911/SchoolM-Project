using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface ITeacherService
    {
        Task<List<Teacher>> GetAllAsync();
        Task<Teacher> GetByIdAsync(int id);
        Task<Teacher> CreateAsync(Teacher teacher);
        Task<Teacher> UpdateAsync(int id, Teacher teacher);
        Task<bool> DeleteAsync(int id);
    }
}