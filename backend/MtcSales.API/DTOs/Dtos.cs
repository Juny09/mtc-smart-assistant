namespace MtcSales.API.DTOs;

public record LoginRequest(string Username, string Password);
public record LoginResponse(string Token, string Role, string FullName);
public record ProductDto(string Code, string Name, string Description, decimal SuggestedPrice, string ImageUrl);
