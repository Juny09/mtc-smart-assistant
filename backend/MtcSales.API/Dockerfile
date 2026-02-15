# Use the official .NET SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY ["MtcSales.API.csproj", "./"]
RUN dotnet restore "MtcSales.API.csproj"

# Copy everything else and build
COPY . .
RUN dotnet publish "MtcSales.API.csproj" -c Release -o /app/publish

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .

# Create directory for uploads
RUN mkdir -p /app/wwwroot/uploads

# Expose port 8080 (default for .NET 8)
EXPOSE 8080

# Set environment variable to ensure binding to 0.0.0.0
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "MtcSales.API.dll"]
