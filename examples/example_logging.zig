/// example_logging.zig
///
/// Demonstrates building a colored logging system using the builder API.
/// Equivalent to the C "Example 2: Logging System".
const std = @import("std");
const c_print = @import("c_print");
const bld = c_print.c_print_builder;

const LogLevel = enum {
    info,
    warning,
    err,
    success,
};

fn logMessage(allocator: std.mem.Allocator, level: LogLevel, message: []const u8) !void {
    var b = bld.cp_new(allocator);
    defer bld.cp_free(&b);

    _ = bld.cp_text(&b, "[");

    switch (level) {
        .info => _ = bld.cp_str(bld.cp_color_str(&b, "cyan"), "INFO"),
        .warning => _ = bld.cp_str(bld.cp_color_str(&b, "yellow"), "WARN"),
        .err => _ = bld.cp_str(bld.cp_style_str(bld.cp_color_str(&b, "red"), "bold"), "ERROR"),
        .success => _ = bld.cp_str(bld.cp_color_str(&b, "green"), "OK"),
    }

    _ = bld.cp_text(&b, "] ");
    _ = bld.cp_str(&b, message);
    try bld.cp_println(&b);
}

fn logWithTimestamp(allocator: std.mem.Allocator, level: LogLevel, message: []const u8) !void {
    var b = bld.cp_new(allocator);
    defer bld.cp_free(&b);

    // Timestamp in dim
    _ = bld.cp_str(bld.cp_style_str(&b, "dim"), "2024-01-15 10:30:45");
    _ = bld.cp_text(&b, " ");

    // Level badge
    _ = bld.cp_text(&b, "[");
    switch (level) {
        .info => _ = bld.cp_str(bld.cp_color_str(&b, "cyan"), "INFO"),
        .warning => _ = bld.cp_str(bld.cp_style_str(bld.cp_color_str(&b, "yellow"), "bold"), "WARN"),
        .err => _ = bld.cp_str(bld.cp_style_str(bld.cp_color_str(&b, "red"), "bold"), "ERROR"),
        .success => _ = bld.cp_str(bld.cp_style_str(bld.cp_color_str(&b, "bright_green"), "bold"), "OK"),
    }
    _ = bld.cp_text(&b, "] ");

    // Message
    _ = bld.cp_str(&b, message);
    try bld.cp_println(&b);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Basic logging
    try logMessage(allocator, .info, "Starting application...");
    try logMessage(allocator, .success, "Connection established");
    try logMessage(allocator, .warning, "Cache nearly full");
    try logMessage(allocator, .err, "Authentication failed");

    // Logging with timestamps
    std.debug.print("\n", .{});
    try logWithTimestamp(allocator, .info, "Server listening on port 8080");
    try logWithTimestamp(allocator, .success, "Database migration complete");
    try logWithTimestamp(allocator, .warning, "Memory usage at 85%");
    try logWithTimestamp(allocator, .err, "Failed to connect to redis");
}
