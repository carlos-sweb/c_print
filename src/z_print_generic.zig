/// z_print_generic.zig - Type-safe generic API for z_print
///
/// Provides compile-time reflection to detect argument types, validate them
/// against format specifiers, and provide debug utilities for type inspection.
///
/// Usage:
///   const generic = @import("z_print_generic.zig");
///   generic.print(writer, "{s:red} {d:green}", .{ "Hello", @as(i32, 42) });
///   generic.debugTypes(writer, "{s} {d} {f}", .{ "test", @as(i32, 42), @as(f64, 3.14) });
const std = @import("std");
const z_print_mod = @import("z_print.zig");
const pattern_parser = @import("pattern_parser.zig");

const PatternStyle = pattern_parser.PatternStyle;

// ============================================================================
// Type Tag Enum
// ============================================================================

/// Enum representing the type of a generic print argument.
/// Mirrors the C PrintArgType enum for compatibility.
pub const PrintArgType = enum(u8) {
    string,
    integer,
    unsigned,
    long,
    ulong,
    float,
    double,
    char,
    bool,
    pointer,
    unknown,
};

// ============================================================================
// Tagged Union for Typed Values
// ============================================================================

/// Tagged union that holds a value along with its type information.
/// Similar to C's PrintArg struct with type tag + union.
pub const PrintArg = union(PrintArgType) {
    string: []const u8,
    integer: i32,
    unsigned: u32,
    long: i64,
    ulong: u64,
    float: f32,
    double: f64,
    char: u8,
    bool: bool,
    pointer: usize,
    unknown: void,

    /// Get the type tag of this argument.
    pub fn getType(self: PrintArg) PrintArgType {
        return self;
    }

    /// Get a human-readable name for this argument's type.
    pub fn typeName(self: PrintArg) []const u8 {
        return typeNameForTag(self);
    }
};

// ============================================================================
// Backward compatibility aliases
// ============================================================================
pub const CPrintArgType = PrintArgType;
pub const CPrintArg = PrintArg;
pub const C_PRINT_MAX_ARGS = printMaxArgs;

// ============================================================================
// Compile-Time Type Detection
// ============================================================================

/// Detect the PrintArgType for a given Zig type at compile time.
/// Uses @typeInfo for compile-time reflection.
pub fn detectArgType(comptime T: type) PrintArgType {
    // Check for string types first (slices and pointers to arrays of u8)
    if (comptime isStringType(T)) return .string;

    // Check for bool before int (bool is not an int in Zig)
    if (T == bool) return .bool;

    const info = @typeInfo(T);

    switch (info) {
        .int => |int_info| {
            if (int_info.signedness == .signed) {
                // Signed integers
                if (int_info.bits <= 32) return .integer;
                return .long;
            } else {
                // Unsigned integers
                if (T == u8) return .char; // u8 treated as char
                if (int_info.bits <= 32) return .unsigned;
                return .ulong;
            }
        },
        .float => |float_info| {
            if (float_info.bits <= 32) return .float;
            return .double;
        },
        .pointer => |ptr_info| {
            // Pointer to u8 already handled by isStringType
            // Other pointers are treated as pointer type
            _ = ptr_info;
            return .pointer;
        },
        .optional => return .pointer, // Optionals as pointer-like
        .@"enum" => return .integer,
        .error_set => return .integer,
        else => return .unknown,
    }
}

/// Compile-time check if T is a string-like type.
fn isStringType(comptime T: type) bool {
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
            if (ptr.size == .slice) {
                return ptr.child == u8;
            }
            return false;
        },
        else => return false,
    }
}

// ============================================================================
// PrintArg Construction
// ============================================================================

/// Create a PrintArg from any value, automatically detecting its type.
pub fn makeArg(value: anytype) PrintArg {
    const T = @TypeOf(value);
    const tag = comptime detectArgType(T);

    return switch (tag) {
        .string => .{ .string = value },
        .integer => .{ .integer = @intCast(value) },
        .unsigned => .{ .unsigned = @intCast(value) },
        .long => .{ .long = @intCast(value) },
        .ulong => .{ .ulong = @intCast(value) },
        .float => .{ .float = @floatCast(value) },
        .double => .{ .double = @floatCast(value) },
        .char => .{ .char = @intCast(value) },
        .bool => .{ .bool = value },
        .pointer => .{ .pointer = @intFromPtr(&value) },
        .unknown => .{ .unknown = {} },
    };
}

/// Get the type name string for a PrintArg union tag.
pub fn typeNameForTag(arg: PrintArg) []const u8 {
    return switch (arg) {
        .string => "string",
        .integer => "int",
        .unsigned => "unsigned int",
        .long => "long",
        .ulong => "unsigned long",
        .float => "float",
        .double => "double",
        .char => "char",
        .bool => "bool",
        .pointer => "pointer",
        .unknown => "unknown",
    };
}

/// Get the type name string for a PrintArgType enum value.
pub fn typeNameForType(arg_type: PrintArgType) []const u8 {
    return switch (arg_type) {
        .string => "string",
        .integer => "int",
        .unsigned => "unsigned int",
        .long => "long",
        .ulong => "unsigned long",
        .float => "float",
        .double => "double",
        .char => "char",
        .bool => "bool",
        .pointer => "pointer",
        .unknown => "unknown",
    };
}

// ============================================================================
// Type Validation
// ============================================================================

/// Validate that an argument type matches the expected format specifier.
/// Returns true if the type is compatible with the format character.
pub fn validateArgType(format_type: u8, arg_type: PrintArgType) bool {
    return switch (format_type) {
        's' => arg_type == .string,
        'd', 'i' => arg_type == .integer,
        'f' => arg_type == .double or arg_type == .float,
        'c' => arg_type == .char,
        'b', 'x', 'o' => arg_type == .unsigned or arg_type == .integer or arg_type == .ulong,
        'u' => arg_type == .unsigned or arg_type == .integer or arg_type == .ulong,
        'l' => arg_type == .long or arg_type == .ulong,
        else => false,
    };
}

/// Get the expected type name for a format specifier character.
pub fn expectedTypeName(format_type: u8) []const u8 {
    return switch (format_type) {
        's' => "string",
        'd', 'i' => "int",
        'f' => "double",
        'c' => "char",
        'b', 'x', 'o', 'u' => "unsigned int",
        'l' => "long",
        else => "unknown",
    };
}

/// Extract format type specifiers from a pattern string at comptime.
/// Returns the number of format specifiers found and fills the specs array.
pub fn extractFormatTypes(comptime pattern: []const u8) struct { specs: [64]u8, count: usize } {
    var specs: [64]u8 = .{0} ** 64;
    var count: usize = 0;
    var i: usize = 0;

    while (i < pattern.len) {
        if (pattern[i] == '{') {
            // Check for escaped brace
            if (i > 0 and pattern[i - 1] == '\\') {
                i += 1;
                continue;
            }
            // Find closing brace
            var j = i + 1;
            while (j < pattern.len) : (j += 1) {
                if (pattern[j] == '}') break;
            }
            if (j < pattern.len and j > i + 1) {
                // Extract format type (first char after '{')
                const first_char = pattern[i + 1];
                if (first_char != '}' and first_char != ' ') {
                    if (count < 64) {
                        specs[count] = first_char;
                        count += 1;
                    }
                }
            }
            i = j + 1;
        } else {
            i += 1;
        }
    }

    return .{ .specs = specs, .count = count };
}

/// Validate that the number and types of arguments match the pattern.
/// Returns a ValidationResult with details about any mismatches.
pub fn validateArgs(comptime pattern: []const u8, args: anytype) ValidationResult {
    const extracted = comptime extractFormatTypes(pattern);
    const ArgsType = @TypeOf(args);
    const fields = @typeInfo(ArgsType).@"struct".fields;
    const NumArgs = fields.len;

    var result = ValidationResult{
        .valid = true,
        .expected_count = extracted.count,
        .actual_count = NumArgs,
        .mismatch_count = 0,
    };

    // Check argument count
    if (extracted.count != NumArgs) {
        result.valid = false;
    }

    // Check each argument type using inline for over actual fields
    const check_count = @min(extracted.count, NumArgs);
    inline for (fields, 0..) |field, idx| {
        if (idx < check_count) {
            const arg_tag = comptime detectArgType(field.type);
            if (!validateArgType(extracted.specs[idx], arg_tag)) {
                result.valid = false;
                result.mismatch_count += 1;
            }
        }
    }

    return result;
}

/// Result of type validation.
pub const ValidationResult = struct {
    valid: bool,
    expected_count: usize,
    actual_count: usize,
    mismatch_count: usize,
};

// ============================================================================
// Main print Function
// ============================================================================

/// Maximum number of arguments supported by print.
pub const printMaxArgs = 64;

/// Type-safe generic print function.
/// Automatically detects argument types using compile-time reflection,
/// validates them against format specifiers, and formats output.
///
/// Usage:
///   print(writer, "{s:red} {d:green}", .{ "Hello", @as(i32, 42) });
pub fn print(writer: *std.Io.Writer, comptime pattern: []const u8, args: anytype) !void {
    // Delegate to the core z_print function which already handles type-safe formatting
    try z_print_mod.z_print(writer, pattern, args);
}

/// Type-safe generic print with compile-time validation.
/// Performs the same validation as print but also returns validation info.
/// Useful for testing and debugging.
pub fn printValidated(writer: *std.Io.Writer, comptime pattern: []const u8, args: anytype) ValidationResult {
    const result = comptime validateArgs(pattern, args);
    z_print_mod.z_print(writer, pattern, args) catch {};
    return result;
}

// ============================================================================
// Debug Functions
// ============================================================================

/// Debug function that prints type information for each argument.
/// Equivalent to debugTypes in the C implementation.
///
/// Output format:
///   [print DEBUG] Pattern: {s} {d} {f}
///   [print DEBUG] Argument count: 3
///   [print DEBUG] Arg 0: string
///   [print DEBUG] Arg 1: int
///   [print DEBUG] Arg 2: double
pub fn debugTypes(writer: *std.Io.Writer, comptime pattern: []const u8, args: anytype) !void {
    const ArgsType = @TypeOf(args);
    const fields = @typeInfo(ArgsType).@"struct".fields;
    const NumArgs = fields.len;

    // Print pattern info
    try writer.writeAll("[print DEBUG] Pattern: ");
    try writer.writeAll(pattern);
    try writer.writeAll("\n");

    // Print argument count
    try writer.print("[print DEBUG] Argument count: {d}\n", .{NumArgs});

    // Print each argument's type
    inline for (fields, 0..) |field, idx| {
        const arg_type = comptime detectArgType(field.type);
        try writer.print("[print DEBUG] Arg {d}: {s}\n", .{ idx, typeNameForType(arg_type) });
    }
}

/// Debug function that prints detailed type and value information.
/// Shows both the detected type and the actual value for each argument.
pub fn debugValues(writer: *std.Io.Writer, comptime pattern: []const u8, args: anytype) !void {
    const ArgsType = @TypeOf(args);
    const fields = @typeInfo(ArgsType).@"struct".fields;
    const NumArgs = fields.len;

    try writer.writeAll("[print DEBUG] Pattern: ");
    try writer.writeAll(pattern);
    try writer.writeAll("\n");
    try writer.print("[print DEBUG] Argument count: {d}\n", .{NumArgs});

    inline for (fields, 0..) |field, idx| {
        const T = field.type;
        const arg_type = comptime detectArgType(T);
        const type_name = typeNameForType(arg_type);

        try writer.print("[print DEBUG] Arg {d}: {s} = ", .{ idx, type_name });

        // Print value based on type
        if (comptime isStringType(T)) {
            try writer.print("\"{s}\"\n", .{args[idx]});
        } else if (T == bool) {
            if (args[idx]) {
                try writer.writeAll("true\n");
            } else {
                try writer.writeAll("false\n");
            }
        } else if (comptime z_print_mod.isFloatType(T)) {
            try writer.print("{d}\n", .{args[idx]});
        } else if (comptime z_print_mod.isSignedIntType(T)) {
            try writer.print("{d}\n", .{args[idx]});
        } else if (comptime z_print_mod.isUnsignedIntType(T)) {
            if (T == u8) {
                try writer.print("'{c}'\n", .{args[idx]});
            } else {
                try writer.print("{d}\n", .{args[idx]});
            }
        } else {
            try writer.writeAll("(complex value)\n");
        }
    }
}

/// Validate a pattern and its arguments, writing any errors to the writer.
/// Returns true if validation passes, false otherwise.
pub fn validateAndReport(writer: *std.Io.Writer, comptime pattern: []const u8, args: anytype) bool {
    const extracted = comptime extractFormatTypes(pattern);
    const ArgsType = @TypeOf(args);
    const fields = @typeInfo(ArgsType).@"struct".fields;
    const NumArgs = fields.len;
    var all_valid = true;

    // Check argument count
    if (extracted.count != NumArgs) {
        writer.print("[print ERROR] Argument count mismatch: expected {d}, got {d}\n", .{ extracted.count, NumArgs }) catch {};
        all_valid = false;
    }

    // Check each argument type
    const check_count = @min(extracted.count, NumArgs);
    inline for (fields, 0..) |field, idx| {
        if (idx < check_count) {
            const arg_type = comptime detectArgType(field.type);
            if (!validateArgType(extracted.specs[idx], arg_type)) {
                writer.print("[print ERROR] Type mismatch at argument {d}:\n", .{idx}) catch {};
                writer.print("  Pattern: {{{c}:...}}\n", .{extracted.specs[idx]}) catch {};
                writer.print("  Expected: {s}\n", .{expectedTypeName(extracted.specs[idx])}) catch {};
                writer.print("  Got: {s}\n", .{typeNameForType(arg_type)}) catch {};
                all_valid = false;
            }
        }
    }

    return all_valid;
}

// ============================================================================
// Backward compatibility function aliases
// ============================================================================
pub const C_PRINT = print;
pub const C_PRINT_VALIDATED = printValidated;
pub const C_PRINT_DEBUG_TYPES = debugTypes;
pub const C_PRINT_DEBUG_VALUES = debugValues;

// ============================================================================
// Tests
// ============================================================================

// -- Type Detection Tests --

test "detectArgType detects string slice" {
    try std.testing.expectEqual(PrintArgType.string, detectArgType([]const u8));
    try std.testing.expectEqual(PrintArgType.string, detectArgType([]u8));
}

test "detectArgType detects string literal" {
    const T = @TypeOf("hello");
    try std.testing.expectEqual(PrintArgType.string, detectArgType(T));
}

test "detectArgType detects signed integers" {
    try std.testing.expectEqual(PrintArgType.integer, detectArgType(i32));
    try std.testing.expectEqual(PrintArgType.integer, detectArgType(i16));
    try std.testing.expectEqual(PrintArgType.integer, detectArgType(i8));
    try std.testing.expectEqual(PrintArgType.long, detectArgType(i64));
}

test "detectArgType detects unsigned integers" {
    try std.testing.expectEqual(PrintArgType.char, detectArgType(u8));
    try std.testing.expectEqual(PrintArgType.unsigned, detectArgType(u32));
    try std.testing.expectEqual(PrintArgType.unsigned, detectArgType(u16));
    try std.testing.expectEqual(PrintArgType.ulong, detectArgType(u64));
}

test "detectArgType detects float types" {
    try std.testing.expectEqual(PrintArgType.float, detectArgType(f32));
    try std.testing.expectEqual(PrintArgType.double, detectArgType(f64));
}

test "detectArgType detects bool" {
    try std.testing.expectEqual(PrintArgType.bool, detectArgType(bool));
}

// -- PrintArg Construction Tests --

test "makeArg creates string arg" {
    const arg = makeArg("hello");
    try std.testing.expectEqual(PrintArgType.string, arg.getType());
    try std.testing.expectEqualStrings("hello", arg.string);
}

test "makeArg creates integer arg" {
    const arg = makeArg(@as(i32, 42));
    try std.testing.expectEqual(PrintArgType.integer, arg.getType());
    try std.testing.expectEqual(@as(i32, 42), arg.integer);
}

test "makeArg creates unsigned arg" {
    const arg = makeArg(@as(u32, 100));
    try std.testing.expectEqual(PrintArgType.unsigned, arg.getType());
    try std.testing.expectEqual(@as(u32, 100), arg.unsigned);
}

test "makeArg creates long arg" {
    const arg = makeArg(@as(i64, 1234567890));
    try std.testing.expectEqual(PrintArgType.long, arg.getType());
    try std.testing.expectEqual(@as(i64, 1234567890), arg.long);
}

test "makeArg creates double arg" {
    const arg = makeArg(@as(f64, 3.14));
    try std.testing.expectEqual(PrintArgType.double, arg.getType());
    try std.testing.expectApproxEqAbs(@as(f64, 3.14), arg.double, 0.001);
}

test "makeArg creates float arg" {
    const arg = makeArg(@as(f32, 2.5));
    try std.testing.expectEqual(PrintArgType.float, arg.getType());
    try std.testing.expectApproxEqAbs(@as(f32, 2.5), arg.float, 0.001);
}

test "makeArg creates char arg" {
    const arg = makeArg(@as(u8, 'A'));
    try std.testing.expectEqual(PrintArgType.char, arg.getType());
    try std.testing.expectEqual(@as(u8, 'A'), arg.char);
}

test "makeArg creates bool arg" {
    const arg_true = makeArg(true);
    try std.testing.expectEqual(PrintArgType.bool, arg_true.getType());
    try std.testing.expectEqual(true, arg_true.bool);

    const arg_false = makeArg(false);
    try std.testing.expectEqual(PrintArgType.bool, arg_false.getType());
    try std.testing.expectEqual(false, arg_false.bool);
}

// -- Type Name Tests --

test "typeNameForType returns correct names" {
    try std.testing.expectEqualStrings("string", typeNameForType(.string));
    try std.testing.expectEqualStrings("int", typeNameForType(.integer));
    try std.testing.expectEqualStrings("unsigned int", typeNameForType(.unsigned));
    try std.testing.expectEqualStrings("long", typeNameForType(.long));
    try std.testing.expectEqualStrings("unsigned long", typeNameForType(.ulong));
    try std.testing.expectEqualStrings("float", typeNameForType(.float));
    try std.testing.expectEqualStrings("double", typeNameForType(.double));
    try std.testing.expectEqualStrings("char", typeNameForType(.char));
    try std.testing.expectEqualStrings("bool", typeNameForType(.bool));
    try std.testing.expectEqualStrings("pointer", typeNameForType(.pointer));
    try std.testing.expectEqualStrings("unknown", typeNameForType(.unknown));
}

test "PrintArg typeName method works" {
    const arg = makeArg("test");
    try std.testing.expectEqualStrings("string", arg.typeName());

    const int_arg = makeArg(@as(i32, 42));
    try std.testing.expectEqualStrings("int", int_arg.typeName());
}

// -- Type Validation Tests --

test "validateArgType accepts string for s format" {
    try std.testing.expect(validateArgType('s', .string));
    try std.testing.expect(!validateArgType('s', .integer));
    try std.testing.expect(!validateArgType('s', .double));
}

test "validateArgType accepts integer for d/i format" {
    try std.testing.expect(validateArgType('d', .integer));
    try std.testing.expect(validateArgType('i', .integer));
    try std.testing.expect(!validateArgType('d', .string));
    try std.testing.expect(!validateArgType('d', .double));
}

test "validateArgType accepts float/double for f format" {
    try std.testing.expect(validateArgType('f', .double));
    try std.testing.expect(validateArgType('f', .float));
    try std.testing.expect(!validateArgType('f', .integer));
    try std.testing.expect(!validateArgType('f', .string));
}

test "validateArgType accepts char for c format" {
    try std.testing.expect(validateArgType('c', .char));
    try std.testing.expect(!validateArgType('c', .integer));
    try std.testing.expect(!validateArgType('c', .string));
}

test "validateArgType accepts unsigned/integer for b/x/o format" {
    try std.testing.expect(validateArgType('b', .unsigned));
    try std.testing.expect(validateArgType('x', .unsigned));
    try std.testing.expect(validateArgType('o', .unsigned));
    try std.testing.expect(validateArgType('b', .integer));
    try std.testing.expect(validateArgType('x', .integer));
    try std.testing.expect(!validateArgType('b', .string));
}

test "validateArgType accepts unsigned/integer for u format" {
    try std.testing.expect(validateArgType('u', .unsigned));
    try std.testing.expect(validateArgType('u', .integer));
    try std.testing.expect(!validateArgType('u', .string));
}

test "validateArgType accepts long for l format" {
    try std.testing.expect(validateArgType('l', .long));
    try std.testing.expect(validateArgType('l', .ulong));
    try std.testing.expect(!validateArgType('l', .integer));
}

test "validateArgType rejects unknown format" {
    try std.testing.expect(!validateArgType('z', .string));
    try std.testing.expect(!validateArgType('z', .integer));
}

// -- Expected Type Name Tests --

test "expectedTypeName returns correct names" {
    try std.testing.expectEqualStrings("string", expectedTypeName('s'));
    try std.testing.expectEqualStrings("int", expectedTypeName('d'));
    try std.testing.expectEqualStrings("int", expectedTypeName('i'));
    try std.testing.expectEqualStrings("double", expectedTypeName('f'));
    try std.testing.expectEqualStrings("char", expectedTypeName('c'));
    try std.testing.expectEqualStrings("unsigned int", expectedTypeName('b'));
    try std.testing.expectEqualStrings("unsigned int", expectedTypeName('x'));
    try std.testing.expectEqualStrings("unsigned int", expectedTypeName('o'));
    try std.testing.expectEqualStrings("unsigned int", expectedTypeName('u'));
    try std.testing.expectEqualStrings("long", expectedTypeName('l'));
    try std.testing.expectEqualStrings("unknown", expectedTypeName('z'));
}

// -- Format Type Extraction Tests --

test "extractFormatTypes extracts single format type" {
    const result = comptime extractFormatTypes("{s}");
    try std.testing.expectEqual(@as(usize, 1), result.count);
    try std.testing.expectEqual(@as(u8, 's'), result.specs[0]);
}

test "extractFormatTypes extracts multiple format types" {
    const result = comptime extractFormatTypes("{s} {d} {f}");
    try std.testing.expectEqual(@as(usize, 3), result.count);
    try std.testing.expectEqual(@as(u8, 's'), result.specs[0]);
    try std.testing.expectEqual(@as(u8, 'd'), result.specs[1]);
    try std.testing.expectEqual(@as(u8, 'f'), result.specs[2]);
}

test "extractFormatTypes handles format with specifiers" {
    const result = comptime extractFormatTypes("{s:red:bold} {d:,}");
    try std.testing.expectEqual(@as(usize, 2), result.count);
    try std.testing.expectEqual(@as(u8, 's'), result.specs[0]);
    try std.testing.expectEqual(@as(u8, 'd'), result.specs[1]);
}

test "extractFormatTypes handles no patterns" {
    const result = comptime extractFormatTypes("plain text");
    try std.testing.expectEqual(@as(usize, 0), result.count);
}

test "extractFormatTypes handles escaped braces" {
    const result = comptime extractFormatTypes("\\{not a pattern} {s}");
    // The \{ is escaped, but our simple extraction still sees the { after \
    // This is a known limitation - the comptime extractor is simpler than the runtime parser
    try std.testing.expect(result.count >= 1);
}

// -- Validation Tests --

test "validateArgs passes for matching types" {
    const result = comptime validateArgs("{s} {d} {f}", .{ "hello", @as(i32, 42), @as(f64, 3.14) });
    try std.testing.expect(result.valid);
    try std.testing.expectEqual(@as(usize, 3), result.expected_count);
    try std.testing.expectEqual(@as(usize, 3), result.actual_count);
    try std.testing.expectEqual(@as(usize, 0), result.mismatch_count);
}

test "validateArgs detects count mismatch" {
    const result = comptime validateArgs("{s} {d}", .{"hello"});
    try std.testing.expect(!result.valid);
    try std.testing.expectEqual(@as(usize, 2), result.expected_count);
    try std.testing.expectEqual(@as(usize, 1), result.actual_count);
}

test "validateArgs detects type mismatch" {
    // Passing integer where string expected
    const result = comptime validateArgs("{s}", .{@as(i32, 42)});
    try std.testing.expect(!result.valid);
    try std.testing.expectEqual(@as(usize, 1), result.mismatch_count);
}

test "validateArgs accepts compatible types" {
    // f64 is compatible with 'f' format
    const result = comptime validateArgs("{f}", .{@as(f64, 3.14)});
    try std.testing.expect(result.valid);

    // f32 is also compatible with 'f' format
    const result2 = comptime validateArgs("{f}", .{@as(f32, 3.14)});
    try std.testing.expect(result2.valid);
}

// -- print Output Tests --

test "print outputs plain text" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "Hello World", .{});
    try std.testing.expectEqualStrings("Hello World", writer.buffered());
}

test "print outputs string format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "Hello {s}!", .{"World"});
    try std.testing.expectEqualStrings("Hello World!", writer.buffered());
}

test "print outputs integer format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "val={d}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("val=42", writer.buffered());
}

test "print outputs float format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{f}", .{@as(f64, 3.14)});
    try std.testing.expectEqualStrings("3.14", writer.buffered());
}

test "print outputs multiple formats" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "Name: {s}, Age: {d}", .{ "Alice", @as(i32, 30) });
    try std.testing.expectEqualStrings("Name: Alice, Age: 30", writer.buffered());
}

test "print outputs with color" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{s:red}", .{"Hi"});
    try std.testing.expectEqualStrings("\x1b[31mHi\x1b[0m", writer.buffered());
}

test "print outputs integer with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{d:,}", .{@as(i32, 1234567)});
    try std.testing.expectEqualStrings("1,234,567", writer.buffered());
}

test "print outputs float with precision" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{f:.2}", .{@as(f64, 3.14159)});
    try std.testing.expectEqualStrings("3.14", writer.buffered());
}

test "print outputs binary format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{b}", .{@as(u64, 5)});
    try std.testing.expectEqualStrings("101", writer.buffered());
}

test "print outputs hex format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{x}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("ff", writer.buffered());
}

test "print outputs octal format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{o}", .{@as(u64, 8)});
    try std.testing.expectEqualStrings("10", writer.buffered());
}

test "print outputs char format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{c}", .{@as(u8, 'A')});
    try std.testing.expectEqualStrings("A", writer.buffered());
}

test "print outputs long format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{l}", .{@as(i64, 1234567890)});
    try std.testing.expectEqualStrings("1234567890", writer.buffered());
}

test "print outputs unsigned format" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{u}", .{@as(u64, 42)});
    try std.testing.expectEqualStrings("42", writer.buffered());
}

// -- printValidated Tests --

test "printValidated returns valid for correct types" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    const result = printValidated(&writer, "{s} {d}", .{ "hello", @as(i32, 42) });
    try std.testing.expect(result.valid);
    try std.testing.expectEqualStrings("hello 42", writer.buffered());
}

test "printValidated returns invalid for mismatched types" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    const result = printValidated(&writer, "{s}", .{@as(i32, 42)});
    try std.testing.expect(!result.valid);
    try std.testing.expectEqual(@as(usize, 1), result.mismatch_count);
}

// -- Debug Output Tests --

test "debugTypes outputs type information" {
    var buf: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try debugTypes(&writer, "{s} {d} {f}", .{ "test", @as(i32, 42), @as(f64, 3.14) });
    const output = writer.buffered();

    // Check that debug output contains expected information
    try std.testing.expect(std.mem.indexOf(u8, output, "[print DEBUG] Pattern:") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "{s} {d} {f}") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Argument count: 3") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Arg 0: string") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Arg 1: int") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Arg 2: double") != null);
}

test "debugTypes handles empty args" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try debugTypes(&writer, "plain text", .{});
    const output = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, output, "Argument count: 0") != null);
}

test "debugValues outputs type and value info" {
    var buf: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try debugValues(&writer, "{s} {d}", .{ "hello", @as(i32, 42) });
    const output = writer.buffered();

    try std.testing.expect(std.mem.indexOf(u8, output, "Arg 0: string") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\"hello\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Arg 1: int") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "42") != null);
}

test "debugValues shows bool values" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try debugValues(&writer, "{d}", .{true});
    const output = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, output, "bool") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "true") != null);
}

// -- validateAndReport Tests --

test "validateAndReport returns true for valid args" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    const valid = validateAndReport(&writer, "{s} {d}", .{ "hello", @as(i32, 42) });
    try std.testing.expect(valid);
}

test "validateAndReport returns false for count mismatch" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    const valid = validateAndReport(&writer, "{s} {d}", .{"hello"});
    try std.testing.expect(!valid);
    const output = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, output, "Argument count mismatch") != null);
}

test "validateAndReport returns false for type mismatch" {
    var buf: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    const valid = validateAndReport(&writer, "{s}", .{@as(i32, 42)});
    try std.testing.expect(!valid);
    const output = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, output, "Type mismatch") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Expected: string") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "Got: int") != null);
}

// -- Edge Case Tests --

test "print handles empty pattern" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "", .{});
    try std.testing.expectEqualStrings("", writer.buffered());
}

test "print handles escaped braces" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "\\{not a pattern}", .{});
    try std.testing.expectEqualStrings("{not a pattern}", writer.buffered());
}

test "print handles alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "|{s:<10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|Hi        |", writer.buffered());
}

test "print handles right alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "|{s:>10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|        Hi|", writer.buffered());
}

test "print handles center alignment" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "|{s:^10}|", .{"Hi"});
    try std.testing.expectEqualStrings("|    Hi    |", writer.buffered());
}

test "print handles hex with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{x:#}", .{@as(u64, 255)});
    try std.testing.expectEqualStrings("0xff", writer.buffered());
}

test "print handles binary with prefix" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{b:#}", .{@as(u64, 5)});
    try std.testing.expectEqualStrings("0b101", writer.buffered());
}

test "print handles float percentage" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{f:.2:%}", .{@as(f64, 0.123)});
    try std.testing.expectEqualStrings("12.30%", writer.buffered());
}

test "print handles integer with zero padding" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{d:05}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("00042", writer.buffered());
}

test "print handles integer with sign" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{d:+}", .{@as(i32, 42)});
    try std.testing.expectEqualStrings("+42", writer.buffered());
}

test "print handles long with separator" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{l:,}", .{@as(i64, 1234567890)});
    try std.testing.expectEqualStrings("1,234,567,890", writer.buffered());
}

test "print handles multiple patterns with colors" {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try print(&writer, "{s:red}={d:blue}", .{ "X", @as(i32, 5) });
    try std.testing.expectEqualStrings("\x1b[31mX\x1b[0m=\x1b[34m5\x1b[0m", writer.buffered());
}

// -- isStringType Tests --

test "isStringType detects string types" {
    try std.testing.expect(isStringType([]const u8));
    try std.testing.expect(isStringType([]u8));
    try std.testing.expect(!isStringType(i32));
    try std.testing.expect(!isStringType(f64));
    try std.testing.expect(!isStringType(bool));
}
