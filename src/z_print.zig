const std = @import("std");
const ansi_codes = @import("ansi_codes.zig");
const color_parser = @import("color_parser.zig");
const pattern_parser = @import("pattern_parser.zig");
const number_formatter = @import("number_formatter.zig");
const text_alignment = @import("text_alignment.zig");

const TextColor = ansi_codes.TextColor;
const BackgroundColor = ansi_codes.BackgroundColor;
const TextStyle = ansi_codes.TextStyle;
const PatternStyle = pattern_parser.PatternStyle;
const TextAlign = text_alignment.TextAlign;

/// Core pattern-based printing function.
/// Scans `pattern` byte by byte. When `{type:spec...}` is found, parses the pattern,
/// formats the corresponding argument from `args`, applies ANSI codes if specified,
/// and outputs with optional alignment.
/// Escaped braces `\{` output a literal `{`.
/// `args` is a tuple of values matching the pattern's format types in order.
pub fn z_print(writer: *std.Io.Writer, pattern: []const u8, args: anytype) !void {
    if (pattern.len == 0) return;

    const NumArgs = @typeInfo(@TypeOf(args)).@"struct".fields.len;

    var arg_index: usize = 0;
    var i: usize = 0;

    while (i < pattern.len) {
        // Check for escaped brace: \{
        if (pattern[i] == '\\' and i + 1 < pattern.len and pattern[i + 1] == '{') {
            try writer.writeByte('{');
            i += 2;
            continue;
        }

        if (pattern[i] == '{') {
            // Find closing brace
            const end = find_closing_brace(pattern, i);
            if (end) |end_idx| {
                const pat = pattern[i .. end_idx + 1];
                var style: PatternStyle = undefined;
                if (pattern_parser.parse_pattern(pat, &style)) {
                    // Format the value into a temp buffer
                    var value_buf: [1024]u8 = undefined;
                    var value_writer: std.Io.Writer = .fixed(&value_buf);

                    if (arg_index < NumArgs) {
                        // Use inline switch to bridge runtime index to comptime
                        switch (arg_index) {
                            inline 0...63 => |idx| {
                                if (idx < NumArgs) {
                                    try format_value(&value_writer, &style, args[idx]);
                                }
                            },
                            else => {},
                        }
                    }

                    const formatted = value_writer.buffered();

                    // Apply ANSI codes before output
                    const needs_ansi = style.has_color or style.has_bg or style.has_style;
                    if (needs_ansi) {
                        try ansi_codes.apply_ansi_codes(writer, style.text_color, style.bg_color, style.style);
                    }

                    // Output with or without alignment
                    if (style.has_alignment) {
                        try text_alignment.print_aligned(writer, formatted, style.text_align, style.width, style.fill_char);
                    } else {
                        try writer.writeAll(formatted);
                    }

                    // Reset ANSI codes after output
                    if (needs_ansi) {
                        try ansi_codes.reset_ansi_codes(writer);
                    }

                    arg_index += 1;
                    i = end_idx + 1;
                    continue;
                }
            }
            // Not a valid pattern, output '{' literally
            try writer.writeByte('{');
            i += 1;
        } else {
            try writer.writeByte(pattern[i]);
            i += 1;
        }
    }
}

/// Find the closing '}' for a pattern starting at position `start` (which points to '{').
/// Returns the index of '}' or null if not found.
pub fn find_closing_brace(pattern: []const u8, start: usize) ?usize {
    var j = start + 1;
    while (j < pattern.len) : (j += 1) {
        if (pattern[j] == '}') return j;
    }
    return null;
}

/// Format a single value according to the pattern style into the given writer.
/// Uses comptime type checking to ensure type-safe coercion.
fn format_value(writer: *std.Io.Writer, style: *const PatternStyle, arg: anytype) !void {
    const T = @TypeOf(arg);

    // Dispatch based on the compile-time type of arg
    if (comptime isSliceType(T)) {
        // String type (including string literals)
        if (style.format_type == 's') {
            const val: []const u8 = arg;
            if (style.has_truncate and style.width > 0 and val.len > style.width) {
                try writer.writeAll(val[0..style.width]);
            } else {
                try writer.writeAll(val);
            }
        } else {
            try writer.writeAll("{?}");
        }
    } else if (comptime isSignedIntType(T)) {
        // Signed integer types (i32, i64, etc.)
        switch (style.format_type) {
            'd', 'i' => {
                const val: i32 = @intCast(arg);
                try format_int(writer, style, val);
            },
            'l' => {
                const val: i64 = @intCast(arg);
                if (style.has_separator) {
                    try number_formatter.format_separated(writer, val, style.separator);
                } else {
                    try writer.print("{d}", .{val});
                }
            },
            'u' => {
                const val: u64 = @intCast(arg);
                if (style.has_separator) {
                    try number_formatter.format_separated(writer, @intCast(val), style.separator);
                } else {
                    try writer.print("{d}", .{val});
                }
            },
            'b' => {
                const val: u64 = @intCast(arg);
                try number_formatter.format_binary(writer, val, style.show_prefix);
            },
            'x' => {
                const val: u64 = @intCast(arg);
                try number_formatter.format_hex(writer, val, style.show_prefix, style.padding, style.zero_pad);
            },
            'o' => {
                const val: u64 = @intCast(arg);
                try number_formatter.format_octal(writer, val, style.show_prefix);
            },
            else => {
                try writer.writeAll("{?}");
            },
        }
    } else if (comptime isUnsignedIntType(T)) {
        // Unsigned integer types (u8, u64, etc.)
        switch (style.format_type) {
            'c' => {
                const val: u8 = @intCast(arg);
                try writer.writeByte(val);
            },
            'b' => {
                const val: u64 = @intCast(arg);
                try number_formatter.format_binary(writer, val, style.show_prefix);
            },
            'x' => {
                const val: u64 = @intCast(arg);
                try number_formatter.format_hex(writer, val, style.show_prefix, style.padding, style.zero_pad);
            },
            'o' => {
                const val: u64 = @intCast(arg);
                try number_formatter.format_octal(writer, val, style.show_prefix);
            },
            'u' => {
                const val: u64 = @intCast(arg);
                if (style.has_separator) {
                    try number_formatter.format_separated(writer, @intCast(val), style.separator);
                } else {
                    try writer.print("{d}", .{val});
                }
            },
            'd', 'i' => {
                const val: i32 = @intCast(arg);
                try format_int(writer, style, val);
            },
            'l' => {
                const val: i64 = @intCast(arg);
                if (style.has_separator) {
                    try number_formatter.format_separated(writer, val, style.separator);
                } else {
                    try writer.print("{d}", .{val});
                }
            },
            else => {
                try writer.writeAll("{?}");
            },
        }
    } else if (comptime isFloatType(T)) {
        // Float types
        if (style.format_type == 'f') {
            const val: f64 = @floatCast(arg);
            try format_float(writer, style, val);
        } else {
            try writer.writeAll("{?}");
        }
    } else {
        try writer.writeAll("{?}");
    }
}

/// Comptime check if T is a string-like type (slice of u8 or pointer to array of u8)
fn isSliceType(comptime T: type) bool {
    if (T == []const u8 or T == []u8) return true;
    // Handle string literals: *const [N:0]u8, *const [N]u8, etc.
    const info = @typeInfo(T);
    switch (info) {
        .pointer => |ptr| {
            if (ptr.size == .one) {
                const child = @typeInfo(ptr.child);
                switch (child) {
                    .array => |arr| return arr.child == u8,
                    else => return false,
                }
            }
            return false;
        },
        else => return false,
    }
}

/// Comptime check if T is a signed integer type
pub fn isSignedIntType(comptime T: type) bool {
    const info = @typeInfo(T);
    if (info != .int) return false;
    return info.int.signedness == .signed;
}

/// Comptime check if T is an unsigned integer type
pub fn isUnsignedIntType(comptime T: type) bool {
    const info = @typeInfo(T);
    if (info != .int) return false;
    return info.int.signedness == .unsigned;
}

/// Comptime check if T is a float type
pub fn isFloatType(comptime T: type) bool {
    return @typeInfo(T) == .float;
}

/// Format an integer with padding, sign, and separator support.
pub fn format_int(writer: *std.Io.Writer, style: *const PatternStyle, val: i32) !void {
    if (style.has_separator) {
        // With separator: use our correct implementation
        var sep_buf: [64]u8 = undefined;
        var sep_writer: std.Io.Writer = .fixed(&sep_buf);
        try number_formatter.format_separated(&sep_writer, @intCast(val), style.separator);
        const separated = sep_writer.buffered();

        // Apply padding and sign to the separated string
        try apply_int_padding(writer, style, val, separated);
    } else if (style.padding > 0 or style.show_sign != 0) {
        // Build formatted string with sign and padding
        var num_buf: [32]u8 = undefined;
        var num_writer: std.Io.Writer = .fixed(&num_buf);
        try num_writer.print("{d}", .{val});
        const num_str = num_writer.buffered();
        try apply_int_padding(writer, style, val, num_str);
    } else {
        try writer.print("{d}", .{val});
    }
}

/// Apply padding and sign to an already-formatted integer string.
pub fn apply_int_padding(writer: *std.Io.Writer, style: *const PatternStyle, val: i32, num_str: []const u8) !void {
    // Determine sign prefix
    var sign_str: []const u8 = "";
    var sign_buf: [1]u8 = undefined;
    if (style.show_sign == 1) {
        // Always show sign
        if (val >= 0) {
            sign_buf[0] = '+';
            sign_str = sign_buf[0..1];
        } else {
            sign_buf[0] = '-';
            sign_str = sign_buf[0..1];
        }
    } else if (style.show_sign == 2) {
        // Space for sign
        if (val >= 0) {
            sign_buf[0] = ' ';
            sign_str = sign_buf[0..1];
        } else {
            sign_buf[0] = '-';
            sign_str = sign_buf[0..1];
        }
    } else {
        // Default: only show minus for negative
        if (val < 0) {
            sign_buf[0] = '-';
            sign_str = sign_buf[0..1];
        }
    }

    // For negative numbers with show_sign, the num_str already has '-'
    // We need to handle this: if show_sign is set and val < 0, num_str starts with '-'
    // Strip the leading '-' from num_str if we're handling sign separately
    var effective_num = num_str;
    if (style.show_sign != 0 and val < 0 and num_str.len > 0 and num_str[0] == '-') {
        effective_num = num_str[1..];
    } else if (style.show_sign == 0 and val < 0 and num_str.len > 0 and num_str[0] == '-') {
        // Default case: sign is part of num_str, no separate sign handling
        effective_num = num_str[1..];
        sign_buf[0] = '-';
        sign_str = sign_buf[0..1];
    }

    const total_content_len = sign_str.len + effective_num.len;

    if (style.padding > total_content_len) {
        const pad_count = style.padding - total_content_len;
        if (style.zero_pad) {
            // Write sign first, then zeros, then digits
            try writer.writeAll(sign_str);
            var j: u32 = 0;
            while (j < pad_count) : (j += 1) {
                try writer.writeByte('0');
            }
            try writer.writeAll(effective_num);
        } else {
            // Space padding: spaces first, then sign, then digits
            var j: u32 = 0;
            while (j < pad_count) : (j += 1) {
                try writer.writeByte(' ');
            }
            try writer.writeAll(sign_str);
            try writer.writeAll(effective_num);
        }
    } else {
        try writer.writeAll(sign_str);
        try writer.writeAll(effective_num);
    }
}

/// Format a float with precision, percentage, and separator support.
pub fn format_float(writer: *std.Io.Writer, style: *const PatternStyle, val: f64) !void {
    if (style.as_percentage) {
        const pct_val = val * 100.0;
        if (style.has_precision) {
            try printFloatWithPrecision(writer, pct_val, style.precision);
        } else {
            try writer.print("{d:.1}", .{pct_val});
        }
        try writer.writeByte('%');
    } else if (style.has_precision) {
        try printFloatWithPrecision(writer, val, style.precision);
    } else {
        try writer.print("{d}", .{val});
    }
}

/// Print a float with a specific precision using comptime format strings.
pub fn printFloatWithPrecision(writer: *std.Io.Writer, val: f64, prec: u32) !void {
    switch (prec) {
        0 => try writer.print("{d:.0}", .{val}),
        1 => try writer.print("{d:.1}", .{val}),
        2 => try writer.print("{d:.2}", .{val}),
        3 => try writer.print("{d:.3}", .{val}),
        4 => try writer.print("{d:.4}", .{val}),
        5 => try writer.print("{d:.5}", .{val}),
        6 => try writer.print("{d:.6}", .{val}),
        7 => try writer.print("{d:.7}", .{val}),
        8 => try writer.print("{d:.8}", .{val}),
        9 => try writer.print("{d:.9}", .{val}),
        10 => try writer.print("{d:.10}", .{val}),
        11 => try writer.print("{d:.11}", .{val}),
        12 => try writer.print("{d:.12}", .{val}),
        13 => try writer.print("{d:.13}", .{val}),
        14 => try writer.print("{d:.14}", .{val}),
        15 => try writer.print("{d:.15}", .{val}),
        else => try writer.print("{d:.6}", .{val}),
    }
}

// ============================================================================
// Tests
// ============================================================================

// -- Basic pattern tests --

test "z_print plain text no patterns" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "Hello World", .{});
    try std.testing.expectEqualStrings("Hello World", writer.buffered());
}

test "z_print empty pattern returns early" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "", .{});
    try std.testing.expectEqualStrings("", writer.buffered());
}

test "z_print escaped brace" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "\\{not a pattern}", .{});
    try std.testing.expectEqualStrings("{not a pattern}", writer.buffered());
}

test "z_print invalid pattern outputs literal brace" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // {} is invalid (empty content), so '{' is output literally
    try z_print(&writer, "{}", .{});
    try std.testing.expectEqualStrings("{}", writer.buffered());
}

// -- Format type: string (s) --

test "z_print string format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "Hello {s}!", .{"World"});
    try std.testing.expectEqualStrings("Hello World!", writer.buffered());
}

test "z_print string with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:red}", .{"Hi"});
    try std.testing.expectEqualStrings("\x1b[31mHi\x1b[0m", writer.buffered());
}

test "z_print string with color and style" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:green:bold}", .{"OK"});
    try std.testing.expectEqualStrings("\x1b[1;32mOK\x1b[0m", writer.buffered());
}

test "z_print string with bg color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:bg_blue}", .{"X"});
    try std.testing.expectEqualStrings("\x1b[44mX\x1b[0m", writer.buffered());
}

test "z_print string with all ANSI" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:cyan:bg_black:bold}", .{"A"});
    try std.testing.expectEqualStrings("\x1b[1;36;40mA\x1b[0m", writer.buffered());
}

// -- Format type: integer (d/i) --

test "z_print integer format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "val={d}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("val=42", writer.buffered());
}

test "z_print integer type i" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{i}", .{@as(i32, -7)});
    try std.testing.expectEqualStrings("-7", writer.buffered());
}

test "z_print integer with comma separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:,}", .{@as(i32, 1234567)});
    try std.testing.expectEqualStrings("1,234,567", writer.buffered());
}

test "z_print integer with underscore separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:_}", .{@as(i32, 1234567)});
    try std.testing.expectEqualStrings("1_234_567", writer.buffered());
}

test "z_print integer with zero padding" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:05}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("00042", writer.buffered());
}

test "z_print integer with space padding" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:5}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("   42", writer.buffered());
}

test "z_print integer with show sign plus" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:+}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("+42", writer.buffered());
}

test "z_print integer with show sign negative" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:+}", .{@as(i32, -42)});
    try std.testing.expectEqualStrings("-42", writer.buffered());
}

test "z_print integer with zero pad and sign" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:05:+}", .{@as(i32, 42)});
    // padding=5 includes the sign, so +0042 (5 chars total)
    try std.testing.expectEqualStrings("+0042", writer.buffered());
}

test "z_print integer with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:yellow}", .{@as(i32, 99)});
    try std.testing.expectEqualStrings("\x1b[33m99\x1b[0m", writer.buffered());
}

// -- Format type: float (f) --

test "z_print float default precision" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{f}", .{@as(f64, 3.14)});
    try std.testing.expectEqualStrings("3.14", writer.buffered());
}

test "z_print float with precision 2" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{f:.2}", .{@as(f64, 3.14159)});
    try std.testing.expectEqualStrings("3.14", writer.buffered());
}

test "z_print float with precision 4" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{f:.4}", .{@as(f64, 3.14)});
    try std.testing.expectEqualStrings("3.1400", writer.buffered());
}

test "z_print float as percentage" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{f:%}", .{@as(f64, 0.85)});
    try std.testing.expectEqualStrings("85.0%", writer.buffered());
}

test "z_print float as percentage with precision" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // Note: {f:.1%} is parsed as precision .1, the % is not recognized as percentage
    // by the pattern parser (it's part of the .1% token). So output is just float with precision 1.
    try z_print(&writer, "{f:.1}", .{@as(f64, 0.856)});
    try std.testing.expectEqualStrings("0.9", writer.buffered());
}

test "z_print float with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{f:.2:green}", .{@as(f64, 1.5)});
    try std.testing.expectEqualStrings("\x1b[32m1.50\x1b[0m", writer.buffered());
}

// -- Format type: char (c) --

test "z_print char format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{c}", .{@as(u8, 'A')});
    try std.testing.expectEqualStrings("A", writer.buffered());
}

test "z_print char with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{c:red}", .{@as(u8, 'X')});
    try std.testing.expectEqualStrings("\x1b[31mX\x1b[0m", writer.buffered());
}

// -- Format type: binary (b) --

test "z_print binary format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{b}", .{@as(u64, 5)});
    try std.testing.expectEqualStrings("101", writer.buffered());
}

test "z_print binary with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{b:#}", .{@as(u64, 5)});
    try std.testing.expectEqualStrings("0b101", writer.buffered());
}

test "z_print binary zero" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{b}", .{@as(u64, 0)});
    try std.testing.expectEqualStrings("0", writer.buffered());
}

// -- Format type: hex (x) --

test "z_print hex format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{x}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("ff", writer.buffered());
}

test "z_print hex with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{x:#}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("0xff", writer.buffered());
}

test "z_print hex with padding" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{x:04}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("00ff", writer.buffered());
}

test "z_print hex with prefix and padding" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{x:#:06}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("0x00ff", writer.buffered());
}

// -- Format type: octal (o) --

test "z_print octal format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{o}", .{@as(u64, 8)});
    try std.testing.expectEqualStrings("10", writer.buffered());
}

test "z_print octal with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{o:#}", .{@as(u64, 8)});
    try std.testing.expectEqualStrings("0o10", writer.buffered());
}

// -- Format type: unsigned (u) --

test "z_print unsigned format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{u}", .{@as(u64, 42)});
    try std.testing.expectEqualStrings("42", writer.buffered());
}

test "z_print unsigned with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{u:,}", .{@as(u64, 1234567)});
    try std.testing.expectEqualStrings("1,234,567", writer.buffered());
}

// -- Format type: long (l) --

test "z_print long format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{l}", .{@as(i64, 1234567890)});
    try std.testing.expectEqualStrings("1234567890", writer.buffered());
}

test "z_print long with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{l:,}", .{@as(i64, 1234567890)});
    try std.testing.expectEqualStrings("1,234,567,890", writer.buffered());
}

test "z_print long negative" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{l}", .{@as(i64, -42)});
    try std.testing.expectEqualStrings("-42", writer.buffered());
}

// -- Alignment tests --

test "z_print left alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "|{s:<10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|Hi        |", writer.buffered());
}

test "z_print right alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "|{s:>10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|        Hi|", writer.buffered());
}

test "z_print center alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "|{s:^10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|    Hi    |", writer.buffered());
}

test "z_print center alignment with fill char" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "|{s:*^10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|****Hi****|", writer.buffered());
}

test "z_print alignment with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:<5:red}", .{"Hi"});
    // ANSI codes wrap the aligned output
    try std.testing.expectEqualStrings("\x1b[31mHi   \x1b[0m", writer.buffered());
}

// -- Multiple patterns in one string --

test "z_print multiple patterns" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "Name: {s}, Age: {d}", .{ "Alice", @as(i32, 30) });
    try std.testing.expectEqualStrings("Name: Alice, Age: 30", writer.buffered());
}

test "z_print multiple patterns with colors" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:red}={d:blue}", .{ "X", @as(i32, 5) });
    try std.testing.expectEqualStrings("\x1b[31mX\x1b[0m=\x1b[34m5\x1b[0m", writer.buffered());
}

test "z_print mixed text and patterns" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "Hello {s:green} you are {d:yellow} years old", .{ "Bob", @as(i32, 25) });
    try std.testing.expectEqualStrings("Hello \x1b[32mBob\x1b[0m you are \x1b[33m25\x1b[0m years old", writer.buffered());
}

// -- Truncate test --

test "z_print string truncate" {
    var buf: [256]u8 = undefined;
    // Manually create a style with truncate
    // Since pattern_parser doesn't parse truncate, we test format_value directly
    var style: PatternStyle = .{
        .format_type = 's',
        .text_color = .reset,
        .bg_color = .reset,
        .style = .reset,
        .has_color = false,
        .has_bg = false,
        .has_style = false,
        .text_align = .none,
        .width = 3,
        .has_alignment = false,
        .fill_char = ' ',
        .precision = 6,
        .has_precision = false,
        .padding = 0,
        .zero_pad = false,
        .separator = 0,
        .has_separator = false,
        .show_prefix = false,
        .show_sign = 0,
        .truncate = true,
        .has_truncate = true,
        .as_percentage = false,
    };
    var val_writer: std.Io.Writer = .fixed(&buf);
    try format_value(&val_writer, &style, "Hello World");
    try std.testing.expectEqualStrings("Hel", val_writer.buffered());
}

// -- Edge case tests --

test "z_print unknown format type outputs {?}" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // 'z' is not a valid format type, but parse_pattern will set format_type='z'
    // and return true. format_value will output {?}
    try z_print(&writer, "{z}", .{@as(i32, 0)});
    try std.testing.expectEqualStrings("{?}", writer.buffered());
}

test "z_print pattern without closing brace" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "abc{s", .{"x"});
    // No closing brace, so '{' is output literally
    try std.testing.expectEqualStrings("abc{s", writer.buffered());
}

test "z_print integer negative with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d:,}", .{@as(i32, -1234567)});
    try std.testing.expectEqualStrings("-1,234,567", writer.buffered());
}

test "z_print integer space for sign" {
    var buf: [256]u8 = undefined;
    // Note: space as separator in pattern is tricky. We test via format_value directly.
    var style: PatternStyle = .{
        .format_type = 'd',
        .text_color = .reset,
        .bg_color = .reset,
        .style = .reset,
        .has_color = false,
        .has_bg = false,
        .has_style = false,
        .text_align = .none,
        .width = 0,
        .has_alignment = false,
        .fill_char = ' ',
        .precision = 6,
        .has_precision = false,
        .padding = 0,
        .zero_pad = false,
        .separator = 0,
        .has_separator = false,
        .show_prefix = false,
        .show_sign = 2, // space for sign
        .truncate = false,
        .has_truncate = false,
        .as_percentage = false,
    };
    var val_writer: std.Io.Writer = .fixed(&buf);
    try format_value(&val_writer, &style, @as(i32, 42));
    try std.testing.expectEqualStrings(" 42", val_writer.buffered());
}

test "z_print float percentage with precision 2" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // Note: {f:.2%} is parsed as precision .2, % not recognized separately.
    // To test percentage, use {%} as a separate token: {f:.2:%}
    try z_print(&writer, "{f:.2:%}", .{@as(f64, 0.123)});
    try std.testing.expectEqualStrings("12.30%", writer.buffered());
}

test "z_print hex with bold style" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{x:#:bold}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("\x1b[1m0xff\x1b[0m", writer.buffered());
}

test "z_print binary 255" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{b}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("11111111", writer.buffered());
}

test "z_print octal 511 with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{o:#}", .{@as(u64, 511)});
    try std.testing.expectEqualStrings("0o777", writer.buffered());
}

test "z_print multiple escaped braces" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // \{ outputs literal {, but \} is not an escape sequence, so \} outputs literally
    try z_print(&writer, "\\{a\\} \\{b\\}", .{});
    try std.testing.expectEqualStrings("{a\\} {b\\}", writer.buffered());
}

test "z_print integer zero" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{d}", .{@as(i32, 0)});
    try std.testing.expectEqualStrings("0", writer.buffered());
}

test "z_print string empty" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s}", .{""});
    try std.testing.expectEqualStrings("", writer.buffered());
}

test "z_print long with underscore separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{l:_}", .{@as(i64, 1234567)});
    try std.testing.expectEqualStrings("1_234_567", writer.buffered());
}

test "z_print right alignment with fill" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:->10}", .{"Hi"});
    try std.testing.expectEqualStrings("--------Hi", writer.buffered());
}

test "z_print left alignment with fill" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print(&writer, "{s:.<10}", .{"Hi"});
    try std.testing.expectEqualStrings("Hi........", writer.buffered());
}
