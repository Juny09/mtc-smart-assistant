using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MtcSales.API.Models;

[Table("carts")]
public class Cart
{
    [Key]
    [Column("id")]
    public Guid Id { get; set; }

    [Column("session_id")]
    public string? SessionId { get; set; }

    [Column("user_id")]
    public Guid? UserId { get; set; }

    [Column("status")]
    public string Status { get; set; } = "active";

    [Column("customer_note")]
    public string? CustomerNote { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<CartItem> Items { get; set; } = new();
}

[Table("cart_items")]
public class CartItem
{
    [Key]
    [Column("id")]
    public Guid Id { get; set; }

    [Column("cart_id")]
    public Guid CartId { get; set; }
    
    [Column("product_id")]
    public Guid ProductId { get; set; }

    [Column("quantity")]
    public int Quantity { get; set; } = 1;

    [Column("added_at")]
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey("ProductId")]
    public Product? Product { get; set; }
}
