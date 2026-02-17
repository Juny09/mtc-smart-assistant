using Microsoft.EntityFrameworkCore;
using MtcSales.API.Models;

namespace MtcSales.API.Data;

public class MtcContext : DbContext
{
    public MtcContext(DbContextOptions<MtcContext> options) : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Category> Categories { get; set; }
    public DbSet<Brand> Brands { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<ProductImage> ProductImages { get; set; }
    public DbSet<Cart> Carts { get; set; }
    public DbSet<CartItem> CartItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Additional configuration if needed
        modelBuilder.HasPostgresExtension("vector");

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Username)
            .IsUnique();

        modelBuilder.Entity<Product>()
            .HasIndex(p => p.Code)
            .IsUnique();
    }
}
