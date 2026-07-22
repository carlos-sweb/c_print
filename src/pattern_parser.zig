const std = @import("std");
const ansi_codes = @import("ansi_codes.zig");
const color_parser = @import("color_parser.zig");
const text_alignment = @import("text_alignment.zig");
const string_utils = @import("string_utils.zig");

const TextColor = ansi_codes.TextColor;
const BackgroundColor = ansi_codes.BackgroundColor;
const TextStyle = ansi_codes.TextStyle;
const TextAlign = text_alignment.TextAlign;
const AlignInfo = text_alignment.AlignInfo;

/// Holds all format specifications parsed from a pattern like {s:red:bold:>20}
pub const PatternStyle = struct {
    format_type: u8, // 's', 'd', 'f', 'b', 'x', 'o', 'u', 'l', 'c', 'i' (0 if none)
    text_color: TextColor,
    bg_color: BackgroundColor,
    style: TextStyle,
    has_color: bool,
    has_bg: bool,
    has_style: bool,
    text_align: TextAlign,
    width: u32,
    has_alignment: bool,
    fill_char: u8,
    precision: u32, // Precision for floats (.2, .4)
    has_precision: bool,
    padding: u32, // Padding width (05, 10)
    zero_pad: bool, // If padding is with zeros
    separator: u8, // Thousands separator (',' or '_')
    has_separator: bool,
    show_prefix: bool, // Show prefix (0b, 0x, 0o)
    show_sign: u8, // 0=none, 1=always show (+), 2=space for sign
    truncate: bool, // Truncate strings
    has_truncate: bool,
    as_percentage: bool, // Show as percentage
};

/// Parse a format pattern like "{s:red:bold:>20}" and extract formatting information.
/// Returns false if pattern doesn't start with '{' or doesn't end with '}'.
/// Returns true if a valid format_type was found.
pub fn parse_pattern(pattern: []const u8, style: *PatternStyle) bool {
    // Validate braces
    if (pattern.len < 2) return false;
    if (pattern[0] != '{') return false;
    if (pattern[pattern.len - 1] != '}') return false;

    // Extract content between braces
    const content = pattern[1 .. pattern.len - 1];
    if (content.len == 0) return false;
    if (content.len >= 200) return false;

    // Initialize style with default values
    style.* = .{
        .format_type = 0,
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
        .precision = 6, // Default precision for floats
        .has_precision = false,
        .padding = 0,
        .zero_pad = false,
        .separator = 0,
        .has_separator = false,
        .show_prefix = false,
        .show_sign = 0,
        .truncate = false,
        .has_truncate = false,
        .as_percentage = false,
    };

    // Split by ':' and process tokens
    var part: usize = 0;
    var remaining = content;

    while (remaining.len > 0) {
        const token = blk: {
            if (std.mem.indexOfScalar(u8, remaining, ':')) |idx| {
                const tok = remaining[0..idx];
                remaining = remaining[idx + 1 ..];
                break :blk tok;
            } else {
                const tok = remaining;
                remaining = "";
                break :blk tok;
            }
        };

        // Trim whitespace from token
        const trimmed = string_utils.trim_whitespace(token);

        if (trimmed.len > 0) {
            if (part == 0) {
                // First token: format type
                style.format_type = trimmed[0];
            } else {
                // Remaining tokens: specifiers
                process_specifier(trimmed, style);
            }
        }

        part += 1;
    }

    return style.format_type != 0;
}

/// Process a specifier token and update the style accordingly.
/// Checks in order: alignment, format modifier, background color, text style, text color.
fn process_specifier(token: []const u8, style: *PatternStyle) void {
    // Is it an alignment?
    var align_info: AlignInfo = undefined;
    if (text_alignment.is_alignment(token, &align_info)) {
        style.text_align = align_info.alignment;
        style.width = align_info.width;
        style.fill_char = align_info.fill_char;
        style.has_alignment = true;
        return;
    }

    // Is it a format modifier?
    if (is_format_modifier(token, style)) {
        return;
    }

    // Is it a background color?
    if (color_parser.is_background_color(token)) {
        style.bg_color = color_parser.parse_bg_color(token);
        style.has_bg = true;
        return;
    }

    // Is it a text style?
    const parsed_style = color_parser.parse_text_style(token);
    if (parsed_style != .reset) {
        style.style = parsed_style;
        style.has_style = true;
        return;
    }

    // Must be a text color
    const parsed_color = color_parser.parse_text_color(token);
    if (parsed_color != .reset) {
        style.text_color = parsed_color;
        style.has_color = true;
        return;
    }
}

/// Detect numeric and symbolic format modifiers in a token.
/// Updates the corresponding fields in style.
/// Returns true if the token was a recognized modifier.
pub fn is_format_modifier(token: []const u8, style: *PatternStyle) bool {
    if (token.len == 0) return false;

    // Precision: ".2", ".4", etc. (optionally followed by %)
    if (token[0] == '.' and token.len > 1) {
        // Find where digits end
        var digit_end: usize = 1;
        while (digit_end < token.len and token[digit_end] >= '0' and token[digit_end] <= '9') : (digit_end += 1) {}
        if (digit_end > 1) {
            style.precision = std.fmt.parseInt(u32, token[1..digit_end], 10) catch return false;
            style.has_precision = true;
            // Check if followed by %
            if (digit_end < token.len and token[digit_end] == '%') {
                style.as_percentage = true;
            }
            return true;
        }
    }

    // Zero padding: "05", "08", etc.
    if (token[0] == '0' and token.len > 1 and text_alignment.is_all_digits(token[1..])) {
        style.padding = std.fmt.parseInt(u32, token[1..], 10) catch return false;
        style.zero_pad = true;
        return true;
    }

    // Space padding: "5", "10", etc. (starts with non-zero digit)
    if (token[0] >= '1' and token[0] <= '9' and text_alignment.is_all_digits(token)) {
        style.padding = std.fmt.parseInt(u32, token, 10) catch return false;
        style.zero_pad = false;
        return true;
    }

    // Thousands separator: ","
    if (std.mem.eql(u8, token, ",")) {
        style.separator = ',';
        style.has_separator = true;
        return true;
    }

    // Thousands separator: "_"
    if (std.mem.eql(u8, token, "_")) {
        style.separator = '_';
        style.has_separator = true;
        return true;
    }

    // Show prefix: "#"
    if (std.mem.eql(u8, token, "#")) {
        style.show_prefix = true;
        return true;
    }

    // Show sign: "+"
    if (std.mem.eql(u8, token, "+")) {
        style.show_sign = 1;
        return true;
    }

    // Space for sign: " "
    if (std.mem.eql(u8, token, " ")) {
        style.show_sign = 2;
        return true;
    }

    // Percentage: "%"
    if (std.mem.eql(u8, token, "%")) {
        style.as_percentage = true;
        return true;
    }

    return false;
}

// ============================================================================
// Tests
// ============================================================================

// -- Format type tests --

test "parse_pattern format type s" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s}", &style));
    try std.testing.expectEqual(@as(u8, 's'), style.format_type);
    try std.testing.expectEqual(TextColor.reset, style.text_color);
    try std.testing.expect(!style.has_color);
}

test "parse_pattern format type d" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d}", &style));
    try std.testing.expectEqual(@as(u8, 'd'), style.format_type);
}

test "parse_pattern format type i" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{i}", &style));
    try std.testing.expectEqual(@as(u8, 'i'), style.format_type);
}

test "parse_pattern format type f" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f}", &style));
    try std.testing.expectEqual(@as(u8, 'f'), style.format_type);
}

test "parse_pattern format type c" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{c}", &style));
    try std.testing.expectEqual(@as(u8, 'c'), style.format_type);
}

test "parse_pattern format type b" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{b}", &style));
    try std.testing.expectEqual(@as(u8, 'b'), style.format_type);
}

test "parse_pattern format type x" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{x}", &style));
    try std.testing.expectEqual(@as(u8, 'x'), style.format_type);
}

test "parse_pattern format type o" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{o}", &style));
    try std.testing.expectEqual(@as(u8, 'o'), style.format_type);
}

test "parse_pattern format type u" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{u}", &style));
    try std.testing.expectEqual(@as(u8, 'u'), style.format_type);
}

test "parse_pattern format type l" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{l}", &style));
    try std.testing.expectEqual(@as(u8, 'l'), style.format_type);
}

// -- Color parsing tests --

test "parse_pattern text color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:red}", &style));
    try std.testing.expectEqual(@as(u8, 's'), style.format_type);
    try std.testing.expectEqual(TextColor.red, style.text_color);
    try std.testing.expect(style.has_color);
}

test "parse_pattern bright text color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:bright_green}", &style));
    try std.testing.expectEqual(TextColor.bright_green, style.text_color);
    try std.testing.expect(style.has_color);
}

test "parse_pattern background color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:bg_blue}", &style));
    try std.testing.expectEqual(BackgroundColor.blue, style.bg_color);
    try std.testing.expect(style.has_bg);
}

test "parse_pattern bright background color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:bg_bright_red}", &style));
    try std.testing.expectEqual(BackgroundColor.bright_red, style.bg_color);
    try std.testing.expect(style.has_bg);
}

test "parse_pattern text and background color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:red:bg_blue}", &style));
    try std.testing.expectEqual(TextColor.red, style.text_color);
    try std.testing.expectEqual(BackgroundColor.blue, style.bg_color);
    try std.testing.expect(style.has_color);
    try std.testing.expect(style.has_bg);
}

// -- Style parsing tests --

test "parse_pattern bold style" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:bold}", &style));
    try std.testing.expectEqual(TextStyle.bold, style.style);
    try std.testing.expect(style.has_style);
}

test "parse_pattern italic style" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:italic}", &style));
    try std.testing.expectEqual(TextStyle.italic, style.style);
    try std.testing.expect(style.has_style);
}

test "parse_pattern underline style" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:underline}", &style));
    try std.testing.expectEqual(TextStyle.underline, style.style);
    try std.testing.expect(style.has_style);
}

test "parse_pattern all styles" {
    const styles = [_]struct { name: []const u8, expected: TextStyle }{
        .{ .name = "bold", .expected = .bold },
        .{ .name = "dim", .expected = .dim },
        .{ .name = "italic", .expected = .italic },
        .{ .name = "underline", .expected = .underline },
        .{ .name = "blink", .expected = .blink },
        .{ .name = "reverse", .expected = .reverse },
        .{ .name = "hidden", .expected = .hidden },
        .{ .name = "strikethrough", .expected = .strikethrough },
    };

    for (styles) |tc| {
        var style: PatternStyle = undefined;
        var buf: [32]u8 = undefined;
        const pattern = std.fmt.bufPrint(&buf, "{{s:{s}}}", .{tc.name}) catch unreachable;
        try std.testing.expect(parse_pattern(pattern, &style));
        try std.testing.expectEqual(tc.expected, style.style);
        try std.testing.expect(style.has_style);
    }
}

// -- Alignment tests --

test "parse_pattern left alignment" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:<20}", &style));
    try std.testing.expectEqual(TextAlign.left, style.text_align);
    try std.testing.expectEqual(@as(u32, 20), style.width);
    try std.testing.expect(style.has_alignment);
    try std.testing.expectEqual(@as(u8, ' '), style.fill_char);
}

test "parse_pattern right alignment" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:>30}", &style));
    try std.testing.expectEqual(TextAlign.right, style.text_align);
    try std.testing.expectEqual(@as(u32, 30), style.width);
    try std.testing.expect(style.has_alignment);
}

test "parse_pattern center alignment" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:^15}", &style));
    try std.testing.expectEqual(TextAlign.center, style.text_align);
    try std.testing.expectEqual(@as(u32, 15), style.width);
    try std.testing.expect(style.has_alignment);
}

test "parse_pattern center alignment with fill char" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:*^20}", &style));
    try std.testing.expectEqual(TextAlign.center, style.text_align);
    try std.testing.expectEqual(@as(u32, 20), style.width);
    try std.testing.expectEqual(@as(u8, '*'), style.fill_char);
    try std.testing.expect(style.has_alignment);
}

test "parse_pattern right alignment with fill char" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:->40}", &style));
    try std.testing.expectEqual(TextAlign.right, style.text_align);
    try std.testing.expectEqual(@as(u32, 40), style.width);
    try std.testing.expectEqual(@as(u8, '-'), style.fill_char);
    try std.testing.expect(style.has_alignment);
}

// -- Format modifier tests --

test "parse_pattern precision .2" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f:.2}", &style));
    try std.testing.expectEqual(@as(u32, 2), style.precision);
    try std.testing.expect(style.has_precision);
}

test "parse_pattern precision .4" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f:.4}", &style));
    try std.testing.expectEqual(@as(u32, 4), style.precision);
    try std.testing.expect(style.has_precision);
}

test "parse_pattern zero padding 05" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:05}", &style));
    try std.testing.expectEqual(@as(u32, 5), style.padding);
    try std.testing.expect(style.zero_pad);
}

test "parse_pattern zero padding 08" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:08}", &style));
    try std.testing.expectEqual(@as(u32, 8), style.padding);
    try std.testing.expect(style.zero_pad);
}

test "parse_pattern space padding 5" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:5}", &style));
    try std.testing.expectEqual(@as(u32, 5), style.padding);
    try std.testing.expect(!style.zero_pad);
}

test "parse_pattern space padding 10" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:10}", &style));
    try std.testing.expectEqual(@as(u32, 10), style.padding);
    try std.testing.expect(!style.zero_pad);
}

test "parse_pattern comma separator" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:,}", &style));
    try std.testing.expectEqual(@as(u8, ','), style.separator);
    try std.testing.expect(style.has_separator);
}

test "parse_pattern underscore separator" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:_}", &style));
    try std.testing.expectEqual(@as(u8, '_'), style.separator);
    try std.testing.expect(style.has_separator);
}

test "parse_pattern show prefix" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{x:#}", &style));
    try std.testing.expect(style.show_prefix);
}

test "parse_pattern show sign plus" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:+}", &style));
    try std.testing.expectEqual(@as(u8, 1), style.show_sign);
}

test "parse_pattern percentage" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f:%}", &style));
    try std.testing.expect(style.as_percentage);
}

// -- is_format_modifier direct tests --

test "is_format_modifier precision" {
    var style: PatternStyle = undefined;
    style.precision = 0;
    style.has_precision = false;
    try std.testing.expect(is_format_modifier(".2", &style));
    try std.testing.expectEqual(@as(u32, 2), style.precision);
    try std.testing.expect(style.has_precision);
}

test "is_format_modifier precision .10" {
    var style: PatternStyle = undefined;
    style.precision = 0;
    style.has_precision = false;
    try std.testing.expect(is_format_modifier(".10", &style));
    try std.testing.expectEqual(@as(u32, 10), style.precision);
    try std.testing.expect(style.has_precision);
}

test "is_format_modifier zero padding" {
    var style: PatternStyle = undefined;
    style.padding = 0;
    style.zero_pad = false;
    try std.testing.expect(is_format_modifier("05", &style));
    try std.testing.expectEqual(@as(u32, 5), style.padding);
    try std.testing.expect(style.zero_pad);
}

test "is_format_modifier space padding" {
    var style: PatternStyle = undefined;
    style.padding = 0;
    style.zero_pad = true;
    try std.testing.expect(is_format_modifier("10", &style));
    try std.testing.expectEqual(@as(u32, 10), style.padding);
    try std.testing.expect(!style.zero_pad);
}

test "is_format_modifier comma separator" {
    var style: PatternStyle = undefined;
    style.has_separator = false;
    try std.testing.expect(is_format_modifier(",", &style));
    try std.testing.expectEqual(@as(u8, ','), style.separator);
    try std.testing.expect(style.has_separator);
}

test "is_format_modifier underscore separator" {
    var style: PatternStyle = undefined;
    style.has_separator = false;
    try std.testing.expect(is_format_modifier("_", &style));
    try std.testing.expectEqual(@as(u8, '_'), style.separator);
    try std.testing.expect(style.has_separator);
}

test "is_format_modifier show prefix" {
    var style: PatternStyle = undefined;
    style.show_prefix = false;
    try std.testing.expect(is_format_modifier("#", &style));
    try std.testing.expect(style.show_prefix);
}

test "is_format_modifier show sign" {
    var style: PatternStyle = undefined;
    style.show_sign = 0;
    try std.testing.expect(is_format_modifier("+", &style));
    try std.testing.expectEqual(@as(u8, 1), style.show_sign);
}

test "is_format_modifier space for sign" {
    var style: PatternStyle = undefined;
    style.show_sign = 0;
    try std.testing.expect(is_format_modifier(" ", &style));
    try std.testing.expectEqual(@as(u8, 2), style.show_sign);
}

test "is_format_modifier percentage" {
    var style: PatternStyle = undefined;
    style.as_percentage = false;
    try std.testing.expect(is_format_modifier("%", &style));
    try std.testing.expect(style.as_percentage);
}

test "is_format_modifier empty string" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!is_format_modifier("", &style));
}

test "is_format_modifier invalid token" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!is_format_modifier("red", &style));
    try std.testing.expect(!is_format_modifier("bold", &style));
    try std.testing.expect(!is_format_modifier("abc", &style));
}

// -- Complex combination tests --

test "parse_pattern color and style" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:green:bold}", &style));
    try std.testing.expectEqual(@as(u8, 's'), style.format_type);
    try std.testing.expectEqual(TextColor.green, style.text_color);
    try std.testing.expect(style.has_color);
    try std.testing.expectEqual(TextStyle.bold, style.style);
    try std.testing.expect(style.has_style);
}

test "parse_pattern color bg and style" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:cyan:bg_black:bold}", &style));
    try std.testing.expectEqual(TextColor.cyan, style.text_color);
    try std.testing.expectEqual(BackgroundColor.black, style.bg_color);
    try std.testing.expectEqual(TextStyle.bold, style.style);
    try std.testing.expect(style.has_color);
    try std.testing.expect(style.has_bg);
    try std.testing.expect(style.has_style);
}

test "parse_pattern alignment and color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:<20:red}", &style));
    try std.testing.expectEqual(TextAlign.left, style.text_align);
    try std.testing.expectEqual(@as(u32, 20), style.width);
    try std.testing.expect(style.has_alignment);
    try std.testing.expectEqual(TextColor.red, style.text_color);
    try std.testing.expect(style.has_color);
}

test "parse_pattern float with precision and color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f:.2:green}", &style));
    try std.testing.expectEqual(@as(u8, 'f'), style.format_type);
    try std.testing.expectEqual(@as(u32, 2), style.precision);
    try std.testing.expect(style.has_precision);
    try std.testing.expectEqual(TextColor.green, style.text_color);
    try std.testing.expect(style.has_color);
}

test "parse_pattern float with precision percentage and color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f:.1%:yellow}", &style));
    try std.testing.expectEqual(@as(u8, 'f'), style.format_type);
    try std.testing.expectEqual(@as(u32, 1), style.precision);
    try std.testing.expect(style.has_precision);
    try std.testing.expect(style.as_percentage);
    try std.testing.expectEqual(TextColor.yellow, style.text_color);
}

test "parse_pattern int with separator and color" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:,}", &style));
    try std.testing.expectEqual(@as(u8, 'd'), style.format_type);
    try std.testing.expectEqual(@as(u8, ','), style.separator);
    try std.testing.expect(style.has_separator);
}

test "parse_pattern complex number formatting" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f:.2:,}", &style));
    try std.testing.expectEqual(@as(u8, 'f'), style.format_type);
    try std.testing.expectEqual(@as(u32, 2), style.precision);
    try std.testing.expect(style.has_precision);
    try std.testing.expectEqual(@as(u8, ','), style.separator);
    try std.testing.expect(style.has_separator);
}

test "parse_pattern hex with prefix and bold" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{x:#:bold}", &style));
    try std.testing.expectEqual(@as(u8, 'x'), style.format_type);
    try std.testing.expect(style.show_prefix);
    try std.testing.expectEqual(TextStyle.bold, style.style);
    try std.testing.expect(style.has_style);
}

test "parse_pattern int with zero pad and sign" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{d:05:+}", &style));
    try std.testing.expectEqual(@as(u8, 'd'), style.format_type);
    try std.testing.expectEqual(@as(u32, 5), style.padding);
    try std.testing.expect(style.zero_pad);
    try std.testing.expectEqual(@as(u8, 1), style.show_sign);
}

test "parse_pattern full complex pattern" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s:red:bg_black:bold:<20}", &style));
    try std.testing.expectEqual(@as(u8, 's'), style.format_type);
    try std.testing.expectEqual(TextColor.red, style.text_color);
    try std.testing.expectEqual(BackgroundColor.black, style.bg_color);
    try std.testing.expectEqual(TextStyle.bold, style.style);
    try std.testing.expectEqual(TextAlign.left, style.text_align);
    try std.testing.expectEqual(@as(u32, 20), style.width);
    try std.testing.expect(style.has_color);
    try std.testing.expect(style.has_bg);
    try std.testing.expect(style.has_style);
    try std.testing.expect(style.has_alignment);
}

// -- Invalid pattern tests --

test "parse_pattern missing opening brace" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!parse_pattern("s}", &style));
}

test "parse_pattern missing closing brace" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!parse_pattern("{s", &style));
}

test "parse_pattern empty pattern" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!parse_pattern("{}", &style));
}

test "parse_pattern empty string" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!parse_pattern("", &style));
}

test "parse_pattern single char" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!parse_pattern("{", &style));
}

test "parse_pattern no braces" {
    var style: PatternStyle = undefined;
    try std.testing.expect(!parse_pattern("s:red", &style));
}

// -- Default values tests --

test "parse_pattern default precision is 6" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{f}", &style));
    try std.testing.expectEqual(@as(u32, 6), style.precision);
    try std.testing.expect(!style.has_precision);
}

test "parse_pattern default fill char is space" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s}", &style));
    try std.testing.expectEqual(@as(u8, ' '), style.fill_char);
}

test "parse_pattern default values for all fields" {
    var style: PatternStyle = undefined;
    try std.testing.expect(parse_pattern("{s}", &style));
    try std.testing.expectEqual(@as(u8, 's'), style.format_type);
    try std.testing.expectEqual(TextColor.reset, style.text_color);
    try std.testing.expectEqual(BackgroundColor.reset, style.bg_color);
    try std.testing.expectEqual(TextStyle.reset, style.style);
    try std.testing.expect(!style.has_color);
    try std.testing.expect(!style.has_bg);
    try std.testing.expect(!style.has_style);
    try std.testing.expectEqual(TextAlign.none, style.text_align);
    try std.testing.expectEqual(@as(u32, 0), style.width);
    try std.testing.expect(!style.has_alignment);
    try std.testing.expectEqual(@as(u8, ' '), style.fill_char);
    try std.testing.expectEqual(@as(u32, 6), style.precision);
    try std.testing.expect(!style.has_precision);
    try std.testing.expectEqual(@as(u32, 0), style.padding);
    try std.testing.expect(!style.zero_pad);
    try std.testing.expectEqual(@as(u8, 0), style.separator);
    try std.testing.expect(!style.has_separator);
    try std.testing.expect(!style.show_prefix);
    try std.testing.expectEqual(@as(u8, 0), style.show_sign);
    try std.testing.expect(!style.truncate);
    try std.testing.expect(!style.has_truncate);
    try std.testing.expect(!style.as_percentage);
}
