# Makefile for SchoolMS project

.PHONY: build run migrate test clean docker-build docker-run

# Build the .NET solution
build:
	dotnet build backend/SchoolMS.sln

# Run the API
run:
	dotnet run --project backend/SchoolMS.API/SchoolMS.API.csproj

# Run database migrations
migrate:
	dotnet ef database update --project backend/SchoolMS.Infrastructure --startup-project backend/SchoolMS.API

# Run tests
test:
	dotnet test backend/SchoolMS.Tests/SchoolMS.Tests.csproj

# Clean build artifacts
clean:
	dotnet clean backend/SchoolMS.sln
	rm -rf backend/SchoolMS.API/bin backend/SchoolMS.API/obj
	rm -rf backend/SchoolMS.Core/bin backend/SchoolMS.Core/obj
	rm -rf backend/SchoolMS.Infrastructure/bin backend/SchoolMS.Infrastructure/obj
	rm -rf backend/SchoolMS.Tests/bin backend/SchoolMS.Tests/obj

# Docker commands
docker-build:
	docker-compose build

docker-run:
	docker-compose up

# Flutter commands (if Flutter is installed)
flutter-build:
	cd frontend && flutter build apk

flutter-run:
	cd frontend && flutter run