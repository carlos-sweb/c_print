const std = @import("std");

/// Text alignment types
pub const TextAlign = enum {
    none,
    left, // '<'
    right, // '>'
    center, // '^'
};

/// Parsed alignment information from a token
pub const AlignInfo = struct {
    alignment: TextAlign,
    width: u32,
    fill_char: u8,
};

/// Detect if a token represents an alignment pattern.
/// Valid formats:
///   - "<20"  → left, width 20, fill ' '
///   - ">30"  → right, width 30, fill ' '
///   - "^15"  → center, width 15, fill ' '
///   - "*^20" → center, width 20, fill '*'
///   - "->40" → right, width 40, fill '-'
/// Returns true if a valid alignment was detected and populates info.
pub fn is_alignment(token: []const u8, info: *AlignInfo) bool {
    if (token.len < 2) return false;

    var fill_char: u8 = ' ';
    var offset: usize = 0;

    // Check for fill char prefix: token[1] is '<', '>', or '^'
    // Format: [fill_char]<align_char><width>
    if (token.len >= 3 and is_align_char(token[1])) {
        fill_char = token[0];
        offset = 1;
    }

    // Check alignment character
    const first = token[offset];
    if (!is_align_char(first)) return false;

    // Remaining must be a valid number (all digits, non-empty)
    const num_part = token[offset + 1 ..];
    if (num_part.len == 0) return false;
    if (!is_all_digits(num_part)) return false;

    // Parse width
    const width = std.fmt.parseInt(u32, num_part, 10) catch return false;

    const alignment: TextAlign = switch (first) {
        '<' => .left,
        '>' => .right,
        '^' => .center,
        else => .none,
    };

    info.* = .{
        .alignment = alignment,
        .width = width,
        .fill_char = fill_char,
    };
    return true;
}

/// Output text with alignment and fill characters.
/// - left: text followed by fill chars to reach width
/// - right: fill chars followed by text to reach width
/// - center: fill chars on both sides (left gets extra if odd padding)
/// - If text length >= width, just output text without padding
pub fn print_aligned(writer: *std.Io.Writer, text: []const u8, text_align: TextAlign, width: u32, fill_char: u8) !void {
    const text_len: u32 = @intCast(text.len);

    // If text is longer than or equal to width, just output text
    if (text_len >= width) {
        try writer.writeAll(text);
        return;
    }

    const padding = width - text_len;

    switch (text_align) {
        .left => {
            try writer.writeAll(text);
            try write_fill(writer, fill_char, padding);
        },
        .right => {
            try write_fill(writer, fill_char, padding);
            try writer.writeAll(text);
        },
        .center => {
            const left_pad = padding / 2;
            const right_pad = padding - left_pad;
            try write_fill(writer, fill_char, left_pad);
            try writer.writeAll(text);
            try write_fill(writer, fill_char, right_pad);
        },
        .none => {
            try writer.writeAll(text);
        },
    }
}

/// Write a fill character repeated count times
fn write_fill(writer: *std.Io.Writer, char: u8, count: u32) !void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        try writer.writeByte(char);
    }
}

/// Check if a character is an alignment symbol
fn is_align_char(c: u8) bool {
    return c == '<' or c == '>' or c == '^';
}

/// Check if a string contains only digit characters
pub fn is_all_digits(s: []const u8) bool {
    if (s.len == 0) return false;
    for (s) |c| {
        if (c < '0' or c > '9') return false;
    }
    return true;
}

// ============================================================================
// Tests
// ============================================================================

test "is_alignment simple left" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment("<20", &info));
    try std.testing.expectEqual(TextAlign.left, info.alignment);
    try std.testing.expectEqual(@as(u32, 20), info.width);
    try std.testing.expectEqual(@as(u8, ' '), info.fill_char);
}

test "is_alignment simple right" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment(">30", &info));
    try std.testing.expectEqual(TextAlign.right, info.alignment);
    try std.testing.expectEqual(@as(u32, 30), info.width);
    try std.testing.expectEqual(@as(u8, ' '), info.fill_char);
}

test "is_alignment simple center" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment("^15", &info));
    try std.testing.expectEqual(TextAlign.center, info.alignment);
    try std.testing.expectEqual(@as(u32, 15), info.width);
    try std.testing.expectEqual(@as(u8, ' '), info.fill_char);
}

test "is_alignment with fill char center" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment("*^20", &info));
    try std.testing.expectEqual(TextAlign.center, info.alignment);
    try std.testing.expectEqual(@as(u32, 20), info.width);
    try std.testing.expectEqual(@as(u8, '*'), info.fill_char);
}

test "is_alignment with fill char right" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment("->40", &info));
    try std.testing.expectEqual(TextAlign.right, info.alignment);
    try std.testing.expectEqual(@as(u32, 40), info.width);
    try std.testing.expectEqual(@as(u8, '-'), info.fill_char);
}

test "is_alignment with fill char left" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment(".<10", &info));
    try std.testing.expectEqual(TextAlign.left, info.alignment);
    try std.testing.expectEqual(@as(u32, 10), info.width);
    try std.testing.expectEqual(@as(u8, '.'), info.fill_char);
}

test "is_alignment invalid tokens" {
    var info: AlignInfo = undefined;
    // Too short
    try std.testing.expect(!is_alignment("<", &info));
    try std.testing.expect(!is_alignment("", &info));
    // No number after alignment char
    try std.testing.expect(!is_alignment("<", &info));
    try std.testing.expect(!is_alignment(">abc", &info));
    try std.testing.expect(!is_alignment("^", &info));
    // Not an alignment token
    try std.testing.expect(!is_alignment("red", &info));
    try std.testing.expect(!is_alignment("bold", &info));
    try std.testing.expect(!is_alignment("20", &info));
}

test "is_alignment single digit width" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment("<5", &info));
    try std.testing.expectEqual(TextAlign.left, info.alignment);
    try std.testing.expectEqual(@as(u32, 5), info.width);
    try std.testing.expectEqual(@as(u8, ' '), info.fill_char);
}

test "is_alignment large width" {
    var info: AlignInfo = undefined;
    try std.testing.expect(is_alignment("^1000", &info));
    try std.testing.expectEqual(TextAlign.center, info.alignment);
    try std.testing.expectEqual(@as(u32, 1000), info.width);
}

test "print_aligned left" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hello", .left, 10, ' ');
    try std.testing.expectEqualStrings("Hello     ", writer.buffered());
}

test "print_aligned right" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hello", .right, 10, ' ');
    try std.testing.expectEqualStrings("     Hello", writer.buffered());
}

test "print_aligned center" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hello", .center, 10, '*');
    try std.testing.expectEqualStrings("**Hello***", writer.buffered());
}

test "print_aligned center even padding" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hi", .center, 10, '-');
    // padding = 8, left = 4, right = 4
    try std.testing.expectEqualStrings("----Hi----", writer.buffered());
}

test "print_aligned center odd padding" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hi", .center, 9, '-');
    // padding = 7, left = 3, right = 4
    try std.testing.expectEqualStrings("---Hi----", writer.buffered());
}

test "print_aligned text longer than width" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hello World", .left, 5, ' ');
    try std.testing.expectEqualStrings("Hello World", writer.buffered());
}

test "print_aligned text equal to width" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hello", .right, 5, ' ');
    try std.testing.expectEqualStrings("Hello", writer.buffered());
}

test "print_aligned empty text" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "", .left, 5, '.');
    try std.testing.expectEqualStrings(".....", writer.buffered());
}

test "print_aligned empty text right" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "", .right, 3, '*');
    try std.testing.expectEqualStrings("***", writer.buffered());
}

test "print_aligned empty text center" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "", .center, 4, '-');
    // width = 4, empty text, center: all fill chars
    try std.testing.expectEqualStrings("----", writer.buffered());
}

test "print_aligned none alignment" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hello", .none, 10, ' ');
    try std.testing.expectEqualStrings("Hello", writer.buffered());
}

test "print_aligned left with custom fill" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hi", .left, 8, '=');
    try std.testing.expectEqualStrings("Hi======", writer.buffered());
}

test "print_aligned right with custom fill" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print_aligned(&writer, "Hi", .right, 8, '=');
    try std.testing.expectEqualStrings("======Hi", writer.buffered());
}

test "is_all_digits helper" {
    try std.testing.expect(is_all_digits("123"));
    try std.testing.expect(is_all_digits("0"));
    try std.testing.expect(is_all_digits("999"));
    try std.testing.expect(!is_all_digits(""));
    try std.testing.expect(!is_all_digits("12a"));
    try std.testing.expect(!is_all_digits("abc"));
    try std.testing.expect(!is_all_digits("12 3"));
}

test "is_align_char helper" {
    try std.testing.expect(is_align_char('<'));
    try std.testing.expect(is_align_char('>'));
    try std.testing.expect(is_align_char('^'));
    try std.testing.expect(!is_align_char('a'));
    try std.testing.expect(!is_align_char(' '));
    try std.testing.expect(!is_align_char('0'));
}
