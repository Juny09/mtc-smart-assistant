using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MtcSales.API.Data;
using MtcSales.API.DTOs;
using MtcSales.API.Models;

using MtcSales.API.Services;

namespace MtcSales.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductController : ControllerBase
{
    private readonly MtcContext _context;
    private readonly PriceCodeService _priceCodeService;

    public ProductController(MtcContext context)
    {
        _context = context;
        _priceCodeService = new PriceCodeService();
    }

    [HttpPost("{id}/images")]
    public async Task<ActionResult<string>> UploadImage(Guid id, IFormFile file)
    {
        var product = await _context.Products.FindAsync(id);
        if (product == null) return NotFound("Product not found");

        if (file == null || file.Length == 0)
            return BadRequest("No file uploaded");

        // Ensure directory exists
        var uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "products", id.ToString());
        if (!Directory.Exists(uploadPath))
            Directory.CreateDirectory(uploadPath);

        // Generate unique filename
        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(uploadPath, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // URL to access the file
        // Assuming base URL is configured correctly or relative path
        var relativeUrl = $"/uploads/products/{id}/{fileName}";

        // Save to DB
        var productImage = new ProductImage
        {
            Id = Guid.NewGuid(),
            ProductId = id,
            ImageUrl = relativeUrl,
            CreatedAt = DateTime.UtcNow
        };
        _context.ProductImages.Add(productImage);
        
        // If product has no main image, set this as main
        if (string.IsNullOrEmpty(product.ImageUrl))
        {
            product.ImageUrl = relativeUrl;
        }

        await _context.SaveChangesAsync();

        return Ok(new { url = relativeUrl });
    }

    [HttpGet("price-code/encode")]
    public ActionResult<string> EncodePrice([FromQuery] decimal price)
    {
        return Ok(new { code = _priceCodeService.Encode(price) });
    }

    [HttpGet("price-code/decode")]
    public ActionResult<decimal?> DecodePrice([FromQuery] string code)
    {
        var price = _priceCodeService.Decode(code);
        if (price == null) return BadRequest("Invalid code");
        return Ok(new { price = price });
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
            CostCode = request.CostCode,
            ImageUrl = request.ImageUrl,
            CategoryId = request.CategoryId
        };

        // Auto-generate CostCode if missing
        if (string.IsNullOrEmpty(product.CostCode) && product.CostPrice.HasValue)
        {
            product.CostCode = _priceCodeService.Encode(product.CostPrice.Value);
        }
        // Auto-decode CostPrice if missing
        else if (!product.CostPrice.HasValue && !string.IsNullOrEmpty(product.CostCode))
        {
            product.CostPrice = _priceCodeService.Decode(product.CostCode);
        }

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
