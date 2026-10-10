#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LEN 128
#define SQUARE(x) ((x) * (x))

/* Точка входа: комментарий */
typedef struct point {
    double x, y;
} Point;

static unsigned long fib(unsigned n) {
    return n < 2 ? n : fib(n - 1) + fib(n - 2);
}

int main(int argc, char **argv) {
    Point p = { 1.5, -2.0 };
    char buf[MAX_LEN] = "hello";
    unsigned long f = fib(20);
    int hex = 0xFF, oct = 0755;

    if (argc > 1 && strcmp(argv[1], "-v") == 0) {
        fprintf(stderr, "version 1.2.3\n");
        return EXIT_FAILURE;
    }
    snprintf(buf, sizeof buf, "%s: %lu (%.2f)", buf, f, p.x + p.y);
    puts(buf);
    for (int i = 0; i < 10; i++) { hex += SQUARE(i); }
    return EXIT_SUCCESS;
}
