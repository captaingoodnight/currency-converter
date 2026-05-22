/* ncurses_ui.c — NCurses terminal UI for the Ada Currency Converter.
 *
 * Screen layout (24×80 example; adapts to actual terminal size):
 *
 *   Row  0: ┌────────── Ada Currency Converter ──────────┐
 *   Row  1: │ AUD BRL CAD CHF CNY CZK DKK EUR GBP ...   │
 *   Row  2: │ ... KRW MXN MYR NOK NZD PHP PLN RON ...   │
 *   Row  3: ├────────────────────────────┬───────────────┤
 *   Row  4: │ (main I/O — left panel)    │Conv. History  │
 *   Row  5: │                            ├───────────────┤
 *   Row  6: │ prompts / results          │ entries …     │
 *   …       │                            │               │
 *   Row N-3: ├────────────────────────────┴───────────────┤
 *   Row N-2: │ Status: …                                  │
 *   Row N-1: └────────────────────────────────────────────┘
 */

#include "ncurses_ui.h"
#include <ncurses.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ------------------------------------------------------------------ */
/* Layout (computed from LINES/COLS at init time)                      */
/* ------------------------------------------------------------------ */

static int g_sep1;          /* row: separator between header and panels  */
static int g_sep2;          /* row: separator between panels and status  */
static int g_hist_col;      /* col: vertical divider between panels      */
static int g_hist_hdr_sep;  /* row: separator below "Conv. History" label */
static int g_main_row;      /* next available output row in the main panel */

/* ------------------------------------------------------------------ */
/* History buffer                                                       */
/* ------------------------------------------------------------------ */

#define MAX_HIST     10
#define MAX_HIST_LEN 72

static char g_hist[MAX_HIST][MAX_HIST_LEN];
static int  g_hist_n = 0;

/* ------------------------------------------------------------------ */
/* Forward declarations                                                 */
/* ------------------------------------------------------------------ */

static void draw_chrome(void);
static void draw_history(void);
static void write_main(const char *text, int color_pair, int attrs);

/* ------------------------------------------------------------------ */
/* Public API                                                           */
/* ------------------------------------------------------------------ */

void ui_init(void)
{
    initscr();
    noecho();
    cbreak();
    keypad(stdscr, TRUE);
    curs_set(0);

    if (has_colors()) {
        start_color();
        use_default_colors();
        init_pair(1, COLOR_CYAN,   -1);  /* title                */
        init_pair(2, COLOR_YELLOW, -1);  /* history heading      */
        init_pair(3, COLOR_GREEN,  -1);  /* conversion result    */
        init_pair(4, COLOR_RED,    -1);  /* error message        */
    }

    g_sep1         = 3;
    g_hist_col     = COLS * 3 / 5;
    g_hist_hdr_sep = g_sep1 + 2;
    g_sep2         = LINES - 3;
    g_main_row     = g_sep1 + 1;

    draw_chrome();
    doupdate();
}

void ui_cleanup(void)
{
    endwin();
}

/* ------------------------------------------------------------------ */

void ui_set_currencies(const char *list)
{
    /* Clear header rows (1 .. g_sep1-1) */
    for (int r = 1; r < g_sep1; r++) {
        move(r, 1);
        clrtoeol();
        mvaddch(r, COLS - 1, ACS_VLINE);
    }

    int max_col = COLS - 3;
    int row = 1, col = 2;
    const char *p = list;

    while (*p) {
        const char *tok = p;
        while (*p && *p != ' ') p++;
        int len = (int)(p - tok);

        if (col + len > max_col && col > 2) {
            row++;
            col = 2;
            if (row >= g_sep1) break;
        }
        mvaddnstr(row, col, tok, len);
        col += len + 1;
        while (*p == ' ') p++;
    }

    wnoutrefresh(stdscr);
    doupdate();
}

/* ------------------------------------------------------------------ */

void ui_clear_main(void)
{
    for (int r = g_sep1 + 1; r < g_sep2; r++) {
        move(r, 1);
        for (int c = 1; c < g_hist_col; c++)
            addch(' ');
        mvaddch(r, g_hist_col, ACS_VLINE);
    }
    g_main_row = g_sep1 + 1;
    wnoutrefresh(stdscr);
    doupdate();
}

/* ------------------------------------------------------------------ */

void ui_prompt(const char *label, char *buf, int maxlen)
{
    char *scratch = malloc(maxlen);

    if (g_main_row >= g_sep2) return;

    int label_len = (int)strlen(label);
    int input_col = 2 + label_len;
    int avail     = g_hist_col - input_col - 2;
    int limit     = (avail > 0 && avail < maxlen - 1) ? avail : maxlen - 1;

    mvprintw(g_main_row, 2, "%s", label);
    move(g_main_row, input_col);

    echo();
    curs_set(1);
    getnstr(buf, limit);
    noecho();
    curs_set(0);

    g_main_row++;
    wnoutrefresh(stdscr);
    doupdate();
}

/* ------------------------------------------------------------------ */

void ui_show_result(const char *line)
{
    write_main(line, 3, A_BOLD);
    doupdate();
}

void ui_show_error(const char *msg)
{
    write_main(msg, 4, 0);
    doupdate();
}

void ui_show_status(const char *msg)
{
    int status_row = g_sep2 + 1;
    move(status_row, 1);
    clrtoeol();
    mvaddch(status_row, COLS - 1, ACS_VLINE);
    mvprintw(status_row, 2, "%.*s", COLS - 4, msg);
    wnoutrefresh(stdscr);
    doupdate();
}

int ui_ask_continue(void)
{
    const char *prompt = "Convert another? [y/n]: ";
    ui_show_status(prompt);

    int status_row = g_sep2 + 1;
    move(status_row, 2 + (int)strlen(prompt));
    curs_set(1);
    refresh();

    int ch = getch();
    curs_set(0);

    move(status_row, 1);
    clrtoeol();
    mvaddch(status_row, COLS - 1, ACS_VLINE);
    doupdate();

    return (ch == 'y' || ch == 'Y') ? 1 : 0;
}

/* ------------------------------------------------------------------ */

void ui_add_history_entry(const char *entry)
{
    if (g_hist_n < MAX_HIST) {
        strncpy(g_hist[g_hist_n], entry, MAX_HIST_LEN - 1);
        g_hist[g_hist_n][MAX_HIST_LEN - 1] = '\0';
        g_hist_n++;
    } else {
        for (int i = 0; i < MAX_HIST - 1; i++)
            memcpy(g_hist[i], g_hist[i + 1], MAX_HIST_LEN);
        strncpy(g_hist[MAX_HIST - 1], entry, MAX_HIST_LEN - 1);
        g_hist[MAX_HIST - 1][MAX_HIST_LEN - 1] = '\0';
    }
    draw_history();
    doupdate();
}

/* ------------------------------------------------------------------ */
/* Internal helpers                                                     */
/* ------------------------------------------------------------------ */

static void draw_chrome(void)
{
    clear();

    /* Outer border */
    box(stdscr, 0, 0);

    /* Title centred on the top border row */
    const char *title = " Ada Currency Converter ";
    int tcol = (COLS - (int)strlen(title)) / 2;
    if (has_colors()) attron(COLOR_PAIR(1) | A_BOLD);
    mvprintw(0, tcol, "%s", title);
    if (has_colors()) attroff(COLOR_PAIR(1) | A_BOLD);

    /* Horizontal separator below header */
    mvaddch(g_sep1, 0, ACS_LTEE);
    mvhline(g_sep1, 1, ACS_HLINE, COLS - 2);
    mvaddch(g_sep1, COLS - 1, ACS_RTEE);
    /* T-junction where vertical separator meets the header separator */
    mvaddch(g_sep1, g_hist_col, ACS_TTEE);

    /* Vertical separator between main panel and history panel */
    mvvline(g_sep1 + 1, g_hist_col, ACS_VLINE, g_sep2 - g_sep1 - 1);

    /* "Conversion History" heading inside the right panel */
    if (has_colors()) attron(COLOR_PAIR(2) | A_BOLD);
    mvprintw(g_sep1 + 1, g_hist_col + 2, "Conversion History");
    if (has_colors()) attroff(COLOR_PAIR(2) | A_BOLD);

    /* Separator below the history heading */
    mvaddch(g_hist_hdr_sep, g_hist_col, ACS_LTEE);
    mvhline(g_hist_hdr_sep, g_hist_col + 1, ACS_HLINE, COLS - g_hist_col - 2);
    mvaddch(g_hist_hdr_sep, COLS - 1, ACS_RTEE);

    /* Horizontal separator above status bar */
    mvaddch(g_sep2, 0, ACS_LTEE);
    mvhline(g_sep2, 1, ACS_HLINE, COLS - 2);
    mvaddch(g_sep2, COLS - 1, ACS_RTEE);
    /* T-junction where vertical separator meets the status separator */
    mvaddch(g_sep2, g_hist_col, ACS_BTEE);

    wnoutrefresh(stdscr);
}

static void write_main(const char *text, int color_pair, int attrs)
{
    if (g_main_row >= g_sep2) return;

    int max_w = g_hist_col - 3;

    if (has_colors() && color_pair > 0) attron(COLOR_PAIR(color_pair) | attrs);
    else if (attrs)                      attron(attrs);

    mvprintw(g_main_row, 2, "%.*s", max_w, text);

    if (has_colors() && color_pair > 0) attroff(COLOR_PAIR(color_pair) | attrs);
    else if (attrs)                      attroff(attrs);

    g_main_row++;
    wnoutrefresh(stdscr);
}

static void draw_history(void)
{
    int hc    = g_hist_col + 1;          /* first content col in right panel */
    int hw    = COLS - hc - 1;           /* usable width                     */
    int hr0   = g_hist_hdr_sep + 1;      /* first entry row                  */
    int hrows = g_sep2 - hr0;            /* number of entry rows available   */

    /* Clear history content area */
    for (int r = hr0; r < g_sep2; r++) {
        move(r, hc);
        for (int c = 0; c < hw; c++) addch(' ');
    }

    /* Show most-recent entries, newest at the bottom */
    int start = (g_hist_n > hrows) ? g_hist_n - hrows : 0;
    for (int i = start; i < g_hist_n; i++) {
        int row = hr0 + (i - start);
        mvprintw(row, hc + 1, "%.*s", hw - 2, g_hist[i]);
    }

    wnoutrefresh(stdscr);
}
