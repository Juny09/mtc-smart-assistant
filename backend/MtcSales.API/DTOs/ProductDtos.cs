using System.ComponentModel.DataAnnotations;

namespace MtcSales.API.DTOs;

public class CreateProductRequest
{
    [Required]
    public string Code { get; set; } = string.Empty;

    [Required]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    [Required]
    public decimal SuggestedPrice { get; set; }

    public decimal? CostPrice { get; set; }

    public string? CostCode { get; set; }

    public string? ImageUrl { get; set; }

    public int? CategoryId { get; set; }

    public int? BrandId { get; set; }
}

public class BrandDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class CategoryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class IdentifyProductResponse
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public double Confidence { get; set; }
}

public class ProductDto
{
    public Guid? Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal SuggestedPrice { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? CategoryName { get; set; }
    public string? BrandName { get; set; }

    public ProductDto(string code, string name, string description, decimal suggestedPrice, string imageUrl, Guid? id = null, string? categoryName = null, string? brandName = null)
    {
        Code = code;
        Name = name;
        Description = description;
        SuggestedPrice = suggestedPrice;
        ImageUrl = imageUrl;
        Id = id;
        CategoryName = categoryName;
        BrandName = brandName;
    }
}
