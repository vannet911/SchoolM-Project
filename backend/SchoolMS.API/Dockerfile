# Use the official .NET 8 SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy the solution and project files
COPY ["SchoolMS.sln", "."]
COPY ["SchoolMS.API/SchoolMS.API.csproj", "SchoolMS.API/"]
COPY ["SchoolMS.Core/SchoolMS.Core.csproj", "SchoolMS.Core/"]
COPY ["SchoolMS.Infrastructure/SchoolMS.Infrastructure.csproj", "SchoolMS.Infrastructure/"]

# Restore dependencies
RUN dotnet restore "SchoolMS.API/SchoolMS.API.csproj"

# Copy everything else
COPY . .

# Build the app
WORKDIR "/src/SchoolMS.API"
RUN dotnet build "SchoolMS.API.csproj" -c Release -o /app/build

# Publish the app
FROM build AS publish
RUN dotnet publish "SchoolMS.API.csproj" -c Release -o /app/publish

# Use the official .NET 8 runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Expose port 80
EXPOSE 80

# Run the app
ENTRYPOINT ["dotnet", "SchoolMS.API.dll"]