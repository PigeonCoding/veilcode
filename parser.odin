package veilcode

import cm "./common"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import lx "thirdparty/lexer_odin"

@(private)
label_stack: [dynamic]int
@(private)
label_counter := 0

peek :: proc(l: lx.lexer) -> lx.token_id {
  b_l: lx.lexer
  b_l = l
  lx.get_token(&b_l)

  return b_l.token.type
}

is_char_lit :: proc(c: byte) -> bool {return c >= 0 && c <= 255}

@(private)
instrs_og: [dynamic]cm.n_instrs

parse :: proc(files: []string) -> []cm.n_instrs {
  for file in files {
    l: lx.lexer = lx.init_lexer(file)
    lx.get_token(&l)

    for l.token.type != .null_char && l.token.type != .either_end_or_failure {
      if l.token.type == .open_brace {
        ins: cm.n_instrs
        ins.instr = .block
        parse_shit(&l, &ins.params)
        append(&instrs_og, ins)
      } else {
        parse_shit(&l, &instrs_og)
      }
    }
  }


  return instrs_og[:]
}

var_exists :: proc(name: string) -> Maybe(cm.n_instrs) {
  for i in instrs_og {
    if (i.instr == .store || i.instr == .create) && i.name == name do return i
  }

  return nil
}

fn_exists :: proc(name: string) -> Maybe(cm.n_instrs) {
  for i in instrs_og {
    if i.instr == .extrn && i.name == name do return i
  }
  // TODO: check for fns once implemented
  return nil
}

parse_shit :: proc(l: ^lx.lexer, instrs: ^[dynamic]cm.n_instrs) {
  ins: cm.n_instrs
  #partial switch auto_cast l.token.type {
  case .intlit:
    ins.instr = .push
    ins.val = auto_cast l.token.intlit

  case .plus_sign:
    ins.instr = .add
    lx.get_token(l)
    if !l.token.charlit && l.token.type != .intlit && l.token.type != .id {
      fmt.eprintln("didn't expect this token", l.token)
      os.exit(1)
    }

    parse_shit(l, instrs)
    append(instrs, ins)
    return

  case .id:
    switch l.token.str {
    case "let":
      lx.get_token(l)
      if !lx.check_type(l, .id) do os.exit(1)

      // can't use the word test appearently with fasm
      switch l.token.str {
      case "test":
        l.token.str = "test____this_should_be_fixed_maybe"
      }

      ins.instr = .store

      ins.val = 1
      ins.type_num = 1
      ins.name = l.token.str


      lx.get_token(l)
      if !lx.check_type(l, .colon) do os.exit(1)

      lx.get_token(l)

      if l.token.type == .open_bracket {
        lx.get_token(l)
        // maybe support variables here at some point
        if !lx.check_type(l, .intlit) do os.exit(1)

        ins.type_num = auto_cast l.token.intlit
        lx.get_token(l)
        if !lx.check_type(l, .close_bracket) do os.exit(1)

        lx.get_token(l)
      }
      if !lx.check_type(l, .id) do os.exit(1)
      ins.type = cm.string_to_type(l.token.str)

      lx.get_token(l)
      if l.token.type == .equals_sign {
        lx.get_token(l)
        for l.token.type != .semicolon &&
            l.token.type != .null_char &&
            l.token.type != .either_end_or_failure {
          parse_shit(l, instrs)
        }
      } else {
        ins.instr = .create
      }

    case "extrn":
      ins.instr = .extrn

      lx.get_token(l)
      if !lx.check_type(l, .id) do os.exit(1)
      ins.name = l.token.str
      if p := peek(l^); p != .either_end_or_failure && p == .dqstring {
        lx.get_token(l)
        ins.optional = l.token.str
      }

    case:
      if var, f := var_exists(l.token.str).?; f {
        ins.name = var.name
        ins.instr = .assign
        ins.type = var.type
        ins.type_num = var.type_num

        lx.get_token(l)
        if l.token.type == .open_bracket {
          lx.get_token(l)
          // TODO: support variables maybe when dynamic allocs are made
          if l.token.type == .intlit {
            ins.offset = auto_cast l.token.intlit
            lx.get_token(l)
            if l.token.type != .close_bracket do os.exit(1)
            lx.get_token(l)

          }
        }

        if l.token.type != .equals_sign {
          ins.instr = .load
        } else {
          lx.get_token(l)

          for l.token.type != .semicolon &&
              l.token.type != .null_char &&
              l.token.type != .either_end_or_failure {
            parse_shit(l, instrs)
          }
        }


      } else if fn, p := fn_exists(l.token.str).?; p {

        ins.instr = .call
        ins.name = fn.name
        lx.get_token(l)
        if !lx.check_type(l, .open_parenthesis) do os.exit(1)
        lx.get_token(l)
        for l.token.type != .close_parenthesis &&
            l.token.type != .semicolon &&
            l.token.type != .null_char &&
            l.token.type != .either_end_or_failure {
          parse_shit(l, &ins.params)
          if l.token.type == .comma_char do lx.get_token(l)
          // fmt.println(l.token)
        }


      } else {
        // fmt.println(instrs)
        fmt.eprintfln("%s:%d:%d unknown id '%s'", l.file, l.row + 1, l.col, l.token.str)
        os.exit(1)

      }


    }

  case .ampersand:
    lx.get_token(l)
    parse_shit(l, instrs)
    instrs[len(instrs) - 1].ptr = true
    // fmt.println(instrs[len(instrs) - 1])
    return

  case .semicolon:
    lx.get_token(l)
    parse_shit(l, instrs)

  // case .either_end_or_failure:
  //   return

  case:
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
    } else {
      // unknown token encountered
      fmt.eprintfln("%s:%d:%d unknown {}", l.file, l.row + 1, l.col, l.token)
      os.exit(1)
    }

  }

  // fmt.println(l.token)
  append(instrs, ins)
  lx.get_token(l)
}

// get_pushed_shit :: proc(instrs: []cm.n_instrs, l: ^lx.lexer) -> cm.n_instrs {
//   ins: cm.n_instrs

//   #partial switch auto_cast l.token.type {

//   case .ampersand:
//     if p := peek(l^); p == .id {
//       lx.get_token(l)
//       ins.instr = .push
//       ins.ptr = true
//       yes := false
//       // s := l.token.str

//       for n in instrs {
//         if n.name == l.token.str && n.instr == cm.n_instrs_enum.store {
//           ins.instr = .load

//           ins.name = l.token.str //
//           ins.type_num = n.type_num
//           yes = true


//           if next := peek(l^); next == .open_bracket {
//             lx.get_token(l)
//             lx.get_token(l)
//             lx.check_type(l, .intlit)
//             ins.offset = auto_cast l.token.intlit

//             lx.get_token(l)
//             lx.check_type(l, .close_bracket)

//           }
//         }
//       }

//       if !yes {
//         fmt.assertf(false, "function calling not implemented yet")
//       }

//       if !yes {
//         fmt.eprintln("1 get ur shit together wtf is", l.token.str)
//         os.exit(1)
//       }

//     }

//   case .id:
//     ins.instr = .push

//     yes := false
//     for n in instrs {
//       if n.name == l.token.str && n.instr == cm.n_instrs_enum.store {
//         ins.instr = .load
//         ins.name = l.token.str
//         ins.type_num = n.type_num
//         yes = true
//         if next := peek(l^); next == .open_bracket {
//           lx.get_token(l)
//           lx.get_token(l)
//           lx.check_type(l, .intlit)
//           ins.offset = auto_cast l.token.intlit

//           lx.get_token(l)
//           lx.check_type(l, .close_bracket)
//         }
//         if yes do break
//       }
//     }

//     if !yes {
//       fmt.assertf(false, "xx function calling not implemented yet or unknown var {}", l.token)
//     }
//     if !yes {
//       fmt.eprintln("1 get ur shit together wtf is", l.token)
//       os.exit(1)
//     }

//     if p := peek(l^); p == .asterisk {
//       ins.instr = .deref
//       lx.get_token(l)
//     }

//   case .plus_sign:
//     ins.instr = .add
//     lx.get_token(l)
//     if !l.token.charlit && l.token.type != .intlit && l.token.type != .id {
//       fmt.eprintln("didn't expect this token", l.token)
//       os.exit(1)
//     }
//     #partial switch auto_cast l.token.type {
//     case .intlit:
//       ins.val = auto_cast l.token.intlit
//     case .id:
//       yes := false
//       s := l.token.str

//       for n in instrs {
//         if n.name == s {
//           tmp2_ins: cm.n_instrs
//           tmp2_ins.instr = .load
//           tmp2_ins.name = l.token.str //  cm.clone_ptr_string(l.string, auto_cast l.string_len)
//           append(&ins.params, tmp2_ins)
//           yes = true
//         }
//       }
//       if !yes {
//         fmt.assertf(false, "function calling not implemented yet")
//       }
//       if !yes {
//         fmt.eprintln("2 get ur shit together wtf is", s)
//         os.exit(1)
//       }

//     case:
//       if l.token.charlit do ins.val = auto_cast l.token.type
//       else {
//         fmt.eprintln("wat is hapening", l.token)
//       }
//     }

//   case .minus_sign:
//     ins.instr = .sub
//     lx.get_token(l)
//     if !l.token.charlit && l.token.type != .intlit && l.token.type != .id {
//       fmt.eprintln("didn't expect this token", l.token)
//       os.exit(1)
//     }
//     #partial switch l.token.type {
//     case .intlit:
//       ins.val = auto_cast l.token.intlit
//     case .id:
//       yes := false
//       for n in instrs {
//         if n.name == l.token.str {
//           tmp2_ins: cm.n_instrs
//           tmp2_ins.instr = .load
//           tmp2_ins.name = l.token.str // .clone_ptr_string(l.string, auto_cast l.string_len)
//           append(&ins.params, tmp2_ins)
//           yes = true
//         }
//       }
//       if !yes {
//         fmt.assertf(false, "function calling not implemented yet")
//       }
//       if !yes {
//         fmt.eprintln("3 get ur shit together wtf is", l.token.str)
//         os.exit(1)
//       }

//     case:
//       if l.token.charlit do ins.val = auto_cast l.token.type
//       else {
//         fmt.eprintln("wat is hapening", l.token)
//       }
//     }

//   case .asterisk:
//     ins.instr = .mult
//     lx.get_token(l)
//     if !l.token.charlit && l.token.type != .intlit && l.token.type != .id {
//       fmt.eprintln("didn't expect this token", l.token)
//       os.exit(1)
//     }
//     #partial switch l.token.type {
//     case .intlit:
//       ins.val = auto_cast l.token.intlit
//     case .id:
//       yes := false
//       // s := cm.clone_ptr_string(l.string, auto_cast l.string_len)
//       for n in instrs {
//         if n.name == l.token.str {
//           tmp2_ins: cm.n_instrs
//           tmp2_ins.instr = .load
//           tmp2_ins.name = l.token.str //cm.clone_ptr_string(l.string, auto_cast l.string_len)
//           append(&ins.params, tmp2_ins)
//           yes = true
//         }
//       }
//       if !yes {
//         fmt.assertf(false, "function calling not implemented yet")
//       }
//       if !yes {
//         fmt.eprintln("4 get ur shit together wtf is", l.token.str)
//         os.exit(1)
//       }

//     case:
//       if l.token.charlit do ins.val = auto_cast l.token.type
//       else {
//         fmt.eprintln("wat is hapening", l.token)
//       }

//     }
//   case .forward_slash:
//     ins.instr = .div
//     lx.get_token(l)
//     if l.token.charlit && l.token.type != .intlit && l.token.type != .id {
//       fmt.eprintln("didn't expect this token", l.token)
//       os.exit(1)
//     }
//     #partial switch auto_cast l.token.type {
//     case .intlit:
//       ins.val = auto_cast l.token.intlit
//     case .id:
//       yes := false
//       for n in instrs {
//         if n.name == l.token.str {
//           tmp2_ins: cm.n_instrs
//           tmp2_ins.instr = .load
//           tmp2_ins.name = l.token.str
//           append(&ins.params, tmp2_ins)
//           yes = true
//         }
//       }
//       if !yes {
//         fmt.assertf(false, "function calling not implemented yet")
//       }
//       if !yes {
//         fmt.eprintln("4 get ur shit together wtf is", l.token.str)
//         os.exit(1)
//       }

//     case:
//       if l.token.charlit do ins.val = auto_cast l.token.type
//       else {
//         fmt.eprintln("wat is hapening", l.token)
//       }
//     }

//   case .open_parenthesis:
//     ins.instr = .nothing
//     lx.get_token(l)
//     for l.token.type != .close_parenthesis {
//       append(&ins.params, get_pushed_shit(instrs, l))
//       lx.get_token(l)
//     }
//   case .notq:
//     ins.instr = .noteq

//     lx.get_token(l)
//     append(&ins.params, get_pushed_shit(instrs, l))
//   case .eq:
//     ins.instr = .eq

//     lx.get_token(l)
//     append(&ins.params, get_pushed_shit(instrs, l))

//   case .intlit:
//     ins.instr = .push
//     ins.val = l.token.intlit

//   case:
//     if l.token.charlit {
//       ins.instr = .push
//       ins.val = auto_cast l.token.type
//     } else {
//       fmt.eprintfln("%d:%d 1 wtf unexpected {}", l.row + 1, l.col + 1, l.token)
//       os.exit(1)
//     }

//   }

//   return ins
// }

// parse :: proc(file_path: []string) -> []cm.n_instrs {
//   instrs: [dynamic]cm.n_instrs

//   label_stack: [dynamic]int


//   for file in file_path {
//     lex: lx.lexer = lx.init_lexer(file)
//     l := &lex
//     lx.get_token(l)

//     f: for l.token.type != .null_char {
//       #partial switch auto_cast l.token.type {
//       case .close_brace:
//         ins: cm.n_instrs
//         lx.get_token(l)
//         // fmt.println(l.token, instrs[len(&instrs) - 1])
//         if l.token.str == "else" {

//           lx.get_token(l)
//           if !lx.check_type(l, .open_brace) do os.exit(1)

//           tmp := pop(&label_stack)

//           ins.instr = .jmp
//           ins.offset = label_counter
//           append(&label_stack, ins.offset)
//           label_counter += 1


//           append(&instrs, ins)

//           ins.instr = .label
//           if len(label_stack) == 0 {
//             fmt.eprintfln(
//               "%s:%d:%d a block was closed when there was nothing to close",
//               l.file,
//               l.row + 1,
//               l.col + 1,
//             )
//             os.exit(1)
//           }
//           ins.offset = tmp
//           lx.get_token(l)


//           append(&instrs, ins)


//           // fmt.println(ins)
//           // os.exit(1)

//         } else {
//           ins.instr = .label
//           if len(label_stack) == 0 {
//             fmt.eprintfln(
//               "%s:%d:%d a block was closed when there was nothing to close",
//               l.file,
//               l.row + 1,
//               l.col + 1,
//             )
//             os.exit(1)
//           }
//           ins.offset = auto_cast pop(&label_stack)
//           // lx.get_token(l)


//           append(&instrs, ins)
//         }
//       // os.exit(1)


//       case .id:
//         if l.token.str == "let" {
//           ins: cm.n_instrs
//           lx.get_token(l)
//           if !lx.check_type(l, .id) do os.exit(1)

//           ins.instr = .store
//           ins.val = 1
//           ins.type_num = 1
//           ins.name = l.token.str

//           lx.get_token(l)
//           if !lx.check_type(l, .colon) do os.exit(1)

//           lx.get_token(l)

//           if l.token.type == .open_bracket {
//             lx.get_token(l)
//             // maybe support variables here at some point
//             if !lx.check_type(l, .intlit) do os.exit(1)

//             ins.type_num = auto_cast l.token.intlit
//             lx.get_token(l)
//             if !lx.check_type(l, .close_bracket) do os.exit(1)

//             lx.get_token(l)
//           }
//           if !lx.check_type(l, .id) do os.exit(1)
//           ins.type = cm.string_to_type(l.token.str)

//           lx.get_token(l)
//           if l.token.type == .equals_sign {
//             lx.get_token(l)
//             for l.token.type != .semicolon {
//               append(&ins.params, get_pushed_shit(instrs[:], l))
//               lx.get_token(l)
//             }
//           }

//           append(&instrs, ins)
//           lx.get_token(l)

//         } else if l.token.str == "syscall" {
//           num := 0
//           ins: cm.n_instrs
//           ins.instr = .syscall
//           lx.get_token(l)
//           if !lx.check_type(l, .open_parenthesis) do os.exit(1)

//           lx.get_token(l)
//           for l.token.type != .close_parenthesis {
//             append(&ins.params, get_pushed_shit(instrs[:], l))
//             lx.get_token(l)
//             if l.token.type == .comma_char do lx.get_token(l)
//           }

//           lx.get_token(l)
//           append(&instrs, ins)
//           if !lx.check_type(l, .semicolon) do os.exit(1)
//           lx.get_token(l)

//         } else if l.token.str == "if" {
//           ins: cm.n_instrs
//           ins.instr = .if_
//           ins.offset = label_counter
//           append(&label_stack, label_counter)
//           label_counter += 1

//           lx.get_token(l)
//           if !lx.check_type(l, .open_parenthesis) do os.exit(1)

//           lx.get_token(l)
//           for l.token.type != .close_parenthesis {
//             append(&ins.params, get_pushed_shit(instrs[:], l))
//             lx.get_token(l)
//           }
//           if !lx.check_type(l, .close_parenthesis) do os.exit(1)
//           lx.get_token(l)
//           if !lx.check_type(l, .open_brace) do os.exit(1)

//           lx.get_token(l)
//           append(&instrs, ins)

//         } else {   // VAR ASSIGNMENT OTHER THAN DECLARING
//           yes2 := false
//           ins: cm.n_instrs

//           for instr in instrs {
//             if instr.name == l.token.str {
//               ins.name = instr.name
//               ins.instr = .assign
//               ins.type = instr.type
//               ins.type_num = instr.type_num
//               yes2 = true
//             }
//           }
//           lx.get_token(l)
//           if l.token.type == .open_bracket {
//             lx.get_token(l)
//             if !lx.check_type(l, .intlit) do os.exit(1)

//             ins.offset = auto_cast l.token.intlit
//             lx.get_token(l)
//             if !lx.check_type(l, .close_bracket) do os.exit(1)
//             lx.get_token(l)


//             if !lx.check_type(l, .equals_sign) do os.exit(1)
//           }

//           lx.get_token(l)

//           if yes2 {
//             for l.token.type != .semicolon {
//               append(&ins.params, get_pushed_shit(instrs[:], l))
//               lx.get_token(l)
//             }
//           }

//           append(&instrs, ins)


//           if ins.instr == .nun {
//             fmt.println("???", l.token)
//             os.exit(1)

//             // fmt.println("didn't assign anything to a variable apearently", l.token.str)
//             // os.exit(1)

//           }

//           lx.get_token(l)

//         }
//       case .either_end_or_failure:
//         break f

//       case:
//         fmt.println("???", l.token)
//         os.exit(1)
//       }

//     }

//     lx.get_token(l)

//   }

//   return instrs[:]
// }
