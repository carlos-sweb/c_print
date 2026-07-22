/// example_data_table.zig
///
/// Demonstrates building a formatted data table using the generic API.
/// Equivalent to the C "Example 3: Data Table".
const std = @import("std");
const c_print = @import("c_print");
const generic = c_print.c_print_generic;

const Product = struct {
    name: []const u8,
    id: i32,
    price: f64,
};

fn printTableRow(writer: *std.Io.Writer, product: Product) !void {
    try generic.C_PRINT(
        writer,
        "| {s:<20} | {d:>8:05} | {f:>12:.2:,} |\n",
        .{ product.name, product.id, product.price },
    );
}

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    const products = [_]Product{
        .{ .name = "Laptop", .id = 1001, .price = 899.99 },
        .{ .name = "Mouse", .id = 2034, .price = 29.99 },
        .{ .name = "Keyboard", .id = 3102, .price = 79.50 },
        .{ .name = "Monitor", .id = 4050, .price = 349.00 },
        .{ .name = "Headphones", .id = 5123, .price = 149.95 },
    };

    // Title
    try generic.C_PRINT(&writer, "{s:=^60:bold}\n", .{" SALES REPORT "});

    // Header
    try generic.C_PRINT(
        &writer,
        "| {s:<20} | {s:>8} | {s:>12} |\n",
        .{ "Product", "ID", "Price" },
    );

    // Separator
    try generic.C_PRINT(&writer, "{s:-^60}\n", .{""});

    // Data rows
    var total: f64 = 0;
    for (products) |product| {
        try printTableRow(&writer, product);
        total += product.price;
    }

    // Footer
    try generic.C_PRINT(&writer, "{s:=^60}\n", .{""});
    try generic.C_PRINT(
        &writer,
        "Total: {s:$}{f:.2:bright_green:bold:,}\n",
        .{ "", total },
    );

    // Summary
    try generic.C_PRINT(
        &writer,
        "\n{s:dim}Products: {d} | Average: ${f:.2}\n",
        .{ "", @as(i32, @intCast(products.len)), total / @as(f64, @floatFromInt(products.len)) },
    );

    _ = try std.io.getStdOut().write(writer.buffered());
}
