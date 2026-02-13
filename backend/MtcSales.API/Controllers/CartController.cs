using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MtcSales.API.Data;
using MtcSales.API.DTOs;
using MtcSales.API.Models;

namespace MtcSales.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CartController : ControllerBase
{
    private readonly MtcContext _context;

    public CartController(MtcContext context)
    {
        _context = context;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CartDto>> GetCart(Guid id)
    {
        var cart = await _context.Carts
            .Include(c => c.Items)
            .ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (cart == null) return NotFound();

        return MapToDto(cart);
    }

    [HttpPost]
    public async Task<ActionResult<CartDto>> CreateCart()
    {
        var cart = new Cart { Id = Guid.NewGuid() };
        _context.Carts.Add(cart);
        await _context.SaveChangesAsync();
        return Ok(MapToDto(cart));
    }

    [HttpPost("{id}/items")]
    public async Task<ActionResult<CartDto>> AddItem(Guid id, AddToCartRequest request)
    {
        var cart = await _context.Carts.Include(c => c.Items).FirstOrDefaultAsync(c => c.Id == id);
        if (cart == null) return NotFound("Cart not found");

        var existingItem = cart.Items.FirstOrDefault(i => i.ProductId == request.ProductId);
        if (existingItem != null)
        {
            existingItem.Quantity += request.Quantity;
        }
        else
        {
            cart.Items.Add(new CartItem
            {
                Id = Guid.NewGuid(),
                CartId = id,
                ProductId = request.ProductId,
                Quantity = request.Quantity
            });
        }

        await _context.SaveChangesAsync();
        
        // Reload to get product details
        var updatedCart = await _context.Carts
            .Include(c => c.Items)
            .ThenInclude(i => i.Product)
            .FirstAsync(c => c.Id == id);

        return Ok(MapToDto(updatedCart));
    }

    private CartDto MapToDto(Cart cart)
    {
        var items = cart.Items.Select(i => new CartItemDto(
            i.ProductId,
            i.Product?.Name ?? "Unknown",
            i.Product?.Code ?? "",
            i.Product?.SuggestedPrice ?? 0,
            i.Quantity,
            i.Product?.ImageUrl ?? ""
        )).ToList();

        var total = items.Sum(i => i.Price * i.Quantity);
        return new CartDto(cart.Id, items, total);
    }
}
