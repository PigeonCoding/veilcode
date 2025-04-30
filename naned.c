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
  char *name;
  enum n_types vars[100];
} n_func_declare_t;

typedef struct {
  int instr_id;
  char *v_str;
  // int v_int;
  // float v_float;
} n_instr_t;

typedef struct {
  n_func_declare_t *items;
  size_t count;
  size_t capacity;
} func_da_t;

func_da_t funcs = {0};

bool get_and_expect(stb_lexer *lexer, int type, const char *file, bool print) {
  stb_c_lexer_get_token(lexer);

  if (lexer->token != type) {
    if (print) {
      stb_lex_location l = {0};
      stb_c_lexer_get_location(lexer, lexer->where_firstchar, &l);
      if (type < 256) {
        eprintf(P_ERR,
                "expected type '%c' but did not get it got %s:%d:%d %c\n", type,
                file, l.line_number, l.line_offset + 1, (int)lexer->token);
      } else {
        eprintf(P_ERR, "expected type '%d' but did not get it got %s:%d:%d\n",
                type, file, l.line_number, l.line_offset + 1);
      }
    }
    return false;
  }
  return true;
}

bool are_same_vars(enum n_types *a, enum n_types *b) {
  for (int i = 0; i < 100; i++) {
    if (a[i] != b[i])
      return false;
  }
  return true;
}

bool fn_is_unique(n_func_declare_t *fn) {
  for (size_t i = 0; i < funcs.count; i++) {
    if (strcmp(fn->name, funcs.items[i].name) == 0 &&
        are_same_vars(fn->vars, funcs.items[i].vars)) {
      return false;
    }
  }
  return true;
}

bool fn_exists(n_func_declare_t *fn) {
  for (size_t i = 0; i < funcs.count; i++) {
    if (strcmp(fn->name, funcs.items[i].name) == 0 &&
        are_same_vars(fn->vars, funcs.items[i].vars))
      return true;
  }
  return false;
}

bool fn_name_exists(const char *name) {
  for (size_t i = 0; i < funcs.count; i++) {
    if (strcmp(name, funcs.items[i].name) == 0)
      return true;
  }
  return false;
}

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
      // break;
      if (strcmp(lexer.string, "declare") == 0) {
        if (!get_and_expect(&lexer, CLEX_id, file, true) &&
            strcmp(lexer.string, "fn") != 0)
          return 1;

        if (!get_and_expect(&lexer, CLEX_id, file, true))
          return 1;

        n_func_declare_t fn = {0};

        fn.name = calloc(1, strlen(lexer.string));
        strcpy(fn.name, lexer.string);
        fprintf(stdout, "  void %s(", fn.name);

        if (!get_and_expect(&lexer, '(', file, true))
          return 1;

        if (!get_and_expect(&lexer, CLEX_id, file, true))
          return 1;

        if (strcmp(lexer.string, "string") == 0) {
          fn.vars[0] = String;
        } else if (strcmp(lexer.string, "int") == 0) {
          fn.vars[0] = Int;
        } else if (strcmp(lexer.string, "float") == 0) {
          fn.vars[0] = Float;
        } else if (strcmp(lexer.string, "char") == 0) {
          fn.vars[0] = Char;
        } else {
          stb_lex_location l = {0};
          stb_c_lexer_get_location(&lexer, lexer.where_firstchar, &l);
          fprintf(stdout, "unknown type %s:%d:%d %s\n", file, l.line_number,
                  l.line_offset + 1, lexer.string);
          return 1;
        }
        if (!fn_is_unique(&fn)) {
          fprintf(stderr, "function %s is redefined \n", fn.name);
          return 1;
        } else
          da_append(&funcs, fn);
        if (fn.vars[0] == Char)
          fprintf(stdout, "int");
        else if (fn.vars[0] == String)
          fprintf(stdout, "char*");

        else
          fprintf(stdout, "%s", lexer.string);

        if (!get_and_expect(&lexer, ')', file, false)) {
          fprintf(
              stderr,
              "currently only one var supported for function declaration\n");
          return 1;
        }

        if (!get_and_expect(&lexer, ';', file, true)) {
          return 1;
        }

        fprintf(stdout, ");\n");
        break;
      }

      if (fn_name_exists(lexer.string)) {
        n_func_declare_t fn = {0};
        fn.name = calloc(1, strlen(lexer.string));
        strcpy(fn.name, lexer.string);

        if (!get_and_expect(&lexer, '(', file, true))
          return 1;

        stb_c_lexer_get_token(&lexer);
        switch (lexer.token) {
        case CLEX_dqstring:
          fn.vars[0] = String;
          break;
        case CLEX_intlit:
          fn.vars[0] = Int;
          break;
        case CLEX_floatlit:
          fn.vars[0] = Float;
          break;
        case CLEX_charlit:
          fn.vars[0] = Char;
          break;
        default:

#pragma GCC diagnostic push
#if defined(__clang__)
#pragma GCC diagnostic ignored "-Wc23-extensions"
#endif
          stb_lex_location l = {0};
#pragma GCC diagnostic pop

          stb_c_lexer_get_location(&lexer, lexer.where_firstchar, &l);
          fprintf(stderr, "unknown type %s:%d:%d %s\n", file, l.line_number,
                  l.line_offset + 1, lexer.string);
          return 1;
        }

        if (fn_exists(&fn)) {
          fprintf(stdout, "  %s(", fn.name);
          // TODO: support multiple args
          if (fn.vars[0] == String) {
            fprintf(stdout, "\"%s\"", lexer.string);
          } else if (fn.vars[0] == Int || fn.vars[0] == Char) {
            fprintf(stdout, "%zd", lexer.int_number);
          } else if (fn.vars[0] == Float) {
            fprintf(stdout, "%f", lexer.real_number);
          }
          // } else if (fn.vars[0] == Char) {
          //   fprintf(stdout, "\'%c\'", (int)lexer.int_number);
          // }

          if (fn.vars[0] == Char) {
            if (!get_and_expect(&lexer, ';', file, true)) {
              return 1;
            }
          } else {
            if (!get_and_expect(&lexer, ')', file, true)) {
              // eprintfn(P_INFO, "token %d", (int)lexer.token);
              stb_lex_location l = {0};
              stb_c_lexer_get_location(&lexer, lexer.where_firstchar, &l);
              fprintf(stderr,
                      "currently only one var supported for function call "
                      "%s:%d:%d %s\n",
                      file, l.line_number, l.line_offset + 1, fn.name);
              return 1;
            }
            if (!get_and_expect(&lexer, ';', file, true))
              return 1;
          }

          fprintf(stdout, ");\n");
          break;
        }
      }

      printf("id: %s\n", lexer.string);
      break;
    // case CLEX_dqstring:
    //   printf("string: %s\n", lexer.string);
    //   break;
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

  // for (size_t i = 0; i < funcs.count; i++) {
  //   printf("found fn: %s\n", funcs.items[i].name);
  // }

  return 0;
}
