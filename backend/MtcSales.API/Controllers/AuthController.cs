using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MtcSales.API.Data;
using MtcSales.API.DTOs;

namespace MtcSales.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly MtcContext _context;

    public AuthController(MtcContext context)
    {
        _context = context;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Username == request.Username);

        if (user == null)
        {
            return Unauthorized("Invalid username or password");
        }

        bool isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        
        if (!isPasswordValid)
        {
            return Unauthorized("Invalid username or password");
        }

        // TODO: Generate real JWT Token
        var token = "fake-jwt-token-for-mvp-" + Guid.NewGuid();

        return Ok(new LoginResponse(token, user.Role, user.FullName ?? user.Username));
    }

    // TODO: Remove this in production
    [HttpPost("seed")]
    public async Task<ActionResult> SeedUsers()
    {
        if (!await _context.Users.AnyAsync())
        {
            var admin = new MtcSales.API.Models.User
            {
                Id = Guid.NewGuid(),
                Username = "admin",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"),
                Role = "admin",
                FullName = "Administrator"
            };
            _context.Users.Add(admin);
            await _context.SaveChangesAsync();
            return Ok("Seeded admin user (password: admin123)");
        }
        return Ok("Users already exist");
    }

    [HttpGet("hash")]
    public ActionResult<string> HashPassword(string password)
    {
        return Ok(BCrypt.Net.BCrypt.HashPassword(password));
    }
}
