#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define STB_C_LEXER_IMPLEMENTATION
#include "thirdparty/stb_c_lexer.h"

#include "c_nice.h"

// ------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ARRAY_GET(array, index)                                                \
  (assert((size_t)index < array_length(array)), array[(size_t)index])

#define DA_INIT_CAP 256
#define da_reserve(da, expected_capacity)                                      \
  do {                                                                         \
    if ((expected_capacity) > (da)->capacity) {                                \
      if ((da)->capacity == 0) {                                               \
        (da)->capacity = DA_INIT_CAP;                                          \
      }                                                                        \
      while ((expected_capacity) > (da)->capacity) {                           \
        (da)->capacity *= 2;                                                   \
      }                                                                        \
      (da)->items =                                                            \
          realloc((da)->items, (da)->capacity * sizeof(*(da)->items));         \
      assert((da)->items != NULL && "Buy more RAM lol");                       \
    }                                                                          \
  } while (0)

#define da_append(da, item)                                                    \
  do {                                                                         \
    da_reserve((da), (da)->count + 1);                                         \
    (da)->items[(da)->count++] = (item);                                       \
  } while (0)

#define da_free(da) free((da).items)

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

enum n_types {
  String = CLEX_dqstring,
  Func,
  Int = CLEX_intlit,
  Float = CLEX_floatlit,
  Char = CLEX_charlit,
};

typedef struct {
  const char *name;
  double real_val;
  long int_val;
  char *string_val;
  int string_val_len;
} vars;

typedef struct {
  const char *name;
  vars* items;
  

} fn_declr;

int main(int argc, char **argv) {

  (void)argc;
  (void)argv;

  const char *file = "test.nn";
  char *lex_store = calloc(1, store_len);

  long file_size = 0;
  char *out = read_file(file, &file_size);
  if (out == NULL)
    return 1;

  stb_lexer lexer = {0};
  stb_c_lexer_init(&lexer, out, out + file_size, lex_store, store_len);
  fprintf(stdout, "int main(int argc, char **argv) {\n");
  while (stb_c_lexer_get_token(&lexer)) {
    switch (lexer.token) {
    case CLEX_id:
      printf("%s\n", lexer.string);
      break;
    default:
      if (lexer.token > 255) {
        printf("token: %d\n", (int)lexer.token);
      } else {
        printf("token: %c\n", (int)lexer.token);
      }
      break;
    }
  }
  fprintf(stdout, "  return 0;\n}\n");

  return 0;
}