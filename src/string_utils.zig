const std = @import("std");

/// Convert an ASCII string to lowercase.
/// Allocates a new buffer for the result. Caller owns the returned memory.
/// Non-ASCII bytes are copied unchanged.
pub fn to_lowercase(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, s.len);
    for (s, 0..) |c, i| {
        result[i] = std.ascii.toLower(c);
    }
    return result;
}

/// Returns true if the string is non-empty and consists only of ASCII digits ('0'-'9').
/// Returns false for empty strings or strings containing any non-digit character.
pub fn is_number(s: []const u8) bool {
    if (s.len == 0) return false;
    for (s) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }
    return true;
}

/// Return a sub-slice of `s` with leading and trailing whitespace removed.
/// Whitespace characters: space, tab, newline, carriage return.
/// Does not allocate; returns a slice of the original input.
pub fn trim_whitespace(s: []const u8) []const u8 {
    const start: usize = blk: {
        var i: usize = 0;
        while (i < s.len and is_whitespace(s[i])) : (i += 1) {}
        break :blk i;
    };

    if (start == s.len) return "";

    const end: usize = blk: {
        var i: usize = s.len;
        while (i > start and is_whitespace(s[i - 1])) : (i -= 1) {}
        break :blk i;
    };

    return s[start..end];
}

fn is_whitespace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r';
}

// ============================================================================
// Tests
// ============================================================================

// -- to_lowercase --

test "to_lowercase: mixed case" {
    const allocator = std.testing.allocator;
    const result = try to_lowercase(allocator, "Hello World");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("hello world", result);
}

test "to_lowercase: already lowercase" {
    const allocator = std.testing.allocator;
    const result = try to_lowercase(allocator, "already lower");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("already lower", result);
}

test "to_lowercase: all uppercase" {
    const allocator = std.testing.allocator;
    const result = try to_lowercase(allocator, "ABCDEFG");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("abcdefg", result);
}

test "to_lowercase: empty string" {
    const allocator = std.testing.allocator;
    const result = try to_lowercase(allocator, "");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("", result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "to_lowercase: digits and symbols unchanged" {
    const allocator = std.testing.allocator;
    const result = try to_lowercase(allocator, "ABC123!@#");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("abc123!@#", result);
}

test "to_lowercase: non-ASCII bytes preserved" {
    const allocator = std.testing.allocator;
    // UTF-8 encoded e-acute: 0xC3 0xA9 — both bytes are >= 0x80, not ASCII upper
    const result = try to_lowercase(allocator, "caf\xC3\xA9");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("caf\xC3\xA9", result);
}

test "to_lowercase: single character" {
    const allocator = std.testing.allocator;
    const result = try to_lowercase(allocator, "Z");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("z", result);
}

// -- is_number --

test "is_number: simple digits" {
    try std.testing.expect(is_number("12345"));
}

test "is_number: single digit" {
    try std.testing.expect(is_number("0"));
}

test "is_number: leading zeros" {
    try std.testing.expect(is_number("007"));
}

test "is_number: empty string returns false" {
    try std.testing.expect(!is_number(""));
}

test "is_number: letters return false" {
    try std.testing.expect(!is_number("123a5"));
}

test "is_number: all letters returns false" {
    try std.testing.expect(!is_number("abc"));
}

test "is_number: space returns false" {
    try std.testing.expect(!is_number("123 456"));
}

test "is_number: negative sign returns false" {
    try std.testing.expect(!is_number("-42"));
}

test "is_number: decimal point returns false" {
    try std.testing.expect(!is_number("3.14"));
}

test "is_number: plus sign returns false" {
    try std.testing.expect(!is_number("+99"));
}

test "is_number: special characters return false" {
    try std.testing.expect(!is_number("0x1F"));
}

// -- trim_whitespace --

test "trim_whitespace: leading spaces" {
    try std.testing.expectEqualStrings("hello", trim_whitespace("   hello"));
}

test "trim_whitespace: trailing spaces" {
    try std.testing.expectEqualStrings("hello", trim_whitespace("hello   "));
}

test "trim_whitespace: both sides" {
    try std.testing.expectEqualStrings("hello", trim_whitespace("  hello  "));
}

test "trim_whitespace: no whitespace" {
    try std.testing.expectEqualStrings("hello", trim_whitespace("hello"));
}

test "trim_whitespace: all whitespace" {
    try std.testing.expectEqualStrings("", trim_whitespace("     "));
}

test "trim_whitespace: empty string" {
    try std.testing.expectEqualStrings("", trim_whitespace(""));
}

test "trim_whitespace: tabs and newlines" {
    try std.testing.expectEqualStrings("content", trim_whitespace("\t\ncontent\r\n"));
}

test "trim_whitespace: mixed whitespace" {
    try std.testing.expectEqualStrings("data", trim_whitespace(" \t\r\n data \t\r\n"));
}

test "trim_whitespace: internal whitespace preserved" {
    try std.testing.expectEqualStrings("hello world", trim_whitespace("  hello world  "));
}

test "trim_whitespace: single non-whitespace character" {
    try std.testing.expectEqualStrings("x", trim_whitespace("  x  "));
}

test "trim_whitespace: returns slice of original" {
    const original = "  trimmed  ";
    const result = trim_whitespace(original);
    // Verify it's a sub-slice (pointer within original)
    try std.testing.expect(@intFromPtr(result.ptr) >= @intFromPtr(original.ptr));
    try std.testing.expect(@intFromPtr(result.ptr) < @intFromPtr(original.ptr) + original.len);
}

test "trim_whitespace: only tabs" {
    try std.testing.expectEqualStrings("", trim_whitespace("\t\t\t"));
}

test "trim_whitespace: only newlines" {
    try std.testing.expectEqualStrings("", trim_whitespace("\n\n"));
}

test "trim_whitespace: whitespace between non-whitespace preserved" {
    try std.testing.expectEqualStrings("a b", trim_whitespace(" a b "));
}
