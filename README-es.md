# c_print

**Biblioteca en C para impresi�n de texto con colores y formato en la consola usando c�digos ANSI**

[![Versi�n](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/carlos-sweb/c_print)
[![Est�ndar C](https://img.shields.io/badge/C-C99%20%7C%20C11-orange.svg)](https://en.wikipedia.org/wiki/C11_(C_standard_revision))
[![Licencia](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Español | [English](README.md)

## Descripci�n

`c_print` es una biblioteca completa en C que proporciona tres enfoques distintos para imprimir texto formateado y coloreado en la terminal. Con soporte para colores ANSI, estilos de texto, alineaci�n avanzada y formato de n�meros, la biblioteca ofrece flexibilidad para diferentes casos de uso y preferencias de programaci�n.

## Caracter�sticas Principales

- <� **16 colores ANSI** (8 est�ndar + 8 brillantes)
- =� **8 estilos de texto** (negrita, cursiva, subrayado, etc.)
- =� **Alineaci�n de texto** (izquierda, derecha, centro con caracteres de relleno personalizables)
- =" **Formato avanzado de n�meros** (separadores de miles, padding, bases num�ricas)
- <� **Tres APIs distintas** para diferentes necesidades
- = **Seguridad de tipos** (seg�n el enfoque elegido)
- =' **Modular y extensible**
- = **Compatible con C++ y C99/C11**
- =� **Biblioteca compartida y est�tica**

---

## Los 3 Enfoques de Impresi�n

### 1. API Basada en Patrones (Recomendada)

**Archivo:** `c_print.h`

Este es el enfoque principal y m�s flexible, usando patrones de formato con sintaxis `{tipo:especificador1:especificador2:...}`.

#### Sintaxis B�sica

```c
c_print("Texto con {tipo:especificadores}", valor);
```

#### Tipos Soportados

- `{s:...}` - Cadena de texto (string)
- `{d:...}` o `{i:...}` - Entero (int)
- `{f:...}` - Decimal (float/double)
- `{c:...}` - Car�cter (char)
- `{b:...}` - Binario
- `{x:...}` - Hexadecimal
- `{o:...}` - Octal
- `{u:...}` - Entero sin signo (unsigned)
- `{l:...}` - Entero largo (long)

#### Especificadores Disponibles

**Colores:**
- B�sicos: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`
- Brillantes: `bright_red`, `bright_green`, `bright_blue`, etc.
- Fondos: `bg_red`, `bg_green`, `bg_blue`, etc.

**Estilos:**
- `bold` - Negrita
- `italic` - Cursiva
- `underline` - Subrayado
- `dim` - Atenuado
- `blink` - Parpadeante
- `reverse` - Invertido
- `strikethrough` - Tachado

**Alineaci�n:**
- `<N` - Alinear a la izquierda (ancho N)
- `>N` - Alinear a la derecha (ancho N)
- `^N` - Centrar (ancho N)
- `*^N` - Centrar con car�cter de relleno personalizado

**Formato de N�meros:**
- `.N` - Precisi�n decimal (ej: `.2` para 2 decimales)
- `0N` - Padding con ceros (ej: `05` para 00042)
- `,` - Separador de miles con coma
- `_` - Separador de miles con guion bajo
- `#` - Mostrar prefijo (0b, 0x, 0o)
- `+` - Mostrar siempre el signo
- `%` - Formatear como porcentaje

#### Ejemplos

```c
#include "c_print.h"

int main() {
    // Texto simple con color
    c_print("�Hola {s:green}!\n", "Mundo");

    // M�ltiples especificadores
    c_print("{s:cyan:bg_black:bold}\n", "IMPORTANTE");

    // Varios valores
    c_print("Usuario: {s:yellow}, Edad: {d:blue}, Puntaje: {f:.2:green}\n",
            "Ana", 25, 95.5);

    // Formato de n�meros
    c_print("Poblaci�n: {d:,}\n", 1234567);               // 1,234,567
    c_print("Progreso: {f:.1%:cyan}\n", 0.85);            // 85.0%
    c_print("Hex: 0x{x:bold}\n", 255);                    // 0xFF
    c_print("Precio: ${f:.2:,}\n", 1234.56);              // $1,234.56

    // Alineaci�n
    c_print("|{s:<20}|\n", "Izquierda");
    c_print("|{s:>20}|\n", "Derecha");
    c_print("|{s:^20}|\n", "Centro");
    c_print("|{s:*^20}|\n", "Relleno");                   // |*****Relleno*****|

    // Ejemplo complejo
    c_print("[{s:bright_green:bold}] {s:white} - {f:.2:green} ms\n",
            "OK", "Solicitud completada", 45.32);

    return 0;
}
```

**Ventajas:**
- Sintaxis compacta y legible
- Muy flexible y potente
- Similar a printf pero con colores y formato avanzado
- Ideal para la mayor�a de casos de uso

**Limitaciones:**
- Verificaci�n de tipos en tiempo de ejecuci�n
- Requiere cuidado con el orden de argumentos

---

### 2. API Patr�n Constructor (Builder)

**Archivo:** `c_print_builder.h`

Este enfoque elimina las funciones vari�dicas, proporcionando seguridad de tipos completa en tiempo de compilaci�n mediante funciones expl�citas para cada tipo de dato.

#### Funciones Principales

```c
// Crear y liberar
CPrintBuilder* cp_new(void);              // Crear constructor
void cp_free(CPrintBuilder* b);           // Liberar memoria
void cp_reset(CPrintBuilder* b);          // Resetear para reutilizar

// Agregar contenido (tipado seguro)
cp_text(b, "texto");                      // Texto literal sin formato
cp_str(b, variable_string);               // String formateado
cp_int(b, 42);                            // Entero
cp_float(b, 3.14);                        // Decimal
cp_char(b, 'A');                          // Car�cter
cp_bool(b, true);                         // Booleano
cp_binary(b, 255);                        // Binario
cp_hex(b, 255);                           // Hexadecimal

// Aplicar formato (encadenable)
cp_color_str(b, "red");                   // Color de texto
cp_bg_str(b, "bg_blue");                  // Color de fondo
cp_style_str(b, "bold");                  // Estilo
cp_precision(b, 2);                       // Precisi�n decimal
cp_zero_pad(b, 5);                        // Padding con ceros
cp_separator(b, ',');                     // Separador de miles
cp_show_prefix(b, true);                  // Mostrar 0x, 0b, etc.
cp_show_sign(b, true);                    // Mostrar signo +/-
cp_as_percentage(b, true);                // Formatear como %
cp_align_left(b, 20);                     // Alinear izquierda
cp_align_right(b, 20);                    // Alinear derecha
cp_align_center(b, 20);                   // Centrar
cp_fill_char(b, '*');                     // Car�cter de relleno

// Imprimir
cp_print(b);                              // Imprimir
cp_println(b);                            // Imprimir con salto de l�nea
char* str = cp_to_string(b);              // Obtener string (debe liberarse)
```

#### Ejemplos

```c
#include "c_print_builder.h"

int main() {
    CPrintBuilder* b = cp_new();

    // Construcci�n tipo segura
    cp_text(b, "Empleado: ");
    cp_str(cp_color_str(b, "cyan"), "Carlos");
    cp_text(b, " | Salario: $");
    cp_float(cp_precision(cp_color_str(b, "green"), 2), 75000.50);
    cp_println(b);
    // Salida: Empleado: Carlos | Salario: $75000.50

    // Reutilizar el constructor
    cp_reset(b);
    cp_text(b, "ID: ");
    cp_int(cp_zero_pad(b, 5), 42);
    cp_println(b);
    // Salida: ID: 00042

    // N�mero con separadores
    cp_reset(b);
    cp_text(b, "Poblaci�n: ");
    cp_int(cp_separator(b, ','), 1234567);
    cp_println(b);
    // Salida: Poblaci�n: 1,234,567

    // Encadenamiento complejo
    cp_reset(b);
    cp_text(b, "Precio: $");
    cp_float(
        cp_separator(
            cp_precision(
                cp_color_str(b, "green"),
                2
            ),
            ','
        ),
        9999.99
    );
    cp_println(b);
    // Salida: Precio: $9,999.99 (en verde)

    cp_free(b);
    return 0;
}
```

**Ventajas:**
- **Seguridad de tipos en tiempo de compilaci�n**: Imposible mezclar tipos
- Sin funciones vari�dicas
- API limpia y encadenable
- Reutilizable (con `cp_reset`)
- Gesti�n autom�tica de memoria interna

**Limitaciones:**
- Sintaxis m�s verbosa
- Requiere crear y liberar el constructor
- Menos flexible que el API de patrones

---

### 3. API Gen�rica (C11 _Generic)

**Archivo:** `c_print_generic.h`

Este enfoque usa `_Generic` de C11 para detectar autom�ticamente los tipos de argumentos, combinando la comodidad de las funciones vari�dicas con la seguridad de tipos en tiempo de compilaci�n.

#### Macro Principal

```c
#define C_PRINT(pattern, ...)
```

#### Configuraci�n

```c
#define C_PRINT_USE_GENERIC          // Habilitar API gen�rica
#include "c_print.h"
#include "c_print_generic.h"
```

#### Caracter�sticas

- Detecci�n autom�tica de tipos usando `_Generic`
- Advertencias en tiempo de compilaci�n
- Detecci�n de discordancia de tipos en tiempo de ejecuci�n
- Modo estricto con abort en errores
- Modo debug para inspeccionar tipos

#### Ejemplos

```c
#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"

int main() {
    const char* nombre = "Mar�a";
    int edad = 30;
    double salario = 85000.75;

    // Detecci�n autom�tica de tipos
    C_PRINT("Nombre: {s:blue}\n", nombre);           //  OK
    C_PRINT("Edad: {d:yellow}\n", edad);             //  OK
    C_PRINT("Salario: ${f:.2:green:,}\n", salario);  //  OK

    // Detecci�n de discordancia de tipos
    C_PRINT("Error: {s:red}\n", 500);                // � Advertencia: int pasado para string

    // Debug de tipos
    C_PRINT_DEBUG_TYPES("{s} {d} {f}", nombre, edad, salario);
    // Salida: Argument 0: type=string
    //         Argument 1: type=int
    //         Argument 2: type=double

    return 0;
}
```

#### Modo Estricto

```c
#define C_PRINT_STRICT
#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"

int main() {
    C_PRINT("{d}", "incorrecto");  // L Aborta el programa con mensaje de error
    return 0;
}
```

#### Tipos Soportados

- `const char*`, `char*` � string
- `int`, `signed char`, `unsigned char` � int
- `unsigned int` � unsigned
- `long`, `long long` � long
- `unsigned long`, `unsigned long long` � unsigned long
- `float`, `double` � double
- `char` � char
- `_Bool` � bool
- `void*` � pointer

**Ventajas:**
- Combinaci�n perfecta de comodidad y seguridad
- Sintaxis simple como el API de patrones
- Verificaci�n de tipos en tiempo de compilaci�n y ejecuci�n
- Mensajes de error informativos

**Limitaciones:**
- Requiere C11 o superior
- No compatible con C99
- Overhead m�nimo por verificaci�n de tipos

---

## Comparaci�n de las 3 APIs

| Caracter�stica | Patrones | Constructor | Gen�rica |
|----------------|----------|-------------|----------|
| **Seguridad de tipos** | Solo en ejecuci�n | En compilaci�n | En compilaci�n + ejecuci�n |
| **Funciones vari�dicas** | S� | No | S� (con _Generic) |
| **Overhead de memoria** | Bajo | Buffer interno | Bajo |
| **Flexibilidad** | Alta | Limitada | Alta |
| **Facilidad de uso** | Muy f�cil | Moderada | F�cil |
| **Est�ndar C requerido** | C99 | C99 | C11 |
| **Mensajes de error** | En ejecuci�n | En compilaci�n | Ambos |
| **Sintaxis** | Compacta | Verbosa | Compacta |
| **Caso de uso ideal** | Uso general | C�digo cr�tico | Proyectos C11+ modernos |

### �Cu�l API elegir?

- **API de Patrones**: Para la mayor�a de proyectos. Simple, flexible y potente.
- **API Constructor**: Para c�digo que requiere m�xima seguridad de tipos y validaci�n en compilaci�n.
- **API Gen�rica**: Para proyectos modernos en C11+ que quieren lo mejor de ambos mundos.

---

## Instalaci�n

### Requisitos

- **CMake** 3.15 o superior
- **Compilador C** con soporte C99 (C11 para API gen�rica)
- **Compilador C++** (opcional, para compatibilidad C++)

### Compilaci�n e Instalaci�n

```bash
# Clonar el repositorio
git clone https://github.com/carlos-sweb/c_print.git
cd c_print

# Crear directorio de compilaci�n
mkdir build && cd build

# Configurar con CMake
cmake ..

# Compilar
make

# Instalar (puede requerir sudo)
sudo make install
```

### Opciones de Compilaci�n

```bash
# Compilar ejemplos (por defecto: ON)
cmake -DBUILD_EXAMPLES=ON ..

# Compilar tests (por defecto: OFF)
cmake -DBUILD_TESTS=ON ..

# Especificar prefijo de instalaci�n
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..

# Compilar todo
cmake -DBUILD_EXAMPLES=ON -DBUILD_TESTS=ON ..
make
```

### Usar con pkg-config

Despu�s de instalar, puedes usar `pkg-config` para enlazar la biblioteca:

```bash
# Ver flags de compilaci�n
pkg-config --cflags c_print

# Ver flags de enlace
pkg-config --libs c_print

# Compilar un programa
gcc mi_programa.c $(pkg-config --cflags --libs c_print) -o mi_programa
```

---

## Uso en Proyectos

### Opci�n 1: Usando CMake (Recomendado)

```cmake
cmake_minimum_required(VERSION 3.15)
project(mi_proyecto C)

# Buscar c_print
find_package(PkgConfig REQUIRED)
pkg_check_modules(CPRINT REQUIRED c_print)

add_executable(mi_programa main.c)

# Enlazar c_print
target_link_libraries(mi_programa ${CPRINT_LIBRARIES})
target_include_directories(mi_programa PUBLIC ${CPRINT_INCLUDE_DIRS})
```

### Opci�n 2: Compilaci�n Manual

```bash
# Con biblioteca compartida (instalada)
gcc mi_programa.c -lc_print -o mi_programa

# Con biblioteca est�tica (instalada)
gcc mi_programa.c -lc_print -static -o mi_programa

# Con archivos fuente directamente
gcc mi_programa.c src/*.c -Iinclude -o mi_programa
```

### Opci�n 3: Incluir como Subm�dulo

```bash
# Agregar como subm�dulo de git
git submodule add https://github.com/carlos-sweb/c_print.git libs/c_print

# En tu CMakeLists.txt
add_subdirectory(libs/c_print)
target_link_libraries(mi_programa c_print)
```

---

## Ejemplos Detallados

### Ejemplo 1: Dashboard de Sistema

```c
#include "c_print.h"

int main() {
    c_print("\n{s:*^60:cyan:bold}\n", " ESTADO DEL SISTEMA ");

    c_print("{s:<20} [{s:bright_green:bold}]\n", "CPU", "OK");
    c_print("{s:<20} {d:,} MB ({f:.1%:yellow})\n",
            "Memoria", 8192, 0.65);
    c_print("{s:<20} {d:,} / {d:,} GB\n",
            "Disco", 450, 1000);
    c_print("{s:<20} {f:.2:green} ms\n",
            "Latencia", 12.45);

    c_print("{s:*^60:cyan}\n", "");

    return 0;
}
```

### Ejemplo 2: Sistema de Logs

```c
#include "c_print_builder.h"

typedef enum {
    LOG_INFO,
    LOG_WARNING,
    LOG_ERROR,
    LOG_SUCCESS
} LogLevel;

void log_message(LogLevel level, const char* message) {
    CPrintBuilder* b = cp_new();

    cp_text(b, "[");

    switch(level) {
        case LOG_INFO:
            cp_str(cp_color_str(b, "cyan"), "INFO");
            break;
        case LOG_WARNING:
            cp_str(cp_color_str(b, "yellow"), "WARN");
            break;
        case LOG_ERROR:
            cp_str(cp_color_str(cp_style_str(b, "bold"), "red"), "ERROR");
            break;
        case LOG_SUCCESS:
            cp_str(cp_color_str(b, "green"), "OK");
            break;
    }

    cp_text(b, "] ");
    cp_str(b, message);
    cp_println(b);

    cp_free(b);
}

int main() {
    log_message(LOG_INFO, "Iniciando aplicaci�n...");
    log_message(LOG_SUCCESS, "Conexi�n establecida");
    log_message(LOG_WARNING, "Cache casi lleno");
    log_message(LOG_ERROR, "Fallo en autenticaci�n");
    return 0;
}
```

### Ejemplo 3: Tabla de Datos

```c
#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"

void print_table_row(const char* name, int id, double value) {
    C_PRINT("| {s:<20} | {d:>8:05} | {f:>12:.2:,} |\n",
            name, id, value);
}

int main() {
    C_PRINT("{s:=^60:bold}\n", " REPORTE DE VENTAS ");
    C_PRINT("| {s:<20} | {s:>8} | {s:>12} |\n",
            "Producto", "ID", "Precio");
    C_PRINT("{s:-^60}\n", "");

    print_table_row("Laptop", 1001, 899.99);
    print_table_row("Mouse", 2034, 29.99);
    print_table_row("Teclado", 3102, 79.50);

    C_PRINT("{s:=^60}\n", "");
    C_PRINT("Total: {s:$}{f:.2:bright_green:bold:,}\n", "", 1009.48);

    return 0;
}
```

---

## Estructura del Proyecto

```
c_print/
   include/                      # Archivos de cabecera p�blicos
      c_print.h                # API principal de patrones
      c_print_builder.h        # API patr�n constructor
      c_print_generic.h        # API gen�rica C11
      ansi_codes.h             # C�digos ANSI
      color_parser.h           # Parser de colores
      pattern_parser.h         # Parser de patrones
      number_formatter.h       # Formato de n�meros
      text_alignment.h         # Alineaci�n de texto
      string_utils.h           # Utilidades de strings
   src/                         # Implementaciones
      c_print.c               # Implementaci�n API patrones
      c_print_builder.c       # Implementaci�n constructor
      c_print_generic.c       # Implementaci�n gen�rica
      c_print_safe.c          # Versiones seguras
      pattern_parser.c
      number_formatter.c
      color_parser.c
      text_alignment.c
      ansi_codes.c
      string_utils.c
   test/                        # Ejemplos y tests
      example.c               # Ejemplo API patrones
      example_builder.c       # Ejemplo constructor
      example_generic.c       # Ejemplo gen�rica
      test_color_parser.c
      test_number_formatter.c
      test_text_alignment.c
      test_builder.c
      test_string_utils.c
   CMakeLists.txt              # Configuraci�n CMake
   c_print.pc.in               # Template pkg-config
   compile_and_test.sh         # Script de compilaci�n
   check_headers.sh            # Verificaci�n de headers
   README.md                   # Este archivo
```

---

## Arquitectura Modular

La biblioteca est� dise�ada con una arquitectura modular donde cada componente es independiente:

### M�dulos Core

1. **ansi_codes** - Generaci�n de c�digos ANSI
2. **color_parser** - Parseo de nombres de colores/estilos
3. **pattern_parser** - Parseo de patrones `{tipo:specs}`
4. **number_formatter** - Formato de n�meros (separadores, bases, padding)
5. **text_alignment** - Alineaci�n de texto con relleno
6. **string_utils** - Utilidades de strings

### APIs de Alto Nivel

1. **c_print** - API de patrones (usa todos los m�dulos)
2. **c_print_builder** - API constructor (usa m�dulos seleccionados)
3. **c_print_generic** - API gen�rica (wrapper sobre c_print con _Generic)

---

## Compatibilidad

### Est�ndares de C

- **C99**:  API de Patrones, API Constructor
- **C11**:  Todas las APIs (incluye _Generic)
- **C++**:  Todas las APIs (con `extern "C"`)

### Plataformas

-  Linux
-  macOS
-  Windows (con soporte ANSI en Windows 10+)
-  BSD

### Compiladores

-  GCC 4.9+
-  Clang 3.5+
-  MSVC 2019+ (con C11)
-  MinGW

---

## Ejecutar Ejemplos

Despu�s de compilar:

```bash
cd build

# API de Patrones
./example_shared

# API Constructor
./example_builder

# API Gen�rica (requiere C11)
./example_generic

# Tests
./test_color_parser
./test_number_formatter
./test_text_alignment
./test_builder
```

---

## Soluci�n de Problemas

### Los colores no se muestran

**Problema**: El texto aparece con c�digos extra�os o sin colores.

**Soluci�n**:
- En Linux/macOS: Aseg�rate de usar una terminal compatible con ANSI
- En Windows 10+: Habilita el soporte ANSI en la consola
- Verifica que `TERM` est� configurado correctamente: `echo $TERM`

### Error de compilaci�n con API Gen�rica

**Problema**: Errores relacionados con `_Generic`.

**Soluci�n**:
- Aseg�rate de compilar con C11: `gcc -std=c11 ...`
- Verifica que tu compilador soporte C11
- Usa GCC 4.9+ o Clang 3.5+

### S�mbolos no definidos al enlazar

**Problema**: `undefined reference to 'c_print'`

**Soluci�n**:
```bash
# Aseg�rate de enlazar la biblioteca
gcc programa.c -lc_print -o programa

# O usar pkg-config
gcc programa.c $(pkg-config --cflags --libs c_print) -o programa
```

---

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Haz commit de tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

### Gu�as de Contribuci�n

- Mantener la compatibilidad con C99 en APIs principales
- Agregar tests para nuevas funcionalidades
- Documentar en ingl�s en el c�digo, espa�ol en README
- Seguir el estilo de c�digo existente

---

## Licencia

Este proyecto est� licenciado bajo la Licencia MIT. Ver el archivo `LICENSE` para m�s detalles.

---

## Autor

**Carlos Illesca** - [GitHub](https://github.com/carlos-sweb)

---

## Agradecimientos

- Inspirado por bibliotecas de formato modernas como fmt, Rich y Chalk
- Comunidad de C por feedback y contribuciones
- Documentaci�n de ANSI escape codes

---

## Roadmap

### v1.1 (Planeado)

- [ ] Soporte para True Color (RGB 24-bit)
- [ ] Temas personalizables
- [ ] Detecci�n autom�tica de capacidades de terminal
- [ ] Tablas autom�ticas con bordes
- [ ] Barras de progreso
- [ ] Spinners animados

### v1.2 (Futuro)

- [ ] Soporte para Windows sin ANSI usando WinAPI
- [ ] Logging estructurado integrado
- [ ] Perfiles de rendimiento
- [ ] Bindings para otros lenguajes (Python, Rust)

---

## Preguntas Frecuentes (FAQ)

### �Puedo usar esta biblioteca en proyectos comerciales?

S�, la licencia MIT permite uso comercial sin restricciones.

### �Funciona en Windows?

S�, en Windows 10+ que tiene soporte nativo para c�digos ANSI. En versiones anteriores, necesitar�as habilitar ANSI o usar una alternativa como ConEmu.

### �Cu�l es el overhead de rendimiento?

El overhead es m�nimo. El parseo de patrones ocurre una vez por llamada y el API constructor tiene costo casi nulo.

### �Puedo mezclar las tres APIs en el mismo proyecto?

S�, las tres APIs son compatibles y pueden usarse simult�neamente en el mismo programa.

### �Hay alternativas a esta biblioteca?

S�, algunas alternativas incluyen:
- **termcolor** (solo colores b�sicos)
- **rang** (C++)
- **colorama** (Python)
- Esta biblioteca ofrece m�s caracter�sticas y flexibilidad que la mayor�a de alternativas en C.

---

## Ejemplos Adicionales

### Progress Bar

```c
#include "c_print.h"

void show_progress(double percent) {
    int filled = (int)(percent * 40);
    c_print("[{s:green}", "");
    for(int i = 0; i < filled; i++) c_print("�", "");
    c_print("{s:dim}", "");
    for(int i = filled; i < 40; i++) c_print("�", "");
    c_print("{s}] {f:.1%}\r", "", percent);
    fflush(stdout);
}

int main() {
    for(int i = 0; i <= 100; i++) {
        show_progress(i / 100.0);
        usleep(50000);  // 50ms
    }
    printf("\n");
    return 0;
}
```

### Sistema de Men�

```c
#include "c_print.h"

void print_menu() {
    c_print("\n{s:=^50:cyan:bold}\n", " MEN� PRINCIPAL ");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 1, "Nueva partida");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 2, "Cargar partida");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 3, "Opciones");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 4, "Salir");
    c_print("{s:=^50:cyan}\n", "");
    c_print("Selecciona una opci�n: ", "");
}

int main() {
    print_menu();
    // ... l�gica del men�
    return 0;
}
```

---

## Contacto

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/c_print/issues)
- **Email**: c4rl0sill3sc4@protonmail.com

---

<p align="center">
  Hecho con {s:red:bold} en C
</p>
