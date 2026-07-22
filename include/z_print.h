/**
 * z_print - Colored and formatted text printing library
 * 
 * C-ABI compatible header for using z_print from C/C++ code.
 * 
 * Usage:
 *   cc example.c -L /usr/local/lib -lz_print -o example
 * 
 * Colors:
 *   0=red, 1=green, 2=blue, 3=yellow, 4=cyan, 5=magenta, 6=white, 7=black
 */

#ifndef C_PRINT_H
#define C_PRINT_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Print a message with a color.
 * 
 * @param message  The text to print (null-terminated string)
 * @param color_code  Color index: 0=red, 1=green, 2=blue, 3=yellow, 
 *                    4=cyan, 5=magenta, 6=white, 7=black
 * @return 0 on success, -1 on error
 */
int z_print_color_msg(const char *message, int color_code);

/**
 * Print a bold message.
 * 
 * @param message  The text to print (null-terminated string)
 * @return 0 on success, -1 on error
 */
int z_print_bold_msg(const char *message);

/**
 * Print a simple string (no formatting).
 * 
 * @param message  The text to print (null-terminated string)
 * @return 0 on success, -1 on error
 */
int z_print_puts(const char *message);

/**
 * Get library version string.
 * 
 * @return Version string (e.g., "z_print 0.1.0 (Zig 0.16.0)")
 */
const char *z_print_version(void);

#ifdef __cplusplus
}
#endif

#endif /* C_PRINT_H */
