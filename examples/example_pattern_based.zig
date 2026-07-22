/// example_pattern_based.zig
///
/// Demonstrates the pattern-based API (c_print_mod.c_print).
/// Equivalent to the C example.c.
///
/// The pattern API uses format strings with {type:specifiers} syntax.
/// Arguments are passed as a comptime tuple for type safety.
const std = @import("std");
const c_print = @import("c_print");
const cp = c_print.c_print_mod;

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    // Simple colored text
    try cp.c_print(&writer, "Hello {s:green}!\n", .{"World"});

    // Multiple specifiers combined
    try cp.c_print(&writer, "{s:cyan:bg_black:bold}\n", .{"IMPORTANT"});

    // Multiple values in one call
    try cp.c_print(
        &writer,
        "User: {s:yellow}, Age: {d:blue}, Score: {f:.2:green}\n",
        .{ "Alice", @as(i32, 25), @as(f64, 95.5) },
    );

    // Number formatting with thousands separators
    try cp.c_print(&writer, "Population: {d:,}\n", .{@as(i32, 1234567)});

    // Percentage formatting
    try cp.c_print(&writer, "Progress: {f:.2:%:cyan}\n", .{@as(f64, 0.85)});

    // Hexadecimal with prefix
    try cp.c_print(&writer, "Hex: {x:#:bold}\n", .{@as(u64, 255)});

    // Price with currency and separators
    try cp.c_print(&writer, "Price: ${f:.2:,}\n", .{@as(f64, 1234.56)});

    // Alignment examples
    try cp.c_print(&writer, "|{s:<20}|\n", .{"Left"});
    try cp.c_print(&writer, "|{s:>20}|\n", .{"Right"});
    try cp.c_print(&writer, "|{s:^20}|\n", .{"Center"});
    try cp.c_print(&writer, "|{s:*^20}|\n", .{"Fill"});

    // Binary and octal
    try cp.c_print(&writer, "Binary: {b:#}\n", .{@as(u64, 42)});
    try cp.c_print(&writer, "Octal:  {o:#}\n", .{@as(u64, 42)});

    // Integer with zero padding
    try cp.c_print(&writer, "Padded: {d:05}\n", .{@as(i32, 42)});

    // Integer with sign
    try cp.c_print(&writer, "Positive: {d:+}\n", .{@as(i32, 42)});
    try cp.c_print(&writer, "Negative: {d:+}\n", .{@as(i32, -42)});

    // Long integer with separator
    try cp.c_print(&writer, "Big number: {l:,}\n", .{@as(i64, 1234567890)});

    // Complex status line
    try cp.c_print(
        &writer,
        "[{s:bright_green:bold}] {s:white} - {f:.2:green} ms\n",
        .{ "SUCCESS", "Request completed", @as(f64, 45.32) },
    );

    // Write buffer to stdout
    std.debug.print("{s}", .{writer.buffered()});
}
