namespace MtcSales.API.DTOs;

public record LoginRequest(string Username, string Password);
public record LoginResponse(string Token, string Role, string FullName);
// ProductDto is now in ProductDtos.cs
