using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;

namespace SchoolMS.API.Controllers
{
    /// <summary>Manage user roles.</summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class RolesController(IRoleService service) : ControllerBase
    {
        /// <summary>Get all roles.</summary>
        /// <response code="200">Returns the list of all roles.</response>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<Role>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<Role>>> GetAll()
        {
            return Ok(await service.GetAllAsync());
        }

        /// <summary>Get a role by ID.</summary>
        /// <param name="id">Role ID.</param>
        /// <response code="200">Returns the matching role.</response>
        /// <response code="404">Role not found.</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(Role), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Role>> GetById(int id)
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

        /// <summary>Create a new role.</summary>
        /// <param name="role">Role details.</param>
        /// <response code="201">Role created successfully.</response>
        [HttpPost]
        [ProducesResponseType(typeof(Role), StatusCodes.Status201Created)]
        public async Task<ActionResult<Role>> Create([FromBody] Role role)
        {
            var created = await service.CreateAsync(role);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        /// <summary>Update an existing role.</summary>
        /// <param name="id">Role ID.</param>
        /// <param name="role">Updated role details.</param>
        /// <response code="204">Role updated successfully.</response>
        /// <response code="400">ID in URL does not match body.</response>
        /// <response code="404">Role not found.</response>
        [HttpPut("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Update(int id, [FromBody] Role role)
        {
            if (id != role.Id) return BadRequest();
            try
            {
                await service.UpdateAsync(id, role);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        /// <summary>Delete a role.</summary>
        /// <param name="id">Role ID.</param>
        /// <response code="204">Role deleted successfully.</response>
        /// <response code="404">Role not found.</response>
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
