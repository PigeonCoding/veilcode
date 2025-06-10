package veilcode

import cm "./common"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

store_list: [dynamic]cm.n_types

peek :: proc(l: lexer) -> (c.long, bool) {
  b_l: lexer
  b_l = l
  v := get_token(&b_l)

  return b_l.token, v != 0
}


get_pushed_shit :: proc(instrs: []cm.n_instrs, l: ^lexer) -> cm.n_instrs {
  ins: cm.n_instrs

  switch auto_cast l.token {
  case CLEX.intlit, CLEX.charlit:
    ins.instr = .push
    ins.val = auto_cast l.int_number
  case '&':
    if p, success := peek(l^); p == auto_cast CLEX.id && success {
      get_token(l)
      ins.instr = .push
      ins.ptr = true
      yes := false
      s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
      for n in instrs {
        if n.name == s && n.instr == cm.n_instrs_enum.store {
          ins.instr = .load
          ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
          ins.type_num = n.type_num
          yes = true
          {
            next, success := peek(l^)
            if success && next == '[' {
              get_and_expect_and_assert(l, '[')
              get_and_expect_and_assert(l, auto_cast CLEX.intlit)
              ins.offset = auto_cast l.int_number
              get_and_expect_and_assert(l, ']')
            }
          }
        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("1 get ur shit together wtf is", s)
        os.exit(1)
      }

    }
  case CLEX.id:
    ins.instr = .push

    yes := false
    s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
    for n in instrs {
      if n.name == s && n.instr == cm.n_instrs_enum.store {
        ins.instr = .load
        ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
        ins.type_num = n.type_num
        yes = true
        {
          next, success := peek(l^)
          if success && next == '[' {
            get_and_expect_and_assert(l, '[')
            get_and_expect_and_assert(l, auto_cast CLEX.intlit)
            ins.offset = auto_cast l.int_number
            get_and_expect_and_assert(l, ']')
          }
        }
      }
    }
    if !yes {
      fmt.assertf(false, "function calling not implemented yet or unknown var")
    }
    if !yes {
      fmt.eprintln("1 get ur shit together wtf is", s)
      os.exit(1)
    }

    if p, success := peek(l^); p == '*' && success {
      ins.instr = .deref
      get_token(l)
    }

  case '+':
    ins.instr = .add
    get_token(l)
    if l.token != auto_cast CLEX.charlit &&
       l.token != auto_cast CLEX.intlit &&
       l.token != auto_cast CLEX.id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    switch auto_cast l.token {
    case CLEX.intlit, CLEX.charlit:
      ins.val = auto_cast l.int_number
    case CLEX.id:
      yes := false
      s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
      for n in instrs {
        if n.name == s {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
          append(&ins.params, tmp2_ins)
          yes = true
        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("2 get ur shit together wtf is", s)
        os.exit(1)
      }

    case:
      fmt.eprintln("wat is hapening", l.token)
    }

  case '-':
    ins.instr = .sub
    get_token(l)
    if l.token != auto_cast CLEX.charlit &&
       l.token != auto_cast CLEX.intlit &&
       l.token != auto_cast CLEX.id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    switch auto_cast l.token {
    case CLEX.intlit, CLEX.charlit:
      ins.val = auto_cast l.int_number
    case CLEX.id:
      yes := false
      s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
      for n in instrs {
        if n.name == s {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
          append(&ins.params, tmp2_ins)
          yes = true
        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("3 get ur shit together wtf is", s)
        os.exit(1)
      }

    case:
      fmt.eprintln("wat is hapening", l.token)
    }

  case '*':
    ins.instr = .mult
    get_token(l)
    if l.token != auto_cast CLEX.charlit &&
       l.token != auto_cast CLEX.intlit &&
       l.token != auto_cast CLEX.id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    switch auto_cast l.token {
    case CLEX.intlit, CLEX.charlit:
      ins.val = auto_cast l.int_number
    case CLEX.id:
      yes := false
      s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
      for n in instrs {
        if n.name == s {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
          append(&ins.params, tmp2_ins)
          yes = true
        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("4 get ur shit together wtf is", s)
        os.exit(1)
      }

    case:
      fmt.eprintln("wat is hapening", l.token)
    }
  case '/':
    ins.instr = .div
    get_token(l)
    if l.token != auto_cast CLEX.charlit &&
       l.token != auto_cast CLEX.intlit &&
       l.token != auto_cast CLEX.id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    switch auto_cast l.token {
    case CLEX.intlit, CLEX.charlit:
      ins.val = auto_cast l.int_number
    case CLEX.id:
      yes := false
      s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
      for n in instrs {
        if n.name == s {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = cm.clone_ptr_string(l.string, auto_cast l.string_len)
          append(&ins.params, tmp2_ins)
          yes = true


        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("5 get ur shit together wtf is", s)
        os.exit(1)
      }

    case:
      fmt.eprintln("wat is hapening", l.token)
    }

  case '(':
    ins.instr = .nothing
    get_token(l)
    for l.token != ')' {
      append(&ins.params, get_pushed_shit(instrs, l))
      get_token(l)
      // fmt.println(ins)
      // os.exit(1)
    }

  case:
    loc: lex_location
    get_location(l, l.where_firstchar, &loc)

    if l.token < 256 {
      fmt.eprintfln("%d:%d 1 wtf unexpected %c", loc.line_number, loc.line_offset + 1, l.token)
    } else {
      fmt.eprintfln("%d:%d 1 wtf unexpected %d", loc.line_number, loc.line_offset + 1, l.token)
    }
    os.exit(1)
  }


  return ins
}

stb_c_lexer_charlit_workaround :: proc(buf: []byte) -> []byte {
  str: strings.Builder

  for b, u in buf {
    append(&str.buf, b)
    if b == '\'' && (buf[u + 1] == ';' || buf[u + 1] == ')') {
      append(&str.buf, ' ')
    }
  }
  // fmt.println(string(str.buf[:]))

  return str.buf[:]
}

parse :: proc(file_path: []string) -> []cm.n_instrs {
  // fns: [dynamic]fn
  // defer delete(fns)
  instrs: [dynamic]cm.n_instrs

  for file in file_path {
    l: lexer
    lex_store: []c.char = make([]c.char, 200)

    buf, err := cm.read_file(file)
    if err != nil {
      fmt.eprintfln("got error {}", err)
    }
    // TODO: maybe fix stb_c_lexer to not have that problem?


    patched_buf := stb_c_lexer_charlit_workaround(buf)

    init(&l, &patched_buf[0], nil, &lex_store[0], auto_cast len(lex_store))


    for get_token(&l) != 0 && l.token != 0 {
      switch auto_cast l.token {
      case CLEX.id:
        if strings.string_from_ptr(l.string, auto_cast l.string_len) == "let" {
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
          ins.type = cm.string_to_type(strings.string_from_ptr(l.string, auto_cast l.string_len))

          get_token(&l)
          if l.token == '=' {
            get_token(&l)
            for l.token != ';' {
              append(&ins.params, get_pushed_shit(instrs[:], &l))
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
            append(&ins.params, get_pushed_shit(instrs[:], &l))
            get_token(&l)
            if l.token == ',' do get_token(&l)
          }

          get_token(&l)
          append(&instrs, ins)


          fmt.assertf(l.token == ';', "expected ;")
        } else if strings.string_from_ptr(l.string, auto_cast l.string_len) == "if" {
          fmt.assertf(false, "if NOT implemented yet")
          get_and_expect_and_assert(&l, '(')


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
              append(&ins.params, get_pushed_shit(instrs[:], &l))
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
