/// C-ABI compatible wrapper functions for c_print library.
/// These functions allow C code to use the c_print library via exported symbols.
const std = @import("std");

/// ANSI escape codes for colors
const RESET = "\x1b[0m";
const BOLD = "\x1b[1m";
const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const BLUE = "\x1b[34m";
const MAGENTA = "\x1b[35m";
const CYAN = "\x1b[36m";
const WHITE = "\x1b[37m";
const BLACK = "\x1b[30m";

fn colorToAnsi(color_code: c_int) []const u8 {
    return switch (color_code) {
        0 => RED,
        1 => GREEN,
        2 => BLUE,
        3 => YELLOW,
        4 => CYAN,
        5 => MAGENTA,
        6 => WHITE,
        7 => BLACK,
        else => WHITE,
    };
}

/// Print a message with a color.
/// color_code: 0=red, 1=green, 2=blue, 3=yellow, 4=cyan, 5=magenta, 6=white, 7=black
/// Returns 0 on success, -1 on error.
pub export fn c_print_color_msg(message: [*:0]const u8, color_code: c_int) callconv(.c) c_int {
    const msg: []const u8 = std.mem.span(message);
    const color: []const u8 = colorToAnsi(color_code);
    std.debug.print("{s}{s}{s}\n", .{ color, msg, RESET });
    return 0;
}

/// Print a bold message.
/// Returns 0 on success, -1 on error.
pub export fn c_print_bold_msg(message: [*:0]const u8) callconv(.c) c_int {
    const msg: []const u8 = std.mem.span(message);
    std.debug.print("{s}{s}{s}\n", .{ BOLD, msg, RESET });
    return 0;
}

/// Print a simple string (no formatting).
/// Returns 0 on success, -1 on error.
pub export fn c_print_puts(message: [*:0]const u8) callconv(.c) c_int {
    const msg: []const u8 = std.mem.span(message);
    std.debug.print("{s}\n", .{msg});
    return 0;
}

/// Get library version string.
pub export fn c_print_version() callconv(.c) [*:0]const u8 {
    return "c_print 0.1.0 (Zig 0.16.0)";
}
