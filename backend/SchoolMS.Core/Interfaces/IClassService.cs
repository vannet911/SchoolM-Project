using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface IClassService
    {
        Task<List<Class>> GetAllClassesAsync();
        Task<Class?> GetClassByIdAsync(int id);
        Task<Class> CreateClassAsync(Class @class);
        Task<Class?> UpdateClassAsync(int id, Class @class);
        Task<bool> DeleteClassAsync(int id);
    }
}