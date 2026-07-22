const std = @import("std");
const ansi_codes = @import("ansi_codes.zig");
const color_parser = @import("color_parser.zig");
const number_formatter = @import("number_formatter.zig");
const text_alignment = @import("text_alignment.zig");

const TextColor = ansi_codes.TextColor;
const BackgroundColor = ansi_codes.BackgroundColor;
const TextStyle = ansi_codes.TextStyle;
const TextAlign = text_alignment.TextAlign;

/// FormatOptions holds all formatting state for the next value to be added.
/// After a value is added, these options are reset to defaults.
pub const FormatOptions = struct {
    text_color: TextColor = .reset,
    bg_color: BackgroundColor = .reset,
    style: TextStyle = .reset,
    precision: u32 = 6,
    has_precision: bool = false,
    padding: u32 = 0,
    zero_pad: bool = false,
    separator: u8 = 0,
    has_separator: bool = false,
    show_prefix: bool = false,
    show_sign: bool = false,
    as_percentage: bool = false,
    text_align: TextAlign = .none,
    align_width: u32 = 0,
    fill_char: u8 = ' ',
};

/// CPrintBuilder provides a type-safe builder pattern for constructing
/// formatted output without variadic functions.
pub const CPrintBuilder = struct {
    buffer: std.array_list.AlignedManaged(u8, null),
    pending: FormatOptions,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) CPrintBuilder {
        return .{
            .buffer = std.array_list.AlignedManaged(u8, null).init(allocator),
            .pending = .{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *CPrintBuilder) void {
        self.buffer.deinit();
    }

    pub fn reset(self: *CPrintBuilder) void {
        self.buffer.clearRetainingCapacity();
        self.pending = .{};
    }
};

// ============================================================================
// Lifecycle functions
// ============================================================================

/// Create a new CPrintBuilder with the given allocator.
pub fn init(allocator: std.mem.Allocator) CPrintBuilder {
    return CPrintBuilder.init(allocator);
}

/// Free the builder's resources.
pub fn deinit(b: *CPrintBuilder) void {
    b.deinit();
}

/// Reset the builder for reuse, clearing the buffer and pending options.
pub fn reset(b: *CPrintBuilder) void {
    b.reset();
}

/// Backward compatibility aliases
pub const cp_new = init;
pub const cp_free = deinit;
pub const cp_reset = reset;
pub const cp_text = appendText;
pub const cp_str = append;
pub const cp_int = appendInt;
pub const cp_uint = appendUint;
pub const cp_long = appendLong;
pub const cp_ulong = appendUlong;
pub const cp_float = appendFloat;
pub const cp_char = appendChar;
pub const cp_bool = appendBool;
pub const cp_binary = appendBinary;
pub const cp_hex = appendHex;
pub const cp_octal = appendOctal;
pub const cp_color = withColor;
pub const cp_color_str = withColorName;
pub const cp_bg = withBgColor;
pub const cp_bg_str = withBgColorName;
pub const cp_style = withStyle;
pub const cp_style_str = withStyleName;
pub const cp_precision = withPrecision;
pub const cp_zero_pad = withZeroPad;
pub const cp_pad = withPad;
pub const cp_separator = withSeparator;
pub const cp_show_prefix = withPrefix;
pub const cp_show_sign = withSign;
pub const cp_as_percentage = asPercentage;
pub const cp_align_left = alignLeft;
pub const cp_align_right = alignRight;
pub const cp_align_center = alignCenter;
pub const cp_fill_char = withFillChar;
pub const cp_print = print;
pub const cp_println = println;
pub const cp_to_string = toString;

// ============================================================================
// Internal helpers
// ============================================================================

/// Reset pending format options to defaults.
fn reset_pending(b: *CPrintBuilder) void {
    b.pending = .{};
}

/// Append a formatted value to the buffer, applying pending format options.
/// After appending, pending options are reset.
fn append_formatted(b: *CPrintBuilder, value_str: []const u8) void {
    var output_buf: [2048]u8 = undefined;
    var output_writer: std.Io.Writer = .fixed(&output_buf);

    const has_styling = (b.pending.text_color != .reset or
        b.pending.bg_color != .reset or
        b.pending.style != .reset);

    // Write ANSI prefix if needed
    if (has_styling) {
        ansi_codes.apply_ansi_codes(&output_writer, b.pending.text_color, b.pending.bg_color, b.pending.style) catch return;
    }

    // Write value with alignment if needed
    if (b.pending.text_align != .none and b.pending.align_width > 0) {
        text_alignment.print_aligned(&output_writer, value_str, b.pending.text_align, b.pending.align_width, b.pending.fill_char) catch return;
    } else {
        output_writer.writeAll(value_str) catch return;
    }

    // Write ANSI reset if needed
    if (has_styling) {
        ansi_codes.reset_ansi_codes(&output_writer) catch return;
    }

    // Append to main buffer
    const output = output_writer.buffered();
    b.buffer.appendSlice(output) catch {};

    // Reset pending options
    reset_pending(b);
}

/// Format an integer with sign and padding options.
fn format_int_with_options(writer: *std.Io.Writer, val: i32, opts: *const FormatOptions) !void {
    // Determine sign
    var sign_str: []const u8 = "";
    var sign_buf: [1]u8 = undefined;
    if (opts.show_sign) {
        if (val >= 0) {
            sign_buf[0] = '+';
            sign_str = sign_buf[0..1];
        } else {
            sign_buf[0] = '-';
            sign_str = sign_buf[0..1];
        }
    } else {
        if (val < 0) {
            sign_buf[0] = '-';
            sign_str = sign_buf[0..1];
        }
    }

    // Format the absolute value
    var num_buf: [32]u8 = undefined;
    var num_writer: std.Io.Writer = .fixed(&num_buf);

    if (opts.has_separator) {
        try number_formatter.format_separated(&num_writer, @intCast(val), opts.separator);
    } else {
        try num_writer.print("{d}", .{val});
    }

    const num_str = num_writer.buffered();

    // Handle sign separately for padding
    var effective_num = num_str;
    if (val < 0 and num_str.len > 0 and num_str[0] == '-') {
        effective_num = num_str[1..];
    }

    const total_content_len = sign_str.len + effective_num.len;

    if (opts.padding > total_content_len) {
        const pad_count = opts.padding - total_content_len;
        if (opts.zero_pad) {
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

/// Print a float with a specific precision.
fn print_float_with_precision(writer: *std.Io.Writer, val: f64, prec: u32) !void {
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
// Text function (no formatting applied)
// ============================================================================

/// Append literal text to the buffer without any formatting.
pub fn appendText(b: *CPrintBuilder, text: []const u8) *CPrintBuilder {
    b.buffer.appendSlice(text) catch {};
    return b;
}

// ============================================================================
// Value setter functions (type-safe)
// ============================================================================

/// Append a formatted string value.
pub fn append(b: *CPrintBuilder, s: []const u8) *CPrintBuilder {
    append_formatted(b, s);
    return b;
}

/// Append a formatted signed 32-bit integer.
pub fn appendInt(b: *CPrintBuilder, i: i32) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    if (b.pending.has_separator or b.pending.show_sign or b.pending.padding > 0) {
        format_int_with_options(&val_writer, i, &b.pending) catch {};
    } else {
        val_writer.print("{d}", .{i}) catch {};
    }

    const val_str = val_writer.buffered();
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted unsigned 32-bit integer.
pub fn appendUint(b: *CPrintBuilder, u: u32) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    if (b.pending.has_separator) {
        number_formatter.format_separated(&val_writer, @intCast(u), b.pending.separator) catch {};
    } else {
        val_writer.print("{d}", .{u}) catch {};
    }

    const val_str = val_writer.buffered();
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted signed 64-bit integer.
pub fn appendLong(b: *CPrintBuilder, l: i64) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    if (b.pending.has_separator) {
        number_formatter.format_separated(&val_writer, l, b.pending.separator) catch {};
    } else {
        val_writer.print("{d}", .{l}) catch {};
    }

    const val_str = val_writer.buffered();
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted unsigned 64-bit integer.
pub fn appendUlong(b: *CPrintBuilder, ul: u64) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    if (b.pending.has_separator) {
        number_formatter.format_separated(&val_writer, @intCast(ul), b.pending.separator) catch {};
    } else {
        val_writer.print("{d}", .{ul}) catch {};
    }

    const val_str = val_writer.buffered();
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted 64-bit float.
pub fn appendFloat(b: *CPrintBuilder, f: f64) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    var value = f;
    if (b.pending.as_percentage) {
        value *= 100.0;
    }

    if (b.pending.has_precision) {
        print_float_with_precision(&val_writer, value, b.pending.precision) catch {};
    } else {
        val_writer.print("{d}", .{value}) catch {};
    }

    if (b.pending.as_percentage) {
        val_writer.writeByte('%') catch {};
    }

    // Apply separator to the integer part if needed
    var final_buf: [256]u8 = undefined;
    var final_writer: std.Io.Writer = .fixed(&final_buf);
    const val_str = val_writer.buffered();

    if (b.pending.has_separator and b.pending.separator != 0) {
        // Find decimal point
        if (std.mem.indexOfScalar(u8, val_str, '.')) |dot_pos| {
            // Parse integer part and format with separator
            const int_part = std.fmt.parseInt(i64, val_str[0..dot_pos], 10) catch 0;
            number_formatter.format_separated(&final_writer, int_part, b.pending.separator) catch {};
            // Append decimal and fractional part
            final_writer.writeAll(val_str[dot_pos..]) catch {};
        } else {
            // No decimal point, just format the whole thing
            const int_val = std.fmt.parseInt(i64, val_str, 10) catch 0;
            number_formatter.format_separated(&final_writer, int_val, b.pending.separator) catch {};
        }
    } else {
        final_writer.writeAll(val_str) catch {};
    }

    append_formatted(b, final_writer.buffered());
    return b;
}

/// Append a formatted character.
pub fn appendChar(b: *CPrintBuilder, c: u8) *CPrintBuilder {
    var val_buf: [2]u8 = .{ c, 0 };
    const val_str = val_buf[0..1];
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted boolean.
pub fn appendBool(b: *CPrintBuilder, bl: bool) *CPrintBuilder {
    const val_str: []const u8 = if (bl) "true" else "false";
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted binary value.
pub fn appendBinary(b: *CPrintBuilder, bin: u64) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    number_formatter.format_binary(&val_writer, bin, b.pending.show_prefix) catch {};

    const val_str = val_writer.buffered();
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted hexadecimal value.
pub fn appendHex(b: *CPrintBuilder, h: u64) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    number_formatter.format_hex(&val_writer, h, b.pending.show_prefix, b.pending.padding, b.pending.zero_pad) catch {};

    const val_str = val_writer.buffered();
    append_formatted(b, val_str);
    return b;
}

/// Append a formatted octal value.
pub fn appendOctal(b: *CPrintBuilder, o: u64) *CPrintBuilder {
    var val_buf: [256]u8 = undefined;
    var val_writer: std.Io.Writer = .fixed(&val_buf);

    number_formatter.format_octal(&val_writer, o, b.pending.show_prefix) catch {};

    const val_str = val_writer.buffered();
    append_formatted(b, val_str);
    return b;
}

// ============================================================================
// Formatting configuration functions
// ============================================================================

/// Set the text color for the next value.
pub fn withColor(b: *CPrintBuilder, color: TextColor) *CPrintBuilder {
    b.pending.text_color = color;
    return b;
}

/// Set the text color by name for the next value.
pub fn withColorName(b: *CPrintBuilder, color_name: []const u8) *CPrintBuilder {
    b.pending.text_color = color_parser.parse_text_color(color_name);
    return b;
}

/// Set the background color for the next value.
pub fn withBgColor(b: *CPrintBuilder, bg: BackgroundColor) *CPrintBuilder {
    b.pending.bg_color = bg;
    return b;
}

/// Set the background color by name for the next value.
pub fn withBgColorName(b: *CPrintBuilder, bg_name: []const u8) *CPrintBuilder {
    b.pending.bg_color = color_parser.parse_bg_color(bg_name);
    return b;
}

/// Set the text style for the next value.
pub fn withStyle(b: *CPrintBuilder, style: TextStyle) *CPrintBuilder {
    b.pending.style = style;
    return b;
}

/// Set the text style by name for the next value.
pub fn withStyleName(b: *CPrintBuilder, style_name: []const u8) *CPrintBuilder {
    b.pending.style = color_parser.parse_text_style(style_name);
    return b;
}

/// Set the decimal precision for the next float value.
pub fn withPrecision(b: *CPrintBuilder, precision: u32) *CPrintBuilder {
    b.pending.precision = precision;
    b.pending.has_precision = true;
    return b;
}

/// Enable zero padding for the next numeric value.
pub fn withZeroPad(b: *CPrintBuilder) *CPrintBuilder {
    b.pending.zero_pad = true;
    return b;
}

/// Set the padding width for the next numeric value.
pub fn withPad(b: *CPrintBuilder, width: u32) *CPrintBuilder {
    b.pending.padding = width;
    return b;
}

/// Set the thousands separator for the next numeric value.
pub fn withSeparator(b: *CPrintBuilder, sep: u8) *CPrintBuilder {
    b.pending.separator = sep;
    b.pending.has_separator = true;
    return b;
}

/// Show the numeric base prefix (0b, 0x, 0o) for the next value.
pub fn withPrefix(b: *CPrintBuilder) *CPrintBuilder {
    b.pending.show_prefix = true;
    return b;
}

/// Always show the sign (+/-) for the next numeric value.
pub fn withSign(b: *CPrintBuilder) *CPrintBuilder {
    b.pending.show_sign = true;
    return b;
}

/// Format the next float value as a percentage.
pub fn asPercentage(b: *CPrintBuilder) *CPrintBuilder {
    b.pending.as_percentage = true;
    return b;
}

/// Left-align the next value with the given width.
pub fn alignLeft(b: *CPrintBuilder, width: u32) *CPrintBuilder {
    b.pending.text_align = .left;
    b.pending.align_width = width;
    return b;
}

/// Right-align the next value with the given width.
pub fn alignRight(b: *CPrintBuilder, width: u32) *CPrintBuilder {
    b.pending.text_align = .right;
    b.pending.align_width = width;
    return b;
}

/// Center-align the next value with the given width.
pub fn alignCenter(b: *CPrintBuilder, width: u32) *CPrintBuilder {
    b.pending.text_align = .center;
    b.pending.align_width = width;
    return b;
}

/// Set the fill character for alignment.
pub fn withFillChar(b: *CPrintBuilder, fill: u8) *CPrintBuilder {
    b.pending.fill_char = fill;
    return b;
}

// ============================================================================
// Output functions
// ============================================================================

/// Write the buffer contents to stdout.
pub fn print(b: *CPrintBuilder) !void {
    // Use debug.print as a workaround for stdout in Zig 0.16.0
    // This writes to stderr but serves the purpose
    std.debug.print("{s}", .{b.buffer.items});
}

/// Write the buffer contents to stdout followed by a newline.
pub fn println(b: *CPrintBuilder) !void {
    std.debug.print("{s}\n", .{b.buffer.items});
}

/// Return an allocated copy of the buffer contents.
/// Caller owns the returned memory and must free it.
pub fn toString(b: *CPrintBuilder) ![]u8 {
    const result = try b.allocator.alloc(u8, b.buffer.items.len);
    @memcpy(result, b.buffer.items);
    return result;
}

// ============================================================================
// Tests
// ============================================================================

test "cp_new creates empty builder" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    try std.testing.expectEqual(@as(usize, 0), b.buffer.items.len);
}

test "appendText appends literal text" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendText(&b, "Hello");
    _ = appendText(&b, " World");

    try std.testing.expectEqualStrings("Hello World", b.buffer.items);
}

test "append appends string value" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(&b, "test");

    try std.testing.expectEqualStrings("test", b.buffer.items);
}

test "appendInt appends integer" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(&b, 42);

    try std.testing.expectEqualStrings("42", b.buffer.items);
}

test "appendInt negative" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(&b, -123);

    try std.testing.expectEqualStrings("-123", b.buffer.items);
}

test "appendUint appends unsigned integer" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendUint(&b, 999);

    try std.testing.expectEqualStrings("999", b.buffer.items);
}

test "appendLong appends 64-bit integer" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendLong(&b, 1234567890);

    try std.testing.expectEqualStrings("1234567890", b.buffer.items);
}

test "appendUlong appends unsigned 64-bit integer" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendUlong(&b, 9876543210);

    try std.testing.expectEqualStrings("9876543210", b.buffer.items);
}

test "appendFloat appends float" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendFloat(&b, 3.14);

    try std.testing.expectEqualStrings("3.14", b.buffer.items);
}

test "appendFloat with precision" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendFloat(withPrecision(&b, 2), 3.14159);

    try std.testing.expectEqualStrings("3.14", b.buffer.items);
}

test "appendChar appends character" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendChar(&b, 'A');

    try std.testing.expectEqualStrings("A", b.buffer.items);
}

test "appendBool true" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendBool(&b, true);

    try std.testing.expectEqualStrings("true", b.buffer.items);
}

test "appendBool false" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendBool(&b, false);

    try std.testing.expectEqualStrings("false", b.buffer.items);
}

test "appendBinary without prefix" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendBinary(&b, 5);

    try std.testing.expectEqualStrings("101", b.buffer.items);
}

test "appendBinary with prefix" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendBinary(withPrefix(&b), 5);

    try std.testing.expectEqualStrings("0b101", b.buffer.items);
}

test "appendHex without prefix" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendHex(&b, 255);

    try std.testing.expectEqualStrings("ff", b.buffer.items);
}

test "appendHex with prefix" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendHex(withPrefix(&b), 255);

    try std.testing.expectEqualStrings("0xff", b.buffer.items);
}

test "appendOctal without prefix" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendOctal(&b, 8);

    try std.testing.expectEqualStrings("10", b.buffer.items);
}

test "appendOctal with prefix" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendOctal(withPrefix(&b), 8);

    try std.testing.expectEqualStrings("0o10", b.buffer.items);
}

test "withColor applies text color" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withColor(&b, .red), "Hi");

    try std.testing.expectEqualStrings("\x1b[31mHi\x1b[0m", b.buffer.items);
}

test "withColorName applies text color by name" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withColorName(&b, "green"), "OK");

    try std.testing.expectEqualStrings("\x1b[32mOK\x1b[0m", b.buffer.items);
}

test "withBgColor applies background color" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withBgColor(&b, .blue), "X");

    try std.testing.expectEqualStrings("\x1b[44mX\x1b[0m", b.buffer.items);
}

test "withBgColorName applies background color by name" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withBgColorName(&b, "bg_yellow"), "Y");

    try std.testing.expectEqualStrings("\x1b[43mY\x1b[0m", b.buffer.items);
}

test "withStyle applies text style" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withStyle(&b, .bold), "B");

    try std.testing.expectEqualStrings("\x1b[1mB\x1b[0m", b.buffer.items);
}

test "withStyleName applies text style by name" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withStyleName(&b, "italic"), "I");

    try std.testing.expectEqualStrings("\x1b[3mI\x1b[0m", b.buffer.items);
}

test "withColor and withStyle combined" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withStyle(withColor(&b, .cyan), .bold), "A");

    try std.testing.expectEqualStrings("\x1b[1;36mA\x1b[0m", b.buffer.items);
}

test "withSeparator with comma" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(withSeparator(&b, ','), 1234567);

    try std.testing.expectEqualStrings("1,234,567", b.buffer.items);
}

test "withSeparator with underscore" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendLong(withSeparator(&b, '_'), 1234567);

    try std.testing.expectEqualStrings("1_234_567", b.buffer.items);
}

test "withPad with space padding" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(withPad(&b, 5), 42);

    try std.testing.expectEqualStrings("   42", b.buffer.items);
}

test "withZeroPad with withPad" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(withPad(withZeroPad(&b), 5), 42);

    try std.testing.expectEqualStrings("00042", b.buffer.items);
}

test "withSign positive" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(withSign(&b), 42);

    try std.testing.expectEqualStrings("+42", b.buffer.items);
}

test "withSign negative" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(withSign(&b), -42);

    try std.testing.expectEqualStrings("-42", b.buffer.items);
}

test "asPercentage" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendFloat(asPercentage(&b), 0.85);

    try std.testing.expectEqualStrings("85%", b.buffer.items);
}

test "asPercentage with precision" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendFloat(withPrecision(asPercentage(&b), 1), 0.856);

    try std.testing.expectEqualStrings("85.6%", b.buffer.items);
}

test "alignLeft" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(alignLeft(&b, 10), "Hi");

    try std.testing.expectEqualStrings("Hi        ", b.buffer.items);
}

test "alignRight" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(alignRight(&b, 10), "Hi");

    try std.testing.expectEqualStrings("        Hi", b.buffer.items);
}

test "alignCenter" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(alignCenter(&b, 10), "Hi");

    try std.testing.expectEqualStrings("    Hi    ", b.buffer.items);
}

test "withFillChar with center alignment" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withFillChar(alignCenter(&b, 10), '*'), "Hi");

    try std.testing.expectEqualStrings("****Hi****", b.buffer.items);
}

test "chaining multiple format options" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(withSign(withSeparator(withPad(&b, 10), ',')), 1234567);

    // +1,234,567 is exactly 10 chars, matches padding width
    try std.testing.expectEqualStrings("+1,234,567", b.buffer.items);
}

test "cp_reset clears buffer and pending" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendText(&b, "Hello");
    _ = withColor(&b, .red);
    try std.testing.expectEqual(@as(usize, 5), b.buffer.items.len);

    cp_reset(&b);

    try std.testing.expectEqual(@as(usize, 0), b.buffer.items.len);
    try std.testing.expectEqual(TextColor.reset, b.pending.text_color);

    // Can reuse after reset
    _ = appendText(&b, "World");
    try std.testing.expectEqualStrings("World", b.buffer.items);
}

test "toString returns allocated copy" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendText(&b, "test");

    const str = try toString(&b);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("test", str);
    // Verify it's a copy (different pointer)
    try std.testing.expect(str.ptr != b.buffer.items.ptr);
}

test "mixed text and formatted values" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendText(&b, "Name: ");
    _ = append(withColor(&b, .cyan), "Alice");
    _ = appendText(&b, ", Age: ");
    _ = appendInt(withColor(&b, .yellow), 30);

    try std.testing.expectEqualStrings("Name: \x1b[36mAlice\x1b[0m, Age: \x1b[33m30\x1b[0m", b.buffer.items);
}

test "pending options reset after value" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    // First value with color
    _ = append(withColor(&b, .red), "A");
    // Second value should not have color
    _ = append(&b, "B");

    try std.testing.expectEqualStrings("\x1b[31mA\x1b[0mB", b.buffer.items);
}

test "empty builder toString" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    const str = try toString(&b);
    defer allocator.free(str);

    try std.testing.expectEqual(@as(usize, 0), str.len);
}

test "appendInt zero" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(&b, 0);

    try std.testing.expectEqualStrings("0", b.buffer.items);
}

test "append empty string" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(&b, "");

    try std.testing.expectEqualStrings("", b.buffer.items);
}

test "complex chaining example" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendText(&b, "Price: $");
    _ = appendFloat(
        withSeparator(
            withPrecision(
                withColorName(&b, "green"),
                2,
            ),
            ',',
        ),
        9999.99,
    );

    try std.testing.expectEqualStrings("Price: $\x1b[32m9,999.99\x1b[0m", b.buffer.items);
}

test "appendHex with padding" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendHex(withPad(withZeroPad(&b), 4), 255);

    try std.testing.expectEqualStrings("00ff", b.buffer.items);
}

test "appendBinary 255" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendBinary(&b, 255);

    try std.testing.expectEqualStrings("11111111", b.buffer.items);
}

test "appendOctal 511 with prefix" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendOctal(withPrefix(&b), 511);

    try std.testing.expectEqualStrings("0o777", b.buffer.items);
}

test "alignment with color" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = append(withColor(alignLeft(&b, 5), .red), "Hi");

    try std.testing.expectEqualStrings("\x1b[31mHi   \x1b[0m", b.buffer.items);
}

test "multiple values with different formatting" {
    const allocator = std.testing.allocator;
    var b = cp_new(allocator);
    defer cp_free(&b);

    _ = appendInt(withColor(&b, .red), 1);
    _ = appendText(&b, " ");
    _ = appendInt(withColor(&b, .green), 2);
    _ = appendText(&b, " ");
    _ = appendInt(withColor(&b, .blue), 3);

    try std.testing.expectEqualStrings("\x1b[31m1\x1b[0m \x1b[32m2\x1b[0m \x1b[34m3\x1b[0m", b.buffer.items);
}
