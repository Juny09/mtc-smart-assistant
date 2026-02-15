# Use Cirrus Labs' Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy the app source code
COPY . .

# Get dependencies
RUN flutter pub get

# Build the web version
RUN flutter build web --release

# Use Nginx to serve the built files
FROM nginx:alpine

# Copy the build output to Nginx's html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
