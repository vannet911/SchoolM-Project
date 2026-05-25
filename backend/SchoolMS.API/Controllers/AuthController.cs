using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Interfaces;
using SchoolMS.Core.Entities;
using System.Security.Cryptography;
using System.Text;

namespace SchoolMS.API.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly IUserService _userService;

        public AuthController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                var user = await _userService.GetByEmailAsync(request.Email);
                if (user == null)
                {
                    return Unauthorized(new { message = "Email not found" });
                }
                if (!VerifyPassword(request.Password, user.PasswordHash))
                {
                    return Unauthorized(new { message = "Invalid password" });
                }

                if (!user.Status)
                {
                    return Unauthorized(new { message = "Account is disabled" });
                }

                // Return user info (in production, generate JWT token here)
                return Ok(new
                {
                    token = $"user_{user.Id}_{Guid.NewGuid()}", // Simple token for demo
                    user = new
                    {
                        id = user.Id,
                        username = user.Username,
                        email = user.Email,
                        roleId = user.RoleId,
                        roleName = user.Role?.Name
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Login failed: {ex.Message}" });
            }
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            try
            {
                // Check if email already exists
                var existingUser = await _userService.GetByEmailAsync(request.Email);
                if (existingUser != null)
                {
                    return BadRequest(new { message = "Email already registered" });
                }

                var user = new User
                {
                    Username = request.Username,
                    Email = request.Email,
                    PasswordHash = HashPassword(request.Password),
                    RoleId = request.RoleId,
                    CreateDate = DateTime.UtcNow,
                    Status = true
                };

                var createdUser = await _userService.CreateAsync(user);
                return Ok(new
                {
                    id = createdUser.Id,
                    username = createdUser.Username,
                    email = createdUser.Email
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Registration failed: {ex.Message}" });
            }
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            try
            {
                await _userService.ChangePasswordAsync(request.UserId, request.CurrentPassword, request.NewPassword);
                return Ok(new { message = "Password changed successfully" });
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized(new { message = "Current password is incorrect" });
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Failed to change password: {ex.Message}" });
            }
        }

        private bool VerifyPassword(string password, string passwordHash)
        {
            return HashPassword(password) == passwordHash;
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

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class RegisterRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public int RoleId { get; set; }
    }

    public class ChangePasswordRequest
    {
        public int UserId { get; set; }
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
}