using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface ITeacherService
    {
        Task<List<Teacher>> GetAllAsync();
        Task<Teacher?> GetByIdAsync(int id);
        Task<Teacher> CreateAsync(Teacher teacher, List<int> subjectIds);
        Task<Teacher?> UpdateAsync(int id, Teacher teacher, List<int> subjectIds);
        Task<bool> DeleteAsync(int id);
        Task<Teacher?> UpdatePhotoAsync(int id, string photoUrl);
    }
}
