using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

namespace SchoolMS.API.Controllers
{
    /// <summary>Manage teacher records.</summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class TeachersController(ITeacherService service) : ControllerBase
    {
        /// <summary>Get all teachers.</summary>
        /// <response code="200">Returns the list of all teachers with their assigned subjects.</response>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<TeacherDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<TeacherDto>>> GetAll()
        {
            var teachers = await service.GetAllAsync();
            return Ok(teachers.Select(MapToDto));
        }

        /// <summary>Get a teacher by ID.</summary>
        /// <param name="id">Teacher ID.</param>
        /// <response code="200">Returns the matching teacher.</response>
        /// <response code="404">Teacher not found.</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(TeacherDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<TeacherDto>> GetById(int id)
        {
            var teacher = await service.GetByIdAsync(id);
            if (teacher == null) return NotFound();
            return Ok(MapToDto(teacher));
        }

        /// <summary>Create a new teacher.</summary>
        /// <param name="dto">Teacher details including subject IDs to assign.</param>
        /// <response code="201">Teacher created successfully.</response>
        [HttpPost]
        [ProducesResponseType(typeof(TeacherDto), StatusCodes.Status201Created)]
        public async Task<ActionResult<TeacherDto>> Create([FromBody] CreateTeacherDto dto)
        {
            var teacher = new Teacher
            {
                Code = dto.Code,
                Name = dto.Name,
                Gender = dto.Gender,
                DateOfBirth = dto.DateOfBirth,
                Email = dto.Email ?? string.Empty,
                PhoneNumber = dto.PhoneNumber ?? string.Empty,
                Address = dto.Address ?? string.Empty,
                Status = dto.Status
            };
            var created = await service.CreateAsync(teacher, dto.SubjectIds);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, MapToDto(created));
        }

        /// <summary>Update an existing teacher.</summary>
        /// <param name="id">Teacher ID.</param>
        /// <param name="dto">Updated teacher details including subject IDs.</param>
        /// <response code="200">Teacher updated successfully.</response>
        /// <response code="404">Teacher not found.</response>
        [HttpPut("{id}")]
        [ProducesResponseType(typeof(TeacherDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<TeacherDto>> Update(int id, [FromBody] UpdateTeacherDto dto)
        {
            var teacher = new Teacher
            {
                Code = dto.Code,
                Name = dto.Name,
                Gender = dto.Gender,
                DateOfBirth = dto.DateOfBirth,
                Email = dto.Email ?? string.Empty,
                PhoneNumber = dto.PhoneNumber ?? string.Empty,
                Address = dto.Address ?? string.Empty,
                Status = dto.Status
            };
            var updated = await service.UpdateAsync(id, teacher, dto.SubjectIds);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        /// <summary>Delete a teacher.</summary>
        /// <param name="id">Teacher ID.</param>
        /// <response code="204">Teacher deleted successfully.</response>
        /// <response code="404">Teacher not found.</response>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Delete(int id)
        {
            var success = await service.DeleteAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }

        private static TeacherDto MapToDto(Teacher t) => new()
        {
            Id = t.Id,
            Code = t.Code,
            Name = t.Name,
            Gender = t.Gender,
            DateOfBirth = t.DateOfBirth,
            Email = t.Email,
            PhoneNumber = t.PhoneNumber,
            Address = t.Address,
            Status = t.Status,
            CreateDate = t.CreateDate,
            Subjects = [.. t.TeacherSubjects.Select(ts => new SubjectDto
                {
                    Id = ts.Subject.Id,
                    Code = ts.Subject.Code,
                    Name = ts.Subject.Name,
                    Description = ts.Subject.Description,
                    Status = ts.Subject.Status
                })]
        };
    }
}
