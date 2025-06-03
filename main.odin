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

n_instrs_enum :: enum {
  push,
  store,
  load,
  call,
  add,
  sub,
  mult,
  div,
}
n_instrs :: struct {
  instr:  n_instrs_enum,
  name:   string,
  val:    i64,
  params: [dynamic]n_instrs,
}
instrs: [dynamic]n_instrs

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
fn :: struct {
  name:        string,
  return_type: n_types,
  params:      [dynamic]fn_params,
  body:        [dynamic]n_instrs,
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
  strings.replace_all(string(buf), "';", "' ;")

  init(&l, &buf[0], nil, &lex_store[0], auto_cast len(lex_store))

  for get_token(&l) != 0 && l.token != 0 {
    switch auto_cast l.token {
    case CLEX.id:
      if strings.string_from_ptr(l.string, auto_cast l.string_len) == "let" {
        ins: n_instrs

        get_and_expect_and_assert(&l, auto_cast CLEX.id)

        ins.instr = .store
        ins.name = clone_ptr_string(l.string, auto_cast l.string_len)

        get_and_expect_and_assert(&l, '=')
        get_token(&l)

        {
          first_ins: n_instrs
          first_ins.instr = .push
          first_ins.val = 0
          append(&ins.params, first_ins)
        }

        for l.token != ';' {
          switch auto_cast l.token {
          case CLEX.intlit:
            tmp_ins: n_instrs
            tmp_ins.instr = .add
            tmp_ins.val = l.int_number
            append(&ins.params, tmp_ins)
          case CLEX.charlit:
            tmp_ins: n_instrs
            tmp_ins.instr = .add
            tmp_ins.val = l.token
            append(&ins.params, tmp_ins)
          case CLEX.id:
            tmp_ins: n_instrs
            tmp_ins.instr = .add

            yes := false
            s := clone_ptr_string(l.string, auto_cast l.string_len)
            for n in instrs {
              if n.name == s && n.instr == n_instrs_enum.store {
                tmp2_ins: n_instrs
                tmp2_ins.instr = .load
                tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                append(&tmp_ins.params, tmp2_ins)
                yes = true
              }
            }
            if !yes {
              for f in fns {
                if f.name == s {
                  get_and_expect_and_assert(&l, '(')
                  tmp2_ins: n_instrs
                  tmp2_ins.instr = .call
                  tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                  append(&tmp_ins.params, tmp2_ins)
                  yes = true
                }
              }
            }
            if !yes {
              fmt.eprintln("get ur shit together wtf is", s)
              os.exit(1)
            }
            append(&ins.params, tmp_ins)

          case '+':
            tmp_ins: n_instrs
            tmp_ins.instr = .add
            get_token(&l)
            if l.token != auto_cast CLEX.charlit &&
               l.token != auto_cast CLEX.intlit &&
               l.token != auto_cast CLEX.id {
              fmt.eprintln("didn't expect this token", l.token)
              os.exit(1)
            }
            switch auto_cast l.token {
            case CLEX.charlit:
              tmp_ins.val = l.token
            case CLEX.intlit:
              tmp_ins.val = l.int_number
            case CLEX.id:
              yes := false
              s := clone_ptr_string(l.string, auto_cast l.string_len)
              for n in instrs {
                if n.name == s {
                  tmp2_ins: n_instrs
                  tmp2_ins.instr = .load
                  tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                  append(&tmp_ins.params, tmp2_ins)
                  yes = true
                }
              }
              if !yes {
                for f in fns {
                  if f.name == s {
                    get_and_expect_and_assert(&l, '(')
                    tmp2_ins: n_instrs
                    tmp2_ins.instr = .call
                    tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                    append(&tmp_ins.params, tmp2_ins)
                    yes = true
                  }
                }
              }
              if !yes {
                fmt.eprintln("get ur shit together wtf is", s)
                os.exit(1)
              }

            case:
              fmt.eprintln("wat is hapening", l.token)
            }

            append(&ins.params, tmp_ins)
          case '-':
            tmp_ins: n_instrs
            tmp_ins.instr = .sub
            get_token(&l)
            if l.token != auto_cast CLEX.charlit &&
               l.token != auto_cast CLEX.intlit &&
               l.token != auto_cast CLEX.id {
              fmt.eprintln("didn't expect this token", l.token)
              os.exit(1)
            }
            switch auto_cast l.token {
            case CLEX.charlit:
              tmp_ins.val = l.token
            case CLEX.intlit:
              tmp_ins.val = l.int_number
            case CLEX.id:
              yes := false
              s := clone_ptr_string(l.string, auto_cast l.string_len)
              for n in instrs {
                if n.name == s {
                  tmp2_ins: n_instrs
                  tmp2_ins.instr = .load
                  tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                  append(&tmp_ins.params, tmp2_ins)
                  yes = true
                }
              }
              if !yes {
                for f in fns {
                  if f.name == s {
                    get_and_expect_and_assert(&l, '(')
                    tmp2_ins: n_instrs
                    tmp2_ins.instr = .call
                    tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                    append(&tmp_ins.params, tmp2_ins)
                    yes = true
                  }
                }
              }
              if !yes {
                fmt.eprintln("get ur shit together wtf is", s)
                os.exit(1)
              }

            case:
              fmt.eprintln("wat is hapening", l.token)
            }

            append(&ins.params, tmp_ins)
          case '*':
            tmp_ins: n_instrs
            tmp_ins.instr = .mult
            get_token(&l)
            if l.token != auto_cast CLEX.charlit &&
               l.token != auto_cast CLEX.intlit &&
               l.token != auto_cast CLEX.id {
              fmt.eprintln("didn't expect this token", l.token)
              os.exit(1)
            }
            switch auto_cast l.token {
            case CLEX.charlit:
              tmp_ins.val = l.token
            case CLEX.intlit:
              tmp_ins.val = l.int_number
            case CLEX.id:
              yes := false
              s := clone_ptr_string(l.string, auto_cast l.string_len)
              for n in instrs {
                if n.name == s {
                  tmp2_ins: n_instrs
                  tmp2_ins.instr = .load
                  tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                  append(&tmp_ins.params, tmp2_ins)
                  yes = true
                }
              }
              if !yes {
                for f in fns {
                  if f.name == s {
                    get_and_expect_and_assert(&l, '(')
                    tmp2_ins: n_instrs
                    tmp2_ins.instr = .call
                    tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                    append(&tmp_ins.params, tmp2_ins)
                    yes = true
                  }
                }
              }
              if !yes {
                fmt.eprintln("get ur shit together wtf is", s)
                os.exit(1)
              }

            case:
              fmt.eprintln("wat is hapening", l.token)
            }


            append(&ins.params, tmp_ins)
          case '/':
            tmp_ins: n_instrs
            tmp_ins.instr = .mult
            get_token(&l)
            if l.token != auto_cast CLEX.charlit &&
               l.token != auto_cast CLEX.intlit &&
               l.token != auto_cast CLEX.id {
              fmt.eprintln("didn't expect this token", l.token)
              os.exit(1)
            }
            switch auto_cast l.token {
            case CLEX.charlit:
              tmp_ins.val = l.token
            case CLEX.intlit:
              tmp_ins.val = l.int_number
            case CLEX.id:
              yes := false
              s := clone_ptr_string(l.string, auto_cast l.string_len)
              for n in instrs {
                if n.name == s {
                  tmp2_ins: n_instrs
                  tmp2_ins.instr = .load
                  tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                  append(&tmp_ins.params, tmp2_ins)
                  yes = true
                }
              }
              if !yes {
                for f in fns {
                  if f.name == s {
                    get_and_expect_and_assert(&l, '(')
                    tmp2_ins: n_instrs
                    tmp2_ins.instr = .call
                    tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                    append(&tmp_ins.params, tmp2_ins)
                    yes = true
                  }
                }
              }
              if !yes {
                fmt.eprintln("get ur shit together wtf is", s)
                os.exit(1)
              }

            case:
              fmt.eprintln("wat is hapening", l.token)
            }

            append(&ins.params, tmp_ins)

          case:
            fmt.eprintln("wtf unexpected {}", l.token)
            os.exit(1)
          }
          get_token(&l)
        }

        // fmt.println(ins)
        append(&instrs, ins)

      } else {
        fmt.println(strings.string_from_ptr(l.string, auto_cast l.string_len))
      }


    case:
      if l.token > 255 do fmt.printfln("'{}'", cast(CLEX)l.token)
      else do fmt.printfln("'%c'", l.token)
    }

  }

  fmt.println(instrs)

}
