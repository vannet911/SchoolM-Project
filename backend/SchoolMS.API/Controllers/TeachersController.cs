using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

namespace SchoolMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TeachersController : ControllerBase
    {
        private readonly ITeacherService _service;

        public TeachersController(ITeacherService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TeacherDto>>> GetAll()
        {
            var teachers = await _service.GetAllAsync();
            return Ok(teachers.Select(MapToDto));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TeacherDto>> GetById(int id)
        {
            var teacher = await _service.GetByIdAsync(id);
            if (teacher == null) return NotFound();
            return Ok(MapToDto(teacher));
        }

        [HttpPost]
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
            var created = await _service.CreateAsync(teacher, dto.SubjectIds);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, MapToDto(created));
        }

        [HttpPut("{id}")]
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
            var updated = await _service.UpdateAsync(id, teacher, dto.SubjectIds);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var success = await _service.DeleteAsync(id);
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
            Subjects = t.TeacherSubjects
                .Select(ts => new SubjectDto
                {
                    Id = ts.Subject.Id,
                    Code = ts.Subject.Code,
                    Name = ts.Subject.Name,
                    Description = ts.Subject.Description,
                    Status = ts.Subject.Status
                }).ToList()
        };
    }
}
