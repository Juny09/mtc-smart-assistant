using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MtcSales.API.Data;
using MtcSales.API.DTOs;
using MtcSales.API.Models;

namespace MtcSales.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductController : ControllerBase
{
    private readonly MtcContext _context;

    public ProductController(MtcContext context)
    {
        _context = context;
    }

    [HttpPost]
    public async Task<ActionResult<ProductDto>> CreateProduct(CreateProductRequest request)
    {
        // 1. Check if Code Exists
        if (await _context.Products.AnyAsync(p => p.Code == request.Code))
        {
            return Conflict("Product code already exists");
        }

        // 2. Map DTO to Entity
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Code = request.Code,
            Name = request.Name,
            Description = request.Description,
            SuggestedPrice = request.SuggestedPrice,
            CostPrice = request.CostPrice,
            ImageUrl = request.ImageUrl,
            CategoryId = request.CategoryId
        };

        _context.Products.Add(product);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetProduct), new { code = product.Code }, new ProductDto(
            product.Code,
            product.Name,
            product.Description ?? "",
            product.SuggestedPrice,
            product.ImageUrl ?? ""
        ));
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetProducts([FromQuery] string? keyword)
    {
        var query = _context.Products.AsQueryable();

        if (!string.IsNullOrWhiteSpace(keyword))
        {
            query = query.Where(p => 
                p.Name.Contains(keyword) || 
                p.Code.Contains(keyword) || 
                (p.Description != null && p.Description.Contains(keyword)));
        }

        var products = await query
            .Select(p => new ProductDto(
                p.Code,
                p.Name,
                p.Description ?? "",
                p.SuggestedPrice,
                p.ImageUrl ?? ""
            ))
            .ToListAsync();

        return Ok(products);
    }

    [HttpGet("{code}")]
    public async Task<ActionResult<ProductDto>> GetProduct(string code)
    {
        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Code == code);

        if (product == null)
        {
            return NotFound();
        }

        return Ok(new ProductDto(
            product.Code,
            product.Name,
            product.Description ?? "",
            product.SuggestedPrice,
            product.ImageUrl ?? ""
        ));
    }

    [HttpPost("{code}/reveal-cost")]
    public async Task<ActionResult<decimal>> RevealCost(string code)
    {
        // 1. Validate Token (In real app, use [Authorize] attribute)
        if (!Request.Headers.ContainsKey("Authorization"))
        {
            return Unauthorized("Missing token");
        }

        // 2. Find Product
        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Code == code);

        if (product == null)
        {
            return NotFound();
        }

        // 3. Log Audit (In MVP, we just log to console)
        Console.WriteLine($"[Audit] User accessed cost price for {code} at {DateTime.UtcNow}");

        // 4. Return Cost
        return Ok(product.CostPrice ?? 0);
    }
}
