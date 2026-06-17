using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

namespace SchoolMS.API.Controllers
{
    [ApiController]
    [Route("api/timetable")]
    [Produces("application/json")]
    public class TimetableController(ITimetableService timetableService) : ControllerBase
    {
        [HttpGet]
        public async Task<ActionResult<List<TimetableDto>>> GetAll()
        {
            var entries = await timetableService.GetAllAsync();
            return Ok(entries.Select(MapToDto));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TimetableDto>> GetById(int id)
        {
            var entry = await timetableService.GetByIdAsync(id);
            if (entry == null) return NotFound();
            return Ok(MapToDto(entry));
        }

        [HttpPost]
        public async Task<ActionResult<TimetableDto>> Create([FromBody] CreateTimetableDto dto)
        {
            var entry = new Timetable
            {
                Day = dto.Day,
                Period = dto.Period,
                ClassId = dto.ClassId,
                SubjectId = dto.SubjectId,
                TeacherId = dto.TeacherId,
                Room = dto.Room,
                AcademicYear = dto.AcademicYear,
            };
            var created = await timetableService.CreateAsync(entry);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, MapToDto(created));
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<TimetableDto>> Update(int id, [FromBody] UpdateTimetableDto dto)
        {
            var entry = new Timetable
            {
                Day = dto.Day,
                Period = dto.Period,
                ClassId = dto.ClassId,
                SubjectId = dto.SubjectId,
                TeacherId = dto.TeacherId,
                Room = dto.Room,
                AcademicYear = dto.AcademicYear,
            };
            var updated = await timetableService.UpdateAsync(id, entry);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var success = await timetableService.DeleteAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }

        private static TimetableDto MapToDto(Timetable t) => new()
        {
            Id = t.Id,
            Day = t.Day,
            Period = t.Period,
            ClassId = t.ClassId,
            ClassName = t.Class?.Name,
            SubjectId = t.SubjectId,
            SubjectName = t.Subject?.Name,
            SubjectCode = t.Subject?.Code,
            TeacherId = t.TeacherId,
            TeacherName = t.Teacher?.Name,
            Room = t.Room,
            AcademicYear = t.AcademicYear,
        };
    }
}
