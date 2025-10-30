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
    std::string name = "Smith";
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

<a name="español"></a>
## 🇪🇸 Versión en Español

### 📖 Descripción

**c_print** es una potente librería de C que proporciona un sistema intuitivo y flexible para imprimir texto coloreado y formateado en la terminal usando códigos ANSI. Cuenta con una sintaxis basada en patrones similar a los format strings de Python, con amplio soporte para colores de texto, colores de fondo, estilos de texto, alineación, formateo numérico avanzado y más.

### ✨ Características

- 🎨 **16 colores de texto** (8 estándar + 8 brillantes)
- 🖼️ **16 colores de fondo**
- ✍️ **9 estilos de texto** (negrita, cursiva, subrayado, etc.)
- 📐 **Alineación de texto** (izquierda, derecha, centro) con caracteres de relleno personalizables
- 🔢 **Formateo avanzado de números**:
  - Control de precisión para floats (`.2`, `.4`)
  - Relleno con ceros (`05`, `08`)
  - Separadores de miles (`,` o `_`)
  - Visualización de signo (`+`)
  - Formato de porcentaje (`%`)
- 💻 **Múltiples bases numéricas**:
  - Binario (`b`) con prefijo opcional (`#b`)
  - Hexadecimal (`x`) con prefijo opcional (`#x`)
  - Octal (`o`) con prefijo opcional (`#o`)
- 🔄 **Orden flexible** de especificaciones de estilo
- 📝 **Múltiples tipos de datos** (string, int, float, char, binario, hex, octal, etc.)
- 🚀 **Fácil de usar** con sintaxis de patrones intuitiva
- 📚 **Librerías compartidas y estáticas** (.so, .a, .dll)
- 🔗 **Compatible con C++** mediante `extern "C"`

### 🔧 Instalación

#### Requisitos
- CMake 3.15 o superior
- Sistema de compilación Ninja
- Compilador de C (GCC, Clang, o MSVC)
- Compilador de C++ (opcional, para ejemplos C++)

#### Descarga
```bash
git clone https://github.com/tuusuario/c_print.git
cd c_print
```

#### Compilación

**Con Ninja (recomendado):**
```bash
cmake -G Ninja -B build
ninja -C build
```

**Con Make:**
```bash
cmake -B build
cmake --build build
```

**Con símbolos de depuración (para Valgrind):**
```bash
cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=Debug
ninja -C build
```

Esto generará:
- `libc_print.so` - Librería compartida (Linux)
- `libc_print.a` - Librería estática (Linux)
- `c_print.dll` - Librería compartida (Windows)
- `example_shared`, `example_static`, `example_cpp` - Programas de ejemplo

#### Instalación
```bash
sudo ninja -C build install
```

### 📦 Uso de la Librería

#### Incluir en tu proyecto:

**Método 1: Usando pkg-config**
```bash
gcc miprograma.c $(pkg-config --cflags --libs c_print) -o miprograma
```

**Método 2: Enlace manual**
```bash
# Librería compartida
gcc miprograma.c -lc_print -o miprograma

# Librería estática
gcc miprograma.c /usr/local/lib/libc_print.a -o miprograma
```

**Método 3: Incluir archivos fuente directamente**
```bash
gcc miprograma.c c_print.c -o miprograma
```

**Para C++:**
```bash
g++ miprograma.cpp c_print.c -o miprograma
```

### 🎨 Uso Básico

```c
#include "c_print.h"

int main() {
    // Texto simple con color
    c_print("Hola {s:green}!\n", "Mundo");
    
    // Texto con color y fondo
    c_print("Esto es {s:red:bg_white}\n", "importante");
    
    // Texto con color, fondo y estilo
    c_print("Mensaje: {s:cyan:bg_black:bold}\n", "ÉXITO");
    
    // Múltiples valores
    c_print("Usuario: {s:green}, Puntos: {d:yellow}\n", "Juan", 1500);
    
    // Con alineación de texto
    c_print("|{s:<20}|\n", "Alineado izq");
    c_print("|{s:>20}|\n", "Alineado der");
    c_print("|{s:^20}|\n", "Centrado");
    
    // Con caracteres de relleno
    c_print("|{s:*^20}|\n", "TEXTO");            // |*******TEXTO*******|
    c_print("|{s:->30}|\n", "DERECHA");          // |---------------------DERECHA|
    c_print("+{s:-^40}+\n", " TÍTULO ");         // +--------------- TÍTULO ---------------+
    
    // Formateo avanzado de números
    c_print("Precio: ${f:.2}\n", 1234.56);       // Precio: $1234.56
    c_print("ID: {d:05}\n", 42);                 // ID: 00042
    c_print("Cantidad: {d:,}\n", 1234567);       // Cantidad: 1,234,567
    c_print("Binario: {#b}\n", 42);              // Binario: 0b101010
    c_print("Progreso: {f:.1%}\n", 0.856);       // Progreso: 85.6%
    
    return 0;
}
```

### 📝 Sintaxis de Patrones

```
{tipo:especificaciones}
```

Donde especificaciones pueden ser (en cualquier orden):
- **tipo**: `s` (string), `d` (int), `f` (float), `c` (char), `b` (binario), `x` (hex), `o` (octal), `u` (unsigned)
- **modificadores numéricos**:
  - `.N` - Precisión para floats (ej., `.2` para 2 decimales)
  - `0N` - Relleno con ceros (ej., `05` rellena con ceros hasta ancho 5)
  - `,` - Separador de miles con comas
  - `_` - Separador de miles con guiones bajos
  - `#` - Mostrar prefijo (`0b`, `0x`, `0o`)
  - `+` - Mostrar signo siempre
  - `%` - Mostrar como porcentaje (multiplica por 100)
- **color**: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`, `bright_*`
- **fondo**: `bg_red`, `bg_green`, `bg_blue`, etc.
- **estilo**: `bold`, `italic`, `underline`, `dim`, `blink`, `reverse`, `strikethrough`
- **alineación**: `<N` (izq), `>N` (der), `^N` (centro) donde N es el ancho
- **carácter de relleno**: Cualquier carácter antes de la alineación (ej., `*^20`, `->30`, `.>25`)

### 🎯 Ejemplos Completos

La librería incluye **37+ ejemplos prácticos** demostrando todas las características. Ejecuta `./build/example_shared` para verlos todos.

#### Ejemplos Básicos (1-17):
1. Uso básico de patrones
2. Colores de texto
3. Colores de texto y fondo
4. Patrones completos (color + fondo + estilo)
5. Múltiples patrones en una línea
6. Diferentes tipos de datos
7. Hexadecimal y octal
8. Solo estilos
9. Solo fondo
10. Combinaciones complejas
11. Simulación de logs del sistema
12. Tablas con colores
13. Barras de progreso
14. Escape de llaves literales
15. Menús interactivos
16. Indicadores de estado
17. Comparación sistema antiguo vs nuevo

#### Ejemplos Avanzados (18-27):
18. Alineación de texto (izquierda, derecha, centro)
19. Orden flexible de especificaciones
20. Alineación con colores y estilos
21. Tablas profesionales con alineación
22. Menús centrados
23. Logs formateados con timestamps
24. Barras de progreso avanzadas
25. Paneles de información
26. Dashboards de métricas
27. Todos los tipos de datos con alineación

#### Ejemplos de Nuevo Formateo (28-37):
28. Caracteres de relleno (`*`, `-`, `.`, `=`)
29. Líneas decorativas
30. Tablas con líneas horizontales
31. Menús con bordes decorativos
32. Indicadores de progreso con rellenos personalizados
33. Etiquetas con puntos guía
34. Facturas profesionales
35. Alertas y notificaciones
36. Separadores estilizados
37. Tablas de precios

### 🔢 Formateo Avanzado de Números

#### Control de Precisión
```c
c_print("Pi: {f:.2}\n", 3.14159);              // Pi: 3.14
c_print("Precio: ${f:.2}\n", 99.999);          // Precio: $100.00
c_print("Científico: {f:.4}\n", 0.00012345);   // Científico: 0.0001
```

#### Relleno con Ceros
```c
c_print("ID: {d:05}\n", 42);                   // ID: 00042
c_print("Código: {d:08}\n", 123);              // Código: 00000123
c_print("Hex: {x:08}\n", 255);                 // Hex: 000000ff
```

#### Separadores de Miles
```c
c_print("Población: {d:,}\n", 1234567);        // Población: 1,234,567
c_print("Distancia: {d:_}\n", 9876543);        // Distancia: 9_876_543
c_print("Dinero: ${d:,}\n", 1000000);          // Dinero: $1,000,000
```

#### Formato Binario
```c
c_print("Binario: {b}\n", 42);                 // Binario: 101010
c_print("Con prefijo: {#b}\n", 42);            // Con prefijo: 0b101010
c_print("Flags: {#b:yellow}\n", 170);          // Flags: 0b10101010 (en amarillo)
```

#### Prefijos para Hex y Octal
```c
c_print("Hex: {x}\n", 255);                    // Hex: ff
c_print("Hex con prefijo: {#x}\n", 255);       // Hex con prefijo: 0xff
c_print("Octal: {o}\n", 64);                   // Octal: 100
c_print("Octal con prefijo: {#o}\n", 64);      // Octal con prefijo: 0o100
```

#### Formato de Porcentaje
```c
c_print("Progreso: {f:%}\n", 0.856);           // Progreso: 85.6%
c_print("Uso CPU: {f:.1%}\n", 0.75);           // Uso CPU: 75.0%
c_print("Completo: {f:.2%}\n", 0.5);           // Completo: 50.00%
```

#### Visualización de Signo
```c
c_print("Temperatura: {d:+}°C\n", 25);         // Temperatura: +25°C
c_print("Cambio: {d:+}\n", -10);               // Cambio: -10
c_print("Positivo: {d:+}\n", 5);               // Positivo: +5
```

#### Combinaciones Complejas
```c
// Precio con precisión, separador de miles, color y alineación
c_print("Total: ${f:.2:,:>15:green:bold}\n", 1234567.89);

// ID con relleno de ceros, color y alineación centrada
c_print("ID: {d:06:^20:cyan}\n", 42);

// Porcentaje con precisión, carácter de relleno y color
c_print("Progreso: {f:.1%:*^30:yellow}\n", 0.678);

// Hex con prefijo, padding, color y alineación derecha
c_print("Color: {#x:08:>15:magenta}\n", 0xFF00FF);
```

### 🎨 Colores Disponibles

**Colores de texto:**
`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
`bright_black`, `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`

**Colores de fondo:**
Los mismos que colores de texto con prefijo `bg_`: `bg_black`, `bg_red`, `bg_green`, etc.

**Estilos:**
`bold`, `dim`, `italic`, `underline`, `blink`, `reverse`, `hidden`, `strikethrough`

### 💻 Uso en C++

La librería es totalmente compatible con C++:

```cpp
#include "c_print.h"
#include <string>

int main() {
    std::string nombre = "Claude";
    int valor = 42;
    
    // Usa .c_str() para std::string
    c_print("Hola {s:green}!\n", nombre.c_str());
    c_print("Valor: {d:05:cyan}\n", valor);
    
    // Funciona también en clases
    class MiClase {
    public:
        void mostrar() {
            c_print("{s:bold:yellow}\n", "Desde clase C++");
        }
    };
    
    return 0;
}
```

### 🔍 Pruebas de Memoria con Valgrind

```bash
# Compilar con símbolos de depuración
cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=Debug
ninja -C build

# Ejecutar Valgrind
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
         ./build/example_shared
```

### 📊 Casos de Uso del Mundo Real

#### Factura Profesional
```c
c_print("+{s:=^50:bright_white:bold}+\n", " FACTURA #00042 ");
c_print("| {s:.<28} ${f:>17:.2:bright_green:bold} |\n", "Subtotal", 8250.50);
c_print("| {s:.<28} ${f:>17:.2:yellow} |\n", "IVA (21%)", 1732.61);
c_print("+{s:-^50}+\n", "");
c_print("| {s:.<28:bold} ${f:>17:.2:bright_cyan:bold} |\n", "TOTAL", 9983.11);
c_print("+{s:=^50:bright_white:bold}+\n", "");
```

#### Dashboard de Métricas del Sistema
```c
c_print("╔{s:═^58}╗\n", "");
c_print("║ {s:^58:bright_cyan:bold} ║\n", "MÉTRICAS DEL SISTEMA");
c_print("╠{s:═^58}╣\n", "");
c_print("║ {s:.<25} {d:>30:,:bright_green:bold} ║\n", "Usuarios Activos", 123456);
c_print("║ {s:.<25} {f:>29:.1%:bright_yellow:bold} ║\n", "Uso de CPU", 0.67);
c_print("║ {s:.<25} ${f:>28:.2:bright_cyan:bold} ║\n", "Ingresos", 456789.50);
c_print("╚{s:═^58}╝\n", "");
```

#### Visualización de Datos Técnicos
```c
c_print("ID de Proceso:    {d:08:cyan}\n", 1234);
c_print("Código de Error:  {#x:08:red:bold}\n", 0x404);
c_print("Flags (binario):  {#b:yellow}\n", 0b10101010);
c_print("Permisos:         {#o:green}\n", 0755);
c_print("Temperatura:      {d:+:red}°C\n", 78);
```

### 📄 Licencia

Licencia MIT - Ver archivo LICENSE para detalles

### 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Por favor siéntete libre de enviar un Pull Request.

---

### 📞 Contact / Contacto

For questions or support, please open an issue on GitHub.  
Para preguntas o soporte, por favor abre un issue en GitHub.

### 🌟 Quick Reference / Referencia Rápida

#### Format Specifiers / Especificadores de Formato

| Specifier | Description | Example |
|-----------|-------------|---------|
| `{s}` | String | `{s:green}` |
| `{d}` | Integer | `{d:05}` |
| `{f}` | Float | `{f:.2}` |
| `{b}` | Binary | `{#b}` |
| `{x}` | Hexadecimal | `{#x:08}` |
| `{o}` | Octal | `{#o}` |

#### Numeric Modifiers / Modificadores Numéricos

| Modifier | Description | Example |
|----------|-------------|---------|
| `.N` | Precision | `{f:.2}` → `3.14` |
| `0N` | Zero-padding | `{d:05}` → `00042` |
| `,` | Comma separator | `{d:,}` → `1,234,567` |
| `_` | Underscore separator | `{d:_}` → `1_000_000` |
| `#` | Show prefix | `{#x}` → `0xff` |
| `+` | Always show sign | `{d:+}` → `+42` |
| `%` | Percentage | `{f:%}` → `85.6%` |

#### Alignment / Alineación

| Specifier | Description | Example |
|-----------|-------------|---------|
| `<N` | Left align | `{s:<20}` |
| `>N` | Right align | `{s:>20}` |
| `^N` | Center align | `{s:^20}` |
| `*^N` | Fill with `*` | `{s:*^20}` |
| `->N` | Fill with `-` | `{s:->20}` |

#### Colors / Colores

| Colors | Bright Colors |
|--------|---------------|
| `red`, `green`, `blue` | `bright_red`, `bright_green` |
| `yellow`, `cyan`, `magenta` | `bright_yellow`, `bright_cyan` |
| `white`, `black` | `bright_white`, `bright_black` |

#### Styles / Estilos

`bold`, `italic`, `underline`, `dim`, `blink`, `reverse`, `strikethrough`

---

**Version / Versión:** 1.0.0  
**License / Licencia:** MIT  
**Author / Autor:** Your Name  
**Repository / Repositorio:** https://github.com/yourusername/c_print