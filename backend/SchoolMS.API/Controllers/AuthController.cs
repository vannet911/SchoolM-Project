using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Interfaces;
using SchoolMS.Core.Entities;
using System.Security.Cryptography;
using System.Text;

namespace SchoolMS.API.Controllers
{
    /// <summary>Authentication — login, register, and password management.</summary>
    [ApiController]
    [Route("api/auth")]
    [Produces("application/json")]
    public class AuthController(IUserService userService) : ControllerBase
    {

        /// <summary>Authenticate a user and return a bearer token.</summary>
        /// <param name="request">Email and password credentials.</param>
        /// <returns>Bearer token and basic user info.</returns>
        /// <response code="200">Login successful — returns token and user object.</response>
        /// <response code="401">Invalid credentials or account disabled.</response>
        /// <response code="500">Unexpected server error.</response>
        [HttpPost("login")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                var user = await userService.GetByEmailAsync(request.Email);
                if (user == null)
                    return Unauthorized(new { message = "Email not found" });

                if (!VerifyPassword(request.Password, user.PasswordHash))
                    return Unauthorized(new { message = "Invalid password" });

                if (!user.Status)
                    return Unauthorized(new { message = "Account is disabled" });

                return Ok(new
                {
                    token = $"user_{user.Id}_{Guid.NewGuid()}",
                    user = new
                    {
                        id = user.Id,
                        username = user.Username,
                        email = user.Email,
                        roleId = user.RoleId,
                        roleName = user.Role?.Name,
                        photoUrl = user.PhotoUrl
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Login failed: {ex.Message}" });
            }
        }

        /// <summary>Register a new user account.</summary>
        /// <param name="request">Username, email, password, and role ID.</param>
        /// <returns>The newly created user's ID, username, and email.</returns>
        /// <response code="200">Registration successful.</response>
        /// <response code="400">Email already in use.</response>
        /// <response code="500">Unexpected server error.</response>
        [HttpPost("register")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            try
            {
                var existingUser = await userService.GetByEmailAsync(request.Email);
                if (existingUser != null)
                    return BadRequest(new { message = "Email already registered" });

                var user = new User
                {
                    Username = request.Username,
                    Email = request.Email,
                    PasswordHash = HashPassword(request.Password),
                    RoleId = request.RoleId,
                    CreateDate = DateTime.UtcNow,
                    Status = true
                };

                var createdUser = await userService.CreateAsync(user);
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

        /// <summary>Change the password for an existing user.</summary>
        /// <param name="request">User ID, current password, and new password.</param>
        /// <response code="200">Password changed successfully.</response>
        /// <response code="401">Current password is incorrect.</response>
        /// <response code="404">User not found.</response>
        /// <response code="500">Unexpected server error.</response>
        [HttpPost("change-password")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            try
            {
                await userService.ChangePasswordAsync(request.UserId, request.CurrentPassword, request.NewPassword);
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

        private static bool VerifyPassword(string password, string passwordHash) =>
            HashPassword(password) == passwordHash;

        private static string HashPassword(string password) =>
            Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(password)));
    }

    /// <summary>Login credentials.</summary>
    public class LoginRequest
    {
        /// <summary>Registered email address.</summary>
        public string Email { get; set; } = string.Empty;
        /// <summary>Account password.</summary>
        public string Password { get; set; } = string.Empty;
    }

    /// <summary>New user registration details.</summary>
    public class RegisterRequest
    {
        /// <summary>Display username.</summary>
        public string Username { get; set; } = string.Empty;
        /// <summary>Email address (must be unique).</summary>
        public string Email { get; set; } = string.Empty;
        /// <summary>Plain-text password (stored as SHA-256 hash).</summary>
        public string Password { get; set; } = string.Empty;
        /// <summary>Role ID to assign to the new user.</summary>
        public int RoleId { get; set; }
    }

    /// <summary>Password change request.</summary>
    public class ChangePasswordRequest
    {
        /// <summary>ID of the user changing their password.</summary>
        public int UserId { get; set; }
        /// <summary>The user's current password.</summary>
        public string CurrentPassword { get; set; } = string.Empty;
        /// <summary>The desired new password.</summary>
        public string NewPassword { get; set; } = string.Empty;
    }
}
