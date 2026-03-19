using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface IRoleService
    {
        Task<List<Role>> GetAllAsync();
        Task<Role> GetByIdAsync(int id);
        Task<Role> CreateAsync(Role role);
        Task<Role> UpdateAsync(int id, Role role);
        Task<bool> DeleteAsync(int id);
    }
}