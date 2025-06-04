package naned

import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

n_instrs_enum :: enum {
  nun,
  compiler_stuff,
  push,
  store,
  load,
  call,
  syscall,
  add,
  sub,
  mult,
  div,
}

// TODO: support floats
n_instrs :: struct {
  instr:  n_instrs_enum,
  name:   string,
  val:    i64,
  flt:    f64,
  params: [dynamic]n_instrs,
}
// 

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

var :: struct {
  name: string,
}

parse :: proc(file_path: []string) -> ([]n_instrs, int) {
  fns: [dynamic]fn
  defer delete(fns)
  instrs: [dynamic]n_instrs
  store_num := 0

  for file in file_path {
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
          store_num += 1
          ins: n_instrs

          get_and_expect_and_assert(&l, auto_cast CLEX.id)

          ins.instr = .store
          ins.val = auto_cast store_num
          ins.name = clone_ptr_string(l.string, auto_cast l.string_len)

          get_and_expect_and_assert(&l, '=')
          get_token(&l)

          // {
          //   first_ins: n_instrs
          //   first_ins.instr = .push
          //   first_ins.val = 0
          //   append(&ins.params, first_ins)
          // }

          for l.token != ';' {
            switch auto_cast l.token {
            case CLEX.intlit, CLEX.charlit:
              tmp_ins: n_instrs
              tmp_ins.instr = .push
              tmp_ins.val = l.int_number
              append(&ins.params, tmp_ins)
            case CLEX.id:
              tmp_ins: n_instrs
              // tmp_ins.instr = .push

              yes := false
              s := clone_ptr_string(l.string, auto_cast l.string_len)
              for n in instrs {
                if n.name == s && n.instr == n_instrs_enum.store {
                  // tmp2_ins: n_instrs
                  tmp_ins.instr = .load
                  tmp_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                  // append(&tmp_ins.params, tmp2_ins)
                  yes = true
                }
              }
              if !yes {
                for f in fns {
                  if f.name == s {
                    get_and_expect_and_assert(&l, '(')
                    fmt.assertf(false, "not implemented function calling")
                    // tmp2_ins: n_instrs
                    // tmp2_ins.instr = .call
                    // tmp2_ins.name = clone_ptr_string(l.string, auto_cast l.string_len)
                    // append(&tmp_ins.params, tmp2_ins)
                    // yes = true
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
              case CLEX.intlit, CLEX.charlit:
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
              case CLEX.intlit, CLEX.charlit:
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
              case CLEX.intlit, CLEX.charlit:
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
              tmp_ins.instr = .div
              get_token(&l)
              if l.token != auto_cast CLEX.charlit &&
                 l.token != auto_cast CLEX.intlit &&
                 l.token != auto_cast CLEX.id {
                fmt.eprintln("didn't expect this token", l.token)
                os.exit(1)
              }
              switch auto_cast l.token {
              case CLEX.intlit, CLEX.charlit:
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

          append(&instrs, ins)

        } else if strings.string_from_ptr(l.string, auto_cast l.string_len) == "syscall" {
          num := 0
          ins: n_instrs
          ins.instr = .syscall
          get_and_expect_and_assert(&l, '(')
          get_token(&l)
          for l.token != ')' {
            tmp_ins: n_instrs
            switch auto_cast l.token {
            case CLEX.intlit, CLEX.charlit:
              tmp_ins.instr = .push
              tmp_ins.val = l.int_number
            case CLEX.id:
              yes := false
              s := clone_ptr_string(l.string, auto_cast l.string_len)

              for n in instrs {
                if n.name == s {
                  tmp_ins.instr = .load
                  tmp_ins.name = s
                  // append(&tmp_ins.params, tmp_ins) 
                  yes = true
                }
              }


              if !yes {
                for f in fns {
                  if f.name == s {
                    get_and_expect_and_assert(&l, '(')
                    fmt.assertf(false, "not implemented function calls")
                  }
                }
              }

              if !yes {
                fmt.eprintln("get ur shit together wtf is", s)
                os.exit(1)
              }

            // append(&ins.params, tmp_ins)

            case:
              fmt.eprintln("wat is hapening here", l.token)
              os.exit(1)
            }
            get_token(&l)
            if l.token == ',' do get_token(&l)
            append(&ins.params, tmp_ins)
          }
          // {
          //   tmp_instr: n_instrs
          //   tmp_instr.instr = .compiler_stuff
          //   tmp_instr.val = auto_cast len(ins.params)
          //   append(&ins.params, tmp_instr)
          // }
          append(&instrs, ins)

        } else {
          fmt.println(strings.string_from_ptr(l.string, auto_cast l.string_len))
        }


      case:
        if l.token > 255 do fmt.printfln("'{}'", cast(CLEX)l.token)
        else do fmt.printfln("'%c'", l.token)
      }

    }

  }

  return instrs[:], store_num
}
