/// c_print - ANSI-colored console formatting library
pub const ansi_codes = @import("ansi_codes.zig");
pub const color_parser = @import("color_parser.zig");
pub const text_alignment = @import("text_alignment.zig");
pub const string_utils = @import("string_utils.zig");
pub const pattern_parser = @import("pattern_parser.zig");
pub const number_formatter = @import("number_formatter.zig");
pub const c_print_mod = @import("c_print.zig");
pub const c_print_builder = @import("c_print_builder.zig");
pub const c_print_generic = @import("c_print_generic.zig");
pub const c_print_safe = @import("c_print_safe.zig");
pub const c_api = @import("c_api.zig");

// Force export of C-ABI functions so they appear in the static library
comptime {
    _ = c_api;
}
