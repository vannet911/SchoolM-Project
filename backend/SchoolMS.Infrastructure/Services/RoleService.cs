using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using Microsoft.EntityFrameworkCore;
using SchoolMS.Infrastructure.Data;

namespace SchoolMS.Infrastructure.Services
{
    public class RoleService : IRoleService
    {
        private readonly SchoolDbContext _context;

        public RoleService(SchoolDbContext context)
        {
            _context = context;
        }

        public async Task<List<Role>> GetAllAsync() => await _context.Roles.ToListAsync();

        public async Task<Role> GetByIdAsync(int id)
        {
            var role = await _context.Roles.FindAsync(id);
            if (role == null) throw new KeyNotFoundException($"Role with id {id} not found");
            return role;
        }

        public async Task<Role> CreateAsync(Role role)
        {
            if (string.IsNullOrWhiteSpace(role.Code))
                throw new ArgumentException("Role Code is required.");
            if (string.IsNullOrWhiteSpace(role.Name))
                throw new ArgumentException("Role Name is required.");

            _context.Roles.Add(role);
            await _context.SaveChangesAsync();
            return role;
        }

        public async Task<Role> UpdateAsync(int id, Role role)
        {
            var existing = await _context.Roles.FindAsync(id);
            if (existing == null) throw new KeyNotFoundException($"Role with id {id} not found");

            existing.Code = role.Code;
            existing.Name = role.Name;
            existing.Description = role.Description;
            existing.Status = role.Status;

            await _context.SaveChangesAsync();
            return existing;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var role = await _context.Roles.FindAsync(id);
            if (role == null) return false;

            _context.Roles.Remove(role);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}