using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface IClassService
    {
        Task<List<Class>> GetAllClassesAsync();
        Task<Class?> GetClassByIdAsync(int id);
        Task<Class> CreateClassAsync(Class @class, List<int> subjectIds);
        Task<Class?> UpdateClassAsync(int id, Class @class, List<int> subjectIds);
        Task<bool> DeleteClassAsync(int id);
    }
}
