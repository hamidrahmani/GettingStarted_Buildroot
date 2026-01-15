
// build: $(CC) -O2 -o /usr/bin/gpio_read_bin gpio_read_bin.c -lgpiod
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gpiod.h>

static int parse_qs(const char *qs, char *chip, size_t chipsz, int *line) {
  // Supports ?chip=gpiochip0&line=23 ; defaults if only line provided
  *line = -1;
  if (!qs) return -1;
  // extremely small parser; production: make robust
  char *q = strdup(qs);
  if (!q) return -1;
  char *tok = strtok(q, "&");
  chip[0] = '\0';
  while (tok) {
    if (sscanf(tok, "line=%d", line) == 1) {}
    else if (sscanf(tok, "chip=%31s", chip) == 1) {}
    tok = strtok(NULL, "&");
  }
  free(q);
  if (chip[0] == '\0') strncpy(chip, "gpiochip0", chipsz);
  return (*line >= 0) ? 0 : -1;
}

int main(void) {
  printf("Content-Type: application/json\r\n\r\n");

  const char *qs = getenv("QUERY_STRING");
  char chipname[32];
  int line;
  if (parse_qs(qs, chipname, sizeof(chipname), &line) < 0) {
    printf("{\"error\":\"bad_query\",\"hint\":\"chip=gpiochip0&line=N\"}\n");
    return 0;
  }

  struct gpiod_chip *chip = gpiod_chip_open_by_name(chipname);
  if (!chip) { printf("{\"error\":\"open_chip\"}\n"); return 0; }

  struct gpiod_line *l = gpiod_chip_get_line(chip, line);
  if (!l) { printf("{\"error\":\"get_line\"}\n"); gpiod_chip_close(chip); return 0; }

  if (gpiod_line_request_input(l, "cgi") < 0) {
    printf("{\"error\":\"request_input\"}\n");
    gpiod_chip_close(chip); return 0;
  }

  int val = gpiod_line_get_value(l);
  if (val < 0) printf("{\"error\":\"read\"}\n");
  else printf("{\"chip\":\"%s\",\"line\":%d,\"value\":%d}\n", chipname, line, val);

  gpiod_line_release(l);
  gpiod_chip_close(chip);
  return 0;
}
