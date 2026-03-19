# SchoolMS

SchoolMS is a full-stack school management system consisting of a Flutter frontend and a .NET Core backend API. The system manages school-related data including students, teachers, users, roles, classes, and subjects.

## Architecture

The project follows Clean Architecture principles with a layered backend structure:

- **SchoolMS.API**: Presentation layer with ASP.NET Core Web API
- **SchoolMS.Core**: Domain layer containing entities, interfaces, and business logic
- **SchoolMS.Infrastructure**: Data access layer with EF Core and repositories
- **SchoolMS.Tests**: Unit and integration tests

The frontend is built with Flutter for cross-platform mobile/desktop applications.

## Project Structure

```
SchoolMS/
├── frontend/                        # Flutter app
│   ├── lib/
│   │   ├── models/                  # Data models
│   │   ├── services/                # API service calls
│   │   ├── screens/                 # UI screens
│   │   ├── widgets/                 # Reusable components
│   │   ├── providers/               # State management
│   │   ├── utils/                   # Helpers and constants
│   │   └── main.dart
│   ├── assets/                      # Images and fonts
│   ├── test/                        # Flutter tests
│   ├── pubspec.yaml
│   └── Dockerfile
│
├── backend/                         # .NET Core solution
│   ├── SchoolMS.API/                # Presentation layer
│   │   ├── Controllers/
│   │   ├── Middlewares/
│   │   ├── DTOs/
│   │   ├── Extensions/
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   └── Dockerfile
│   ├── SchoolMS.Core/               # Domain layer
│   │   ├── Entities/
│   │   ├── Interfaces/
│   │   ├── Enums/
│   │   └── Exceptions/
│   ├── SchoolMS.Infrastructure/     # Data layer
│   │   ├── Data/                    # DbContext
│   │   ├── Repositories/
│   │   ├── Services/
│   │   └── Migrations/
│   ├── SchoolMS.Tests/              # Test projects
│   │   ├── UnitTests/
│   │   └── IntegrationTests/
│   └── SchoolMS.sln
│
├── .github/workflows/               # CI/CD pipelines
├── docs/                           # Documentation
├── scripts/sql/                    # Database scripts
├── docker-compose.yml              # Container orchestration
├── .env                            # Environment variables
├── .gitignore
├── Makefile                        # Build shortcuts
└── README.md
```

## Prerequisites

- .NET 8 SDK
- Flutter SDK
- Docker & Docker Compose
- SQL Server (or use Docker container)

## Setup

1. Clone the repository
2. Copy `.env` and configure your environment variables
3. Run `make build` to build the .NET solution
4. Run `make migrate` to apply database migrations
5. Run `make run` to start the API
6. For frontend: `cd frontend && flutter pub get && flutter run`

## Docker

Use Docker Compose for full environment:

```bash
docker-compose up --build
```

## API Documentation

Swagger UI available at `http://localhost:5000/swagger` when running the API.

## Contributing

1. Create a feature branch
2. Make changes
3. Run tests: `make test`
4. Submit a pull request

## License

[Your License Here]
├── 📁 Migrations/
│   ├── 20251127075840_InitialCreate.cs
│   ├── 20251127075840_InitialCreate.Designer.cs
│   ├── 20251127075904_RecreateStudentAndTeacherTables.cs
│   ├── 20251127075904_RecreateStudentAndTeacherTables.Designer.cs
│   ├── 20251127110107_AddUserAndRole.cs
│   ├── 20251127110107_AddUserAndRole.Designer.cs
│   ├── 20251127110954_AddUserAndRoleServices.cs
│   ├── 20251127110954_AddUserAndRoleServices.Designer.cs
│   ├── AddClassAndSubjectModels.cs
│   ├── AddClassAndSubjectModels.Designer.cs
│   └── SchoolDbContextModelSnapshot.cs
├── 📁 models/
│   ├── Class.cs
│   ├── Role.cs
│   ├── Student.cs
│   ├── Subject.cs
│   ├── Teacher.cs
│   └── User.cs
├── 📁 obj/
│   ├── 📁 Debug/
│   │   └── net8.0/
│   └── project.assets.json
├── 📁 Properties/
│   └── launchSettings.json
├── 📁 repositories/
├── 📁 services/
│   ├── ClassService.cs
│   ├── RoleService.cs
│   ├── StudentService.cs
│   ├── SubjectService.cs
│   ├── TeacherService.cs
│   └── UserService.cs
├── 📁 assets/
├── 📁 bin/
│   └── 📁 Debug/
│       └── net8.0/
├── appsettings.Development.json
├── appsettings.json
├── Program.cs
├── README.md
├── SchoolMAPI.csproj
├── SchoolMAPI.http
└── SchoolMAPI.sln
```

### Root Files
- **appsettings.json** & **appsettings.Development.json**: Configuration files for application settings, including database connections and environment-specific configurations.
- **Program.cs**: The entry point of the application, responsible for configuring the web host and services.
- **SchoolMAPI.csproj**: The project file defining dependencies, target framework (.NET 8), and build settings.
- **SchoolMAPI.http**: HTTP request files for testing API endpoints.
- **SchoolMAPI.sln**: The solution file for the Visual Studio project.

### Folders

#### controllers/
Contains API controllers that handle HTTP requests and responses.
- **ClassesController.cs**: Manages class-related operations.
- **RolesController.cs**: Manages role-related operations.
- **StudentsController.cs**: Handles student data operations.
- **SubjectsController.cs**: Manages subject-related operations.
- **TeachersController.cs**: Manages teacher data operations.
- **UsersController.cs**: Handles user authentication and management.

#### data/
Contains the Entity Framework database context.
- **SchoolDbContext.cs**: Defines the database context, including DbSets for entities and configurations.

#### DTOs/
Data Transfer Objects for transferring data between layers.
- (Specific DTO files would be listed here if present.)

#### mappings/
Contains mapping configurations, likely using AutoMapper or similar libraries to map between models and DTOs.

#### middlewares/
Custom middleware components for request processing, such as authentication, logging, or error handling.

#### Migrations/
Entity Framework Core migration files for database schema changes.
- **20251127075840_InitialCreate.cs** & **Designer.cs**: Initial database creation migration.
- **20251127075904_RecreateStudentAndTeacherTables.cs** & **Designer.cs**: Migration to recreate student and teacher tables.
- **20251127110107_AddUserAndRole.cs** & **Designer.cs**: Migration to add user and role entities.
- **20251127110954_AddUserAndRoleServices.cs** & **Designer.cs**: Migration for user and role services.
- **AddClassAndSubjectModels.cs** & **Designer.cs**: Migration to add class and subject entities.
- **SchoolDbContextModelSnapshot.cs**: Snapshot of the current database model.

#### models/
Entity models representing database tables.
- **Class.cs**: Represents class/group information.
- **Role.cs**: Represents user roles.
- **Student.cs**: Represents student information.
- **Subject.cs**: Represents academic subjects.
- **Teacher.cs**: Represents teacher information.
- **User.cs**: Represents user accounts.

#### Properties/
- **launchSettings.json**: Configuration for launching the application in development.

#### repositories/
Data access layer implementations, providing methods to interact with the database.

#### services/
Business logic layer containing service classes.
- **ClassService.cs**: Business logic for class operations.
- **RoleService.cs**: Business logic for role management.
- **StudentService.cs**: Business logic for student operations.
- **SubjectService.cs**: Business logic for subject operations.
- **TeacherService.cs**: Business logic for teacher operations.
- **UserService.cs**: Business logic for user management.

#### assets/
Static assets like images, stylesheets, or other resources.

#### bin/ & obj/
Build output and intermediate files generated during compilation. These are typically excluded from version control.

## Getting Started

1. Ensure you have .NET 8 SDK installed.
2. Restore dependencies: `dotnet restore`
3. Update the database: `dotnet ef database update`
4. Run the application: `dotnet run`

## API Endpoints

The API provides endpoints for managing school data. Refer to the controllers for specific routes and the SchoolMAPI.http file for example requests.

### Classes
- `GET /api/classes` - Retrieve all classes
- `GET /api/classes/{id}` - Retrieve a specific class by ID
- `POST /api/classes` - Create a new class
- `PUT /api/classes/{id}` - Update an existing class
- `DELETE /api/classes/{id}` - Delete a class

### Roles
- `GET /api/roles` - Retrieve all roles
- `GET /api/roles/{id}` - Retrieve a specific role by ID
- `POST /api/roles` - Create a new role
- `PUT /api/roles/{id}` - Update an existing role
- `DELETE /api/roles/{id}` - Delete a role

### Students
- `GET /api/students` - Retrieve all students
- `GET /api/students/{id}` - Retrieve a specific student by ID
- `POST /api/students` - Create a new student
- `PUT /api/students/{id}` - Update an existing student
- `DELETE /api/students/{id}` - Delete a student

### Subjects
- `GET /api/subjects` - Retrieve all subjects
- `GET /api/subjects/{id}` - Retrieve a specific subject by ID
- `POST /api/subjects` - Create a new subject
- `PUT /api/subjects/{id}` - Update an existing subject
- `DELETE /api/subjects/{id}` - Delete a subject

### Teachers
- `GET /api/teachers` - Retrieve all teachers
- `GET /api/teachers/{id}` - Retrieve a specific teacher by ID
- `POST /api/teachers` - Create a new teacher
- `PUT /api/teachers/{id}` - Update an existing teacher
- `DELETE /api/teachers/{id}` - Delete a teacher

### Users
- `GET /api/users` - Retrieve all users
- `GET /api/users/{id}` - Retrieve a specific user by ID
- `POST /api/users` - Create a new user
- `PUT /api/users/{id}` - Update an existing user
- `DELETE /api/users/{id}` - Delete a user

## Technologies Used

- .NET 8
- Entity Framework Core
- ASP.NET Core Web API
- C#

## Contributing

Please follow standard coding practices and ensure all changes are tested before submission.