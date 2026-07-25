/// example_builder.zig
///
/// Demonstrates the builder pattern API (z_print_builder).
/// Equivalent to the C example_builder.c.
///
/// The builder API provides type-safe, chainable formatting without
/// format strings. Each value is added explicitly with its type.
const std = @import("std");
const z_print = @import("z_print");
const bld = z_print.z_print_builder;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var b = bld.cp_new(allocator);
    defer bld.cp_free(&b);

    // Type-safe construction with chaining
    _ = bld.cp_text(&b, "Employee: ");
    _ = bld.cp_str(bld.cp_color_str(&b, "cyan"), "Carlos");
    _ = bld.cp_text(&b, " | Salary: $");
    _ = bld.cp_float(bld.cp_precision(bld.cp_color_str(&b, "green"), 2), 75000.50);
    try bld.cp_println(&b);

    // Reuse builder after reset
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "ID: ");
    _ = bld.cp_int(bld.cp_pad(bld.cp_zero_pad(&b), 5), 42);
    try bld.cp_println(&b);

    // Number with thousands separator
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "Population: ");
    _ = bld.cp_int(bld.cp_separator(&b, ','), 1234567);
    try bld.cp_println(&b);

    // Complex chaining: price with color, precision, and separator
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "Price: $");
    _ = bld.cp_float(
        bld.cp_separator(
            bld.cp_precision(
                bld.cp_color_str(&b, "green"),
                2,
            ),
            ',',
        ),
        9999.99,
    );
    try bld.cp_println(&b);

    // Boolean values
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "Active: ");
    _ = bld.cp_bool(bld.cp_color(&b, .green), true);
    try bld.cp_println(&b);

    // Binary and hex with prefix
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "Binary: ");
    _ = bld.cp_binary(bld.cp_show_prefix(&b), 255);
    try bld.cp_println(&b);

    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "Hex:    ");
    _ = bld.cp_hex(bld.cp_show_prefix(&b), 255);
    try bld.cp_println(&b);

    // Alignment examples
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "|");
    _ = bld.cp_str(bld.cp_align_left(&b, 10), "Left");
    _ = bld.cp_text(&b, "|");
    try bld.cp_println(&b);

    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "|");
    _ = bld.cp_str(bld.cp_align_right(&b, 10), "Right");
    _ = bld.cp_text(&b, "|");
    try bld.cp_println(&b);

    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "|");
    _ = bld.cp_str(bld.cp_fill_char(bld.cp_align_center(&b, 10), '*'), "Center");
    _ = bld.cp_text(&b, "|");
    try bld.cp_println(&b);

    // Percentage formatting
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "Progress: ");
    _ = bld.cp_float(bld.cp_precision(bld.cp_as_percentage(&b), 1), 0.856);
    try bld.cp_println(&b);

    // Using cp_to_string to get the buffer as an allocated string
    bld.cp_reset(&b);
    _ = bld.cp_text(&b, "Result: ");
    _ = bld.cp_str(bld.cp_color(&b, .bright_green), "OK");
    const result = try bld.cp_to_string(&b);
    defer allocator.free(result);
    try z_print.stdio.writeStdoutLine(result);
}
