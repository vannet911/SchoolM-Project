using SchoolMS.Core.Entities;

namespace SchoolMS.Core.Interfaces
{
    public interface ISubjectService
    {
        Task<List<Subject>> GetAllSubjectsAsync();
        Task<Subject?> GetSubjectByIdAsync(int id);
        Task<Subject> CreateSubjectAsync(Subject subject);
        Task<Subject?> UpdateSubjectAsync(int id, Subject subject);
        Task<bool> DeleteSubjectAsync(int id);
    }
}