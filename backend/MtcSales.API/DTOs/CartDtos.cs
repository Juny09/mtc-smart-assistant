using MtcSales.API.Models;

namespace MtcSales.API.DTOs;

public record AddToCartRequest(Guid ProductId, int Quantity);
public record CartItemDto(Guid ProductId, string ProductName, string ProductCode, decimal Price, int Quantity, string ImageUrl);
public record CartDto(Guid Id, List<CartItemDto> Items, decimal TotalAmount);
