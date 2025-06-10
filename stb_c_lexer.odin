// TODO: rewrite my oen version it seems buggy for some reason
package naned

import "core:c"
import "core:fmt"

when ODIN_OS == .Linux do foreign import stb_c_lexer "thirdparty/stb_c_lexer/stb_c_lexer_linux.o"

CLEX :: enum c.long {
  eof = 256,
  parse_error,
  intlit,
  floatlit,
  id,
  dqstring,
  sqstring,
  charlit,
  eq,
  noteq,
  lesseq,
  greatereq,
  andand,
  oror,
  shl,
  shr,
  plusplus,
  minusminus,
  pluseq,
  minuseq,
  muleq,
  diveq,
  modeq,
  andeq,
  oreq,
  xoreq,
  arrow,
  eqarrow,
  shleq,
  CLEX_shr,
  first_unused_token,
}

lexer :: struct {
  input_stream:       ^c.char,
  eof:                ^c.char,
  parse_point:        ^c.char,
  string_storage:     ^c.char,
  string_storage_len: c.int,
  where_firstchar:    ^c.char,
  where_lastchar:     ^c.char,
  token:              c.long,
  real_number:        c.double,
  int_number:         c.long,
  string:             ^c.char,
  string_len:         c.int,
}

lex_location :: struct {
  line_number: c.int,
  line_offset: c.int,
}

@(link_prefix = "stb_c_lexer_")
foreign stb_c_lexer {
  init :: proc(lex: ^lexer, input_stream: ^c.char, input_stream_end: ^c.char, string_store: ^c.char, store_length: c.int) ---
  get_token :: proc(lex: ^lexer) -> c.int ---
  get_location :: proc(lex: ^lexer, where_char: ^c.char, loc: ^lex_location) ---
}

get_and_expect :: proc(l: ^lexer, expected: c.long) -> bool {
  get_token(l)
  return l.token == expected
}

get_and_expect_and_assert :: proc(l: ^lexer, expected: c.long) {

  res := get_and_expect(l, expected)

  loc: lex_location
  get_location(l, l.where_firstchar, &loc)

  fmt.assertf(
    res,
    "'%d:%d expected %d but got %d'",
    loc.line_number,
    loc.line_offset + 1,
    expected,
    l.token,
  )
}
