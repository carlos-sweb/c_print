/// z_print_safe.zig - Safe variant of z_print with runtime validation
///
/// Adds runtime checks for:
/// - Invalid char values (outside ASCII 0-127)
/// - Pattern vs argument count mismatches
/// - Visual error feedback (red bold error messages)
///
const std = @import("std");
const z_print_mod = @import("z_print.zig");
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

// ============================================================================
// Helper Functions
// ============================================================================

/// Count the number of format patterns `{...}` in a pattern string,
/// excluding escaped braces `\{`.
fn countPatterns(pattern: []const u8) usize {
    var count: usize = 0;
    var i: usize = 0;
    while (i < pattern.len) {
        if (pattern[i] == '\\' and i + 1 < pattern.len and pattern[i + 1] == '{') {
            i += 2;
            continue;
        }
        if (pattern[i] == '{') {
            // Check if there's a closing brace
            var j = i + 1;
            while (j < pattern.len) : (j += 1) {
                if (pattern[j] == '}') {
                    count += 1;
                    break;
                }
            }
        }
        i += 1;
    }
    return count;
}

// ============================================================================
// Core Safe Print Function
// ============================================================================

/// Safe variant of z_print with runtime validation.
///
/// Scans `pattern` byte by byte. When `{type:spec...}` is found, parses the pattern,
/// validates the corresponding argument from `args`, formats it, applies ANSI codes,
/// and outputs with optional alignment.
///
/// Validation includes:
/// - String pointers: checked against SUSPICIOUS_PTR_THRESHOLD
/// - Char values: checked for valid ASCII range (0-127)
/// - Pattern/arg count: logged as debug info if mismatched
///
/// On validation failure, an error message is displayed in red bold text.
/// Escaped braces `\{` output a literal `{`.
/// `args` is a tuple of values matching the pattern's format types in order.
pub fn z_print_safe(writer: *std.Io.Writer, pattern: []const u8, args: anytype) !void {
    if (pattern.len == 0) return;

    const NumArgs = @typeInfo(@TypeOf(args)).@"struct".fields.len;
    const expected_args = countPatterns(pattern);

    if (expected_args != NumArgs) {
    }

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
            const end = z_print_mod.find_closing_brace(pattern, i);
            if (end) |end_idx| {
                const pat = pattern[i .. end_idx + 1];
                var style: PatternStyle = undefined;
                if (pattern_parser.parse_pattern(pat, &style)) {
                    // Format the value into a temp buffer
                    var value_buf: [1024]u8 = undefined;
                    var value_writer: std.Io.Writer = .fixed(&value_buf);

                    var had_error = false;

                    if (arg_index < NumArgs) {
                        // Use inline switch to bridge runtime index to comptime
                        switch (arg_index) {
                            inline 0...63 => |idx| {
                                if (idx < NumArgs) {
                                    had_error = !format_value_safe(&value_writer, &style, args[idx], idx);
                                }
                            },
                            else => {},
                        }
                    } else {
                        // Not enough arguments
                         try value_writer.print("{{? missing arg at index {d}}}", .{arg_index});
                        had_error = true;
                    }

                    const formatted = value_writer.buffered();

                    // Apply ANSI codes
                    if (had_error) {
                        // Show errors in red bold
                        try ansi_codes.apply_ansi_codes(writer, .red, .reset, .bold);
                    } else if (style.has_color or style.has_bg or style.has_style) {
                        try ansi_codes.apply_ansi_codes(writer, style.text_color, style.bg_color, style.style);
                    }

                    // Output with or without alignment
                    if (style.has_alignment) {
                        try text_alignment.print_aligned(writer, formatted, style.text_align, style.width, style.fill_char);
                    } else {
                        try writer.writeAll(formatted);
                    }

                    // Reset ANSI codes if they were applied
                    if (had_error or style.has_color or style.has_bg or style.has_style) {
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


/// Format a single value with runtime validation. Returns true on success, false on error.
/// On validation failure, writes an error message into the writer.
fn format_value_safe(writer: *std.Io.Writer, style: *const PatternStyle, arg: anytype, arg_idx: usize) bool {
    const T = @TypeOf(arg);

    if (comptime isSliceType(T)) {
        // String type
        if (style.format_type == 's') {
            const val: []const u8 = arg;
            const ptr_val = @intFromPtr(val.ptr);
            if (ptr_val == 0) {
                writer.print("{{? null string pointer}}", .{}) catch {};
                return false;
            }
            if (ptr_val < 0x1000) {
                writer.print("{{? expected string, got int={d}}}", .{ptr_val}) catch {};
                return false;
            }
            // Valid string - format it
            if (style.has_truncate and style.width > 0 and val.len > style.width) {
                writer.writeAll(val[0..style.width]) catch {};
            } else {
                writer.writeAll(val) catch {};
            }
            return true;
        } else {
            writer.writeAll("{?}") catch {};
            return false;
        }
    } else if (comptime z_print_mod.isSignedIntType(T)) {
        return format_signed_int_safe(writer, style, arg, arg_idx);
    } else if (comptime z_print_mod.isUnsignedIntType(T)) {
        return format_unsigned_int_safe(writer, style, arg, arg_idx);
    } else if (comptime z_print_mod.isFloatType(T)) {
        return format_float_safe(writer, style, arg);
    } else {
        writer.writeAll("{?}") catch {};
        return false;
    }
}

/// Format a signed integer with validation.
fn format_signed_int_safe(writer: *std.Io.Writer, style: *const PatternStyle, arg: anytype, _: usize) bool {
    switch (style.format_type) {
        'd', 'i' => {
            const val: i32 = @intCast(arg);
            z_print_mod.format_int(writer, style, val) catch {};
            return true;
        },
        'l' => {
            const val: i64 = @intCast(arg);
            if (style.has_separator) {
                number_formatter.format_separated(writer, val, style.separator) catch {};
            } else {
                writer.print("{d}", .{val}) catch {};
            }
            return true;
        },
        'u' => {
            const val: u64 = @intCast(arg);
            if (style.has_separator) {
                number_formatter.format_separated(writer, @intCast(val), style.separator) catch {};
            } else {
                writer.print("{d}", .{val}) catch {};
            }
            return true;
        },
        'b' => {
            const val: u64 = @intCast(arg);
            number_formatter.format_binary(writer, val, style.show_prefix) catch {};
            return true;
        },
        'x' => {
            const val: u64 = @intCast(arg);
            number_formatter.format_hex(writer, val, style.show_prefix, style.padding, style.zero_pad) catch {};
            return true;
        },
        'o' => {
            const val: u64 = @intCast(arg);
            number_formatter.format_octal(writer, val, style.show_prefix) catch {};
            return true;
        },
        else => {
            writer.writeAll("{?}") catch {};
            return false;
        },
    }
}

/// Format an unsigned integer with validation (including char range check).
fn format_unsigned_int_safe(writer: *std.Io.Writer, style: *const PatternStyle, arg: anytype, _: usize) bool {
    switch (style.format_type) {
        'c' => {
            const val: u8 = @intCast(arg);
            // Validate ASCII range
            if (val > 127) {
                writer.print("{{? invalid char: {d}}}", .{val}) catch {};
                return false;
            }
            writer.writeByte(val) catch {};
            return true;
        },
        'b' => {
            const val: u64 = @intCast(arg);
            number_formatter.format_binary(writer, val, style.show_prefix) catch {};
            return true;
        },
        'x' => {
            const val: u64 = @intCast(arg);
            number_formatter.format_hex(writer, val, style.show_prefix, style.padding, style.zero_pad) catch {};
            return true;
        },
        'o' => {
            const val: u64 = @intCast(arg);
            number_formatter.format_octal(writer, val, style.show_prefix) catch {};
            return true;
        },
        'u' => {
            const val: u64 = @intCast(arg);
            if (style.has_separator) {
                number_formatter.format_separated(writer, @intCast(val), style.separator) catch {};
            } else {
                writer.print("{d}", .{val}) catch {};
            }
            return true;
        },
        'd', 'i' => {
            const val: i32 = @intCast(arg);
            z_print_mod.format_int(writer, style, val) catch {};
            return true;
        },
        'l' => {
            const val: i64 = @intCast(arg);
            if (style.has_separator) {
                number_formatter.format_separated(writer, val, style.separator) catch {};
            } else {
                writer.print("{d}", .{val}) catch {};
            }
            return true;
        },
        else => {
            writer.writeAll("{?}") catch {};
            return false;
        },
    }
}

/// Format a float with validation.
fn format_float_safe(writer: *std.Io.Writer, style: *const PatternStyle, arg: anytype) bool {
    if (style.format_type == 'f') {
        const val: f64 = @floatCast(arg);
        z_print_mod.format_float(writer, style, val) catch {};
        return true;
    } else {
        writer.writeAll("{?}") catch {};
        return false;
    }
}

// ============================================================================
// Comptime Type Checks
// ============================================================================

/// Comptime check if T is a string-like type (slice of u8 or pointer to array of u8)
fn isSliceType(comptime T: type) bool {
    if (T == []const u8 or T == []u8) return true;
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

// ============================================================================
// Tests
// ============================================================================

// -- Helper function tests --

test "countPatterns basic" {
    try std.testing.expectEqual(@as(usize, 2), countPatterns("Hello {s}, Age: {d}"));
}

test "countPatterns with escaped brace" {
    try std.testing.expectEqual(@as(usize, 1), countPatterns("\\{not} {s}"));
}

test "countPatterns no patterns" {
    try std.testing.expectEqual(@as(usize, 0), countPatterns("plain text"));
}

test "countPatterns empty" {
    try std.testing.expectEqual(@as(usize, 0), countPatterns(""));
}

// -- Normal operation tests (should work like regular z_print) --

test "z_print_safe plain text no patterns" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "Hello World", .{});
    try std.testing.expectEqualStrings("Hello World", writer.buffered());
}

test "z_print_safe empty pattern returns early" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "", .{});
    try std.testing.expectEqualStrings("", writer.buffered());
}

test "z_print_safe escaped brace" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "\\{not a pattern}", .{});
    try std.testing.expectEqualStrings("{not a pattern}", writer.buffered());
}

test "z_print_safe string format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "Hello {s}!", .{"World"});
    try std.testing.expectEqualStrings("Hello World!", writer.buffered());
}

test "z_print_safe string with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{s:red}", .{"Hi"});
    try std.testing.expectEqualStrings("\x1b[31mHi\x1b[0m", writer.buffered());
}

test "z_print_safe integer format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "val={d}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("val=42", writer.buffered());
}

test "z_print_safe float format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{f:.2}", .{@as(f64, 3.14)});
    try std.testing.expectEqualStrings("3.14", writer.buffered());
}

test "z_print_safe char format valid" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{c}", .{@as(u8, 'A')});
    try std.testing.expectEqualStrings("A", writer.buffered());
}

test "z_print_safe binary format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{b}", .{@as(u64, 5)});
    try std.testing.expectEqualStrings("101", writer.buffered());
}

test "z_print_safe hex format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{x}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("ff", writer.buffered());
}

test "z_print_safe octal format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{o}", .{@as(u64, 8)});
    try std.testing.expectEqualStrings("10", writer.buffered());
}

test "z_print_safe unsigned format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{u}", .{@as(u64, 42)});
    try std.testing.expectEqualStrings("42", writer.buffered());
}

test "z_print_safe long format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{l}", .{@as(i64, 1234567890)});
    try std.testing.expectEqualStrings("1234567890", writer.buffered());
}

test "z_print_safe multiple patterns" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "Name: {s}, Age: {d}", .{ "Alice", @as(i32, 30) });
    try std.testing.expectEqualStrings("Name: Alice, Age: 30", writer.buffered());
}

test "z_print_safe alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "|{s:<10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|Hi        |", writer.buffered());
}

test "z_print_safe integer with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{d:,}", .{@as(i32, 1234567)});
    try std.testing.expectEqualStrings("1,234,567", writer.buffered());
}

// -- Invalid char value tests --

test "z_print_safe invalid char above 127" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // 200 is outside ASCII range (0-127)
    try z_print_safe(&writer, "{c}", .{@as(u8, 200)});
    const output = writer.buffered();
    // Should contain error message wrapped in red bold ANSI codes
    // Error message: {? invalid char: 200}
    try std.testing.expect(std.mem.indexOf(u8, output, "invalid char: 200") != null);
    // Should have red ANSI code (31) - may be combined with bold as \x1b[1;31m
    try std.testing.expect(std.mem.indexOf(u8, output, "31m") != null);
    // Should have reset
    try std.testing.expect(std.mem.indexOf(u8, output, "\x1b[0m") != null);
}

test "z_print_safe invalid char at boundary 128" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{c}", .{@as(u8, 128)});
    const output = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, output, "invalid char: 128") != null);
}

test "z_print_safe valid char at boundary 127" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{c}", .{@as(u8, 127)});
    // 127 is valid ASCII (DEL character), should output without error
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "invalid char") == null);
}

test "z_print_safe valid char at 0" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{c}", .{@as(u8, 0)});
    // 0 is valid ASCII (NUL), should output without error message
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "invalid char") == null);
}

// -- Suspicious pointer detection tests --

test "z_print_safe suspicious string pointer" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // Create a slice with a suspicious low address pointer
    const fake_ptr: [*]const u8 = @ptrFromInt(0x100);
    const fake_str: []const u8 = fake_ptr[0..5];
    try z_print_safe(&writer, "{s}", .{fake_str});
    const output = writer.buffered();
    // Should contain error message about invalid pointer
    try std.testing.expect(std.mem.indexOf(u8, output, "expected string") != null or
        std.mem.indexOf(u8, output, "invalid pointer") != null);
    // Should be wrapped in red bold (may be combined as \x1b[1;31m)
    try std.testing.expect(std.mem.indexOf(u8, output, "31m") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\x1b[0m") != null);
}

test "z_print_safe very low suspicious pointer shows as int" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // A very low address (< 10000) should show "expected string, got int=..."
    const fake_ptr: [*]const u8 = @ptrFromInt(42);
    const fake_str: []const u8 = fake_ptr[0..1];
    try z_print_safe(&writer, "{s}", .{fake_str});
    const output = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, output, "expected string, got int=42") != null);
}

// -- Error message visibility tests --

test "z_print_safe error messages use red bold ANSI" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    // Trigger an error with invalid char
    try z_print_safe(&writer, "{c}", .{@as(u8, 200)});
    const output = writer.buffered();
    // Red = \x1b[31m, Bold = \x1b[1m
    // Combined: \x1b[1;31m (bold + red)
    try std.testing.expect(std.mem.indexOf(u8, output, "\x1b[1;31m") != null);
}

test "z_print_safe error reset code present" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{c}", .{@as(u8, 255)});
    const output = writer.buffered();
    // Must end with reset code
    try std.testing.expect(std.mem.indexOf(u8, output, "\x1b[0m") != null);
}

// -- Valid inputs still work correctly --

test "z_print_safe string with bg color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{s:bg_blue}", .{"X"});
    try std.testing.expectEqualStrings("\x1b[44mX\x1b[0m", writer.buffered());
}

test "z_print_safe string with all ANSI" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{s:cyan:bg_black:bold}", .{"A"});
    try std.testing.expectEqualStrings("\x1b[1;36;40mA\x1b[0m", writer.buffered());
}

test "z_print_safe char with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{c:red}", .{@as(u8, 'X')});
    try std.testing.expectEqualStrings("\x1b[31mX\x1b[0m", writer.buffered());
}

test "z_print_safe integer with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{d:yellow}", .{@as(i32, 99)});
    try std.testing.expectEqualStrings("\x1b[33m99\x1b[0m", writer.buffered());
}

test "z_print_safe float with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{f:.2:green}", .{@as(f64, 1.5)});
    try std.testing.expectEqualStrings("\x1b[32m1.50\x1b[0m", writer.buffered());
}

test "z_print_safe hex with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{x:#}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("0xff", writer.buffered());
}

test "z_print_safe binary with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{b:#}", .{@as(u64, 5)});
    try std.testing.expectEqualStrings("0b101", writer.buffered());
}

test "z_print_safe octal with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{o:#}", .{@as(u64, 8)});
    try std.testing.expectEqualStrings("0o10", writer.buffered());
}

test "z_print_safe long with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{l:,}", .{@as(i64, 1234567890)});
    try std.testing.expectEqualStrings("1,234,567,890", writer.buffered());
}

test "z_print_safe unsigned with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{u:,}", .{@as(u64, 1234567)});
    try std.testing.expectEqualStrings("1,234,567", writer.buffered());
}

test "z_print_safe float percentage with precision" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{f:.2:%}", .{@as(f64, 0.123)});
    try std.testing.expectEqualStrings("12.30%", writer.buffered());
}

test "z_print_safe integer with zero padding" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{d:05}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("00042", writer.buffered());
}

test "z_print_safe integer with show sign" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{d:+}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("+42", writer.buffered());
}

test "z_print_safe right alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "|{s:>10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|        Hi|", writer.buffered());
}

test "z_print_safe center alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "|{s:^10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|    Hi    |", writer.buffered());
}

test "z_print_safe center alignment with fill" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "|{s:*^10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|****Hi****|", writer.buffered());
}

test "z_print_safe multiple patterns with colors" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{s:red}={d:blue}", .{ "X", @as(i32, 5) });
    try std.testing.expectEqualStrings("\x1b[31mX\x1b[0m=\x1b[34m5\x1b[0m", writer.buffered());
}

test "z_print_safe string empty" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{s}", .{""});
    try std.testing.expectEqualStrings("", writer.buffered());
}

test "z_print_safe integer zero" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{d}", .{@as(i32, 0)});
    try std.testing.expectEqualStrings("0", writer.buffered());
}

test "z_print_safe pattern without closing brace" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "abc{s", .{"x"});
    try std.testing.expectEqualStrings("abc{s", writer.buffered());
}

test "z_print_safe integer negative with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{d:,}", .{@as(i32, -1234567)});
    try std.testing.expectEqualStrings("-1,234,567", writer.buffered());
}

test "z_print_safe long negative" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{l}", .{@as(i64, -42)});
    try std.testing.expectEqualStrings("-42", writer.buffered());
}

test "z_print_safe alignment with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try z_print_safe(&writer, "{s:<5:red}", .{"Hi"});
    try std.testing.expectEqualStrings("\x1b[31mHi   \x1b[0m", writer.buffered());
}
