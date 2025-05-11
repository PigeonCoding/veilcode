package naned

import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

// when ODIN_OS == .Windows do foreign import foo "foo.lib"
when ODIN_OS == .Linux do foreign import stb_c_lexer "thirdparty/stb_c_lexer.o"

CLEX :: enum {
  eof_s = 256,
  parse_error_s,
  intlit_s,
  floatlit_s,
  id_s,
  dqstring_s,
  sqstring_s,
  charlit_s,
  eq_s,
  noteq_s,
  lesseq_s,
  greatereq_s,
  andand_s,
  oror_s,
  shl_s,
  shr_s,
  plusplus_s,
  minusminus_s,
  pluseq_s,
  minuseq_s,
  muleq_s,
  diveq_s,
  modeq_s,
  andeq_s,
  oreq_s,
  xoreq_s,
  arrow_s,
  eqarrow_s,
  shleq_s,
  CLEX_shreq,
  first_unused_token_s,
}

lexer :: struct {
  input_stream:       ^c.char,
  eof:                ^c.char,
  parse_point:        ^c.char,
  string_storage:     ^c.char,
  string_storage_len: c.int,
  where_firstchar:    ^c.char,
  where_lastchar:     ^c.char,
  token:              CLEX,
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

read_file :: proc(file: string) -> (res: []c.char, err: os.Error) {
  file, ferr := os.open(file)
  if ferr != nil {
    return make([]c.char, 0), ferr
  }
  defer os.close(file)

  buff_size, _ := os.file_size(file)
  buf := make([]c.char, buff_size)
  for {
    n, _ := os.read(file, buf)
    if n == 0 do break
  }

  return buf, nil
}

main :: proc() {

  if ODIN_OS != .Linux {
    assert(false, "not implemented for platforms that are not linux")
  }


  l: lexer
  lex_store: []c.char = make([]c.char, 100)

  buf, err := read_file("test.nn")
  if err != nil {
    fmt.eprintfln("got error {}", err)
  }

  init(&l, &buf[0], nil, &lex_store[0], auto_cast len(lex_store))
  get_token(&l)

  fmt.printfln("got: '{}'", strings.string_from_ptr(l.string, auto_cast l.string_len))
  
}
