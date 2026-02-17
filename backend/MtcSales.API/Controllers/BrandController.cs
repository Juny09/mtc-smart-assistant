using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MtcSales.API.Data;
using MtcSales.API.DTOs;
using MtcSales.API.Models;

namespace MtcSales.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BrandController : ControllerBase
{
    private readonly MtcContext _context;

    public BrandController(MtcContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<BrandDto>>> GetBrands()
    {
        return await _context.Brands
            .Select(b => new BrandDto { Id = b.Id, Name = b.Name })
            .ToListAsync();
    }

    [HttpPost]
    public async Task<ActionResult<BrandDto>> CreateBrand(BrandDto brandDto)
    {
        var brand = new Brand { Name = brandDto.Name };
        _context.Brands.Add(brand);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetBrands), new { id = brand.Id }, 
            new BrandDto { Id = brand.Id, Name = brand.Name });
    }
}
