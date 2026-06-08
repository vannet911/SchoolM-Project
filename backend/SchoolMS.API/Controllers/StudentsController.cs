using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.API.DTOs;

namespace SchoolMS.API.Controllers
{
    /// <summary>Manage student records.</summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class StudentsController(IStudentService studentService, IWebHostEnvironment env) : ControllerBase
    {
        /// <summary>Get all students.</summary>
        /// <response code="200">Returns the list of all students.</response>
        [HttpGet]
        [ProducesResponseType(typeof(List<StudentDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<List<StudentDto>>> GetAllStudents()
        {
            var students = await studentService.GetAllStudentsAsync();
            return Ok(students.Select(MapToDto));
        }

        /// <summary>Get a student by ID.</summary>
        /// <param name="id">Student ID.</param>
        /// <response code="200">Returns the matching student.</response>
        /// <response code="404">Student not found.</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(StudentDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<StudentDto>> GetStudentById(int id)
        {
            var student = await studentService.GetStudentByIdAsync(id);
            if (student == null) return NotFound();
            return Ok(MapToDto(student));
        }

        /// <summary>Create a new student.</summary>
        /// <param name="createDto">Student details.</param>
        /// <response code="201">Student created successfully.</response>
        [HttpPost]
        [ProducesResponseType(typeof(StudentDto), StatusCodes.Status201Created)]
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
            var created = await studentService.CreateStudentAsync(student);
            return CreatedAtAction(nameof(GetStudentById), new { id = created.Id }, MapToDto(created));
        }

        /// <summary>Update an existing student.</summary>
        /// <param name="id">Student ID.</param>
        /// <param name="updateDto">Updated student details.</param>
        /// <response code="200">Student updated successfully.</response>
        /// <response code="404">Student not found.</response>
        [HttpPut("{id}")]
        [ProducesResponseType(typeof(StudentDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
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
            var updated = await studentService.UpdateStudentAsync(id, student);
            if (updated == null) return NotFound();
            return Ok(MapToDto(updated));
        }

        /// <summary>Delete a student.</summary>
        /// <param name="id">Student ID.</param>
        /// <response code="204">Student deleted successfully.</response>
        /// <response code="404">Student not found.</response>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteStudent(int id)
        {
            var success = await studentService.DeleteStudentAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }

        /// <summary>Upload a profile photo for a student.</summary>
        /// <param name="id">Student ID.</param>
        /// <param name="file">Image file (multipart/form-data).</param>
        /// <response code="200">Returns the new photo URL.</response>
        /// <response code="400">No file provided or invalid file type.</response>
        /// <response code="404">Student not found.</response>
        [HttpPost("{id}/photo")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UploadPhoto(int id, IFormFile? file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "No file provided" });

            var ext = Path.GetExtension(file.FileName).ToLower();
            var allowedExt = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            if (!allowedExt.Contains(ext))
                return BadRequest(new { message = "Invalid file type" });

            try
            {
                var webRoot = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
                var uploadsDir = Path.Combine(webRoot, "uploads", "students");
                Directory.CreateDirectory(uploadsDir);

                var filename = $"student_{id}_{Guid.NewGuid()}{ext}";
                var filePath = Path.Combine(uploadsDir, filename);

                using var stream = new FileStream(filePath, FileMode.Create);
                await file.CopyToAsync(stream);

                var photoUrl = $"{Request.Scheme}://{Request.Host}/uploads/students/{filename}";
                var student = await studentService.UpdatePhotoAsync(id, photoUrl);
                if (student == null) return NotFound();
                return Ok(new { photoUrl = student.PhotoUrl });
            }
            catch (Exception)
            {
                return StatusCode(500, new { message = "Upload failed" });
            }
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
            Status = s.Status ?? true,
            PhotoUrl = s.PhotoUrl
        };
    }
}
