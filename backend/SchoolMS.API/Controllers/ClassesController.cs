using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

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
        public async Task<ActionResult<List<ClassDto>>> GetAllClasses()
        {
            var classes = await _classService.GetAllClassesAsync();
            return Ok(classes.Select(MapToDto));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ClassDto>> GetClassById(int id)
        {
            var @class = await _classService.GetClassByIdAsync(id);
            if (@class == null) return NotFound();
            return Ok(MapToDto(@class));
        }

        [HttpPost]
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
            var created = await _classService.CreateClassAsync(@class, dto.SubjectIds);
            return CreatedAtAction(nameof(GetClassById), new { id = created.Id }, MapToDto(created));
        }

        [HttpPut("{id}")]
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
            var updated = await _classService.UpdateClassAsync(id, @class, dto.SubjectIds);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteClass(int id)
        {
            var success = await _classService.DeleteClassAsync(id);
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
            Subjects = c.ClassSubjects
                .Select(cs => new SubjectDto
                {
                    Id = cs.Subject.Id,
                    Code = cs.Subject.Code,
                    Name = cs.Subject.Name,
                    Description = cs.Subject.Description,
                    Status = cs.Subject.Status
                }).ToList()
        };
    }
}
