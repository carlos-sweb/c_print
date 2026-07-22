# c_print

**Biblioteca Zig para imprimir texto coloreado y formateado en la consola usando codigos de escape ANSI**

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/carlos-sweb/c_print)
[![Zig](https://img.shields.io/badge/Zig-0.16.0-orange.svg)](https://ziglang.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[English](README.md) | Espanol

## Descripcion

`c_print` es una biblioteca completa de Zig que proporciona tres enfoques distintos para imprimir texto formateado y coloreado en la terminal. Con soporte para colores ANSI, estilos de texto, alineacion avanzada y formateo de numeros, la biblioteca ofrece flexibilidad para diferentes casos de uso y preferencias de programacion.

Construida enteramente en Zig 0.16.0, aprovechando la seguridad de tipos en comptime, la API `std.Io.Writer` y el poderoso reflejo en tiempo de compilacion de Zig. Los usuarios de C pueden integrar la biblioteca via las funciones exportadas compatibles con C-ABI.

## Caracteristicas Principales

- 16 colores ANSI (8 estandar + 8 brillantes)
- 8 estilos de texto (negrita, cursiva, subrayado, etc.)
- Alineacion de texto (izquierda, derecha, centro con caracteres de relleno personalizables)
- Formateo avanzado de numeros (separadores de miles, relleno, bases numericas)
- Tres APIs distintas para diferentes necesidades
- Seguridad de tipos en tiempo de compilacion via reflejo comptime de Zig
- Arquitectura modular y extensible
- Cero dependencias externas
- Biblioteca estatica via `zig build`

---

## Los 3 Enfoques de Impresion

### 1. API Basada en Patrones (Recomendada)

**Modulo:** `c_print.zig`

Este es el enfoque principal y mas flexible, utilizando patrones de formato con sintaxis `{type:specifier1:specifier2:...}`. Los argumentos se pasan como una tupla comptime, dando seguridad de tipos completa en tiempo de compilacion.

#### Sintaxis Basica

```zig
const c_print = @import("c_print");

try c_print.c_print_mod.c_print(&writer, "Texto con {type:specifiers}", .{valor});
```

#### Tipos Soportados

- `{s:...}` - Cadena (`[]const u8`)
- `{d:...}` o `{i:...}` - Entero con signo (`i32`)
- `{f:...}` - Decimal (`f64`)
- `{c:...}` - Caracter (`u8`)
- `{b:...}` - Binario (`u64`)
- `{x:...}` - Hexadecimal (`u64`)
- `{o:...}` - Octal (`u64`)
- `{u:...}` - Entero sin signo (`u64`)
- `{l:...}` - Entero largo (`i64`)

#### Especificadores Disponibles

**Colores:**
- Basicos: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`
- Brillantes: `bright_red`, `bright_green`, `bright_blue`, etc.
- Fondos: `bg_red`, `bg_green`, `bg_blue`, etc.

**Estilos:**
- `bold` - Negrita
- `italic` - Cursiva
- `underline` - Subrayado
- `dim` - Atenuado
- `blink` - Parpadeo
- `reverse` - Invertido
- `strikethrough` - Tachado

**Alineacion:**
- `<N` - Alinear a la izquierda (ancho N)
- `>N` - Alinear a la derecha (ancho N)
- `^N` - Centrar (ancho N)
- `*^N` - Centrar con caracter de relleno personalizado

**Formateo de Numeros:**
- `.N` - Precision decimal (ej., `.2` para 2 decimales)
- `0N` - Relleno con ceros (ej., `05` para 00042)
- `,` - Separador de miles con coma
- `_` - Separador de miles con guion bajo
- `#` - Mostrar prefijo (0b, 0x, 0o)
- `+` - Siempre mostrar signo
- `%` - Formatear como porcentaje

#### Ejemplos

```zig
const std = @import("std");
const c_print = @import("c_print");

pub fn main() !void {
    var stdout: std.Io.Writer = .fixed(&std.io.getStdOut().writer().buffer);

    // Texto coloreado simple
    try c_print.c_print_mod.c_print(&stdout, "Hola {s:green}!\n", .{"Mundo"});

    // Multiples especificadores
    try c_print.c_print_mod.c_print(&stdout, "{s:cyan:bg_black:bold}\n", .{"IMPORTANTE"});

    // Multiples valores
    try c_print.c_print_mod.c_print(
        &stdout,
        "Usuario: {s:yellow}, Edad: {d:blue}, Puntuacion: {f:.2:green}\n",
        .{ "Carlos", @as(i32, 25), @as(f64, 95.5) },
    );

    // Formateo de numeros
    try c_print.c_print_mod.c_print(&stdout, "Poblacion: {d:,}\n", .{@as(i32, 1234567)});
    try c_print.c_print_mod.c_print(&stdout, "Hex: 0x{x:bold}\n", .{@as(u64, 255)});
    try c_print.c_print_mod.c_print(&stdout, "Precio: ${f:.2:,}\n", .{@as(f64, 1234.56)});

    // Alineacion
    try c_print.c_print_mod.c_print(&stdout, "|{s:<20}|\n", .{"Izquierda"});
    try c_print.c_print_mod.c_print(&stdout, "|{s:>20}|\n", .{"Derecha"});
    try c_print.c_print_mod.c_print(&stdout, "|{s:^20}|\n", .{"Centro"});
    try c_print.c_print_mod.c_print(&stdout, "|{s:*^20}|\n", .{"Relleno"});
}
```

**Ventajas:**
- Sintaxis compacta y legible
- Muy flexible y poderosa
- Verificacion de tipos en comptime en los argumentos
- Similar a printf pero con colores y formateo avanzado
- Ideal para la mayoria de los casos de uso

**Limitaciones:**
- Requiere casteos de tipos explicitos para literales de entero/float en tuplas
- El orden de argumentos debe coincidir con el patron

---

### 2. API de Builder (Patron de Construccion)

**Modulo:** `c_print_builder.zig`

Este enfoque elimina las funciones variadicas, proporcionando seguridad de tipos completa en tiempo de compilacion a traves de funciones explicitas para cada tipo de dato. El builder acumula salida formateada en un buffer interno, luego imprime o retorna el resultado.

#### Funciones Principales

```zig
const Builder = c_print.c_print_builder;

// Crear y liberar
var b = Builder.init(allocator);         // Crear builder (alias: cp_new)
defer b.deinit();                         // Liberar memoria (alias: cp_free)
b.reset();                                // Resetear para reutilizar (alias: cp_reset)

// Agregar contenido (seguro por tipos)
_ = b.appendText("texto");               // Texto literal sin formato
_ = b.append(cadena_variable);            // Cadena formateada
_ = b.appendInt(42);                      // Entero (i32)
_ = b.appendFloat(3.14);                  // Decimal (f64)
_ = b.appendChar('A');                    // Caracter (u8)
_ = b.appendBool(true);                   // Booleano
_ = b.appendBinary(255);                  // Binario
_ = b.appendHex(255);                     // Hexadecimal

// Aplicar formato (encadenable)
_ = b.withColorName("red");               // Color de texto por nombre
_ = b.withColor(.red);                    // Color de texto por enum
_ = b.withBgColorName("bg_blue");         // Color de fondo
_ = b.withStyleName("bold");              // Estilo por nombre
_ = b.withStyle(.bold);                   // Estilo por enum
_ = b.withPrecision(2);                   // Precision decimal
_ = b.withZeroPad();                      // Habilitar relleno con ceros
_ = b.withPad(5);                         // Establecer ancho de relleno
_ = b.withSeparator(',');                 // Separador de miles
_ = b.withPrefix();                       // Mostrar 0x, 0b, etc.
_ = b.withSign();                         // Mostrar signo +/-
_ = b.asPercentage();                     // Formatear como %
_ = b.alignLeft(20);                      // Alinear a la izquierda
_ = b.alignRight(20);                     // Alinear a la derecha
_ = b.alignCenter(20);                    // Centrar
_ = b.withFillChar('*');                  // Caracter de relleno

// Imprimir
try b.print();                            // Imprimir a stderr
try b.println();                          // Imprimir con salto de linea
const str = try b.toString();             // Obtener cadena allocada
defer allocator.free(str);
```

> **Compatibilidad retroactiva:** Los nombres antiguos `cp_*` (ej., `cp_new`, `cp_text`, `cp_color_str`) estan disponibles como alias y continuaran funcionando.

#### Ejemplos

```zig
const std = @import("std");
const c_print = @import("c_print");
const Builder = c_print.c_print_builder;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var b = Builder.init(allocator);
    defer b.deinit();

    // Construccion segura por tipos
    _ = b.appendText("Empleado: ");
    _ = b.withColorName("cyan").append("Carlos");
    _ = b.appendText(" | Salario: $");
    _ = b.withColorName("green").withPrecision(2).appendFloat(75000.50);
    try b.println();
    // Salida: Empleado: Carlos | Salario: $75000.50

    // Reutilizar builder
    b.reset();
    _ = b.appendText("ID: ");
    _ = b.withZeroPad().withPad(5).appendInt(42);
    try b.println();
    // Salida: ID: 00042

    // Numero con separadores
    b.reset();
    _ = b.appendText("Poblacion: ");
    _ = b.withSeparator(',').appendInt(1234567);
    try b.println();
    // Salida: Poblacion: 1,234,567
}
```

**Ventajas:**
- **Seguridad de tipos en tiempo de compilacion**: Imposible mezclar tipos
- Sin funciones variadicas
- API limpia y encadenable
- Reutilizable (con `reset()`)
- Gestion automatica de memoria interna via `std.ArrayList`

**Limitaciones:**
- Sintaxis mas verbosa
- Requiere crear y liberar el builder
- Menos flexible que la API de patrones para cadenas de formato complejas

---

### 3. API Generica (Reflejo Comptime)

**Modulo:** `c_print_generic.zig`

Este enfoque utiliza el reflejo en tiempo de compilacion de Zig (`@typeInfo`) para detectar automaticamente los tipos de argumentos, validarlos contra especificadores de formato en comptime, y proporcionar utilidades de depuracion para inspeccion de tipos.

#### Funcion Principal

```zig
const generic = c_print.c_print_generic;

try generic.print(&writer, "{s:red} {d:green}", .{ "Hola", @as(i32, 42) });
```

#### Caracteristicas

- Deteccion automatica de tipos usando `@typeInfo` en comptime
- Validacion de tipos de argumentos contra especificadores en tiempo de compilacion
- Deteccion de errores de tipo en tiempo de ejecucion via `validateAndReport`
- Modo de depuracion para inspeccionar tipos (`C_PRINT_DEBUG_TYPES`)
- Modo de depuracion para inspeccionar tipos y valores (`C_PRINT_DEBUG_VALUES`)

#### Ejemplos

```zig
const std = @import("std");
const c_print = @import("c_print");
const generic = c_print.c_print_generic;

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    const nombre: []const u8 = "Maria";
    const edad: i32 = 30;
    const salario: f64 = 85000.75;

    // Deteccion automatica de tipos
    try generic.print(&writer, "Nombre: {s:blue}\n", .{nombre});
    try generic.print(&writer, "Edad: {d:yellow}\n", .{edad});
    try generic.print(&writer, "Salario: ${f:.2:green:,}\n", .{salario});

    // Validacion en tiempo de compilacion
    const resultado = generic.validateArgs("{s} {d} {f}", .{ nombre, edad, salario });
    // resultado.valid == true

    // Depurar tipos
    try generic.debugTypes(&writer, "{s} {d} {f}", .{ nombre, edad, salario });
}
```

#### Tipos Soportados

- `[]const u8`, `[]u8`, literales de cadena -> string
- `i8`, `i16`, `i32` -> integer
- `u8` -> char
- `u16`, `u32` -> unsigned
- `i64` -> long
- `u64` -> unsigned long
- `f32` -> float
- `f64` -> double
- `bool` -> bool

**Ventajas:**
- Combinacion perfecta de conveniencia y seguridad
- Sintaxis simple como la API de patrones
- Verificacion de tipos en tiempo de compilacion con mensajes informativos
- Utilidades de depuracion para desarrollo

**Limitaciones:**
- Requiere anotaciones de tipo explicitas para literales en tuplas
- Sobrecarga minima para validacion comptime

---

## Comparacion de las 3 APIs

| Caracteristica | Patrones | Builder | Generica |
|---------|---------|---------|---------|
| **Seguridad de Tipos** | Comptime | Compilacion | Comptime + Runtime |
| **Funciones Variadicas** | No (tuplas) | No | No (tuplas) |
| **Memoria** | Baja | Buffer interno | Baja |
| **Flexibilidad** | Alta | Limitada | Alta |
| **Facilidad de Uso** | Muy facil | Moderada | Facil |
| **Mensajes de Error** | Compilacion | Compilacion | Ambos |
| **Sintaxis** | Compacta | Verbosa | Compacta |
| **Caso de Uso Ideal** | Uso general | Codigo critico | Proyectos Zig modernos |

### Cual API Elegir?

- **API de Patrones**: Para la mayoria de los proyectos. Simple, flexible y poderosa.
- **API de Builder**: Para codigo que requiere maxima seguridad de tipos y construccion programatica.
- **API Generica**: Para proyectos que quieran validacion en tiempo de compilacion con utilidades de depuracion.

---

## Instalacion

### Requisitos

- **Zig** 0.16.0 o superior

### Compilar

```bash
# Clonar el repositorio
git clone https://github.com/carlos-sweb/c_print.git
cd c_print

# Compilar la biblioteca estatica
zig build

# Ejecutar pruebas
zig build test
```

### Uso como Dependencia

Agregar `c_print` a las dependencias en tu `build.zig.zon`:

```zig
.{
    .name = .mi_proyecto,
    .version = "0.1.0",
    .dependencies = .{
        .c_print = .{
            .url = "https://github.com/carlos-sweb/c_print/archive/refs/heads/main.tar.gz",
            .hash = "...",
        },
    },
}
```

Luego en tu `build.zig`:

```zig
const c_print_dep = b.dependency("c_print", .{
    .target = target,
    .optimize = optimize,
});

const exe = b.addExecutable(.{
    .name = "mi_app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});

exe.root_module.addImport("c_print", c_print_dep.module("c_print"));
```

---

## Uso en Proyectos

### Opcion 1: Como Modulo Zig (Recomendada)

```zig
const c_print = @import("c_print");

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    // API de Patrones
    try c_print.c_print_mod.c_print(&writer, "Hola {s:green}!\n", .{"Mundo"});

    // API de Builder
    var b = c_print.c_print_builder.init(std.heap.page_allocator);
    defer c_print.c_print_builder.deinit(&b);
    _ = c_print.c_print_builder.withColorName(&b, "cyan")
        .append("Hola desde builder");
    try c_print.c_print_builder.println(&b);

    // API Generica
    try c_print.c_print_generic.print(
        &writer,
        "Valor: {d:yellow}\n",
        .{@as(i32, 42)},
    );
}
```

### Opcion 2: Importar Modulos Individuales

```zig
const c_print_mod = @import("c_print.zig").c_print_mod;
const c_print_builder = @import("c_print.zig").c_print_builder;
const c_print_generic = @import("c_print.zig").c_print_generic;
```

### Opcion 3: Importar Archivos Directamente

```zig
const c_print_mod = @import("c_print.zig");
const builder = @import("c_print_builder.zig");
const generic = @import("c_print_generic.zig");
```

---

## Compatibilidad C-ABI

La biblioteca exporta funciones compatibles con C-ABI que pueden ser llamadas desde codigo C. Esto es util para proyectos que quieran usar c_print desde una base de codigo C/C++.

### Funciones Exportadas

```c
// Imprimir un mensaje con color (0=rojo, 1=verde, 2=azul, 3=amarillo, 4=cyan, 5=magenta, 6=blanco, 7=negro)
int c_print_color_msg(const char *message, int color_code);

// Imprimir un mensaje en negrita
int c_print_bold_msg(const char *message);

// Imprimir una cadena simple (sin formato)
int c_print_puts(const char *message);

// Obtener cadena de version de la biblioteca
const char *c_print_version(void);
```

### Compilar el Ejemplo C

```bash
# Compilar la biblioteca estatica
zig build lib

# Compilar y enlazar el ejemplo C
zig build example_c_simple

# Ejecutar el ejemplo
./zig-out/bin/example_c_simple
```

### Uso desde C

```c
#include <stdio.h>

extern int c_print_puts(const char *message);
extern int c_print_color_msg(const char *message, int color_code);
extern int c_print_bold_msg(const char *message);

int main(void) {
    c_print_puts("Hola desde C!");
    c_print_color_msg("Este texto es verde", 1);
    c_print_bold_msg("Este texto es negrita");
    return 0;
}
```

Compilar y enlazar:
```bash
cc ejemplo.c -L zig-out/lib -lc_print -o ejemplo
```

---

## Ejecutar Ejemplos

Despues de clonar el repositorio:

```bash
# Compilar la biblioteca estatica
zig build

# Ejecutar un ejemplo especifico
zig build run -Dexample=pattern_based
zig build run -Dexample=builder
zig build run -Dexample=generic

# Ejecutar pruebas
zig build test

# Compilar el ejemplo C-ABI (requiere un compilador C)
zig build example_c_simple
./zig-out/bin/example_c_simple
```

---

## Estructura del Proyecto

```
c_print/
├── src/                              # Archivos fuente Zig
│   ├── main.zig                     # Modulo raiz (re-exporta todos los modulos)
│   ├── c_print.zig                  # Implementacion API de Patrones
│   ├── c_print_builder.zig          # API de Builder
│   ├── c_print_generic.zig          # API Generica comptime
│   ├── c_print_safe.zig             # Funciones wrapper seguras
│   ├── c_api.zig                    # Funciones exportadas C-ABI
│   ├── ansi_codes.zig               # Generacion de codigos ANSI
│   ├── color_parser.zig             # Parser de nombres de color/estilo
│   ├── pattern_parser.zig           # Parser de patrones {type:specs}
│   ├── number_formatter.zig         # Formateo de numeros (separadores, bases)
│   ├── text_alignment.zig           # Alineacion de texto con relleno
│   └── string_utils.zig             # Utilidades de cadenas
├── examples/                         # Programas de ejemplo
│   ├── example_pattern_based.zig    # Ejemplo API de Patrones
│   ├── example_builder.zig          # Ejemplo API de Builder
│   ├── example_generic.zig          # Ejemplo API Generica
│   ├── example_system_dashboard.zig # Demo de panel de sistema
│   ├── example_logging.zig          # Demo de sistema de registro
│   └── example_data_table.zig       # Demo de tabla de datos
├── test/
│   └── example_c_simple.c           # Ejemplo de compatibilidad C-ABI
├── build.zig                        # Configuracion de construccion Zig
├── build.zig.zon                    # Manifiesto de paquete
├── README.md                        # Archivo en ingles
└── LICENSE                          # Licencia MIT
```

---

## Arquitectura Modular

La biblioteca esta disenada con una arquitectura modular donde cada componente es independiente:

### Modulos Principales

1. **ansi_codes** - Generacion y aplicacion de codigos ANSI
2. **color_parser** - Parseo de nombres de colores/estilos a enums
3. **pattern_parser** - Parseo de patrones `{type:specs}` a structs `PatternStyle`
4. **number_formatter** - Formateo de numeros (separadores, bases, relleno)
5. **text_alignment** - Alineacion de texto con caracteres de relleno
6. **string_utils** - Utilidades de cadenas

### APIs de Alto Nivel

1. **c_print** - API de Patrones (usa todos los modulos centrales)
2. **c_print_builder** - API de Builder (usa modulos seleccionados)
3. **c_print_generic** - API Generica (wrapper comptime sobre c_print con validacion de tipos)

---

## Compatibilidad

### Version de Zig

- **Zig 0.16.0**: Todas las APIs completamente soportadas
- Usa `std.Io.Writer` (API de Zig 0.16.0)
- Usa reflejo comptime (`@typeInfo`, `inline for`, `inline switch`)

### Plataformas

- Linux
- macOS
- Windows (con soporte ANSI en Windows 10+)
- BSD

---

## Solucion de Problemas

### Colores no se muestran

**Problema**: El texto aparece con codigos extraños o sin colores.

**Solucion**:
- En Linux/macOS: Asegurate de usar una terminal compatible con ANSI
- En Windows 10+: Habilita el soporte ANSI en la consola
- Verifica que `TERM` este configurado correctamente: `echo $TERM`

### Errores de tipos en tuplas

**Problema**: Errores de compilacion sobre tipos incompatibles en tuplas.

**Solucion**:
- Zig requiere tipos explicitos para literales de entero y float en tuplas
- Usa `@as(i32, 42)` para enteros, `@as(f64, 3.14)` para floats
- Los literales de cadena (`[]const u8`) funcionan sin casteos explicitos

### Salida del builder no visible

**Problema**: Builder `print` escribe a stderr via `std.debug.print`.

**Solucion**:
- Usa `toString` para obtener el contenido del buffer y escribirlo tu mismo
- O usa la API de patrones/generica con un writer personalizado para stdout

---

## Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Haz un fork del repositorio
2. Crea una rama para tu caracteristica (`git checkout -b feature/nueva-caracteristica`)
3. Confirma tus cambios (`git commit -am 'Anade nueva caracteristica'`)
4. Empuja a la rama (`git push origin feature/nueva-caracteristica`)
5. Crea un Pull Request

### Guia de Contribuciones

- Manten la compatibilidad con Zig 0.16.0
- Anade pruebas para nuevas caracteristicas
- Documenta las APIs publicas con comentarios doc
- Sigue el estilo de codigo existente

---

## Licencia

Este proyecto esta licenciado bajo la Licencia MIT. Consulta el archivo `LICENSE` para mas detalles.

---

## Autor

**Carlos Illesca** - [GitHub](https://github.com/carlos-sweb)

---

## Agradecimientos

- Inspirado en bibliotecas modernas de formateo como fmt, Rich y Chalk
- Comunidad de Zig por retroalimentacion y contribuciones
- Documentacion de codigos de escape ANSI

---

## Hoja de Ruta

### v0.2 (Planeada)

- Soporte para True Color (RGB de 24 bits)
- Temas personalizables
- Deteccion automatica de capacidades de terminal
- Tablas automaticas con bordes
- Barras de progreso
- Spinners animados

### v0.3 (Futura)

- Soporte para Windows sin ANSI usando WinAPI
- Registro estructurado integrado
- Perfilamiento de rendimiento
- Suite de benchmarking

---

## Preguntas Frecuentes (FAQ)

### Puedo usar esta biblioteca en proyectos comerciales?

Si, la licencia MIT permite el uso comercial sin restricciones.

### Funciona en Windows?

Si, en Windows 10+ que tiene soporte nativo para codigos ANSI. En versiones anteriores, necesitarias habilitar ANSI o usar una terminal alternativa.

### Cual es la sobrecarga de rendimiento?

La sobrecarga es minima. El analisis de patrones ocurre una vez por llamada. La API de Builder usa un `ArrayList` con asignacion amortizada. La API Generica hace toda la validacion en comptime con costo cero en tiempo de ejecucion.

### Puedo mezclar las tres APIs en el mismo proyecto?

Si, las tres APIs son compatibles y se pueden usar simultaneamente en el mismo programa.

### Por que el builder usa `std.debug.print`?

Los metodos `print` y `println` del builder usan `std.debug.print` como mecanismo simple de salida. Para uso en produccion, prefiere `toString` para obtener el contenido del buffer y escribirlo en tu propio writer.

---

## Ejemplos Adicionales

### Barra de Progreso

```zig
const std = @import("std");
const c_print = @import("c_print");
const cp = c_print.c_print_mod;

fn showProgress(writer: *std.Io.Writer, percent: f64) !void {
    const filled: usize = @intFromFloat(percent * 40);
    try cp.c_print(writer, "[{s:green}", .{""});
    var i: usize = 0;
    while (i < filled) : (i += 1) {
        try writer.writeAll("\u{2588}");
    }
    try cp.c_print(writer, "{s:dim}", .{""});
    i = filled;
    while (i < 40) : (i += 1) {
        try writer.writeAll("\u{2591}");
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

### Sistema de Menu

```zig
const std = @import("std");
const c_print = @import("c_print");
const cp = c_print.c_print_mod;

fn printMenu(writer: *std.Io.Writer) !void {
    try cp.c_print(writer, "\n{s:=^50:cyan:bold}\n", .{" MENU PRINCIPAL "});
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 1), "Nuevo Juego" });
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 2), "Cargar Juego" });
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 3), "Opciones" });
    try cp.c_print(writer, "{s:bright_white:bold} {d}. {s}\n", .{ "", @as(i32, 4), "Salir" });
    try cp.c_print(writer, "{s:=^50:cyan}\n", .{""});
    try cp.c_print(writer, "Selecciona una opcion: ", .{});
}

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    try printMenu(&writer);
    _ = try std.io.getStdOut().write(writer.buffered());
}
```

---

## Contacto

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/c_print/issues)
- **Email**: c4rl0sill3sc4@protonmail.com

---

<p align="center">
  Made with {s:red:bold} in Zig
</p>
