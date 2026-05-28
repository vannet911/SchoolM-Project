using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

namespace SchoolMS.API.Controllers
{
    /// <summary>Manage class records.</summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class ClassesController(IClassService classService) : ControllerBase
    {
        /// <summary>Get all classes.</summary>
        /// <response code="200">Returns the list of all classes with their subjects and class teacher.</response>
        [HttpGet]
        [ProducesResponseType(typeof(List<ClassDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<List<ClassDto>>> GetAllClasses()
        {
            var classes = await classService.GetAllClassesAsync();
            return Ok(classes.Select(MapToDto));
        }

        /// <summary>Get a class by ID.</summary>
        /// <param name="id">Class ID.</param>
        /// <response code="200">Returns the matching class.</response>
        /// <response code="404">Class not found.</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(ClassDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ClassDto>> GetClassById(int id)
        {
            var @class = await classService.GetClassByIdAsync(id);
            if (@class == null) return NotFound();
            return Ok(MapToDto(@class));
        }

        /// <summary>Create a new class.</summary>
        /// <param name="dto">Class details including subject IDs to assign.</param>
        /// <response code="201">Class created successfully.</response>
        [HttpPost]
        [ProducesResponseType(typeof(ClassDto), StatusCodes.Status201Created)]
        public async Task<ActionResult<ClassDto>> CreateClass([FromBody] CreateClassDto dto)
        {
            var @class = new Class
            {
                Code = dto.Code,
                Name = dto.Name,
                Description = dto.Description,
                GradeLevel = dto.GradeLevel,
                ClassTeacherId = dto.ClassTeacherId,
                Status = dto.Status
            };
            var created = await classService.CreateClassAsync(@class, dto.SubjectIds);
            return CreatedAtAction(nameof(GetClassById), new { id = created.Id }, MapToDto(created));
        }

        /// <summary>Update an existing class.</summary>
        /// <param name="id">Class ID.</param>
        /// <param name="dto">Updated class details including subject IDs.</param>
        /// <response code="200">Class updated successfully.</response>
        /// <response code="404">Class not found.</response>
        [HttpPut("{id}")]
        [ProducesResponseType(typeof(ClassDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ClassDto>> UpdateClass(int id, [FromBody] UpdateClassDto dto)
        {
            var @class = new Class
            {
                Code = dto.Code,
                Name = dto.Name,
                Description = dto.Description,
                GradeLevel = dto.GradeLevel,
                ClassTeacherId = dto.ClassTeacherId,
                Status = dto.Status
            };
            var updated = await classService.UpdateClassAsync(id, @class, dto.SubjectIds);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        /// <summary>Delete a class.</summary>
        /// <param name="id">Class ID.</param>
        /// <response code="204">Class deleted successfully.</response>
        /// <response code="404">Class not found.</response>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteClass(int id)
        {
            var success = await classService.DeleteClassAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }

        private static ClassDto MapToDto(Class c) => new()
        {
            Id = c.Id,
            Code = c.Code,
            Name = c.Name,
            Description = c.Description,
            GradeLevel = c.GradeLevel,
            ClassTeacherId = c.ClassTeacherId,
            ClassTeacherName = c.ClassTeacher?.Name,
            Status = c.Status,
            CreateDate = c.CreateDate,
            Subjects = [.. c.ClassSubjects.Select(cs => new SubjectDto
            {
                Id = cs.Subject.Id,
                Code = cs.Subject.Code,
                Name = cs.Subject.Name,
                Description = cs.Subject.Description,
                Status = cs.Subject.Status
            })]
        };
    }
}
