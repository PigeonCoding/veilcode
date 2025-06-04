package naned

import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import cm "./common"

store_list: [dynamic]cm.n_types



// 

// cm.n_types :: enum {
//   n_not_a_type,
//   n_void,
//   n_int,
//   n_float,
//   n_string,
//   n_char,
//   n_bool,
// }

// fn_params :: struct {
//   name: string,
//   ptr:  bool,
//   type: cm.n_types,
// }
// fn :: struct {
//   name:        string,
//   return_type: cm.n_types,
//   params:      [dynamic]fn_params,
//   body:        [dynamic]cm.n_instrs,
// }

// var :: struct {
//   name: string,
// }

parse :: proc(file_path: []string) -> []cm.n_instrs {
  // fns: [dynamic]fn
  // defer delete(fns)
  instrs: [dynamic]cm.n_instrs
  
  for file in file_path {
    l: lexer
    lex_store: []c.char = make([]c.char, 100)

    buf, err := cm.read_file(file)
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
          // store_num += 1
          ins: cm.n_instrs

          get_and_expect_and_assert(&l, auto_cast CLEX.id)

          ins.instr = .store
          ins.val = 1
          ins.type_num = 1
          ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)


          get_and_expect_and_assert(&l, ':')
          get_token(&l)

          if l.token == '[' {
            get_and_expect_and_assert(&l, auto_cast CLEX.intlit)
            ins.type_num = auto_cast l.int_number
            get_and_expect_and_assert(&l, ']')
            get_token(&l)
          }
          fmt.assertf(l.token == auto_cast CLEX.id, "expected id but got {}", l.token)
          // get_and_expect(&l, auto_cast CLEX.id)
          ins.type = cm.string_to_type(strings.string_from_ptr(l.string, auto_cast l.string_len))

          // if !get_and_expect(&l, '=') && ins.type_num == 0 {
          //   fmt.eprintfln("expected")
          // }

          get_token(&l)
          if l.token == '=' {
            get_token(&l)

            for l.token != ';' {
              switch auto_cast l.token {
              case CLEX.intlit, CLEX.charlit:

                tmp_ins: cm.n_instrs
                tmp_ins.instr = .push
                tmp_ins.val = l.int_number
                append(&ins.params, tmp_ins)
              case CLEX.id:
                tmp_ins: cm.n_instrs
                // tmp_ins.instr = .push

                yes := false
                s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                for n in instrs {
                  if n.name == s && n.instr == cm.n_instrs_enum.store {
                    // tmp2_ins: cm.n_instrs
                    tmp_ins.instr = .load
                    tmp_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    // append(&tmp_ins.params, tmp2_ins)
                    yes = true
                  }
                }
                if !yes {
                  // for f in fns {
                  //   if f.name == s {
                  //     get_and_expect_and_assert(&l, '(')
                  //     fmt.assertf(false, "not implemented function calling")
                  //     // tmp2_ins: cm.n_instrs
                  //     // tmp2_ins.instr = .call
                  //     // tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  //     // append(&tmp_ins.params, tmp2_ins)
                  //     // yes = true
                  //   }
                  // }
                }
                if !yes {
                  fmt.eprintln("1 get ur shit together wtf is", s)
                  os.exit(1)
                }
                append(&ins.params, tmp_ins)

              case '+':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("2 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }

                append(&ins.params, tmp_ins)
              case '-':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("3 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }

                append(&ins.params, tmp_ins)
              case '*':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("4 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }


                append(&ins.params, tmp_ins)
              case '/':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("5 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }

                append(&ins.params, tmp_ins)

              case:
                loc: lex_location
                get_location(&l, l.where_firstchar, &loc)
                if l.token < 256 {
                  fmt.eprintfln(
                    "%d:%d wtf unexpected %c",
                    loc.line_number,
                    loc.line_offset + 1,
                    l.token,
                  )
                } else {
                  fmt.eprintfln(
                    "%d:%d wtf unexpected %d",
                    loc.line_number,
                    loc.line_offset + 1,
                    l.token,
                  )
                }
                os.exit(1)
              }
              get_token(&l)
            }
          }

          append(&instrs, ins)

        } else if strings.string_from_ptr(l.string, auto_cast l.string_len) == "syscall" {
          num := 0
          ins: cm.n_instrs
          ins.instr = .syscall
          get_and_expect_and_assert(&l, '(')
          get_token(&l)
          for l.token != ')' {
            tmp_ins: cm.n_instrs
            tmp_ins.type_num = 1
            switch auto_cast l.token {
            case CLEX.intlit, CLEX.charlit:
              tmp_ins.instr = .push
              tmp_ins.val = l.int_number
            case CLEX.id:
              yes := false
              s := strings.string_from_ptr(l.string, auto_cast l.string_len)

              for n in instrs {
                if n.name == s && n.instr == .store {
                  tmp_ins.instr = .load
                  tmp_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  tmp_ins.type_num = n.type_num
                  if n.type_num > 1 {
                    get_and_expect_and_assert(&l, '[')
                    get_and_expect_and_assert(&l, auto_cast CLEX.intlit)
                    tmp_ins.offset = auto_cast l.int_number
                    get_and_expect_and_assert(&l, ']')
                  }
                  yes = true
                }
              }

              if !yes {
                // for f in fns {
                //   if f.name == s {
                //     get_and_expect_and_assert(&l, '(')
                //     fmt.assertf(false, "not implemented function calls")
                //   }
                // }
              }

              if !yes {
                fmt.eprintln("6 get ur shit together wtf is", s)
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

          append(&instrs, ins)

          get_and_expect_and_assert(&l, ';')
        } else {   // VAR ASSIGNMENT OTHER THAN DECLARING
          s := strings.string_from_ptr(l.string, auto_cast l.string_len)
          yes2 := false
          ins: cm.n_instrs
          for instr in instrs {
            if instr.name == s {
              ins.name = instr.name
              ins.instr = .assign
              ins.type = instr.type
              ins.type_num = instr.type_num
              yes2 = true
            }
          }
          if !get_and_expect(&l, '=') && l.token == '[' {
            get_and_expect_and_assert(&l, auto_cast CLEX.intlit)
            ins.offset = auto_cast l.int_number
            get_and_expect_and_assert(&l, ']')
            get_and_expect_and_assert(&l, '=')
          }

          get_token(&l)

          if yes2 {
            for l.token != ';' {
              switch auto_cast l.token {
              case CLEX.intlit, CLEX.charlit:
                tmp_ins: cm.n_instrs
                tmp_ins.instr = .push
                tmp_ins.val = l.int_number
                append(&ins.params, tmp_ins)
              case CLEX.id:
                tmp_ins: cm.n_instrs
                // tmp_ins.instr = .push

                yes := false
                s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                for n in instrs {
                  if n.name == s && n.instr == cm.n_instrs_enum.store {
                    // tmp2_ins: cm.n_instrs
                    tmp_ins.instr = .load
                    tmp_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    // append(&tmp_ins.params, tmp2_ins)
                    yes = true
                  }
                }
                if !yes {
                  // for f in fns {
                  //   if f.name == s {
                  //     get_and_expect_and_assert(&l, '(')
                  //     fmt.assertf(false, "not implemented function calling")
                  //     // tmp2_ins: cm.n_instrs
                  //     // tmp2_ins.instr = .call
                  //     // tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  //     // append(&tmp_ins.params, tmp2_ins)
                  //     // yes = true
                  //   }
                  // }
                }
                if !yes {
                  fmt.eprintln("7 get ur shit together wtf is", s)
                  os.exit(1)
                }
                append(&ins.params, tmp_ins)

              case '+':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("8 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }

                append(&ins.params, tmp_ins)
              case '-':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("9 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }

                append(&ins.params, tmp_ins)
              case '*':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("10 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }


                append(&ins.params, tmp_ins)
              case '/':
                tmp_ins: cm.n_instrs
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
                  s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
                  for n in instrs {
                    if n.name == s {
                      tmp2_ins: cm.n_instrs
                      tmp2_ins.instr = .load
                      tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                      append(&tmp_ins.params, tmp2_ins)
                      yes = true
                    }
                  }
                  if !yes {
                    // for f in fns {
                    //   if f.name == s {
                    //     get_and_expect_and_assert(&l, '(')
                    //     tmp2_ins: cm.n_instrs
                    //     tmp2_ins.instr = .call
                    //     tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
                    //     append(&tmp_ins.params, tmp2_ins)
                    //     yes = true
                    //   }
                    // }
                  }
                  if !yes {
                    fmt.eprintln("11 get ur shit together wtf is", s)
                    os.exit(1)
                  }

                case:
                  fmt.eprintln("wat is hapening", l.token)
                }

                append(&ins.params, tmp_ins)

              case:
                loc: lex_location
                get_location(&l, l.where_firstchar, &loc)
                if l.token < 256 {
                  fmt.eprintfln(
                    "%d:%d wtf unexpected %c",
                    loc.line_number,
                    loc.line_offset + 1,
                    l.token,
                  )
                } else {
                  fmt.eprintfln(
                    "%d:%d wtf unexpected %d",
                    loc.line_number,
                    loc.line_offset + 1,
                    l.token,
                  )
                }
                os.exit(1)
              }
              get_token(&l)
            }
          }

          append(&instrs, ins)


          if ins.instr == .nun {
            fmt.println(
              "didn't assign anything to a variable apearently",
              strings.string_from_ptr(l.string, auto_cast l.string_len),
            )
            os.exit(1)

          }

        }


      case:
        if l.token > 255 do fmt.printfln("'{}'", cast(CLEX)l.token)
        else do fmt.printfln("'%c'", l.token)
      }

    }

  }

  return instrs[:]
}
