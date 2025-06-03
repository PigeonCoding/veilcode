package naned

import "core:c"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

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

n_types :: enum {
  n_not_a_type,
  n_void,
  n_int,
  n_float,
  n_string,
  n_char,
  n_bool,
}

fn_params :: struct {
  name: string,
  ptr:  bool,
  type: n_types,
}

fn_call :: struct {
  name:   string,
  params: [dynamic]fn_params,
}

fn :: struct {
  name:        string,
  return_type: n_types,
  params:      [dynamic]fn_params,
}
fns: [dynamic]fn

var :: struct {
  name: string,

}

clone_ptr_string :: proc(ptr: ^c.char, sz: int) -> string {
  n := strings.string_from_ptr(auto_cast ptr, sz)
  buf := make([]c.char, len(n))
  mem.copy(&buf[0], ptr, len(n))

  return string(buf)
}

fn_is_unique :: proc(f: ^fn) -> bool {
  for &func in fns {
    if f.name == func.name &&
       f.return_type == func.return_type &&
       len(f.params) == len(func.params) {
      yes := true
      for i in 0 ..< len(f.params) {
        if f.params[i] != func.params[i] do yes = false
      }
      if yes do return false
    }
  }
  return true
}

string_to_type :: proc(s: string) -> (type: n_types, err: bool) {
  switch s {
  case "int":
    return .n_int, false
  case "char":
    return .n_char, false
  case "string":
    return .n_string, false
  case "bool":
    return .n_bool, false
  case "float":
    return .n_float, false
  case "void":
    return .n_void, false
  case:
    return .n_not_a_type, true
  }
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
  // TODO: maybe fix stb_c_lexer to not have that problem?
  strings.replace_all(string(buf), "')", "' )")

  init(&l, &buf[0], nil, &lex_store[0], auto_cast len(lex_store))

  for get_token(&l) != 0 && l.token != 0 {
    switch auto_cast l.token {
    // case 1 ..= 255:
    //   fmt.printfln("got char : '%c'", l.token)

    case CLEX.id:
      if clone_ptr_string(l.string, auto_cast l.string_len) == "let" {

      }


    //   if strings.string_from_ptr(l.string, auto_cast l.string_len) == "fn" {
    //     fn_tmp: fn
    //     get_and_expect_and_assert(&l, auto_cast CLEX.id)
    //     fn_tmp.name = clone_ptr_string(l.string, auto_cast l.string_len)
    //     get_and_expect_and_assert(&l, '(')
    //     get_token(&l)

    //     for {
    //       v: fn_params
    //       switch l.token {
    //       case 1 ..= 255:
    //         t := make([]u8, 1)
    //         t[0] = auto_cast l.token
    //         v.name = string(t)
    //       case auto_cast CLEX.id:
    //         v.name = clone_ptr_string(l.string, auto_cast l.string_len)
    //       case:
    //         fmt.printfln("nuh nuh {}", l.token)
    //         os.exit(1)
    //       }

    //       get_and_expect_and_assert(&l, ':')
    //       get_token(&l)
    //       if l.token == '*' {
    //         v.ptr = true
    //         get_and_expect_and_assert(&l, auto_cast CLEX.id)
    //       } else {
    //         v.ptr = false
    //       }

    //       {
    //         e: bool
    //         v.type, e = string_to_type(strings.string_from_ptr(l.string, auto_cast l.string_len))
    //         if e {
    //           fmt.eprintfln(
    //             "type unknown {}",
    //             string_to_type(strings.string_from_ptr(l.string, auto_cast l.string_len)),
    //           )
    //           os.exit(1)
    //         }
    //       }

    //       append(&fn_tmp.params, v)
    //       get_token(&l)
    //       if l.token == ')' do break
    //       if l.token != ',' {
    //         fmt.println("huh", l.token)
    //         os.exit(1)
    //       }
    //       get_token(&l)

    //     }

    //     get_and_expect_and_assert(&l, ':')
    //     get_and_expect_and_assert(&l, auto_cast CLEX.id)
    //     {
    //       e: bool
    //       fn_tmp.return_type, e = string_to_type(
    //         strings.string_from_ptr(l.string, auto_cast l.string_len),
    //       )
    //     }

    //     if fn_is_unique(&fn_tmp) do append(&fns, fn_tmp)
    //     fmt.println(fn_tmp)

    //   }

    case:
      if l.token > 255 do fmt.printfln("'{}'", cast(CLEX)l.token)
      else do fmt.printfln("'%c'", l.token)
    // fmt.printfln("'%c'", l.token)
    }

  }

  fmt.println(fns)


}
