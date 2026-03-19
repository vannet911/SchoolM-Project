using SchoolMAPI.Data;
using SchoolMAPI.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace SchoolMAPI.Services
{
    public interface IUserService
    {
        Task<List<User>> GetAllAsync();
        Task<User> GetByIdAsync(int id);
        Task<User> CreateAsync(User user);
        Task<User> UpdateAsync(int id, User user);
        Task<bool> DeleteAsync(int id);
    }

    public class UserService : IUserService
    {
        private readonly SchoolDbContext _context;

        public UserService(SchoolDbContext context)
        {
            _context = context;
        }

        public async Task<List<User>> GetAllAsync() => await _context.Users.Include(u => u.Role).ToListAsync();

        public async Task<User> GetByIdAsync(int id)
        {
            var user = await _context.Users.Include(u => u.Role).FirstOrDefaultAsync(u => u.Id == id);
            if (user == null) throw new KeyNotFoundException($"User with id {id} not found");
            return user;
        }

        public async Task<User> CreateAsync(User user)
        {
            if (string.IsNullOrWhiteSpace(user.Username))
                throw new ArgumentException("Username is required.");
            if (string.IsNullOrWhiteSpace(user.Email))
                throw new ArgumentException("Email is required.");
            if (string.IsNullOrWhiteSpace(user.PasswordHash))
                throw new ArgumentException("Password is required.");

            user.PasswordHash = HashPassword(user.PasswordHash);
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return user;
        }

        public async Task<User> UpdateAsync(int id, User user)
        {
            var existing = await _context.Users.FindAsync(id);
            if (existing == null) throw new KeyNotFoundException($"User with id {id} not found");

            existing.Username = user.Username;
            existing.Email = user.Email;
            existing.RoleId = user.RoleId;
            existing.Status = user.Status;

            await _context.SaveChangesAsync();
            return existing;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return false;

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
            return true;
        }

        private string HashPassword(string password)
        {
            using (var sha256 = SHA256.Create())
            {
                var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(hashedBytes);
            }
        }
    }
}