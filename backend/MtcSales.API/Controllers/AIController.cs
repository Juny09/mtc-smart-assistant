using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MtcSales.API.Data;
using MtcSales.API.DTOs;

namespace MtcSales.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AIController : ControllerBase
{
    private readonly MtcContext _context;

    public AIController(MtcContext context)
    {
        _context = context;
    }

    [HttpPost("identify")]
    public async Task<ActionResult<IdentifyProductResponse>> Identify(IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest("No image uploaded");
        }

        // Mock Logic: 
        // 1. In real world, we would send this file to a Python Flask/FastAPI service or use ONNX Runtime.
        // 2. For MVP, we will pick a random product or use a deterministic hash of the filename/size to pick one.
        
        var products = await _context.Products.ToListAsync();
        if (products.Count == 0)
        {
            return NotFound("No products in database to identify against");
        }

        // Deterministic mock: Use file length to pick a product
        var index = (int)(file.Length % products.Count);
        var identifiedProduct = products[index];

        // Random confidence between 0.70 and 0.99
        var random = new Random((int)DateTime.Now.Ticks);
        var confidence = 0.70 + (random.NextDouble() * 0.29);

        return Ok(new IdentifyProductResponse
        {
            ProductId = identifiedProduct.Id.ToString(),
            ProductCode = identifiedProduct.Code,
            ProductName = identifiedProduct.Name,
            Confidence = confidence
        });
    }
}
