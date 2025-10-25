#include "c_print.h"
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>

// Función interna para convertir string a minúsculas
static void to_lowercase(char* str) {
    for (int i = 0; str[i]; i++) {
        str[i] = tolower((unsigned char)str[i]);
    }
}

// Verificar si un string es un número
static bool is_number(const char* str) {
    if (!str || *str == '\0') return false;
    while (*str) {
        if (!isdigit(*str)) return false;
        str++;
    }
    return true;
}

// Parsear color de texto desde string
TextColor parse_text_color(const char* color) {
    if (!color || strlen(color) == 0) return COLOR_RESET;
    
    char temp[50];
    strncpy(temp, color, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    
    if (strcmp(temp, "black") == 0) return COLOR_BLACK;
    if (strcmp(temp, "red") == 0) return COLOR_RED;
    if (strcmp(temp, "green") == 0) return COLOR_GREEN;
    if (strcmp(temp, "yellow") == 0) return COLOR_YELLOW;
    if (strcmp(temp, "blue") == 0) return COLOR_BLUE;
    if (strcmp(temp, "magenta") == 0) return COLOR_MAGENTA;
    if (strcmp(temp, "cyan") == 0) return COLOR_CYAN;
    if (strcmp(temp, "white") == 0) return COLOR_WHITE;
    if (strcmp(temp, "bright_black") == 0) return COLOR_BRIGHT_BLACK;
    if (strcmp(temp, "bright_red") == 0) return COLOR_BRIGHT_RED;
    if (strcmp(temp, "bright_green") == 0) return COLOR_BRIGHT_GREEN;
    if (strcmp(temp, "bright_yellow") == 0) return COLOR_BRIGHT_YELLOW;
    if (strcmp(temp, "bright_blue") == 0) return COLOR_BRIGHT_BLUE;
    if (strcmp(temp, "bright_magenta") == 0) return COLOR_BRIGHT_MAGENTA;
    if (strcmp(temp, "bright_cyan") == 0) return COLOR_BRIGHT_CYAN;
    if (strcmp(temp, "bright_white") == 0) return COLOR_BRIGHT_WHITE;
    
    return COLOR_RESET;
}

// Parsear color de fondo desde string (soporta bg_ prefix o sin él)
BackgroundColor parse_bg_color(const char* color) {
    if (!color || strlen(color) == 0) return BG_RESET;
    
    char temp[50];
    strncpy(temp, color, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    
    // Remover prefijo "bg_" si existe
    const char* color_name = temp;
    if (strncmp(temp, "bg_", 3) == 0) {
        color_name = temp + 3;
    }
    
    if (strcmp(color_name, "black") == 0) return BG_BLACK;
    if (strcmp(color_name, "red") == 0) return BG_RED;
    if (strcmp(color_name, "green") == 0) return BG_GREEN;
    if (strcmp(color_name, "yellow") == 0) return BG_YELLOW;
    if (strcmp(color_name, "blue") == 0) return BG_BLUE;
    if (strcmp(color_name, "magenta") == 0) return BG_MAGENTA;
    if (strcmp(color_name, "cyan") == 0) return BG_CYAN;
    if (strcmp(color_name, "white") == 0) return BG_WHITE;
    if (strcmp(color_name, "bright_black") == 0) return BG_BRIGHT_BLACK;
    if (strcmp(color_name, "bright_red") == 0) return BG_BRIGHT_RED;
    if (strcmp(color_name, "bright_green") == 0) return BG_BRIGHT_GREEN;
    if (strcmp(color_name, "bright_yellow") == 0) return BG_BRIGHT_YELLOW;
    if (strcmp(color_name, "bright_blue") == 0) return BG_BRIGHT_BLUE;
    if (strcmp(color_name, "bright_magenta") == 0) return BG_BRIGHT_MAGENTA;
    if (strcmp(color_name, "bright_cyan") == 0) return BG_BRIGHT_CYAN;
    if (strcmp(color_name, "bright_white") == 0) return BG_BRIGHT_WHITE;
    
    return BG_RESET;
}

// Parsear estilo de texto desde string
TextStyle parse_text_style(const char* style) {
    if (!style || strlen(style) == 0) return STYLE_RESET;
    
    char temp[50];
    strncpy(temp, style, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    
    if (strcmp(temp, "bold") == 0) return STYLE_BOLD;
    if (strcmp(temp, "dim") == 0) return STYLE_DIM;
    if (strcmp(temp, "italic") == 0) return STYLE_ITALIC;
    if (strcmp(temp, "underline") == 0) return STYLE_UNDERLINE;
    if (strcmp(temp, "blink") == 0) return STYLE_BLINK;
    if (strcmp(temp, "reverse") == 0) return STYLE_REVERSE;
    if (strcmp(temp, "hidden") == 0) return STYLE_HIDDEN;
    if (strcmp(temp, "strikethrough") == 0) return STYLE_STRIKETHROUGH;
    
    return STYLE_RESET;
}

// Aplicar códigos ANSI
void apply_ansi_codes(TextColor fg, BackgroundColor bg, TextStyle style) {
    printf("\033[");
    
    int first = 1;
    if (style != STYLE_RESET) {
        printf("%d", style);
        first = 0;
    }
    
    if (fg != COLOR_RESET) {
        if (!first) printf(";");
        printf("%d", fg);
        first = 0;
    }
    
    if (bg != BG_RESET) {
        if (!first) printf(";");
        printf("%d", bg);
    }
    
    printf("m");
}

// Resetear códigos ANSI
void reset_ansi_codes(void) {
    printf("\033[0m");
}

// Detectar si un token es alineación (<20, >20, ^20)
static bool is_alignment(const char* token, TextAlign* align, int* width) {
    if (!token || strlen(token) < 2) return false;
    
    char first = token[0];
    if (first == '<' || first == '>' || first == '^') {
        if (is_number(token + 1)) {
            *align = (TextAlign)first;
            *width = atoi(token + 1);
            return true;
        }
    }
    return false;
}

// Detectar si un token es un color de fondo (empieza con bg_)
static bool is_background_color(const char* token) {
    if (!token) return false;
    char temp[50];
    strncpy(temp, token, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    to_lowercase(temp);
    return strncmp(temp, "bg_", 3) == 0;
}

// Parsear un patrón mejorado: {s:green:bg_white:bold:>30}
static bool parse_pattern(const char* pattern, PatternStyle* style) {
    if (!pattern || pattern[0] != '{') return false;
    
    // Encontrar el cierre
    const char* end = strchr(pattern, '}');
    if (!end) return false;
    
    // Copiar el contenido entre {}
    int len = end - pattern - 1;
    if (len <= 0 || len >= 200) return false;
    
    char buffer[200];
    strncpy(buffer, pattern + 1, len);
    buffer[len] = '\0';
    
    // Inicializar estructura
    style->format_type = '\0';
    style->text_color = COLOR_RESET;
    style->bg_color = BG_RESET;
    style->style = STYLE_RESET;
    style->has_color = 0;
    style->has_bg = 0;
    style->has_style = 0;
    style->align = ALIGN_NONE;
    style->width = 0;
    style->has_alignment = 0;
    
    // Dividir por ':' y procesar tokens
    char* saveptr;
    char* token = strtok_r(buffer, ":", &saveptr);
    int part = 0;
    
    while (token != NULL) {
        // Eliminar espacios
        while (*token == ' ') token++;
        char* end_token = token + strlen(token) - 1;
        while (end_token > token && *end_token == ' ') {
            *end_token = '\0';
            end_token--;
        }
        
        if (strlen(token) > 0) {
            if (part == 0) {
                // Primera parte siempre es el tipo de formato
                style->format_type = token[0];
            } else {
                // Los demás pueden ser en cualquier orden
                TextAlign align;
                int width;
                
                // Verificar si es alineación
                if (is_alignment(token, &align, &width)) {
                    style->align = align;
                    style->width = width;
                    style->has_alignment = 1;
                }
                // Verificar si es color de fondo
                else if (is_background_color(token)) {
                    style->bg_color = parse_bg_color(token);
                    style->has_bg = 1;
                }
                // Verificar si es un estilo conocido
                else {
                    TextStyle parsed_style = parse_text_style(token);
                    if (parsed_style != STYLE_RESET) {
                        style->style = parsed_style;
                        style->has_style = 1;
                    } else {
                        // Debe ser un color de texto
                        TextColor parsed_color = parse_text_color(token);
                        if (parsed_color != COLOR_RESET) {
                            style->text_color = parsed_color;
                            style->has_color = 1;
                        }
                    }
                }
            }
        }
        
        token = strtok_r(NULL, ":", &saveptr);
        part++;
    }
    
    return style->format_type != '\0';
}

// Imprimir con alineación
static void print_aligned(const char* text, TextAlign align, int width) {
    int text_len = strlen(text);
    
    if (text_len >= width) {
        // Si el texto es más largo que el ancho, imprimir sin padding
        printf("%s", text);
        return;
    }
    
    int padding = width - text_len;
    
    switch (align) {
        case ALIGN_LEFT:  // <
            printf("%s", text);
            for (int i = 0; i < padding; i++) printf(" ");
            break;
            
        case ALIGN_RIGHT:  // >
            for (int i = 0; i < padding; i++) printf(" ");
            printf("%s", text);
            break;
            
        case ALIGN_CENTER:  // ^
            {
                int left_pad = padding / 2;
                int right_pad = padding - left_pad;
                for (int i = 0; i < left_pad; i++) printf(" ");
                printf("%s", text);
                for (int i = 0; i < right_pad; i++) printf(" ");
            }
            break;
            
        default:
            printf("%s", text);
            break;
    }
}

// FUNCIÓN PRINCIPAL CON SISTEMA DE PATRONES MEJORADO
void c_print(const char* pattern, ...) {
    if (!pattern) return;
    
    va_list args;
    va_start(args, pattern);
    
    const char* p = pattern;
    
    while (*p) {
        // Buscar el inicio de un patrón
        if (*p == '{') {
            PatternStyle style;
            // const char* pattern_start = p;  // Guardado para futuro uso (debug/error messages)
            
            // Intentar parsear el patrón
            if (parse_pattern(p, &style)) {
                // Buffer para el valor formateado
                char value_buffer[1024];
                value_buffer[0] = '\0';
                
                // Formatear el valor según el tipo
                switch (style.format_type) {
                    case 's': {
                        char* str = va_arg(args, char*);
                        if (str) {
                            snprintf(value_buffer, sizeof(value_buffer), "%s", str);
                        }
                        break;
                    }
                    case 'd':
                    case 'i': {
                        int num = va_arg(args, int);
                        snprintf(value_buffer, sizeof(value_buffer), "%d", num);
                        break;
                    }
                    case 'f': {
                        double num = va_arg(args, double);
                        snprintf(value_buffer, sizeof(value_buffer), "%f", num);
                        break;
                    }
                    case 'c': {
                        char ch = (char)va_arg(args, int);
                        snprintf(value_buffer, sizeof(value_buffer), "%c", ch);
                        break;
                    }
                    case 'x': {
                        unsigned int num = va_arg(args, unsigned int);
                        snprintf(value_buffer, sizeof(value_buffer), "%x", num);
                        break;
                    }
                    case 'o': {
                        unsigned int num = va_arg(args, unsigned int);
                        snprintf(value_buffer, sizeof(value_buffer), "%o", num);
                        break;
                    }
                    case 'u': {
                        unsigned int num = va_arg(args, unsigned int);
                        snprintf(value_buffer, sizeof(value_buffer), "%u", num);
                        break;
                    }
                    case 'l': {
                        long num = va_arg(args, long);
                        snprintf(value_buffer, sizeof(value_buffer), "%ld", num);
                        break;
                    }
                    default:
                        snprintf(value_buffer, sizeof(value_buffer), "{?}");
                        break;
                }
                
                // Aplicar estilos ANSI
                if (style.has_color || style.has_bg || style.has_style) {
                    apply_ansi_codes(style.text_color, style.bg_color, style.style);
                }
                
                // Imprimir con o sin alineación
                if (style.has_alignment) {
                    print_aligned(value_buffer, style.align, style.width);
                } else {
                    printf("%s", value_buffer);
                }
                
                // Resetear estilos
                if (style.has_color || style.has_bg || style.has_style) {
                    reset_ansi_codes();
                }
                
                // Avanzar hasta después del }
                while (*p && *p != '}') p++;
                if (*p == '}') p++;
                
            } else {
                // No es un patrón válido, imprimir literal
                putchar(*p);
                p++;
            }
        } else if (*p == '\\' && *(p + 1) == '{') {
            // Escape para {
            putchar('{');
            p += 2;
        } else {
            // Carácter normal
            putchar(*p);
            p++;
        }
    }
    
    va_end(args);
}

// Imprimir con todos los estilos (funciones antiguas)
void c_print_styled(const char* text, TextColor fg, BackgroundColor bg, TextStyle style) {
    apply_ansi_codes(fg, bg, style);
    printf("%s", text);
    reset_ansi_codes();
}

// Imprimir solo con color de texto
void c_print_color(const char* text, TextColor fg) {
    c_print_styled(text, fg, BG_RESET, STYLE_RESET);
}

// Imprimir solo con color de fondo
void c_print_bg(const char* text, BackgroundColor bg) {
    c_print_styled(text, COLOR_RESET, bg, STYLE_RESET);
}

// Imprimir solo con estilo
void c_print_style(const char* text, TextStyle style) {
    c_print_styled(text, COLOR_RESET, BG_RESET, style);
}

// Imprimir con estructura de opciones
void c_print_full(const char* text, PrintOptions opts) {
    c_print_styled(text, opts.text_color, opts.bg_color, opts.style);
}

// Printf con formato y estilos
void c_printf_styled(TextColor fg, BackgroundColor bg, TextStyle style, const char* format, ...) {
    apply_ansi_codes(fg, bg, style);
    
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
    
    reset_ansi_codes();
}