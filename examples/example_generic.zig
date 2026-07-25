/// example_generic.zig
///
/// Demonstrates the generic API (z_print_generic).
/// Equivalent to the C example_generic.c.
///
/// The generic API uses Zig's comptime reflection to automatically
/// detect argument types and validate them against format specifiers.
const std = @import("std");
const z_print = @import("z_print");
const generic = z_print.z_print_generic;

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    const name: []const u8 = "Maria";
    const age: i32 = 30;
    const salary: f64 = 85000.75;

    // Automatic type detection via comptime reflection
    try generic.C_PRINT(&writer, "Name: {s:blue}\n", .{name});
    try generic.C_PRINT(&writer, "Age: {d:yellow}\n", .{age});
    try generic.C_PRINT(&writer, "Salary: ${f:.2:green:,}\n", .{salary});

    // Compile-time validation
    const result = generic.validateArgs("{s} {d} {f}", .{ name, age, salary });
    try writer.print("Validation: valid={any}, expected={d}, actual={d}, mismatches={d}\n", .{
        result.valid,
        result.expected_count,
        result.actual_count,
        result.mismatch_count,
    });

    // Debug type information
    try generic.C_PRINT_DEBUG_TYPES(&writer, "{s} {d} {f}", .{ name, age, salary });

    // Debug type and value information
    try generic.C_PRINT_DEBUG_VALUES(&writer, "{s} {d} {f}", .{ name, age, salary });

    // Type detection examples
    try writer.writeAll("\nType detection:\n");
    try writer.print("  []const u8 -> {s}\n", .{generic.typeNameForType(generic.detectArgType([]const u8))});
    try writer.print("  i32        -> {s}\n", .{generic.typeNameForType(generic.detectArgType(i32))});
    try writer.print("  u8         -> {s}\n", .{generic.typeNameForType(generic.detectArgType(u8))});
    try writer.print("  u64        -> {s}\n", .{generic.typeNameForType(generic.detectArgType(u64))});
    try writer.print("  f64        -> {s}\n", .{generic.typeNameForType(generic.detectArgType(f64))});
    try writer.print("  bool       -> {s}\n", .{generic.typeNameForType(generic.detectArgType(bool))});

    // Using C_PRINT with various format types
    try generic.C_PRINT(&writer, "\nBinary: {b:#}\n", .{@as(u64, 42)});
    try generic.C_PRINT(&writer, "Hex:    {x:#}\n", .{@as(u64, 255)});
    try generic.C_PRINT(&writer, "Octal:  {o:#}\n", .{@as(u64, 42)});
    try generic.C_PRINT(&writer, "Char:   {c}\n", .{@as(u8, 'Z')});
    try generic.C_PRINT(&writer, "Long:   {l:,}\n", .{@as(i64, 9876543210)});

    // validateAndReport for runtime error reporting
    try writer.writeAll("\nValidation with error reporting:\n");
    const valid = generic.validateAndReport(&writer, "{s} {d}", .{ name, age });
    try writer.print("  Result: {s}\n", .{if (valid) @as([]const u8, "PASS") else "FAIL"});

    // Write buffer to stdout
    try z_print.stdio.writeStdout(writer.buffered());
}
