#ifndef C_PRINT_H
#define C_PRINT_H

#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

// Códigos ANSI para colores de texto
typedef enum {
    COLOR_RESET = 0,
    COLOR_BLACK = 30,
    COLOR_RED = 31,
    COLOR_GREEN = 32,
    COLOR_YELLOW = 33,
    COLOR_BLUE = 34,
    COLOR_MAGENTA = 35,
    COLOR_CYAN = 36,
    COLOR_WHITE = 37,
    COLOR_BRIGHT_BLACK = 90,
    COLOR_BRIGHT_RED = 91,
    COLOR_BRIGHT_GREEN = 92,
    COLOR_BRIGHT_YELLOW = 93,
    COLOR_BRIGHT_BLUE = 94,
    COLOR_BRIGHT_MAGENTA = 95,
    COLOR_BRIGHT_CYAN = 96,
    COLOR_BRIGHT_WHITE = 97
} TextColor;

// Códigos ANSI para colores de fondo
typedef enum {
    BG_RESET = 0,
    BG_BLACK = 40,
    BG_RED = 41,
    BG_GREEN = 42,
    BG_YELLOW = 43,
    BG_BLUE = 44,
    BG_MAGENTA = 45,
    BG_CYAN = 46,
    BG_WHITE = 47,
    BG_BRIGHT_BLACK = 100,
    BG_BRIGHT_RED = 101,
    BG_BRIGHT_GREEN = 102,
    BG_BRIGHT_YELLOW = 103,
    BG_BRIGHT_BLUE = 104,
    BG_BRIGHT_MAGENTA = 105,
    BG_BRIGHT_CYAN = 106,
    BG_BRIGHT_WHITE = 107
} BackgroundColor;

// Códigos ANSI para estilos de texto
typedef enum {
    STYLE_RESET = 0,
    STYLE_BOLD = 1,
    STYLE_DIM = 2,
    STYLE_ITALIC = 3,
    STYLE_UNDERLINE = 4,
    STYLE_BLINK = 5,
    STYLE_REVERSE = 7,
    STYLE_HIDDEN = 8,
    STYLE_STRIKETHROUGH = 9
} TextStyle;

// Alineación de texto
typedef enum {
    ALIGN_NONE = 0,
    ALIGN_LEFT = '<',
    ALIGN_RIGHT = '>',
    ALIGN_CENTER = '^'
} TextAlign;

// Estructura para opciones de impresión
typedef struct {
    TextColor text_color;
    BackgroundColor bg_color;
    TextStyle style;
} PrintOptions;

// Estructura interna para parsear patrones
typedef struct {
    char format_type;  // 's', 'd', 'f', 'b', etc.
    TextColor text_color;
    BackgroundColor bg_color;
    TextStyle style;
    int has_color;
    int has_bg;
    int has_style;
    TextAlign align;
    int width;
    int has_alignment;
    char fill_char;    // Carácter de relleno (por defecto ' ')
    
    // Nuevos modificadores de formato
    int precision;     // Precisión para floats (.2, .4, etc.)
    int has_precision;
    int padding;       // Ancho de padding (05, 10, etc.)
    int zero_pad;      // Si es padding con ceros (05 vs 5)
    char separator;    // Separador de miles (',' o '_')
    int has_separator;
    int show_prefix;   // Mostrar prefijo (0b, 0x, 0o) con #
    int show_sign;     // Mostrar signo siempre (+) o espacio ( )
    int truncate;      // Truncar strings a N caracteres
    int has_truncate;
    int as_percentage; // Mostrar como porcentaje (%)
} PatternStyle;

// Funciones principales con sistema antiguo
void c_print_styled(const char* text, TextColor fg, BackgroundColor bg, TextStyle style);
void c_print_color(const char* text, TextColor fg);
void c_print_bg(const char* text, BackgroundColor bg);
void c_print_style(const char* text, TextStyle style);
void c_print_full(const char* text, PrintOptions opts);

// NUEVA FUNCIÓN: Sistema de patrones mejorado
// Uso: c_print("Texto {s:green:white:bold}", "valor");
// Formato: {tipo:especificadores} donde especificadores pueden ser:
// - Colores: green, red, blue, etc.
// - Fondos: bg_green, bg_red, bg_blue, etc.
// - Estilos: bold, italic, underline, etc.
// - Alineación: <20 (izq), >20 (der), ^20 (centro)
// Ejemplos:
//   {s:green:bold:>30}
//   {s:<20:red:bg_white}
//   {d:^15:yellow}
void c_print(const char* pattern, ...);

// Funciones auxiliares para convertir strings a enums
TextColor parse_text_color(const char* color);
BackgroundColor parse_bg_color(const char* color);
TextStyle parse_text_style(const char* style);

// Función para imprimir con formato (como printf) con estilos
void c_printf_styled(TextColor fg, BackgroundColor bg, TextStyle style, const char* format, ...);

// Funciones internas
void apply_ansi_codes(TextColor fg, BackgroundColor bg, TextStyle style);
void reset_ansi_codes(void);

#ifdef __cplusplus
}
#endif

#endif // C_PRINT_H