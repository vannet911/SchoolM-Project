using Microsoft.AspNetCore.Mvc;
using SchoolMS.Core.Entities;
using SchoolMS.Core.Interfaces;
using SchoolMS.Infrastructure.Services;

namespace SchoolMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SubjectsController : ControllerBase
    {
        private readonly ISubjectService _subjectService;

        public SubjectsController(ISubjectService subjectService)
        {
            _subjectService = subjectService;
        }

        [HttpGet]
        public async Task<ActionResult<List<Subject>>> GetAllSubjects()
        {
            var subjects = await _subjectService.GetAllSubjectsAsync();
            return Ok(subjects);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Subject>> GetSubjectById(int id)
        {
            var subject = await _subjectService.GetSubjectByIdAsync(id);
            if (subject == null)
                return NotFound();
            return Ok(subject);
        }

        [HttpPost]
        public async Task<ActionResult<Subject>> CreateSubject([FromBody] Subject subject)
        {
            var createdSubject = await _subjectService.CreateSubjectAsync(subject);
            return CreatedAtAction(nameof(GetSubjectById), new { id = createdSubject.Id }, createdSubject);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<Subject>> UpdateSubject(int id, [FromBody] Subject subject)
        {
            var updatedSubject = await _subjectService.UpdateSubjectAsync(id, subject);
            if (updatedSubject == null)
                return NotFound();
            return Ok(updatedSubject);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSubject(int id)
        {
            var success = await _subjectService.DeleteSubjectAsync(id);
            if (!success)
                return NotFound();
            return NoContent();
        }
    }
}