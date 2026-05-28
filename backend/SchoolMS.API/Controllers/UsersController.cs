using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;

namespace SchoolMS.API.Controllers
{
    /// <summary>Manage system user accounts.</summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class UsersController(IUserService service) : ControllerBase
    {
        /// <summary>Get all users.</summary>
        /// <response code="200">Returns the list of all users.</response>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<User>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<User>>> GetAll()
        {
            return Ok(await service.GetAllAsync());
        }

        /// <summary>Get a user by ID.</summary>
        /// <param name="id">User ID.</param>
        /// <response code="200">Returns the matching user.</response>
        /// <response code="404">User not found.</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(User), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<User>> GetById(int id)
        {
            try
            {
                return Ok(await service.GetByIdAsync(id));
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        /// <summary>Create a new user.</summary>
        /// <param name="user">User details.</param>
        /// <response code="201">User created successfully.</response>
        [HttpPost]
        [ProducesResponseType(typeof(User), StatusCodes.Status201Created)]
        public async Task<ActionResult<User>> Create([FromBody] User user)
        {
            var created = await service.CreateAsync(user);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        /// <summary>Update an existing user.</summary>
        /// <param name="id">User ID.</param>
        /// <param name="user">Updated user details.</param>
        /// <response code="204">User updated successfully.</response>
        /// <response code="400">ID in URL does not match body.</response>
        /// <response code="404">User not found.</response>
        [HttpPut("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Update(int id, [FromBody] User user)
        {
            if (id != user.Id) return BadRequest();
            try
            {
                await service.UpdateAsync(id, user);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        /// <summary>Delete a user.</summary>
        /// <param name="id">User ID.</param>
        /// <response code="204">User deleted successfully.</response>
        /// <response code="404">User not found.</response>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Delete(int id)
        {
            var success = await service.DeleteAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }
    }
}
