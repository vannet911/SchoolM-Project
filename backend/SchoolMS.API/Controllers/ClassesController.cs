using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.Infrastructure.Services;

namespace SchoolMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ClassesController : ControllerBase
    {
        private readonly IClassService _classService;

        public ClassesController(IClassService classService)
        {
            _classService = classService;
        }

        [HttpGet]
        public async Task<ActionResult<List<Class>>> GetAllClasses()
        {
            var classes = await _classService.GetAllClassesAsync();
            return Ok(classes);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Class>> GetClassById(int id)
        {
            var @class = await _classService.GetClassByIdAsync(id);
            if (@class == null)
                return NotFound();
            return Ok(@class);
        }

        [HttpPost]
        public async Task<ActionResult<Class>> CreateClass([FromBody] Class @class)
        {
            var createdClass = await _classService.CreateClassAsync(@class);
            return CreatedAtAction(nameof(GetClassById), new { id = createdClass.Id }, createdClass);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<Class>> UpdateClass(int id, [FromBody] Class @class)
        {
            var updatedClass = await _classService.UpdateClassAsync(id, @class);
            if (updatedClass == null)
                return NotFound();
            return Ok(updatedClass);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteClass(int id)
        {
            var success = await _classService.DeleteClassAsync(id);
            if (!success)
                return NotFound();
            return NoContent();
        }
    }
}