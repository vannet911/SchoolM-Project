# Use the official Flutter image
FROM instrumentisto/flutter:latest

# Set the working directory
WORKDIR /app

# Copy the pubspec files
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the code
COPY . .

# Build the app
RUN flutter build web

# Use nginx to serve the built app
FROM nginx:alpine
COPY --from=0 /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]