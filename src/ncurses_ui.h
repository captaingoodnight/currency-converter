#ifndef NCURSES_UI_H
#define NCURSES_UI_H

/* Initialize NCurses and draw the initial screen chrome. */
void ui_init(void);

/* Restore the terminal to its original state. */
void ui_cleanup(void);

/* Display a space-separated list of currency codes in the header panel. */
void ui_set_currencies(const char *list);

/* Add one formatted entry to the history panel (shifts oldest out when full). */
void ui_add_history_entry(const char *entry);

/* Show LABEL, read a line of input into BUF (at most MAXLEN-1 chars). */
void ui_prompt(const char *label, char *buf, int maxlen);

/* Write LINE to the main panel in green (conversion result). */
void ui_show_result(const char *line);

/* Write MSG to the main panel in red (validation / fetch error). */
void ui_show_error(const char *msg);

/* Replace the status bar text with MSG. */
void ui_show_status(const char *msg);

/* Erase the main (left) panel and reset the output cursor to its top. */
void ui_clear_main(void);

/* Show "Convert another? [y/n]" in the status bar; return 1 for y/Y, 0 otherwise. */
int ui_ask_continue(void);

#endif /* NCURSES_UI_H */
