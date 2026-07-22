const std = @import("std");
const ansi_codes = @import("ansi_codes.zig");

const TextColor = ansi_codes.TextColor;
const BackgroundColor = ansi_codes.BackgroundColor;
const TextStyle = ansi_codes.TextStyle;

/// Parse a text color name string into a TextColor enum value.
/// Case-insensitive. Returns .reset for empty or unrecognized input.
pub fn parse_text_color(color: []const u8) TextColor {
    if (color.len == 0) return .reset;

    if (std.ascii.eqlIgnoreCase(color, "black")) return .black;
    if (std.ascii.eqlIgnoreCase(color, "red")) return .red;
    if (std.ascii.eqlIgnoreCase(color, "green")) return .green;
    if (std.ascii.eqlIgnoreCase(color, "yellow")) return .yellow;
    if (std.ascii.eqlIgnoreCase(color, "blue")) return .blue;
    if (std.ascii.eqlIgnoreCase(color, "magenta")) return .magenta;
    if (std.ascii.eqlIgnoreCase(color, "cyan")) return .cyan;
    if (std.ascii.eqlIgnoreCase(color, "white")) return .white;

    if (std.ascii.eqlIgnoreCase(color, "bright_black")) return .bright_black;
    if (std.ascii.eqlIgnoreCase(color, "bright_red")) return .bright_red;
    if (std.ascii.eqlIgnoreCase(color, "bright_green")) return .bright_green;
    if (std.ascii.eqlIgnoreCase(color, "bright_yellow")) return .bright_yellow;
    if (std.ascii.eqlIgnoreCase(color, "bright_blue")) return .bright_blue;
    if (std.ascii.eqlIgnoreCase(color, "bright_magenta")) return .bright_magenta;
    if (std.ascii.eqlIgnoreCase(color, "bright_cyan")) return .bright_cyan;
    if (std.ascii.eqlIgnoreCase(color, "bright_white")) return .bright_white;

    return .reset;
}

/// Parse a background color name string into a BackgroundColor enum value.
/// Strips "bg_" prefix if present. Case-insensitive.
/// Returns .reset for empty or unrecognized input.
pub fn parse_bg_color(color: []const u8) BackgroundColor {
    if (color.len == 0) return .reset;

    // Strip "bg_" prefix if present (case-insensitive)
    const color_name = strip_bg_prefix(color);

    if (std.ascii.eqlIgnoreCase(color_name, "black")) return .black;
    if (std.ascii.eqlIgnoreCase(color_name, "red")) return .red;
    if (std.ascii.eqlIgnoreCase(color_name, "green")) return .green;
    if (std.ascii.eqlIgnoreCase(color_name, "yellow")) return .yellow;
    if (std.ascii.eqlIgnoreCase(color_name, "blue")) return .blue;
    if (std.ascii.eqlIgnoreCase(color_name, "magenta")) return .magenta;
    if (std.ascii.eqlIgnoreCase(color_name, "cyan")) return .cyan;
    if (std.ascii.eqlIgnoreCase(color_name, "white")) return .white;

    if (std.ascii.eqlIgnoreCase(color_name, "bright_black")) return .bright_black;
    if (std.ascii.eqlIgnoreCase(color_name, "bright_red")) return .bright_red;
    if (std.ascii.eqlIgnoreCase(color_name, "bright_green")) return .bright_green;
    if (std.ascii.eqlIgnoreCase(color_name, "bright_yellow")) return .bright_yellow;
    if (std.ascii.eqlIgnoreCase(color_name, "bright_blue")) return .bright_blue;
    if (std.ascii.eqlIgnoreCase(color_name, "bright_magenta")) return .bright_magenta;
    if (std.ascii.eqlIgnoreCase(color_name, "bright_cyan")) return .bright_cyan;
    if (std.ascii.eqlIgnoreCase(color_name, "bright_white")) return .bright_white;

    return .reset;
}

/// Parse a text style name string into a TextStyle enum value.
/// Case-insensitive. Returns .reset for empty or unrecognized input.
pub fn parse_text_style(style: []const u8) TextStyle {
    if (style.len == 0) return .reset;

    if (std.ascii.eqlIgnoreCase(style, "bold")) return .bold;
    if (std.ascii.eqlIgnoreCase(style, "dim")) return .dim;
    if (std.ascii.eqlIgnoreCase(style, "italic")) return .italic;
    if (std.ascii.eqlIgnoreCase(style, "underline")) return .underline;
    if (std.ascii.eqlIgnoreCase(style, "blink")) return .blink;
    if (std.ascii.eqlIgnoreCase(style, "reverse")) return .reverse;
    if (std.ascii.eqlIgnoreCase(style, "hidden")) return .hidden;
    if (std.ascii.eqlIgnoreCase(style, "strikethrough")) return .strikethrough;

    return .reset;
}

/// Check if a token represents a background color (starts with "bg_").
/// Case-insensitive. Returns false for empty input.
pub fn is_background_color(token: []const u8) bool {
    if (token.len < 3) return false;
    return std.ascii.eqlIgnoreCase(token[0..3], "bg_");
}

/// Strip the "bg_" prefix from a color string if present.
/// Returns the substring after "bg_" or the original string if no prefix.
fn strip_bg_prefix(color: []const u8) []const u8 {
    if (color.len >= 3 and std.ascii.eqlIgnoreCase(color[0..3], "bg_")) {
        return color[3..];
    }
    return color;
}

// ============================================================================
// Tests
// ============================================================================

test "parse_text_color standard colors" {
    try std.testing.expectEqual(TextColor.black, parse_text_color("black"));
    try std.testing.expectEqual(TextColor.red, parse_text_color("red"));
    try std.testing.expectEqual(TextColor.green, parse_text_color("green"));
    try std.testing.expectEqual(TextColor.yellow, parse_text_color("yellow"));
    try std.testing.expectEqual(TextColor.blue, parse_text_color("blue"));
    try std.testing.expectEqual(TextColor.magenta, parse_text_color("magenta"));
    try std.testing.expectEqual(TextColor.cyan, parse_text_color("cyan"));
    try std.testing.expectEqual(TextColor.white, parse_text_color("white"));
}

test "parse_text_color bright colors" {
    try std.testing.expectEqual(TextColor.bright_black, parse_text_color("bright_black"));
    try std.testing.expectEqual(TextColor.bright_red, parse_text_color("bright_red"));
    try std.testing.expectEqual(TextColor.bright_green, parse_text_color("bright_green"));
    try std.testing.expectEqual(TextColor.bright_yellow, parse_text_color("bright_yellow"));
    try std.testing.expectEqual(TextColor.bright_blue, parse_text_color("bright_blue"));
    try std.testing.expectEqual(TextColor.bright_magenta, parse_text_color("bright_magenta"));
    try std.testing.expectEqual(TextColor.bright_cyan, parse_text_color("bright_cyan"));
    try std.testing.expectEqual(TextColor.bright_white, parse_text_color("bright_white"));
}

test "parse_text_color case insensitive" {
    try std.testing.expectEqual(TextColor.red, parse_text_color("RED"));
    try std.testing.expectEqual(TextColor.red, parse_text_color("Red"));
    try std.testing.expectEqual(TextColor.red, parse_text_color("rEd"));
    try std.testing.expectEqual(TextColor.green, parse_text_color("GREEN"));
    try std.testing.expectEqual(TextColor.green, parse_text_color("Green"));
    try std.testing.expectEqual(TextColor.bright_blue, parse_text_color("BRIGHT_BLUE"));
    try std.testing.expectEqual(TextColor.bright_blue, parse_text_color("Bright_Blue"));
    try std.testing.expectEqual(TextColor.bright_cyan, parse_text_color("BRIGHT_CYAN"));
}

test "parse_text_color empty and invalid" {
    try std.testing.expectEqual(TextColor.reset, parse_text_color(""));
    try std.testing.expectEqual(TextColor.reset, parse_text_color("unknown"));
    try std.testing.expectEqual(TextColor.reset, parse_text_color("foo"));
    try std.testing.expectEqual(TextColor.reset, parse_text_color("bright"));
    try std.testing.expectEqual(TextColor.reset, parse_text_color("bg_red"));
}

test "parse_bg_color standard colors with bg_ prefix" {
    try std.testing.expectEqual(BackgroundColor.black, parse_bg_color("bg_black"));
    try std.testing.expectEqual(BackgroundColor.red, parse_bg_color("bg_red"));
    try std.testing.expectEqual(BackgroundColor.green, parse_bg_color("bg_green"));
    try std.testing.expectEqual(BackgroundColor.yellow, parse_bg_color("bg_yellow"));
    try std.testing.expectEqual(BackgroundColor.blue, parse_bg_color("bg_blue"));
    try std.testing.expectEqual(BackgroundColor.magenta, parse_bg_color("bg_magenta"));
    try std.testing.expectEqual(BackgroundColor.cyan, parse_bg_color("bg_cyan"));
    try std.testing.expectEqual(BackgroundColor.white, parse_bg_color("bg_white"));
}

test "parse_bg_color bright colors with bg_ prefix" {
    try std.testing.expectEqual(BackgroundColor.bright_black, parse_bg_color("bg_bright_black"));
    try std.testing.expectEqual(BackgroundColor.bright_red, parse_bg_color("bg_bright_red"));
    try std.testing.expectEqual(BackgroundColor.bright_green, parse_bg_color("bg_bright_green"));
    try std.testing.expectEqual(BackgroundColor.bright_yellow, parse_bg_color("bg_bright_yellow"));
    try std.testing.expectEqual(BackgroundColor.bright_blue, parse_bg_color("bg_bright_blue"));
    try std.testing.expectEqual(BackgroundColor.bright_magenta, parse_bg_color("bg_bright_magenta"));
    try std.testing.expectEqual(BackgroundColor.bright_cyan, parse_bg_color("bg_bright_cyan"));
    try std.testing.expectEqual(BackgroundColor.bright_white, parse_bg_color("bg_bright_white"));
}

test "parse_bg_color without bg_ prefix" {
    try std.testing.expectEqual(BackgroundColor.red, parse_bg_color("red"));
    try std.testing.expectEqual(BackgroundColor.green, parse_bg_color("green"));
    try std.testing.expectEqual(BackgroundColor.bright_blue, parse_bg_color("bright_blue"));
}

test "parse_bg_color case insensitive" {
    try std.testing.expectEqual(BackgroundColor.red, parse_bg_color("BG_RED"));
    try std.testing.expectEqual(BackgroundColor.red, parse_bg_color("Bg_Red"));
    try std.testing.expectEqual(BackgroundColor.red, parse_bg_color("bg_Red"));
    try std.testing.expectEqual(BackgroundColor.green, parse_bg_color("BG_GREEN"));
    try std.testing.expectEqual(BackgroundColor.bright_cyan, parse_bg_color("BG_BRIGHT_CYAN"));
    try std.testing.expectEqual(BackgroundColor.bright_cyan, parse_bg_color("Bg_Bright_Cyan"));
}

test "parse_bg_color empty and invalid" {
    try std.testing.expectEqual(BackgroundColor.reset, parse_bg_color(""));
    try std.testing.expectEqual(BackgroundColor.reset, parse_bg_color("bg_unknown"));
    try std.testing.expectEqual(BackgroundColor.reset, parse_bg_color("unknown"));
    try std.testing.expectEqual(BackgroundColor.reset, parse_bg_color("bg_"));
    try std.testing.expectEqual(BackgroundColor.reset, parse_bg_color("bold"));
}

test "parse_text_style all styles" {
    try std.testing.expectEqual(TextStyle.bold, parse_text_style("bold"));
    try std.testing.expectEqual(TextStyle.dim, parse_text_style("dim"));
    try std.testing.expectEqual(TextStyle.italic, parse_text_style("italic"));
    try std.testing.expectEqual(TextStyle.underline, parse_text_style("underline"));
    try std.testing.expectEqual(TextStyle.blink, parse_text_style("blink"));
    try std.testing.expectEqual(TextStyle.reverse, parse_text_style("reverse"));
    try std.testing.expectEqual(TextStyle.hidden, parse_text_style("hidden"));
    try std.testing.expectEqual(TextStyle.strikethrough, parse_text_style("strikethrough"));
}

test "parse_text_style case insensitive" {
    try std.testing.expectEqual(TextStyle.bold, parse_text_style("BOLD"));
    try std.testing.expectEqual(TextStyle.bold, parse_text_style("Bold"));
    try std.testing.expectEqual(TextStyle.italic, parse_text_style("ITALIC"));
    try std.testing.expectEqual(TextStyle.italic, parse_text_style("Italic"));
    try std.testing.expectEqual(TextStyle.underline, parse_text_style("UNDERLINE"));
    try std.testing.expectEqual(TextStyle.strikethrough, parse_text_style("STRIKETHROUGH"));
    try std.testing.expectEqual(TextStyle.strikethrough, parse_text_style("Strikethrough"));
}

test "parse_text_style empty and invalid" {
    try std.testing.expectEqual(TextStyle.reset, parse_text_style(""));
    try std.testing.expectEqual(TextStyle.reset, parse_text_style("unknown"));
    try std.testing.expectEqual(TextStyle.reset, parse_text_style("red"));
    try std.testing.expectEqual(TextStyle.reset, parse_text_style("bg_bold"));
}

test "is_background_color with bg_ prefix" {
    try std.testing.expect(is_background_color("bg_red"));
    try std.testing.expect(is_background_color("bg_green"));
    try std.testing.expect(is_background_color("bg_bright_blue"));
    try std.testing.expect(is_background_color("bg_"));
}

test "is_background_color case insensitive" {
    try std.testing.expect(is_background_color("BG_RED"));
    try std.testing.expect(is_background_color("Bg_Red"));
    try std.testing.expect(is_background_color("BG_bright_CYAN"));
}

test "is_background_color without bg_ prefix" {
    try std.testing.expect(!is_background_color("red"));
    try std.testing.expect(!is_background_color("green"));
    try std.testing.expect(!is_background_color("bold"));
    try std.testing.expect(!is_background_color("bright_red"));
}

test "is_background_color empty and short" {
    try std.testing.expect(!is_background_color(""));
    try std.testing.expect(!is_background_color("b"));
    try std.testing.expect(!is_background_color("bg"));
}

test "strip_bg_prefix helper" {
    try std.testing.expectEqualStrings("red", strip_bg_prefix("bg_red"));
    try std.testing.expectEqualStrings("red", strip_bg_prefix("red"));
    try std.testing.expectEqualStrings("bright_blue", strip_bg_prefix("bg_bright_blue"));
    try std.testing.expectEqualStrings("bright_blue", strip_bg_prefix("bright_blue"));
    try std.testing.expectEqualStrings("", strip_bg_prefix("bg_"));
    try std.testing.expectEqualStrings("RED", strip_bg_prefix("BG_RED")[0..3]);
}
