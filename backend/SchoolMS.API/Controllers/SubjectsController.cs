using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;

namespace SchoolMS.API.Controllers
{
    /// <summary>Manage subject records.</summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class SubjectsController(ISubjectService subjectService) : ControllerBase
    {
        /// <summary>Get all subjects.</summary>
        /// <response code="200">Returns the list of all subjects.</response>
        [HttpGet]
        [ProducesResponseType(typeof(List<Subject>), StatusCodes.Status200OK)]
        public async Task<ActionResult<List<Subject>>> GetAllSubjects()
        {
            var subjects = await subjectService.GetAllSubjectsAsync();
            return Ok(subjects);
        }

        /// <summary>Get a subject by ID.</summary>
        /// <param name="id">Subject ID.</param>
        /// <response code="200">Returns the matching subject.</response>
        /// <response code="404">Subject not found.</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(Subject), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Subject>> GetSubjectById(int id)
        {
            var subject = await subjectService.GetSubjectByIdAsync(id);
            if (subject == null) return NotFound();
            return Ok(subject);
        }

        /// <summary>Create a new subject.</summary>
        /// <param name="subject">Subject details.</param>
        /// <response code="201">Subject created successfully.</response>
        [HttpPost]
        [ProducesResponseType(typeof(Subject), StatusCodes.Status201Created)]
        public async Task<ActionResult<Subject>> CreateSubject([FromBody] Subject subject)
        {
            var created = await subjectService.CreateSubjectAsync(subject);
            return CreatedAtAction(nameof(GetSubjectById), new { id = created.Id }, created);
        }

        /// <summary>Update an existing subject.</summary>
        /// <param name="id">Subject ID.</param>
        /// <param name="subject">Updated subject details.</param>
        /// <response code="200">Subject updated successfully.</response>
        /// <response code="404">Subject not found.</response>
        [HttpPut("{id}")]
        [ProducesResponseType(typeof(Subject), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Subject>> UpdateSubject(int id, [FromBody] Subject subject)
        {
            var updated = await subjectService.UpdateSubjectAsync(id, subject);
            if (updated == null) return NotFound();
            return Ok(updated);
        }

        /// <summary>Delete a subject.</summary>
        /// <param name="id">Subject ID.</param>
        /// <response code="204">Subject deleted successfully.</response>
        /// <response code="404">Subject not found.</response>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteSubject(int id)
        {
            var success = await subjectService.DeleteSubjectAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }
    }
}
