
// build: $(CC) -O2 -o /usr/bin/gpio_write_bin gpio_write_bin.c -lgpiod
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gpiod.h>

int main(void) {
  printf("Content-Type: application/json\r\n\r\n");

  char body[256] = {0};
  size_t n = fread(body, 1, sizeof(body)-1, stdin);
  (void)n;

  char chipname[32] = "gpiochip0";
  int line = -1, value = -1;
  // super-minimal parser for {"chip":"gpiochip0","line":N,"value":0|1}
  sscanf(body, "{\"chip\":\"%31[^\"]\",\"line\":%d,\"value\":%d}", chipname, &line, &value);
  if (line < 0 || (value != 0 && value != 1)) {
    printf("{\"error\":\"bad_input\"}\n"); return 0;
  }

  struct gpiod_chip *chip = gpiod_chip_open_by_name(chipname);
  if (!chip) { printf("{\"error\":\"open_chip\"}\n"); return 0; }

  struct gpiod_line *l = gpiod_chip_get_line(chip, line);
  if (!l) { printf("{\"error\":\"get_line\"}\n"); gpiod_chip_close(chip); return 0; }

  if (gpiod_line_request_output(l, "cgi", value) < 0) {
    printf("{\"error\":\"request_output\"}\n");
    gpiod_chip_close(chip); return 0;
  }

  if (gpiod_line_set_value(l, value) < 0) printf("{\"error\":\"write\"}\n");
  else printf("{\"chip\":\"%s\",\"line\":%d,\"value\":%d}\n", chipname, line, value);

  gpiod_line_release(l);
  gpiod_chip_close(chip);
  return 0;
}
