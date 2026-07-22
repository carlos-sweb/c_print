const std = @import("std");

/// Format an integer with thousands separators inserted every 3 digits.
/// Handles negative numbers correctly. The separator is typically ',' or '_'.
/// Examples:
///   1234567 with ',' -> "1,234,567"
///   -1234567 with ',' -> "-1,234,567"
///   123 with ',' -> "123"
///   0 with ',' -> "0"
pub fn format_separated(writer: *std.Io.Writer, num: i64, separator: u8) !void {
    if (num == 0) {
        try writer.writeByte('0');
        return;
    }

    // Handle negative numbers
    const negative = num < 0;
    // Use unsigned arithmetic to handle i64.MIN correctly
    const abs_val: u64 = if (negative)
        @as(u64, @intCast(-(num + 1))) + 1
    else
        @intCast(num);

    // Extract digits into a buffer (reversed order)
    var digits: [20]u8 = undefined; // max 20 digits for u64
    var digit_count: usize = 0;
    var remaining = abs_val;

    while (remaining > 0) : (remaining /= 10) {
        digits[digit_count] = @intCast('0' + (remaining % 10));
        digit_count += 1;
    }

    // Write negative sign if needed
    if (negative) {
        try writer.writeByte('-');
    }

    // Write digits from most significant to least significant,
    // inserting separators every 3 digits
    const first_group = if (digit_count % 3 == 0) 3 else digit_count % 3;
    var digits_written: usize = 0;
    var i: usize = digit_count;
    while (i > 0) {
        i -= 1;

        // Insert separator before this digit if we've completed a group of 3
        if (digits_written >= first_group and (digits_written - first_group) % 3 == 0) {
            try writer.writeByte(separator);
        }

        try writer.writeByte(digits[i]);
        digits_written += 1;
    }
}

/// Format an unsigned integer as a binary string.
/// If show_prefix is true, adds "0b" prefix.
/// Examples:
///   0 with show_prefix=false -> "0"
///   0 with show_prefix=true -> "0b0"
///   5 with show_prefix=false -> "101"
///   5 with show_prefix=true -> "0b101"
pub fn format_binary(writer: *std.Io.Writer, num: u64, show_prefix: bool) !void {
    if (show_prefix) {
        try writer.writeAll("0b");
    }

    if (num == 0) {
        try writer.writeByte('0');
        return;
    }

    // Extract binary digits into a buffer (reversed order)
    var digits: [64]u8 = undefined; // max 64 bits for u64
    var digit_count: usize = 0;
    var remaining = num;

    while (remaining > 0) : (remaining >>= 1) {
        digits[digit_count] = if (remaining & 1 == 1) '1' else '0';
        digit_count += 1;
    }

    // Write digits from most significant to least significant
    var i: usize = digit_count;
    while (i > 0) {
        i -= 1;
        try writer.writeByte(digits[i]);
    }
}

/// Format an unsigned integer as a hexadecimal string (lowercase).
/// If show_prefix is true, adds "0x" prefix.
/// If padding > 0, pads to the specified width:
///   - With spaces if zero_pad is false
///   - With zeros if zero_pad is true
/// Padding includes the prefix length if show_prefix is true.
/// Examples:
///   255, show_prefix=false, padding=0, zero_pad=false -> "ff"
///   255, show_prefix=true, padding=0, zero_pad=false -> "0xff"
///   255, show_prefix=false, padding=4, zero_pad=true -> "00ff"
///   255, show_prefix=true, padding=6, zero_pad=true -> "0x00ff"
pub fn format_hex(writer: *std.Io.Writer, num: u64, show_prefix: bool, padding: u32, zero_pad: bool) !void {
    // Extract hex digits into a buffer (reversed order)
    var digits: [16]u8 = undefined; // max 16 hex digits for u64
    var digit_count: usize = 0;

    if (num == 0) {
        digits[0] = '0';
        digit_count = 1;
    } else {
        var remaining = num;
        while (remaining > 0) : (remaining >>= 4) {
            const digit_val: u8 = @intCast(remaining & 0xF);
            digits[digit_count] = hex_digit(digit_val);
            digit_count += 1;
        }
    }

    const prefix_len: u32 = if (show_prefix) 2 else 0;
    const content_len: u32 = @intCast(digit_count);
    const total_len = prefix_len + content_len;

    if (padding > total_len) {
        const pad_count = padding - total_len;
        if (zero_pad) {
            // Write prefix first, then zero-pad, then digits
            if (show_prefix) {
                try writer.writeAll("0x");
            }
            var j: u32 = 0;
            while (j < pad_count) : (j += 1) {
                try writer.writeByte('0');
            }
        } else {
            // Space padding: write spaces first, then prefix, then digits
            var j: u32 = 0;
            while (j < pad_count) : (j += 1) {
                try writer.writeByte(' ');
            }
            if (show_prefix) {
                try writer.writeAll("0x");
            }
        }
    } else {
        // No padding needed, just write prefix if needed
        if (show_prefix) {
            try writer.writeAll("0x");
        }
    }

    // Write hex digits from most significant to least significant
    var i: usize = digit_count;
    while (i > 0) {
        i -= 1;
        try writer.writeByte(digits[i]);
    }
}

/// Format an unsigned integer as an octal string.
/// If show_prefix is true, adds "0o" prefix.
/// Examples:
///   0 with show_prefix=false -> "0"
///   0 with show_prefix=true -> "0o0"
///   8 with show_prefix=false -> "10"
///   8 with show_prefix=true -> "0o10"
pub fn format_octal(writer: *std.Io.Writer, num: u64, show_prefix: bool) !void {
    if (show_prefix) {
        try writer.writeAll("0o");
    }

    if (num == 0) {
        try writer.writeByte('0');
        return;
    }

    // Extract octal digits into a buffer (reversed order)
    var digits: [22]u8 = undefined; // max 22 octal digits for u64
    var digit_count: usize = 0;
    var remaining = num;

    while (remaining > 0) : (remaining >>= 3) {
        digits[digit_count] = @intCast('0' + (remaining & 0x7));
        digit_count += 1;
    }

    // Write digits from most significant to least significant
    var i: usize = digit_count;
    while (i > 0) {
        i -= 1;
        try writer.writeByte(digits[i]);
    }
}

/// Convert a hex digit value (0-15) to its lowercase ASCII character
fn hex_digit(val: u8) u8 {
    return if (val < 10) '0' + val else 'a' + (val - 10);
}

// ============================================================================
// Tests
// ============================================================================

// -- format_separated --

test "format_separated: zero" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 0, ',');
    try std.testing.expectEqualStrings("0", writer.buffered());
}

test "format_separated: small number no separator" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 123, ',');
    try std.testing.expectEqualStrings("123", writer.buffered());
}

test "format_separated: exactly 3 digits" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 999, ',');
    try std.testing.expectEqualStrings("999", writer.buffered());
}

test "format_separated: 4 digits one separator" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 1234, ',');
    try std.testing.expectEqualStrings("1,234", writer.buffered());
}

test "format_separated: millions with comma" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 1234567, ',');
    try std.testing.expectEqualStrings("1,234,567", writer.buffered());
}

test "format_separated: negative number" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, -1234567, ',');
    try std.testing.expectEqualStrings("-1,234,567", writer.buffered());
}

test "format_separated: negative small number" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, -42, ',');
    try std.testing.expectEqualStrings("-42", writer.buffered());
}

test "format_separated: underscore separator" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 1234567, '_');
    try std.testing.expectEqualStrings("1_234_567", writer.buffered());
}

test "format_separated: single digit" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 5, ',');
    try std.testing.expectEqualStrings("5", writer.buffered());
}

test "format_separated: exactly 6 digits" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 123456, ',');
    try std.testing.expectEqualStrings("123,456", writer.buffered());
}

test "format_separated: large number" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, 1000000000, ',');
    try std.testing.expectEqualStrings("1,000,000,000", writer.buffered());
}

test "format_separated: negative one" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_separated(&writer, -1, ',');
    try std.testing.expectEqualStrings("-1", writer.buffered());
}

// -- format_binary --

test "format_binary: zero no prefix" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 0, false);
    try std.testing.expectEqualStrings("0", writer.buffered());
}

test "format_binary: zero with prefix" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 0, true);
    try std.testing.expectEqualStrings("0b0", writer.buffered());
}

test "format_binary: 5 no prefix" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 5, false);
    try std.testing.expectEqualStrings("101", writer.buffered());
}

test "format_binary: 5 with prefix" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 5, true);
    try std.testing.expectEqualStrings("0b101", writer.buffered());
}

test "format_binary: 1 no prefix" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 1, false);
    try std.testing.expectEqualStrings("1", writer.buffered());
}

test "format_binary: 255 no prefix" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 255, false);
    try std.testing.expectEqualStrings("11111111", writer.buffered());
}

test "format_binary: 255 with prefix" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 255, true);
    try std.testing.expectEqualStrings("0b11111111", writer.buffered());
}

test "format_binary: 10 decimal" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 10, false);
    try std.testing.expectEqualStrings("1010", writer.buffered());
}

test "format_binary: power of 2" {
    var buf: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_binary(&writer, 16, false);
    try std.testing.expectEqualStrings("10000", writer.buffered());
}

// -- format_hex --

test "format_hex: 255 no prefix no padding" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 255, false, 0, false);
    try std.testing.expectEqualStrings("ff", writer.buffered());
}

test "format_hex: 255 with prefix no padding" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 255, true, 0, false);
    try std.testing.expectEqualStrings("0xff", writer.buffered());
}

test "format_hex: 255 zero padded to 4" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 255, false, 4, true);
    try std.testing.expectEqualStrings("00ff", writer.buffered());
}

test "format_hex: 255 with prefix zero padded to 6" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 255, true, 6, true);
    try std.testing.expectEqualStrings("0x00ff", writer.buffered());
}

test "format_hex: zero no prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 0, false, 0, false);
    try std.testing.expectEqualStrings("0", writer.buffered());
}

test "format_hex: zero with prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 0, true, 0, false);
    try std.testing.expectEqualStrings("0x0", writer.buffered());
}

test "format_hex: zero with prefix and padding" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 0, true, 6, true);
    try std.testing.expectEqualStrings("0x0000", writer.buffered());
}

test "format_hex: space padding" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 255, false, 6, false);
    try std.testing.expectEqualStrings("    ff", writer.buffered());
}

test "format_hex: space padding with prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 255, true, 8, false);
    try std.testing.expectEqualStrings("    0xff", writer.buffered());
}

test "format_hex: 0xDEADBEEF" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 0xDEADBEEF, true, 0, false);
    try std.testing.expectEqualStrings("0xdeadbeef", writer.buffered());
}

test "format_hex: padding smaller than content" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 0xABCD, false, 2, true);
    try std.testing.expectEqualStrings("abcd", writer.buffered());
}

test "format_hex: 16 no prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 16, false, 0, false);
    try std.testing.expectEqualStrings("10", writer.buffered());
}

test "format_hex: all hex digits" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_hex(&writer, 0xABCDEF, false, 0, false);
    try std.testing.expectEqualStrings("abcdef", writer.buffered());
}

// -- format_octal --

test "format_octal: zero no prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 0, false);
    try std.testing.expectEqualStrings("0", writer.buffered());
}

test "format_octal: zero with prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 0, true);
    try std.testing.expectEqualStrings("0o0", writer.buffered());
}

test "format_octal: 8 no prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 8, false);
    try std.testing.expectEqualStrings("10", writer.buffered());
}

test "format_octal: 8 with prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 8, true);
    try std.testing.expectEqualStrings("0o10", writer.buffered());
}

test "format_octal: 7 no prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 7, false);
    try std.testing.expectEqualStrings("7", writer.buffered());
}

test "format_octal: 7 with prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 7, true);
    try std.testing.expectEqualStrings("0o7", writer.buffered());
}

test "format_octal: 64 no prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 64, false);
    try std.testing.expectEqualStrings("100", writer.buffered());
}

test "format_octal: 511 with prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 511, true);
    try std.testing.expectEqualStrings("0o777", writer.buffered());
}

test "format_octal: 255 no prefix" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try format_octal(&writer, 255, false);
    try std.testing.expectEqualStrings("377", writer.buffered());
}

// -- hex_digit helper --

test "hex_digit: 0-9" {
    try std.testing.expectEqual(@as(u8, '0'), hex_digit(0));
    try std.testing.expectEqual(@as(u8, '1'), hex_digit(1));
    try std.testing.expectEqual(@as(u8, '5'), hex_digit(5));
    try std.testing.expectEqual(@as(u8, '9'), hex_digit(9));
}

test "hex_digit: a-f" {
    try std.testing.expectEqual(@as(u8, 'a'), hex_digit(10));
    try std.testing.expectEqual(@as(u8, 'b'), hex_digit(11));
    try std.testing.expectEqual(@as(u8, 'c'), hex_digit(12));
    try std.testing.expectEqual(@as(u8, 'd'), hex_digit(13));
    try std.testing.expectEqual(@as(u8, 'e'), hex_digit(14));
    try std.testing.expectEqual(@as(u8, 'f'), hex_digit(15));
}
