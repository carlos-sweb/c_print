# c_print

**Zig library for printing colored and formatted text to the console using ANSI escape codes**

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/carlos-sweb/c_print)
[![Zig](https://img.shields.io/badge/Zig-0.16.0-orange.svg)](https://ziglang.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

English

## Description

`c_print` is a comprehensive Zig library that provides three distinct approaches for printing formatted and colored text to the terminal. With support for ANSI colors, text styles, advanced alignment, and number formatting, the library offers flexibility for different use cases and programming preferences.

Built entirely in Zig 0.16.0, taking advantage of comptime type safety, the `std.Io.Writer` API, and Zig's powerful compile-time reflection. C users can integrate the library via the C-ABI compatible exported functions.

## Key Features

- 16 ANSI colors (8 standard + 8 bright)
- 8 text styles (bold, italic, underline, etc.)
- Text alignment (left, right, center with customizable fill characters)
- Advanced number formatting (thousands separators, padding, numeric bases)
- Three distinct APIs for different needs
- Compile-time type safety via Zig comptime reflection
- Modular and extensible architecture
- Zero external dependencies
- Static library output via `zig build`

---

## The 3 Printing Approaches

### 1. Pattern-Based API (Recommended)

**Module:** `c_print.zig`

This is the main and most flexible approach, using format patterns with `{type:specifier1:specifier2:...}` syntax. Arguments are passed as a comptime tuple, giving full type safety at compile time.

#### Basic Syntax

```zig
const c_print = @import("c_print");

try c_print.c_print_mod.c_print(&writer, "Text with {type:specifiers}", .{value});
```

#### Supported Types

- `{s:...}` - String (`[]const u8`)
- `{d:...}` or `{i:...}` - Signed integer (`i32`)
- `{f:...}` - Decimal (`f64`)
- `{c:...}` - Character (`u8`)
- `{b:...}` - Binary (`u64`)
- `{x:...}` - Hexadecimal (`u64`)
- `{o:...}` - Octal (`u64`)
- `{u:...}` - Unsigned integer (`u64`)
- `{l:...}` - Long integer (`i64`)

#### Available Specifiers

**Colors:**
- Basic: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`
- Bright: `bright_red`, `bright_green`, `bright_blue`, etc.
- Backgrounds: `bg_red`, `bg_green`, `bg_blue`, etc.

**Styles:**
- `bold` - Bold
- `italic` - Italic
- `underline` - Underline
- `dim` - Dim
- `blink` - Blink
- `reverse` - Reverse
- `strikethrough` - Strikethrough

**Alignment:**
- `<N` - Left align (width N)
- `>N` - Right align (width N)
- `^N` - Center (width N)
- `*^N` - Center with custom fill character

**Number Formatting:**
- `.N` - Decimal precision (e.g., `.2` for 2 decimals)
- `0N` - Zero padding (e.g., `05` for 00042)
- `,` - Thousands separator with comma
- `_` - Thousands separator with underscore
- `#` - Show prefix (0b, 0x, 0o)
- `+` - Always show sign
- `%` - Format as percentage

#### Examples

```zig
const std = @import("std");
const c_print = @import("c_print");

pub fn main() !void {
    var stdout: std.Io.Writer = .fixed(&std.io.getStdOut().writer().buffer);

    // Simple colored text
    try c_print.c_print_mod.c_print(&stdout, "Hello {s:green}!\n", .{"World"});

    // Multiple specifiers
    try c_print.c_print_mod.c_print(&stdout, "{s:cyan:bg_black:bold}\n", .{"IMPORTANT"});

    // Multiple values
    try c_print.c_print_mod.c_print(
        &stdout,
        "User: {s:yellow}, Age: {d:blue}, Score: {f:.2:green}\n",
        .{ "Alice", @as(i32, 25), @as(f64, 95.5) },
    );

    // Number formatting
    try c_print.c_print_mod.c_print(&stdout, "Population: {d:,}\n", .{@as(i32, 1234567)});
    try c_print.c_print_mod.c_print(&stdout, "Hex: 0x{x:bold}\n", .{@as(u64, 255)});
    try c_print.c_print_mod.c_print(&stdout, "Price: ${f:.2:,}\n", .{@as(f64, 1234.56)});

    // Alignment
    try c_print.c_print_mod.c_print(&stdout, "|{s:<20}|\n", .{"Left"});
    try c_print.c_print_mod.c_print(&stdout, "|{s:>20}|\n", .{"Right"});
    try c_print.c_print_mod.c_print(&stdout, "|{s:^20}|\n", .{"Center"});
    try c_print.c_print_mod.c_print(&stdout, "|{s:*^20}|\n", .{"Fill"});

    // Complex example
    try c_print.c_print_mod.c_print(
        &stdout,
        "[{s:bright_green:bold}] {s:white} - {f:.2:green} ms\n",
        .{ "SUCCESS", "Request completed", @as(f64, 45.32) },
    );
}
```

**Advantages:**
- Compact and readable syntax
- Very flexible and powerful
- Comptime type checking on arguments
- Similar to printf but with colors and advanced formatting
- Ideal for most use cases

**Limitations:**
- Requires explicit type casts for integer/float literals in tuples
- Argument order must match pattern order

---

### 2. Builder Pattern API

**Module:** `c_print_builder.zig`

This approach eliminates variadic functions entirely, providing complete compile-time type safety through explicit functions for each data type. The builder accumulates formatted output in an internal buffer, then prints or returns the result.

#### Main Functions

```zig
const Builder = c_print.c_print_builder;

// Create and free
var b = Builder.init(allocator);         // Create builder (alias: cp_new)
defer b.deinit();                         // Free memory (alias: cp_free)
b.reset();                                // Reset for reuse (alias: cp_reset)

// Add content (type-safe)
_ = b.appendText("text");                // Literal text without formatting
_ = b.append(variable_string);           // Formatted string
_ = b.appendInt(42);                     // Integer (i32)
_ = b.appendFloat(3.14);                 // Decimal (f64)
_ = b.appendChar('A');                   // Character (u8)
_ = b.appendBool(true);                  // Boolean
_ = b.appendBinary(255);                 // Binary
_ = b.appendHex(255);                    // Hexadecimal

// Apply formatting (chainable)
_ = b.withColorName("red");              // Text color by name
_ = b.withColor(.red);                   // Text color by enum
_ = b.withBgColorName("bg_blue");        // Background color
_ = b.withStyleName("bold");             // Style by name
_ = b.withStyle(.bold);                  // Style by enum
_ = b.withPrecision(2);                  // Decimal precision
_ = b.withZeroPad();                     // Enable zero padding
_ = b.withPad(5);                        // Set padding width
_ = b.withSeparator(',');                // Thousands separator
_ = b.withPrefix();                      // Show 0x, 0b, etc.
_ = b.withSign();                        // Show +/- sign
_ = b.asPercentage();                    // Format as %
_ = b.alignLeft(20);                     // Left align
_ = b.alignRight(20);                    // Right align
_ = b.alignCenter(20);                   // Center
_ = b.withFillChar('*');                 // Fill character

// Print
try b.print();                           // Print to stderr
try b.println();                         // Print with newline
const str = try b.toString();            // Get allocated string
defer allocator.free(str);
```

> **Backward compatibility:** The old `cp_*` function names (e.g., `cp_new`, `cp_text`, `cp_color_str`) are available as aliases and will continue to work.

#### Examples

```zig
const std = @import("std");
const c_print = @import("c_print");
const Builder = c_print.c_print_builder;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var b = Builder.init(allocator);
    defer b.deinit();

    // Type-safe construction
    _ = b.appendText("Employee: ");
    _ = b.withColorName("cyan").append("Carlos");
    _ = b.appendText(" | Salary: $");
    _ = b.withColorName("green").withPrecision(2).appendFloat(75000.50);
    try b.println();
    // Output: Employee: Carlos | Salary: $75000.50

    // Reuse builder
    b.reset();
    _ = b.appendText("ID: ");
    _ = b.withZeroPad().withPad(5).appendInt(42);
    try b.println();
    // Output: ID: 00042

    // Number with separators
    b.reset();
    _ = b.appendText("Population: ");
    _ = b.withSeparator(',').appendInt(1234567);
    try b.println();
    // Output: Population: 1,234,567

    // Complex chaining
    b.reset();
    _ = b.appendText("Price: $");
    _ = b.withColorName("green").withPrecision(2).withSeparator(',').appendFloat(9999.99);
    try b.println();
    // Output: Price: $9,999.99 (in green)
}
```

**Advantages:**
- **Compile-time type safety**: Impossible to mix types
- No variadic functions needed
- Clean, chainable API
- Reusable (with `reset()`)
- Automatic internal memory management via `std.ArrayList`

**Limitations:**
- More verbose syntax
- Requires creating and freeing the builder
- Less flexible than pattern API for complex format strings

---

### 3. Generic API (Comptime Type Detection)

**Module:** `c_print_generic.zig`

This approach uses Zig's compile-time reflection (`@typeInfo`) to automatically detect argument types, validate them against format specifiers at comptime, and provide debug utilities for type inspection.

#### Main Function

```zig
const generic = c_print.c_print_generic;

try generic.C_PRINT(&writer, "{s:red} {d:green}", .{ "Hello", @as(i32, 42) });
```

#### Features

- Automatic type detection using `@typeInfo` at comptime
- Compile-time validation of argument types against format specifiers
- Runtime type mismatch detection via `validateAndReport`
- Debug mode to inspect detected types (`C_PRINT_DEBUG_TYPES`)
- Debug mode to inspect types and values (`C_PRINT_DEBUG_VALUES`)

#### Examples

```zig
const std = @import("std");
const c_print = @import("c_print");
const generic = c_print.c_print_generic;

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    const name: []const u8 = "Maria";
    const age: i32 = 30;
    const salary: f64 = 85000.75;

    // Automatic type detection
    try generic.C_PRINT(&writer, "Name: {s:blue}\n", .{name});
    try generic.C_PRINT(&writer, "Age: {d:yellow}\n", .{age});
    try generic.C_PRINT(&writer, "Salary: ${f:.2:green:,}\n", .{salary});

    // Compile-time validation
    const result = generic.validateArgs("{s} {d} {f}", .{ name, age, salary });
    // result.valid == true

    // Debug types
    try generic.C_PRINT_DEBUG_TYPES(&writer, "{s} {d} {f}", .{ name, age, salary });
    // Output:
    // [C_PRINT DEBUG] Pattern: {s} {d} {f}
    // [C_PRINT DEBUG] Argument count: 3
    // [C_PRINT DEBUG] Arg 0: string
    // [C_PRINT DEBUG] Arg 1: int
    // [C_PRINT DEBUG] Arg 2: double
}
```

#### Supported Types

- `[]const u8`, `[]u8`, string literals -> string
- `i8`, `i16`, `i32` -> integer
- `u8` -> char
- `u16`, `u32` -> unsigned
- `i64` -> long
- `u64` -> unsigned long
- `f32` -> float
- `f64` -> double
- `bool` -> bool

**Advantages:**
- Perfect combination of convenience and safety
- Simple syntax like pattern API
- Compile-time type checking with informative error messages
- Debug utilities for development

**Limitations:**
- Requires explicit type annotations for literals in tuples
- Minimal overhead for comptime validation

---

## Comparison of the 3 APIs

| Feature | Pattern | Builder | Generic |
|---------|---------|---------|---------|
| **Type Safety** | Comptime | Compile-time | Comptime + Runtime |
| **Variadic Functions** | No (tuples) | No | No (tuples) |
| **Memory Overhead** | Low | Internal buffer | Low |
| **Flexibility** | High | Limited | High |
| **Ease of Use** | Very easy | Moderate | Easy |
| **Error Messages** | Compile-time | Compile-time | Both |
| **Syntax** | Compact | Verbose | Compact |
| **Ideal Use Case** | General use | Critical code | Modern Zig projects |

### Which API to Choose?

- **Pattern API**: For most projects. Simple, flexible, and powerful.
- **Builder API**: For code requiring maximum type safety and programmatic construction.
- **Generic API**: For projects wanting compile-time validation with debug utilities.

---

## Installation

### Requirements

- **Zig** 0.16.0 or higher

### Build

```bash
# Clone the repository
git clone https://github.com/carlos-sweb/c_print.git
cd c_print

# Build the static library
zig build

# Run tests
zig build test
```

### Using as a Dependency

Add `c_print` to your `build.zig.zon` dependencies:

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .dependencies = .{
        .c_print = .{
            .url = "https://github.com/carlos-sweb/c_print/archive/refs/heads/main.tar.gz",
            .hash = "...",
        },
    },
}
```

Then in your `build.zig`:

```zig
const c_print_dep = b.dependency("c_print", .{
    .target = target,
    .optimize = optimize,
});

const exe = b.addExecutable(.{
    .name = "my_app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});

exe.root_module.addImport("c_print", c_print_dep.module("c_print"));
```

---

## Usage in Projects

### Option 1: As a Zig Module (Recommended)

```zig
const c_print = @import("c_print");

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    // Pattern API
    try c_print.c_print_mod.c_print(&writer, "Hello {s:green}!\n", .{"World"});

    // Builder API
    var b = c_print.c_print_builder.init(std.heap.page_allocator);
    defer c_print.c_print_builder.deinit(&b);
    _ = c_print.c_print_builder.withColorName(&b, "cyan")
        .append("Hello from builder");
    try c_print.c_print_builder.println(&b);

    // Generic API
    try c_print.c_print_generic.C_PRINT(
        &writer,
        "Value: {d:yellow}\n",
        .{@as(i32, 42)},
    );
}
```

### Option 2: Import Individual Modules

```zig
const c_print_mod = @import("c_print.zig").c_print_mod;
const c_print_builder = @import("c_print.zig").c_print_builder;
const c_print_generic = @import("c_print.zig").c_print_generic;
```

### Option 3: Direct File Import

```zig
const c_print_mod = @import("c_print.zig");
const builder = @import("c_print_builder.zig");
const generic = @import("c_print_generic.zig");
```

---

## Detailed Examples

### Example 1: System Dashboard

```zig
const std = @import("std");
const c_print = @import("c_print");
const cp = c_print.c_print_mod;

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    try cp.c_print(&writer, "\n{s:*^60:cyan:bold}\n", .{" SYSTEM STATUS "});

    try cp.c_print(&writer, "{s:<20} [{s:bright_green:bold}]\n", .{ "CPU", "OK" });
    try cp.c_print(
        &writer,
        "{s:<20} {d:,} MB ({f:.1%:yellow})\n",
        .{ "Memory", @as(i32, 8192), @as(f64, 0.65) },
    );
    try cp.c_print(
        &writer,
        "{s:<20} {d:,} / {d:,} GB\n",
        .{ "Disk", @as(i32, 450), @as(i32, 1000) },
    );
    try cp.c_print(
        &writer,
        "{s:<20} {f:.2:green} ms\n",
        .{ "Latency", @as(f64, 12.45) },
    );

    try cp.c_print(&writer, "{s:*^60:cyan}\n", .{""});

    _ = try std.io.getStdOut().write(writer.buffered());
}
```

### Example 2: Logging System

```zig
const std = @import("std");
const c_print = @import("c_print");
const Builder = c_print.c_print_builder;

const LogLevel = enum {
    info,
    warning,
    err,
    success,
};

fn log_message(allocator: std.mem.Allocator, level: LogLevel, message: []const u8) !void {
    var b = Builder.init(allocator);
    defer b.deinit();

    _ = b.appendText("[");

    switch (level) {
        .info => _ = b.withColorName("cyan").append("INFO"),
        .warning => _ = b.withColorName("yellow").append("WARN"),
        .err => _ = b.withStyleName("bold").withColorName("red").append("ERROR"),
        .success => _ = b.withColorName("green").append("OK"),
    }

    _ = b.appendText("] ");
    _ = b.append(message);
    try b.println();
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    try log_message(allocator, .info, "Starting application...");
    try log_message(allocator, .success, "Connection established");
    try log_message(allocator, .warning, "Cache nearly full");
    try log_message(allocator, .err, "Authentication failed");
}
```

### Example 3: Data Table

```zig
const std = @import("std");
const c_print = @import("c_print");
const generic = c_print.c_print_generic;

fn printTableRow(writer: *std.Io.Writer, name: []const u8, id: i32, value: f64) !void {
    try generic.C_PRINT(writer, "| {s:<20} | {d:>8:05} | {f:>12:.2:,} |\n", .{ name, id, value });
}

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    try generic.C_PRINT(&writer, "{s:=^60:bold}\n", .{" SALES REPORT "});
    try generic.C_PRINT(
        &writer,
        "| {s:<20} | {s:>8} | {s:>12} |\n",
        .{ "Product", "ID", "Price" },
    );
    try generic.C_PRINT(&writer, "{s:-^60}\n", .{""});

    try printTableRow(&writer, "Laptop", 1001, 899.99);
    try printTableRow(&writer, "Mouse", 2034, 29.99);
    try printTableRow(&writer, "Keyboard", 3102, 79.50);

    try generic.C_PRINT(&writer, "{s:=^60}\n", .{""});
    try generic.C_PRINT(
        &writer,
        "Total: {s:$}{f:.2:bright_green:bold:,}\n",
        .{ "", @as(f64, 1009.48) },
    );

    _ = try std.io.getStdOut().write(writer.buffered());
}
```

---

## Project Structure

```
c_print/
├── src/                              # Zig source files
│   ├── main.zig                     # Root module (re-exports all modules)
│   ├── c_print.zig                  # Pattern API implementation
│   ├── c_print_builder.zig          # Builder pattern API
│   ├── c_print_generic.zig          # Generic comptime API
│   ├── c_print_safe.zig             # Safe wrapper functions
│   ├── c_api.zig                    # C-ABI exported functions
│   ├── ansi_codes.zig               # ANSI code generation
│   ├── color_parser.zig             # Color/style name parser
│   ├── pattern_parser.zig           # Pattern {type:specs} parser
│   ├── number_formatter.zig         # Number formatting (separators, bases)
│   ├── text_alignment.zig           # Text alignment with fill
│   └── string_utils.zig             # String utilities
├── examples/                         # Example programs
│   ├── example_pattern_based.zig    # Pattern API example
│   ├── example_builder.zig          # Builder API example
│   ├── example_generic.zig          # Generic API example
│   ├── example_system_dashboard.zig # Dashboard demo
│   ├── example_logging.zig          # Logging system demo
│   └── example_data_table.zig       # Data table demo
├── test/
│   └── example_c_simple.c           # C-ABI compatibility example
├── build.zig                        # Zig build configuration
├── build.zig.zon                    # Package manifest
├── README.md                        # This file
└── LICENSE                          # MIT License
```

---

## Modular Architecture

The library is designed with a modular architecture where each component is independent:

### Core Modules

1. **ansi_codes** - ANSI code generation and application
2. **color_parser** - Parse color/style names to enums
3. **pattern_parser** - Parse `{type:specs}` patterns into `PatternStyle` structs
4. **number_formatter** - Number formatting (separators, bases, padding)
5. **text_alignment** - Text alignment with fill characters
6. **string_utils** - String utilities

### High-Level APIs

1. **c_print** - Pattern API (uses all core modules)
2. **c_print_builder** - Builder API (uses selected core modules)
3. **c_print_generic** - Generic API (comptime wrapper over c_print with type validation)

---

## Compatibility

### Zig Version

- **Zig 0.16.0**: All APIs fully supported
- Uses `std.Io.Writer` (Zig 0.16.0 API)
- Uses comptime reflection (`@typeInfo`, `inline for`, `inline switch`)

### Platforms

- Linux
- macOS
- Windows (with ANSI support in Windows 10+)
- BSD

---

## C-ABI Compatibility

The library exports C-ABI compatible functions that can be called from C code. This is useful for projects that want to use c_print from a C/C++ codebase.

### Exported Functions

```c
// Print a message with a color (0=red, 1=green, 2=blue, 3=yellow, 4=cyan, 5=magenta, 6=white, 7=black)
int c_print_color_msg(const char *message, int color_code);

// Print a bold message
int c_print_bold_msg(const char *message);

// Print a simple string (no formatting)
int c_print_puts(const char *message);

// Get library version string
const char *c_print_version(void);
```

### Building the C Example

```bash
# Build the static library
zig build lib

# Build and link the C example
zig build example_c_simple

# Run the example
./zig-out/bin/example_c_simple
```

### Using from C

```c
#include <stdio.h>

extern int c_print_puts(const char *message);
extern int c_print_color_msg(const char *message, int color_code);
extern int c_print_bold_msg(const char *message);

int main(void) {
    c_print_puts("Hello from C!");
    c_print_color_msg("This is green text", 1);
    c_print_bold_msg("This is bold text");
    return 0;
}
```

Compile and link:
```bash
cc example.c -L zig-out/lib -lc_print -o example
```

---

## Running Examples

After cloning the repository:

```bash
# Build the static library
zig build

# Run a specific example
zig build run -Dexample=pattern_based
zig build run -Dexample=builder
zig build run -Dexample=generic

# Run tests
zig build test

# Build the C-ABI example (requires a C compiler)
zig build example_c_simple
./zig-out/bin/example_c_simple
```

---

## Troubleshooting

### Colors not showing

**Problem**: Text appears with strange codes or without colors.

**Solution**:
- On Linux/macOS: Make sure you're using an ANSI-compatible terminal
- On Windows 10+: Enable ANSI support in console
- Verify `TERM` is configured correctly: `echo $TERM`

### Type mismatch errors

**Problem**: Compile errors about type mismatches in tuples.

**Solution**:
- Zig requires explicit types for integer and float literals in tuples
- Use `@as(i32, 42)` for integers, `@as(f64, 3.14)` for floats
- String literals (`[]const u8`) work without explicit casts

```zig
// Wrong: bare integer literal
try c_print(&writer, "{d}", .{42});

// Correct: explicit type
try c_print(&writer, "{d}", .{@as(i32, 42)});
```

### Builder output not visible

**Problem**: Builder `print` writes to stderr via `std.debug.print`.

**Solution**:
- Use `toString` to get the buffer contents and write them yourself
- Or use the pattern/generic API with a custom writer for stdout

---

## Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Contribution Guidelines

- Maintain Zig 0.16.0 compatibility
- Add tests for new features
- Document public APIs with doc comments
- Follow existing code style

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Author

**Carlos Illesca** - [GitHub](https://github.com/carlos-sweb)

---

## Acknowledgments

- Inspired by modern formatting libraries like fmt, Rich, and Chalk
- Zig community for feedback and contributions
- ANSI escape codes documentation

---

## Roadmap

### v0.2 (Planned)

- True Color support (24-bit RGB)
- Customizable themes
- Automatic terminal capability detection
- Automatic tables with borders
- Progress bars
- Animated spinners

### v0.3 (Future)

- Windows support without ANSI using WinAPI
- Integrated structured logging
- Performance profiling
- Benchmarking suite

---

## Frequently Asked Questions (FAQ)

### Can I use this library in commercial projects?

Yes, the MIT license allows commercial use without restrictions.

### Does it work on Windows?

Yes, on Windows 10+ which has native support for ANSI codes. On earlier versions, you would need to enable ANSI or use an alternative terminal.

### What is the performance overhead?

The overhead is minimal. Pattern parsing occurs once per call. The Builder API uses an `ArrayList` with amortized allocation. The Generic API does all validation at comptime with zero runtime cost.

### Can I mix the three APIs in the same project?

Yes, all three APIs are compatible and can be used simultaneously in the same program.

### Why does the builder use `std.debug.print`?

The builder's `print` and `println` use `std.debug.print` as a simple output mechanism. For production use, prefer `toString` to get the buffer contents and write them to your own writer.

### Are there alternatives to this library?

Yes, some alternatives in the Zig ecosystem include:
- **zig-clap** (CLI argument parsing with formatting)
- **zig-log** (structured logging)
- This library offers more formatting features and flexibility than most Zig alternatives.

---

## Additional Examples

### Progress Bar

```zig
const std = @import("std");
const c_print = @import("c_print");
const cp = c_print.c_print_mod;

fn showProgress(writer: *std.Io.Writer, percent: f64) !void {
    const filled: usize = @intFromFloat(percent * 40);
    try cp.c_print(writer, "[{s:green}", .{""});
    var i: usize = 0;
    while (i < filled) : (i += 1) {
        try writer.writeAll("█");
    }
    try cp.c_print(writer, "{s:dim}", .{""});
    i = filled;
    while (i < 40) : (i += 1) {
        try writer.writeAll("░");
    }
    try cp.c_print(writer, "{s}] {f:.1%}\r", .{ "", percent });
}

pub fn main() !void {
    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    var i: usize = 0;
    while (i <= 100) : (i += 1) {
        try showProgress(&writer, @as(f64, @floatFromInt(i)) / 100.0);
        _ = try std.io.getStdOut().write(writer.buffered());
        writer.reset();
        std.time.sleep(50 * std.time.ns_per_ms);
    }
    try std.io.getStdOut().writeAll("\n");
}
```

### Menu System

```zig
const std = @import("std");
const c_print = @import("c_print");
const cp = c_print.c_print_mod;

fn printMenu(writer: *std.Io.Writer) !void {
    try cp.c_print(writer, "\n{s:=^50:cyan:bold}\n", .{" MAIN MENU "});
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 1), "New Game" });
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 2), "Load Game" });
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 3), "Options" });
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 4), "Exit" });
    try cp.c_print(writer, "{s:=^50:cyan}\n", .{""});
    try cp.c_print(writer, "Select an option: ", .{});
}

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    try printMenu(&writer);
    _ = try std.io.getStdOut().write(writer.buffered());
}
```

---

## Contact

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/c_print/issues)
- **Email**: c4rl0sill3sc4@protonmail.com

---

<p align="center">
  Made with {s:red:bold} in Zig
</p>
