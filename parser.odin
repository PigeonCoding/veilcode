package veilcode

import cm "./common"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import lx "thirdparty/lexer_odin"

store_list: [dynamic]cm.n_types

peek :: proc(l: lx.lexer) -> lx.token_id {
  b_l: lx.lexer
  b_l = l
  lx.get_token(&b_l)

  return b_l.token.type
}

is_char_lit :: proc(c: byte) -> bool {return c >= 0 && c <= 255}

get_pushed_shit :: proc(instrs: []cm.n_instrs, l: ^lx.lexer) -> cm.n_instrs {
  ins: cm.n_instrs

  #partial switch auto_cast l.token.type {

  case .ampersand:
    if p := peek(l^); p == .id {
      lx.get_token(l)
      ins.instr = .push
      ins.ptr = true
      yes := false
      // s := l.token.str

      for n in instrs {
        if n.name == l.token.str && n.instr == cm.n_instrs_enum.store {
          ins.instr = .load

          ins.name = l.token.str //  cm.clone_ptr_string(l.string, auto_cast l.string_len)
          ins.type_num = n.type_num
          yes = true


          if next := peek(l^); next == .open_bracket {
            lx.get_token(l)
            lx.get_token(l)
            lx.check_type(l, .intlit)
            ins.offset = auto_cast l.token.intlit

            lx.get_token(l)
            lx.check_type(l, .close_bracket)

          }
        }
      }

      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }

      if !yes {
        fmt.eprintln("1 get ur shit together wtf is", l.token.str)
        os.exit(1)
      }

    }

  case .id:
    ins.instr = .push

    yes := false
    s := l.token.str // cm.clone_ptr_string(l.string, auto_cast l.string_len)
    for n in instrs {
      if n.name == s && n.instr == cm.n_instrs_enum.store {
        ins.instr = .load
        ins.name = l.token.str // .clone_ptr_string(l.string, auto_cast l.string_len)
        ins.type_num = n.type_num
        yes = true
        {
          next := peek(l^)
          if next == .open_bracket {
            lx.get_token(l)
            lx.get_token(l)
            lx.check_type(l, .intlit)
            ins.offset = auto_cast l.token.intlit

            lx.get_token(l)
            lx.check_type(l, .close_bracket)
          }
          // if success && next == '[' {
          //   get_and_expect_and_assert(l, '[')
          //   get_and_expect_and_assert(l, auto_cast CLEX.intlit)
          //   ins.offset = auto_cast l.int_number
          //   get_and_expect_and_assert(l, ']')
          // }
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

    if p := peek(l^); p == .asterisk {
      ins.instr = .deref
      lx.get_token(l)
    }

  case .plus_sign:
    ins.instr = .add
    lx.get_token(l)
    if !l.token.charlit && l.token.type != .intlit && l.token.type != .id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    #partial switch auto_cast l.token.type {
    case .intlit:
      ins.val = auto_cast l.token.intlit
    case .id:
      yes := false
      s := l.token.str

      for n in instrs {
        if n.name == s {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = l.token.str //  cm.clone_ptr_string(l.string, auto_cast l.string_len)
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
      if l.token.charlit do ins.val = auto_cast l.token.type
      else {
        fmt.eprintln("wat is hapening", l.token)
      }
    }

  case .minus_sign:
    ins.instr = .sub
    lx.get_token(l)
    if !l.token.charlit && l.token.type != .intlit && l.token.type != .id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    #partial switch l.token.type {
    case .intlit:
      ins.val = auto_cast l.token.intlit
    case .id:
      yes := false
      for n in instrs {
        if n.name == l.token.str {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = l.token.str // .clone_ptr_string(l.string, auto_cast l.string_len)
          append(&ins.params, tmp2_ins)
          yes = true
        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("3 get ur shit together wtf is", l.token.str)
        os.exit(1)
      }

    case:
      if l.token.charlit do ins.val = auto_cast l.token.type
      else {
        fmt.eprintln("wat is hapening", l.token)
      }
    }

  case .asterisk:
    ins.instr = .mult
    lx.get_token(l)
    if !l.token.charlit && l.token.type != .intlit && l.token.type != .id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    #partial switch l.token.type {
    case .intlit:
      ins.val = auto_cast l.token.intlit
    case .id:
      yes := false
      // s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
      for n in instrs {
        if n.name == l.token.str {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = l.token.str //cm.clone_ptr_string(l.string, auto_cast l.string_len)
          append(&ins.params, tmp2_ins)
          yes = true
        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("4 get ur shit together wtf is", l.token.str)
        os.exit(1)
      }

    case:
      if l.token.charlit do ins.val = auto_cast l.token.type
      else {
        fmt.eprintln("wat is hapening", l.token)
      }

    }
  case .forward_slash:
    ins.instr = .div
    lx.get_token(l)
    if l.token.charlit && l.token.type != .intlit && l.token.type != .id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }
    #partial switch auto_cast l.token.type {
    case .intlit:
      ins.val = auto_cast l.token.intlit
    case .id:
      yes := false
      // s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
      for n in instrs {
        if n.name == l.token.str {
          tmp2_ins: cm.n_instrs
          tmp2_ins.instr = .load
          tmp2_ins.name = l.token.str //cm.clone_ptr_string(l.string, auto_cast l.string_len)
          append(&ins.params, tmp2_ins)
          yes = true
        }
      }
      if !yes {
        fmt.assertf(false, "function calling not implemented yet")
      }
      if !yes {
        fmt.eprintln("4 get ur shit together wtf is", l.token.str)
        os.exit(1)
      }

    case:
      if l.token.charlit do ins.val = auto_cast l.token.type
      else {
        fmt.eprintln("wat is hapening", l.token)
      }
    }

  case .open_parenthesis:
    ins.instr = .nothing
    lx.get_token(l)
    for l.token.type != .close_parenthesis {
      append(&ins.params, get_pushed_shit(instrs, l))
      lx.get_token(l)
      // fmt.println(ins)
      // os.exit(1)
    }
  case .eq:
    ins.instr = .eq

    lx.get_token(l)
    append(&ins.params, get_pushed_shit(instrs, l))

    fmt.println(ins)


  case .intlit:
    ins.instr = .push
    ins.val = l.token.intlit

  case:
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
    } else {
      fmt.eprintfln("%d:%d 1 wtf unexpected {}", l.row + 1, l.col + 1, l.token)
      os.exit(1)
    }

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

  return str.buf[:]
}

parse :: proc(file_path: []string) -> []cm.n_instrs {
  instrs: [dynamic]cm.n_instrs

  for file in file_path {
    lex: lx.lexer = lx.init_lexer(file)
    l := &lex
    lx.get_token(l)

    f: for l.token.type != .null_char {
      #partial switch auto_cast l.token.type {
      case .id:
        if l.token.str == "let" {
          ins: cm.n_instrs
          lx.get_token(l)
          if !lx.check_type(l, .id) do os.exit(1)

          ins.instr = .store
          ins.val = 1
          ins.type_num = 1
          ins.name = l.token.str
          // cm.clone_ptr_string(l.string, auto_cast l.string_len)

          // get_and_expect_and_assert(&l, ':')
          lx.get_token(l)
          if !lx.check_type(l, .colon) do os.exit(1)

          lx.get_token(l)

          if l.token.type == .open_bracket {
            lx.get_token(l)
            // maybe support variables here at some point
            if !lx.check_type(l, .intlit) do os.exit(1)

            // get_and_expect_and_assert(&l, auto_cast CLEX.intlit)
            ins.type_num = auto_cast l.token.intlit
            // get_and_expect_and_assert(&l, ']')
            lx.get_token(l)
            if !lx.check_type(l, .close_bracket) do os.exit(1)

            lx.get_token(l)
          }
          fmt.assertf(l.token.type == .id, "expected id but got {}", l.token) // TODO: new location printing
          ins.type = cm.string_to_type(l.token.str) // cm.string_to_type(strings.string_from_ptr(l.string, auto_cast l.string_len))

          lx.get_token(l)
          if l.token.type == .equals_sign {
            lx.get_token(l)
            for l.token.type != .semicolon {
              append(&ins.params, get_pushed_shit(instrs[:], l))
              lx.get_token(l)
            }
          }

          append(&instrs, ins)
          lx.get_token(l)

        } else if l.token.str == "syscall" {
          num := 0
          ins: cm.n_instrs
          ins.instr = .syscall
          lx.get_token(l)
          if !lx.check_type(l, .open_parenthesis) do os.exit(1)

          // get_and_expect_and_assert(&l, '(')
          lx.get_token(l)
          for l.token.type != .close_parenthesis {
            append(&ins.params, get_pushed_shit(instrs[:], l))
            lx.get_token(l)
            if l.token.type == .comma_char do lx.get_token(l)
          }

          lx.get_token(l)
          append(&instrs, ins)
          fmt.assertf(l.token.type == .semicolon, "expected ;")
          lx.get_token(l)

        } else if l.token.str == "if" {
          ins: cm.n_instrs
          ins.instr = .if_

          // get_and_expect_and_assert(&l, '(')
          lx.get_token(l)
          if !lx.check_type(l, .open_parenthesis) do os.exit(1)

          lx.get_token(l)
          for l.token.type != .close_parenthesis {
            append(&ins.params, get_pushed_shit(instrs[:], l))
            lx.get_token(l)
          }

          // get_and_expect_and_assert(&l, auto_cast CLEX.id)
          fmt.println(ins)

          // lx.get_token(&l)
          // switch l.token {
          // case auto_cast CLEX.eq:

          // }

          fmt.assertf(false, "if NOT implemented yet")


        } else {   // VAR ASSIGNMENT OTHER THAN DECLARING
          yes2 := false
          ins: cm.n_instrs
          for instr in instrs {
            if instr.name == l.token.str {
              ins.name = instr.name
              ins.instr = .assign
              ins.type = instr.type
              ins.type_num = instr.type_num
              yes2 = true
            }
          }
          lx.get_token(l)
          if l.token.type == .open_bracket {
            lx.get_token(l)
            if !lx.check_type(l, .intlit) do os.exit(1)

            // get_and_expect_and_assert(&l, auto_cast CLEX.intlit)
            ins.offset = auto_cast l.token.intlit
            lx.get_token(l)
            if !lx.check_type(l, .close_bracket) do os.exit(1)
            lx.get_token(l)


            if !lx.check_type(l, .equals_sign) do os.exit(1)
          }

          lx.get_token(l)

          if yes2 {
            for l.token.type != .semicolon {
              append(&ins.params, get_pushed_shit(instrs[:], l))
              lx.get_token(l)
            }
          }

          append(&instrs, ins)


          if ins.instr == .nun {
            fmt.println("didn't assign anything to a variable apearently", l.token.str)
            os.exit(1)

          }

          lx.get_token(l)

        }
      case .either_end_or_failure:
        break f

      case:
        fmt.println("???", l.token)
        os.exit(1)
      // if l.token > 255 do fmt.printfln("'{}'", cast(CLEX)l.token)
      // else do fmt.printfln("'%c'", l.token)
      }

    }

    lx.get_token(l)

  }

  return instrs[:]
}
