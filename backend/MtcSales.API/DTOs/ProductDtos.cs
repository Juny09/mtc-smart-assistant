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
}

public class IdentifyProductResponse
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public double Confidence { get; set; }
}
