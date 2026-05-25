using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

namespace SchoolMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StudentsController : ControllerBase
    {
        private readonly IStudentService _studentService;

        public StudentsController(IStudentService studentService)
        {
            _studentService = studentService;
        }

        [HttpGet]
        public async Task<ActionResult<List<StudentDto>>> GetAllStudents()
        {
            var students = await _studentService.GetAllStudentsAsync();
            return Ok(students.Select(MapToDto));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StudentDto>> GetStudentById(int id)
        {
            var student = await _studentService.GetStudentByIdAsync(id);
            if (student == null) return NotFound();
            return Ok(MapToDto(student));
        }

        [HttpPost]
        public async Task<ActionResult<StudentDto>> CreateStudent([FromBody] CreateStudentDto createDto)
        {
            var student = new Student
            {
                Code = createDto.Code,
                FirstName = createDto.FirstName,
                LastName = createDto.LastName,
                Gender = createDto.Gender,
                DateOfBirth = createDto.DateOfBirth,
                Email = createDto.Email,
                PhoneNumber = createDto.PhoneNumber,
                Address = createDto.Address,
                ClassId = createDto.ClassId,
                Status = createDto.Status ?? true,
                CreateDate = DateTime.UtcNow
            };
            var created = await _studentService.CreateStudentAsync(student);
            return CreatedAtAction(nameof(GetStudentById), new { id = created.Id }, MapToDto(created));
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<StudentDto>> UpdateStudent(int id, [FromBody] UpdateStudentDto updateDto)
        {
            var student = new Student
            {
                Id = id,
                Code = updateDto.Code,
                FirstName = updateDto.FirstName,
                LastName = updateDto.LastName,
                Gender = updateDto.Gender,
                DateOfBirth = updateDto.DateOfBirth,
                Email = updateDto.Email,
                PhoneNumber = updateDto.PhoneNumber,
                Address = updateDto.Address,
                ClassId = updateDto.ClassId,
                Status = updateDto.Status
            };
            var updated = await _studentService.UpdateStudentAsync(id, student);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStudent(int id)
        {
            var success = await _studentService.DeleteStudentAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }

        private static StudentDto MapToDto(Student s) => new()
        {
            Id = s.Id,
            Code = s.Code,
            FirstName = s.FirstName,
            LastName = s.LastName,
            Gender = s.Gender,
            DateOfBirth = s.DateOfBirth,
            Email = s.Email,
            PhoneNumber = s.PhoneNumber,
            Address = s.Address,
            ClassId = s.ClassId,
            ClassName = s.Class?.Name,
            CreateDate = s.CreateDate,
            Status = s.Status ?? true
        };
    }
}
