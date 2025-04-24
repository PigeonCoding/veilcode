#include <stdio.h>
#include <stdlib.h>

#define STB_C_LEXER_IMPLEMENTATION
#include "thirdparty/stb_c_lexer.h"

// ------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *read_file(const char *filename, long *size) {

  char *out = NULL;
  FILE *file = fopen(filename, "r");
  if (!file) {
    fprintf(stderr, "Failed to open file\n");
    return NULL;
  }

  // Move the file pointer to the end to determine the file size
  fseek(file, 0, SEEK_END);
  long file_size = ftell(file);
  fseek(file, 0, SEEK_SET); // Move back to the beginning of the file

  // Allocate memory for the file content (+1 for the null terminator)
  out = (char *)malloc(file_size + 1);
  if (!out) {
    fprintf(stderr, "Failed to allocate memory\n");
    fclose(file);
    return NULL;
  }

  long i = 0;
  while (1) {
    char c = fgetc(file);
    if (c == EOF) {
      out[i] = '\0';
      break;
    }
    out[i] = c;
    i += 1;
  }

  if (i != file_size) {
    fprintf(stderr, "read size %ld does not match file size %ld", i, file_size);
    fclose(file);
    return NULL;
  }

  fclose(file);
  *size = file_size;
  return out;
}

// ---------------------------------------------------------------------------
// TODO: Move what is in this block to a header

#define store_len 100

int main(int argc, char **argv) {

  const char *file = "test.nn";
  long size = 0;
  char *store = malloc(store_len);

  char *out = read_file(file, &size);
  if (out == NULL)
    return 1;

  stb_lexer lexer = {0};
  stb_c_lexer_init(&lexer, out, out + size, store, store_len);
  while (stb_c_lexer_get_token(&lexer)) {
    switch (lexer.token) {
    case CLEX_id:
      printf("id: %s\n", lexer.string);
      break;
    case CLEX_dqstring:
      printf("string: %s\n", lexer.string);
      break;
    default:
      printf("token: %c\n", (int)lexer.token);
      break;
    }
  }

  return 0;
}
