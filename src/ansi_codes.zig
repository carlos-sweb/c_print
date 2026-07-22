const std = @import("std");

/// ANSI text color codes
pub const TextColor = enum(u8) {
    reset = 0,
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37,
    bright_black = 90,
    bright_red = 91,
    bright_green = 92,
    bright_yellow = 93,
    bright_blue = 94,
    bright_magenta = 95,
    bright_cyan = 96,
    bright_white = 97,
};

/// ANSI background color codes
pub const BackgroundColor = enum(u8) {
    reset = 0,
    black = 40,
    red = 41,
    green = 42,
    yellow = 43,
    blue = 44,
    magenta = 45,
    cyan = 46,
    white = 47,
    bright_black = 100,
    bright_red = 101,
    bright_green = 102,
    bright_yellow = 103,
    bright_blue = 104,
    bright_magenta = 105,
    bright_cyan = 106,
    bright_white = 107,
};

/// ANSI text style codes
pub const TextStyle = enum(u8) {
    reset = 0,
    bold = 1,
    dim = 2,
    italic = 3,
    underline = 4,
    blink = 5,
    reverse = 7,
    hidden = 8,
    strikethrough = 9,
};

/// Apply ANSI escape codes for text color, background color, and style
/// Outputs the escape sequence in the format: \x1b[<style>;<fg>;<bg>m
/// Only includes non-reset values, separated by semicolons
pub fn apply_ansi_codes(writer: *std.Io.Writer, fg: TextColor, bg: BackgroundColor, style: TextStyle) !void {
    try writer.writeAll("\x1b[");

    var first = true;

    // Apply style if not reset
    if (style != .reset) {
        try writer.print("{d}", .{@intFromEnum(style)});
        first = false;
    }

    // Apply foreground color if not reset
    if (fg != .reset) {
        if (!first) {
            try writer.writeAll(";");
        }
        try writer.print("{d}", .{@intFromEnum(fg)});
        first = false;
    }

    // Apply background color if not reset
    if (bg != .reset) {
        if (!first) {
            try writer.writeAll(";");
        }
        try writer.print("{d}", .{@intFromEnum(bg)});
    }

    try writer.writeAll("m");
}

/// Reset all ANSI codes to default values
/// Outputs the reset sequence: \x1b[0m
pub fn reset_ansi_codes(writer: *std.Io.Writer) !void {
    try writer.writeAll("\x1b[0m");
}

// ============================================================================
// Tests
// ============================================================================

test "TextColor enum values" {
    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(TextColor.reset));
    try std.testing.expectEqual(@as(u8, 30), @intFromEnum(TextColor.black));
    try std.testing.expectEqual(@as(u8, 31), @intFromEnum(TextColor.red));
    try std.testing.expectEqual(@as(u8, 32), @intFromEnum(TextColor.green));
    try std.testing.expectEqual(@as(u8, 33), @intFromEnum(TextColor.yellow));
    try std.testing.expectEqual(@as(u8, 34), @intFromEnum(TextColor.blue));
    try std.testing.expectEqual(@as(u8, 35), @intFromEnum(TextColor.magenta));
    try std.testing.expectEqual(@as(u8, 36), @intFromEnum(TextColor.cyan));
    try std.testing.expectEqual(@as(u8, 37), @intFromEnum(TextColor.white));
    try std.testing.expectEqual(@as(u8, 90), @intFromEnum(TextColor.bright_black));
    try std.testing.expectEqual(@as(u8, 91), @intFromEnum(TextColor.bright_red));
    try std.testing.expectEqual(@as(u8, 92), @intFromEnum(TextColor.bright_green));
    try std.testing.expectEqual(@as(u8, 93), @intFromEnum(TextColor.bright_yellow));
    try std.testing.expectEqual(@as(u8, 94), @intFromEnum(TextColor.bright_blue));
    try std.testing.expectEqual(@as(u8, 95), @intFromEnum(TextColor.bright_magenta));
    try std.testing.expectEqual(@as(u8, 96), @intFromEnum(TextColor.bright_cyan));
    try std.testing.expectEqual(@as(u8, 97), @intFromEnum(TextColor.bright_white));
}

test "BackgroundColor enum values" {
    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(BackgroundColor.reset));
    try std.testing.expectEqual(@as(u8, 40), @intFromEnum(BackgroundColor.black));
    try std.testing.expectEqual(@as(u8, 41), @intFromEnum(BackgroundColor.red));
    try std.testing.expectEqual(@as(u8, 42), @intFromEnum(BackgroundColor.green));
    try std.testing.expectEqual(@as(u8, 43), @intFromEnum(BackgroundColor.yellow));
    try std.testing.expectEqual(@as(u8, 44), @intFromEnum(BackgroundColor.blue));
    try std.testing.expectEqual(@as(u8, 45), @intFromEnum(BackgroundColor.magenta));
    try std.testing.expectEqual(@as(u8, 46), @intFromEnum(BackgroundColor.cyan));
    try std.testing.expectEqual(@as(u8, 47), @intFromEnum(BackgroundColor.white));
    try std.testing.expectEqual(@as(u8, 100), @intFromEnum(BackgroundColor.bright_black));
    try std.testing.expectEqual(@as(u8, 101), @intFromEnum(BackgroundColor.bright_red));
    try std.testing.expectEqual(@as(u8, 102), @intFromEnum(BackgroundColor.bright_green));
    try std.testing.expectEqual(@as(u8, 103), @intFromEnum(BackgroundColor.bright_yellow));
    try std.testing.expectEqual(@as(u8, 104), @intFromEnum(BackgroundColor.bright_blue));
    try std.testing.expectEqual(@as(u8, 105), @intFromEnum(BackgroundColor.bright_magenta));
    try std.testing.expectEqual(@as(u8, 106), @intFromEnum(BackgroundColor.bright_cyan));
    try std.testing.expectEqual(@as(u8, 107), @intFromEnum(BackgroundColor.bright_white));
}

test "TextStyle enum values" {
    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(TextStyle.reset));
    try std.testing.expectEqual(@as(u8, 1), @intFromEnum(TextStyle.bold));
    try std.testing.expectEqual(@as(u8, 2), @intFromEnum(TextStyle.dim));
    try std.testing.expectEqual(@as(u8, 3), @intFromEnum(TextStyle.italic));
    try std.testing.expectEqual(@as(u8, 4), @intFromEnum(TextStyle.underline));
    try std.testing.expectEqual(@as(u8, 5), @intFromEnum(TextStyle.blink));
    try std.testing.expectEqual(@as(u8, 7), @intFromEnum(TextStyle.reverse));
    try std.testing.expectEqual(@as(u8, 8), @intFromEnum(TextStyle.hidden));
    try std.testing.expectEqual(@as(u8, 9), @intFromEnum(TextStyle.strikethrough));
}

test "apply_ansi_codes with all reset values" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .reset, .reset, .reset);
    try std.testing.expectEqualStrings("\x1b[m", writer.buffered());
}

test "apply_ansi_codes with only style" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .reset, .reset, .bold);
    try std.testing.expectEqualStrings("\x1b[1m", writer.buffered());
}

test "apply_ansi_codes with only foreground color" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .red, .reset, .reset);
    try std.testing.expectEqualStrings("\x1b[31m", writer.buffered());
}

test "apply_ansi_codes with only background color" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .reset, .blue, .reset);
    try std.testing.expectEqualStrings("\x1b[44m", writer.buffered());
}

test "apply_ansi_codes with style and foreground" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .green, .reset, .bold);
    try std.testing.expectEqualStrings("\x1b[1;32m", writer.buffered());
}

test "apply_ansi_codes with style and background" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .reset, .yellow, .italic);
    try std.testing.expectEqualStrings("\x1b[3;43m", writer.buffered());
}

test "apply_ansi_codes with foreground and background" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .cyan, .magenta, .reset);
    try std.testing.expectEqualStrings("\x1b[36;45m", writer.buffered());
}

test "apply_ansi_codes with all values" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .red, .blue, .bold);
    try std.testing.expectEqualStrings("\x1b[1;31;44m", writer.buffered());
}

test "apply_ansi_codes with bright colors" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .bright_green, .bright_black, .underline);
    try std.testing.expectEqualStrings("\x1b[4;92;100m", writer.buffered());
}

test "apply_ansi_codes with all styles" {
    var buf: [64]u8 = undefined;

    // Test each style
    const styles = [_]TextStyle{
        .bold,  .dim,     .italic, .underline,
        .blink, .reverse, .hidden, .strikethrough,
    };
    const expected = [_][]const u8{
        "\x1b[1m", "\x1b[2m", "\x1b[3m", "\x1b[4m",
        "\x1b[5m", "\x1b[7m", "\x1b[8m", "\x1b[9m",
    };

    for (styles, expected) |style, exp| {
        var writer: std.Io.Writer = .fixed(&buf);
        try apply_ansi_codes(&writer, .reset, .reset, style);
        try std.testing.expectEqualStrings(exp, writer.buffered());
    }
}

test "reset_ansi_codes" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try reset_ansi_codes(&writer);
    try std.testing.expectEqualStrings("\x1b[0m", writer.buffered());
}

test "apply_ansi_codes complex combination" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try apply_ansi_codes(&writer, .bright_white, .bright_blue, .strikethrough);
    try std.testing.expectEqualStrings("\x1b[9;97;104m", writer.buffered());
}
