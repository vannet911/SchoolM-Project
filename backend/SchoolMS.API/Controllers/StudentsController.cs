using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.Infrastructure.Services;
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
            var dtos = students.Select(s => MapToDto(s)).ToList();
            return Ok(dtos);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StudentDto>> GetStudentById(int id)
        {
            var student = await _studentService.GetStudentByIdAsync(id);
            if (student == null)
                return NotFound();
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
                Status = createDto.Status ?? true,
                CreateDate = DateTime.UtcNow
            };
            
            var createdStudent = await _studentService.CreateStudentAsync(student);
            return CreatedAtAction(nameof(GetStudentById), new { id = createdStudent.Id }, MapToDto(createdStudent));
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
                Status = updateDto.Status
            };
            
            var updatedStudent = await _studentService.UpdateStudentAsync(id, student);
            if (updatedStudent == null)
                return NotFound();
            return Ok(MapToDto(updatedStudent));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStudent(int id)
        {
            var success = await _studentService.DeleteStudentAsync(id);
            if (!success)
                return NotFound();
            return NoContent();
        }

        private StudentDto MapToDto(Student student)
        {
            return new StudentDto
            {
                Id = student.Id,
                Code = student.Code,
                FirstName = student.FirstName,
                LastName = student.LastName,
                Gender = student.Gender,
                DateOfBirth = student.DateOfBirth,
                Email = student.Email,
                PhoneNumber = student.PhoneNumber,
                Address = student.Address,
                CreateDate = student.CreateDate,
                Status = student.Status ?? true
            };
        }
    }
}