using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

namespace SchoolMS.API.Controllers
{
    /// <summary>Manage attendance records.</summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class AttendanceController(IAttendanceService attendanceService) : ControllerBase
    {
        /// <summary>Get all attendance records.</summary>
        [HttpGet]
        [ProducesResponseType(typeof(List<AttendanceDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<List<AttendanceDto>>> GetAll()
        {
            var records = await attendanceService.GetAllAsync();
            return Ok(records.Select(MapToDto));
        }

        /// <summary>Get attendance record by ID.</summary>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(AttendanceDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<AttendanceDto>> GetById(int id)
        {
            var record = await attendanceService.GetByIdAsync(id);
            if (record == null) return NotFound();
            return Ok(MapToDto(record));
        }

        /// <summary>Create a new attendance record.</summary>
        [HttpPost]
        [ProducesResponseType(typeof(AttendanceDto), StatusCodes.Status201Created)]
        public async Task<ActionResult<AttendanceDto>> Create([FromBody] CreateAttendanceDto dto)
        {
            var attendance = new Attendance
            {
                Date = dto.Date,
                StudentId = dto.StudentId,
                ClassId = dto.ClassId,
                SubjectId = dto.SubjectId,
                TeacherId = dto.TeacherId,
                Period = dto.Period,
                Code = dto.Code,
                Status = dto.Status,
                Notes = dto.Notes
            };
            var created = await attendanceService.CreateAsync(attendance);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, MapToDto(created));
        }

        /// <summary>Update an attendance record.</summary>
        [HttpPut("{id}")]
        [ProducesResponseType(typeof(AttendanceDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<AttendanceDto>> Update(int id, [FromBody] UpdateAttendanceDto dto)
        {
            var attendance = new Attendance
            {
                Date = dto.Date,
                StudentId = dto.StudentId,
                ClassId = dto.ClassId,
                SubjectId = dto.SubjectId,
                TeacherId = dto.TeacherId,
                Period = dto.Period,
                Code = dto.Code,
                Status = dto.Status,
                Notes = dto.Notes
            };
            var updated = await attendanceService.UpdateAsync(id, attendance);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        /// <summary>Delete an attendance record.</summary>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Delete(int id)
        {
            var success = await attendanceService.DeleteAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }

        private static AttendanceDto MapToDto(Attendance a) => new()
        {
            Id = a.Id,
            Date = a.Date,
            StudentId = a.StudentId,
            StudentCode = a.Student?.Code,
            StudentName = a.Student != null
                ? $"{a.Student.FirstName} {a.Student.LastName}".Trim()
                : null,
            ClassId = a.ClassId,
            ClassName = a.Class?.Name,
            SubjectId = a.SubjectId,
            SubjectName = a.Subject?.Name,
            TeacherId = a.TeacherId,
            TeacherName = a.Teacher?.Name,
            Period = a.Period,
            Code = a.Code,
            Status = a.Status,
            Notes = a.Notes
        };
    }
}
