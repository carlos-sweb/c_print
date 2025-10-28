# c_print - Colored Text Printing Library for C

[🇪🇸 Versión en Español](#español) | [🇬🇧 English Version](#english)

---

<a name="english"></a>
## 🇬🇧 English Version

### 📖 Description

**c_print** is a powerful C library that provides an intuitive and flexible system for printing colored and formatted text in the terminal using ANSI codes. It features a pattern-based syntax similar to Python's format strings, with extensive support for text colors, background colors, text styles, alignment, numeric formatting, and more.

### ✨ Features

- 🎨 **16 text colors** (8 standard + 8 bright)
- 🖼️ **16 background colors**
- ✍️ **9 text styles** (bold, italic, underline, etc.)
- 📐 **Text alignment** (left, right, center) with custom fill characters
- 🔢 **Advanced number formatting**:
  - Precision control for floats (`.2`, `.4`)
  - Zero-padding (`05`, `08`)
  - Thousands separators (`,` or `_`)
  - Sign display (`+`)
  - Percentage format (`%`)
- 💻 **Multiple number bases**:
  - Binary (`b`) with optional prefix (`#b`)
  - Hexadecimal (`x`) with optional prefix (`#x`)
  - Octal (`o`) with optional prefix (`#o`)
- 🔄 **Flexible order** of style specifications
- 📝 **Multiple data types** (string, int, float, char, binary, hex, octal, etc.)
- 🚀 **Easy to use** with intuitive pattern syntax
- 📚 **Shared and static libraries** (.so, .a, .dll)
- 🔗 **C++ compatible** with `extern "C"` support

### 🔧 Installation

#### Requirements
- CMake 3.15 or higher
- Ninja build system
- C compiler (GCC, Clang, or MSVC)
- C++ compiler (optional, for C++ examples)

#### Download
```bash
git clone https://github.com/yourusername/c_print.git
cd c_print
```

#### Compilation

**With Ninja (recommended):**
```bash
cmake -G Ninja -B build
ninja -C build
```

**With Make:**
```bash
cmake -B build
cmake --build build
```

**With Debug symbols (for Valgrind):**
```bash
cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=Debug
ninja -C build
```

This will generate:
- `libc_print.so` - Shared library (Linux)
- `libc_print.a` - Static library (Linux)
- `c_print.dll` - Shared library (Windows)
- `example_shared`, `example_static`, `example_cpp` - Example programs

#### Installation
```bash
sudo ninja -C build install
```

### 📦 Library Usage

#### Include in your project:

**Method 1: Using pkg-config**
```bash
gcc myprogram.c $(pkg-config --cflags --libs c_print) -o myprogram
```

**Method 2: Manual linking**
```bash
# Shared library
gcc myprogram.c -lc_print -o myprogram

# Static library
gcc myprogram.c /usr/local/lib/libc_print.a -o myprogram
```

**Method 3: Include source files directly**
```bash
gcc myprogram.c c_print.c -o myprogram
```

**For C++:**
```bash
g++ myprogram.cpp c_print.c -o myprogram
```

### 🎨 Basic Usage

```c
#include "c_print.h"

int main() {
    // Simple text with color
    c_print("Hello {s:green}!\n", "World");
    
    // Text with color and background
    c_print("This is {s:red:bg_white}\n", "important");
    
    // Text with color, background and style
    c_print("Message: {s:cyan:bg_black:bold}\n", "SUCCESS");
    
    // Multiple values
    c_print("User: {s:green}, Points: {d:yellow}\n", "John", 1500);
    
    // With text alignment
    c_print("|{s:<20}|\n", "Left aligned");
    c_print("|{s:>20}|\n", "Right aligned");
    c_print("|{s:^20}|\n", "Centered");
    
    // With fill characters
    c_print("|{s:*^20}|\n", "STAR");           // |*******STAR********|
    c_print("|{s:->30}|\n", "RIGHT");          // |------------------------RIGHT|
    c_print("+{s:-^40}+\n", " TITLE ");        // +--------------- TITLE ---------------+
    
    // Advanced number formatting
    c_print("Price: ${f:.2}\n", 1234.56);      // Price: $1234.56
    c_print("ID: {d:05}\n", 42);               // ID: 00042
    c_print("Count: {d:,}\n", 1234567);        // Count: 1,234,567
    c_print("Binary: {#b}\n", 42);             // Binary: 0b101010
    c_print("Progress: {f:.1%}\n", 0.856);     // Progress: 85.6%
    
    return 0;
}
```

### 📝 Pattern Syntax

```
{type:specifications}
```

Where specifications can be (in any order):
- **type**: `s` (string), `d` (int), `f` (float), `c` (char), `b` (binary), `x` (hex), `o` (octal), `u` (unsigned)
- **numeric modifiers**:
  - `.N` - Precision for floats (e.g., `.2` for 2 decimals)
  - `0N` - Zero-padding (e.g., `05` pads with zeros to width 5)
  - `,` - Thousands separator with commas
  - `_` - Thousands separator with underscores
  - `#` - Show prefix (`0b`, `0x`, `0o`)
  - `+` - Always show sign
  - `%` - Display as percentage (multiplies by 100)
- **color**: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`, `bright_*`
- **background**: `bg_red`, `bg_green`, `bg_blue`, etc.
- **style**: `bold`, `italic`, `underline`, `dim`, `blink`, `reverse`, `strikethrough`
- **alignment**: `<N` (left), `>N` (right), `^N` (center) where N is the width
- **fill character**: Any character before alignment (e.g., `*^20`, `->30`, `.>25`)

### 🎯 Complete Examples

The library includes **37+ practical examples** demonstrating all features. Run `./build/example_shared` to see them all.

#### Core Examples (1-17):
1. Basic pattern usage
2. Text colors
3. Text and background colors
4. Complete patterns (color + background + style)
5. Multiple patterns in one line
6. Different data types
7. Hexadecimal and octal
8. Styles only
9. Background only
10. Complex combinations
11. System logs simulation
12. Colored tables
13. Progress bars
14. Literal braces escape
15. Interactive menus
16. Status indicators
17. Old vs new system comparison

#### Advanced Examples (18-27):
18. Text alignment (left, right, center)
19. Flexible order of specifications
20. Alignment with colors and styles
21. Professional tables with alignment
22. Centered menus
23. Formatted logs with timestamps
24. Advanced progress bars
25. Information panels
26. Metrics dashboards
27. All data types with alignment

#### New Formatting Examples (28-37):
28. Fill characters (`*`, `-`, `.`, `=`)
29. Decorative lines
30. Tables with horizontal lines
31. Menus with decorative borders
32. Progress indicators with custom fills
33. Labels with dot leaders
34. Professional invoices
35. Alerts and notifications
36. Styled separators
37. Pricing tables

### 🔢 Advanced Number Formatting

#### Precision Control
```c
c_print("Pi: {f:.2}\n", 3.14159);              // Pi: 3.14
c_print("Price: ${f:.2}\n", 99.999);           // Price: $100.00
c_print("Scientific: {f:.4}\n", 0.00012345);   // Scientific: 0.0001
```

#### Zero-Padding
```c
c_print("ID: {d:05}\n", 42);                   // ID: 00042
c_print("Code: {d:08}\n", 123);                // Code: 00000123
c_print("Hex: {x:08}\n", 255);                 // Hex: 000000ff
```

#### Thousands Separators
```c
c_print("Population: {d:,}\n", 1234567);       // Population: 1,234,567
c_print("Distance: {d:_}\n", 9876543);         // Distance: 9_876_543
c_print("Money: ${d:,}\n", 1000000);           // Money: $1,000,000
```

#### Binary Format
```c
c_print("Binary: {b}\n", 42);                  // Binary: 101010
c_print("With prefix: {#b}\n", 42);            // With prefix: 0b101010
c_print("Flags: {#b:yellow}\n", 170);          // Flags: 0b10101010 (in yellow)
```

#### Prefixes for Hex and Octal
```c
c_print("Hex: {x}\n", 255);                    // Hex: ff
c_print("Hex with prefix: {#x}\n", 255);       // Hex with prefix: 0xff
c_print("Octal: {o}\n", 64);                   // Octal: 100
c_print("Octal with prefix: {#o}\n", 64);      // Octal with prefix: 0o100
```

#### Percentage Format
```c
c_print("Progress: {f:%}\n", 0.856);           // Progress: 85.6%
c_print("CPU Usage: {f:.1%}\n", 0.75);         // CPU Usage: 75.0%
c_print("Complete: {f:.2%}\n", 0.5);           // Complete: 50.00%
```

#### Sign Display
```c
c_print("Temperature: {d:+}°C\n", 25);         // Temperature: +25°C
c_print("Change: {d:+}\n", -10);               // Change: -10
c_print("Positive: {d:+}\n", 5);               // Positive: +5
```

#### Complex Combinations
```c
// Price with precision, thousands separator, color and alignment
c_print("Total: ${f:.2:,:>15:green:bold}\n", 1234567.89);

// ID with zero-padding, color and center alignment
c_print("ID: {d:06:^20:cyan}\n", 42);

// Percentage with precision, fill character and color
c_print("Progress: {f:.1%:*^30:yellow}\n", 0.678);

// Hex with prefix, padding, color and right alignment
c_print("Color: {#x:08:>15:magenta}\n", 0xFF00FF);
```

### 🎨 Available Colors

**Text colors:**
`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
`bright_black`, `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`

**Background colors:**
Same as text colors with `bg_` prefix: `bg_black`, `bg_red`, `bg_green`, etc.

**Styles:**
`bold`, `dim`, `italic`, `underline`, `blink`, `reverse`, `hidden`, `strikethrough`

### 💻 C++ Usage

The library is fully compatible with C++:

```cpp
#include "c_print.h"
#include <string>

int main() {
    std::string name = "James";
    int value = 42;
    
    // Use .c_str() for std::string
    c_print("Hello {s:green}!\n", name.c_str());
    c_print("Value: {d:05:cyan}\n", value);
    
    // Works in classes too
    class MyClass {
    public:
        void display() {
            c_print("{s:bold:yellow}\n", "From C++ class");
        }
    };
    
    return 0;
}
```

### 🔍 Memory Testing with Valgrind

```bash
# Compile with debug symbols
cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=Debug
ninja -C build

# Run Valgrind
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
         ./build/example_shared
```

### 📊 Real-World Use Cases

#### Professional Invoice
```c
c_print("+{s:=^50:bright_white:bold}+\n", " INVOICE #00042 ");
c_print("| {s:.<28} ${f:>17:.2:bright_green:bold} |\n", "Subtotal", 8250.50);
c_print("| {s:.<28} ${f:>17:.2:yellow} |\n", "Tax (21%)", 1732.61);
c_print("+{s:-^50}+\n", "");
c_print("| {s:.<28:bold} ${f:>17:.2:bright_cyan:bold} |\n", "TOTAL", 9983.11);
c_print("+{s:=^50:bright_white:bold}+\n", "");
```

#### System Metrics Dashboard
```c
c_print("╔{s:═^58}╗\n", "");
c_print("║ {s:^58:bright_cyan:bold} ║\n", "SYSTEM METRICS");
c_print("╠{s:═^58}╣\n", "");
c_print("║ {s:.<25} {d:>30:,:bright_green:bold} ║\n", "Active Users", 123456);
c_print("║ {s:.<25} {f:>29:.1%:bright_yellow:bold} ║\n", "CPU Usage", 0.67);
c_print("║ {s:.<25} ${f:>28:.2:bright_cyan:bold} ║\n", "Revenue", 456789.50);
c_print("╚{s:═^58}╝\n", "");
```

#### Technical Data Display
```c
c_print("Process ID:       {d:08:cyan}\n", 1234);
c_print("Error Code:       {#x:08:red:bold}\n", 0x404);
c_print("Flags (binary):   {#b:yellow}\n", 0b10101010);
c_print("Permissions:      {#o:green}\n", 0755);
c_print("Temperature:      {d:+:red}°C\n", 78);
```

### 📄 License

MIT License - See LICENSE file for details

### 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---