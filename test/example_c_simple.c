#include <stdio.h>

extern int z_print_puts(const char *message);
extern int z_print_color_msg(const char *message, int color_code);
extern int z_print_bold_msg(const char *message);
extern const char *z_print_version(void);

int main(void) {
    z_print_puts("Hello from C!");
    z_print_color_msg("This is green text", 1);
    z_print_bold_msg("This is bold text");
    printf("z_print version: %s\n", z_print_version());
    return 0;
}
