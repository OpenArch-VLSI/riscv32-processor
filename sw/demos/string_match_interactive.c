#include "../lib/uart.h"

/*
 * Interactive pattern matching demo.
 *
 * Prompts for a text line and a pattern over the UART, then runs a naive
 * substring search and prints every alignment attempt so the pattern can
 * be watched sliding along the text:
 *
 *   Text: ABABCABAB
 *   Pattern: ABC
 *   [0] ABABCABAB
 *       ABC  mismatch at 2
 *   [1] ABABCABAB
 *        ABC  mismatch at 0
 *   [2] ABABCABAB
 *         ABC  MATCH!
 *   ...
 *   Matches: 1 at [2]
 *   Cycles: 1234
 *
 * The search itself is timed with the cycle counter in a separate silent
 * pass, so the reported cycle count is not distorted by UART printing.
 *
 * NOTE: this is a strict Harvard target — no string literals or
 * initialized globals (they land in .rodata/.data, which the zeroed data
 * RAM never receives). All text is emitted with putchar chains, and no
 * divide/modulo is used (print_dec subtracts powers of ten; the core has
 * MUL but this demo does not rely on DIV).
 */

volatile unsigned int* const CYCLE_CNT = (volatile unsigned int*)0xC0000000;

#define MAX_TEXT  40
#define MAX_PAT   12
#define MAX_MATCH 8

static void crlf(void) {
    putchar('\r');
    putchar('\n');
}

static void print_dec(unsigned int v) {
    unsigned int pw[10];
    int i;
    int started = 0;
    pw[9] = 1;
    for (i = 8; i >= 0; i--) pw[i] = pw[i + 1] * 10;
    for (i = 0; i < 10; i++) {
        unsigned int d = 0;
        while (v >= pw[i]) {
            v -= pw[i];
            d++;
        }
        if (d != 0 || started || i == 9) {
            putchar((char)('0' + d));
            started = 1;
        }
    }
}

/* Read one line with echo; Enter finishes, backspace/DEL edits. */
static int read_line(char* buf, int maxlen) {
    int len = 0;
    for (;;) {
        char c = getchar();
        if (c == '\r' || c == '\n') {
            crlf();
            buf[len] = 0;
            return len;
        }
        if (c == 8 || c == 127) {
            if (len > 0) {
                len--;
                putchar(8); putchar(' '); putchar(8);
            }
            continue;
        }
        if (len < maxlen - 1 && c >= 32 && c < 127) {
            buf[len] = c;
            len++;
            putchar(c);
        }
    }
}

static void print_prompt_text(void) {
    putchar('T'); putchar('e'); putchar('x'); putchar('t');
    putchar(':'); putchar(' ');
}

static void print_prompt_pattern(void) {
    putchar('P'); putchar('a'); putchar('t'); putchar('t');
    putchar('e'); putchar('r'); putchar('n');
    putchar(':'); putchar(' ');
}

static void print_mismatch_at(void) {
    putchar('m'); putchar('i'); putchar('s'); putchar('m');
    putchar('a'); putchar('t'); putchar('c'); putchar('h');
    putchar(' '); putchar('a'); putchar('t'); putchar(' ');
}

static void print_match_word(void) {
    putchar('M'); putchar('A'); putchar('T'); putchar('C');
    putchar('H'); putchar('!');
}

int main(void) {
    char text[MAX_TEXT];
    char pat[MAX_PAT];
    int  pos[MAX_MATCH];

    for (;;) {
        print_prompt_text();
        int tlen = read_line(text, MAX_TEXT);

        print_prompt_pattern();
        int plen = read_line(pat, MAX_PAT);

        if (tlen == 0 || plen == 0 || plen > tlen) {
            putchar('E'); putchar('R'); putchar('R');
            crlf();
            continue;
        }

        /* Silent timed pass: pure search cost, no UART in the loop */
        unsigned int c0 = *CYCLE_CNT;
        int count = 0;
        for (int i = 0; i + plen <= tlen; i++) {
            int j = 0;
            while (j < plen && text[i + j] == pat[j]) j++;
            if (j == plen) {
                if (count < MAX_MATCH) pos[count] = i;
                count++;
            }
        }
        unsigned int c1 = *CYCLE_CNT;

        /* Traced pass: show every alignment attempt */
        for (int i = 0; i + plen <= tlen; i++) {
            int j = 0;
            while (j < plen && text[i + j] == pat[j]) j++;

            putchar('[');
            print_dec((unsigned int)i);
            putchar(']');
            putchar(' ');
            for (int k = 0; k < tlen; k++) putchar(text[k]);
            crlf();

            /* Indent pattern under its alignment: "[i] " is 4 or 5 wide */
            int prefix = (i >= 10) ? 5 : 4;
            for (int k = 0; k < prefix + i; k++) putchar(' ');
            for (int k = 0; k < plen; k++) putchar(pat[k]);
            putchar(' '); putchar(' ');
            if (j == plen) {
                print_match_word();
            } else {
                print_mismatch_at();
                print_dec((unsigned int)j);
            }
            crlf();
        }

        /* Summary: "Matches: N at [p, q, ...]" */
        putchar('M'); putchar('a'); putchar('t'); putchar('c');
        putchar('h'); putchar('e'); putchar('s');
        putchar(':'); putchar(' ');
        print_dec((unsigned int)count);
        if (count > 0) {
            putchar(' '); putchar('a'); putchar('t'); putchar(' ');
            putchar('[');
            int shown = (count < MAX_MATCH) ? count : MAX_MATCH;
            for (int k = 0; k < shown; k++) {
                if (k > 0) { putchar(','); putchar(' '); }
                print_dec((unsigned int)pos[k]);
            }
            putchar(']');
        }
        crlf();

        /* "Cycles: N" — silent search pass only */
        putchar('C'); putchar('y'); putchar('c'); putchar('l');
        putchar('e'); putchar('s');
        putchar(':'); putchar(' ');
        print_dec(c1 - c0);
        crlf();
        crlf();
    }

    return 0;
}
