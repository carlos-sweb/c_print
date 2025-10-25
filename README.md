# c_print - Colored Text Printing Library for C

[🇪🇸 Versión en Español](#español) | [🇬🇧 English Version](#english)

---

<a name="english"></a>
## 🇬🇧 English Version

### 📖 Description

**c_print** is a C library that provides an intuitive and powerful system for printing colored text in the terminal using ANSI codes. It features a flexible pattern-based syntax similar to Python's format strings, with support for text colors, background colors, text styles, and text alignment.

### ✨ Features

- 🎨 **16 text colors** (8 standard + 8 bright)
- 🖼️ **16 background colors**
- ✍️ **9 text styles** (bold, italic, underline, etc.)
- 📐 **Text alignment** (left, right, center)
- 🔄 **Flexible order** of style specifications
- 📝 **Multiple data types** (string, int, float, char, hex, octal, etc.)
- 🚀 **Easy to use** with intuitive pattern syntax
- 📚 **Shared and static libraries** (.so, .a, .dll)

### 🔧 Installation

#### Requirements
- CMake 3.15 or higher
- Ninja build system
- C compiler (GCC, Clang, or MSVC)

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
- `example_shared` and `example_static` - Example programs

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
    
    return 0;
}
```

### 📝 Pattern Syntax

```
{type:specifications}
```

Where specifications can be (in any order):
- **type**: `s` (string), `d` (int), `f` (float), `c` (char), `x` (hex), `o` (octal), `u` (unsigned)
- **color**: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`, `bright_*`
- **background**: `bg_red`, `bg_green`, `bg_blue`, etc.
- **style**: `bold`, `italic`, `underline`, `dim`, `blink`, `reverse`, `strikethrough`
- **alignment**: `<N` (left), `>N` (right), `^N` (center) where N is the width

### 🎯 Complete Examples (27 total)

#### Examples 1-17: Basic Features
1. **Basic pattern** - Simple type usage
2. **Text color** - Colored text
3. **Text and background color** - Combined colors
4. **Complete pattern** - Color + background + style
5. **Multiple patterns** - Multiple values in one line
6. **Different data types** - String, int, float, char
7. **Hexadecimal and octal** - Number format variations
8. **Styles only** - Bold, italic, underline without colors
9. **Background only** - Background colors without text colors
10. **Complex combinations** - Advanced color combinations
11. **System logs** - Error, warning, info messages simulation
12. **Colored table** - Simple table with colors
13. **Progress bar** - Simulated progress indicators
14. **Literal braces escape** - Using `\{` for literal braces
15. **Interactive menu** - Menu with colors and styles
16. **Status indicators** - Service status with colored bullets
17. **Comparison** - Old system vs new pattern system

#### Examples 18-27: Advanced Features with Alignment
18. **Text alignment** - Left, right, center alignment demonstrations
19. **Flexible order** - Specifications in any order
20. **Alignment with colors** - Combined alignment and styling
21. **Aligned table** - Professional table with column alignment
22. **Centered menu** - Menu system with centered title
23. **Formatted logs** - Logs with aligned timestamps
24. **Progress bars with alignment** - Advanced progress indicators
25. **Information panel** - System info display with borders
26. **Metrics dashboard** - Server metrics with styled layout
27. **All data types** - All supported types with alignment

### 🎨 Available Colors

**Text colors:**
`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `bright_black`, `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`

**Background colors:**
Same as text colors with `bg_` prefix: `bg_black`, `bg_red`, `bg_green`, etc.

**Styles:**
`bold`, `dim`, `italic`, `underline`, `blink`, `reverse`, `hidden`, `strikethrough`

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

### 📄 License

MIT License - See LICENSE file for details

### 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<a name="español"></a>
## 🇪🇸 Versión en Español

### 📖 Descripción

**c_print** es una librería de C que proporciona un sistema intuitivo y potente para imprimir texto con colores en la terminal usando códigos ANSI. Cuenta con una sintaxis flexible basada en patrones similar a los format strings de Python, con soporte para colores de texto, colores de fondo, estilos de texto y alineación de texto.

### ✨ Características

- 🎨 **16 colores de texto** (8 estándar + 8 brillantes)
- 🖼️ **16 colores de fondo**
- ✍️ **9 estilos de texto** (negrita, cursiva, subrayado, etc.)
- 📐 **Alineación de texto** (izquierda, derecha, centro)
- 🔄 **Orden flexible** de especificaciones de estilo
- 📝 **Múltiples tipos de datos** (string, int, float, char, hex, octal, etc.)
- 🚀 **Fácil de usar** con sintaxis de patrones intuitiva
- 📚 **Librerías compartidas y estáticas** (.so, .a, .dll)

### 🔧 Instalación

#### Requisitos
- CMake 3.15 o superior
- Sistema de compilación Ninja
- Compilador de C (GCC, Clang, o MSVC)

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
- `example_shared` y `example_static` - Programas de ejemplo

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
    
    return 0;
}
```

### 📝 Sintaxis de Patrones

```
{tipo:especificaciones}
```

Donde especificaciones pueden ser (en cualquier orden):
- **tipo**: `s` (string), `d` (int), `f` (float), `c` (char), `x` (hex), `o` (octal), `u` (unsigned)
- **color**: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`, `bright_*`
- **fondo**: `bg_red`, `bg_green`, `bg_blue`, etc.
- **estilo**: `bold`, `italic`, `underline`, `dim`, `blink`, `reverse`, `strikethrough`
- **alineación**: `<N` (izq), `>N` (der), `^N` (centro) donde N es el ancho

### 🎯 Ejemplos Completos (27 en total)

#### Ejemplos 1-17: Características Básicas
1. **Patrón básico** - Uso simple de tipo
2. **Color de texto** - Texto coloreado
3. **Color de texto y fondo** - Colores combinados
4. **Patrón completo** - Color + fondo + estilo
5. **Múltiples patrones** - Múltiples valores en una línea
6. **Diferentes tipos de datos** - String, int, float, char
7. **Hexadecimal y octal** - Variaciones de formato numérico
8. **Solo estilos** - Negrita, cursiva, subrayado sin colores
9. **Solo fondo** - Colores de fondo sin colores de texto
10. **Combinaciones complejas** - Combinaciones avanzadas de colores
11. **Logs de sistema** - Simulación de mensajes de error, advertencia, info
12. **Tabla con colores** - Tabla simple con colores
13. **Barra de progreso** - Indicadores de progreso simulados
14. **Escape de llaves literales** - Usando `\{` para llaves literales
15. **Menú interactivo** - Menú con colores y estilos
16. **Indicadores de estado** - Estado de servicios con bullets coloreados
17. **Comparación** - Sistema antiguo vs nuevo sistema de patrones

#### Ejemplos 18-27: Características Avanzadas con Alineación
18. **Alineación de texto** - Demostraciones de alineación izquierda, derecha, centro
19. **Orden flexible** - Especificaciones en cualquier orden
20. **Alineación con colores** - Combinación de alineación y estilos
21. **Tabla alineada** - Tabla profesional con alineación de columnas
22. **Menú centrado** - Sistema de menú con título centrado
23. **Logs formateados** - Logs con timestamps alineados
24. **Barras de progreso con alineación** - Indicadores avanzados de progreso
25. **Panel de información** - Visualización de info del sistema con bordes
26. **Dashboard de métricas** - Métricas del servidor con diseño estilizado
27. **Todos los tipos de datos** - Todos los tipos soportados con alineación

### 🎨 Colores Disponibles

**Colores de texto:**
`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `bright_black`, `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`

**Colores de fondo:**
Los mismos que colores de texto con prefijo `bg_`: `bg_black`, `bg_red`, `bg_green`, etc.

**Estilos:**
`bold`, `dim`, `italic`, `underline`, `blink`, `reverse`, `hidden`, `strikethrough`

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

### 📄 Licencia

Licencia MIT - Ver archivo LICENSE para detalles

### 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Por favor siéntete libre de enviar un Pull Request.

---

### 📞 Contact / Contacto

For questions or support, please open an issue on GitHub.  
Para preguntas o soporte, por favor abre un issue en GitHub.