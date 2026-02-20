using Microsoft.EntityFrameworkCore;
using MtcSales.API.Data;

var builder = WebApplication.CreateBuilder(args);

// Render sets the PORT environment variable.
// If running on Render, we need to bind to http://0.0.0.0:PORT
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
builder.WebHost.UseUrls($"http://*:{port}");

// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<MtcContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy =>
        {
            policy.SetIsOriginAllowed(origin => true) // Allow any origin
                   .AllowAnyMethod()
                   .AllowAnyHeader()
                   .AllowCredentials(); // Allow credentials (cookies, auth headers)
        });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseCors("AllowAll"); // CORS must be first

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

// Health check endpoint
app.MapGet("/", () => new { status = "online", version = "1.0.1", message = "MTC Sales API is running" });


// Run schema update on startup (for MVP deployment)
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<MtcContext>();
    try
    {
        // For simple deployment, read SQL file and execute
        // In production, use EF Migrations properly: context.Database.Migrate();
        // But since we are "remote controlling", let's execute our idempotent script
        var sqlPath = Path.Combine(AppContext.BaseDirectory, "schema_v5.sql");
        if (File.Exists(sqlPath))
        {
            var sql = File.ReadAllText(sqlPath);
            context.Database.ExecuteSqlRaw(sql);
            Console.WriteLine("Schema updated successfully from schema_v5.sql");
        }
        else
        {
            Console.WriteLine($"Schema file not found at {sqlPath}");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error updating schema: {ex.Message}");
    }
}

app.Run();
