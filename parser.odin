package veilcode

import cm "./common"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import lx "thirdparty/lexer_odin"

@(private)
label_stack: [dynamic]uint
@(private)
label_counter: uint = 0

peek :: proc(l: lx.lexer) -> lx.token {
  b_l: lx.lexer
  b_l = l
  lx.get_token(&b_l)

  return b_l.token
}

is_char_lit :: proc(c: byte) -> bool {return c >= 0 && c <= 255}

@(private)
instrs_og: [dynamic]cm.n_instrs

parse :: proc(files: []string) -> []cm.n_instrs {
  for file in files {
    // fmt.println(file)
    l: lx.lexer = lx.init_lexer(file)
    lx.get_token(&l)

    for l.token.type != .null_char && l.token.type != .either_end_or_failure {
      if l.token.type == .open_brace {
        // fmt.println("entered")
        ins: cm.n_instrs
        ins.instr = .block
        ins.offset = auto_cast label_counter
        label_counter += 1
        lx.get_token(&l)
        for l.token.type != .close_brace &&
            l.token.type != .null_char &&
            l.token.type != .either_end_or_failure {
          parse_shit(&l, &ins.params)
        }

        append(&instrs_og, ins)
        lx.get_token(&l)
        // fmt.println("ended")
      } else {
        parse_shit(&l, &instrs_og)
      }
    }
  }

  // cm.print_instrs(instrs_og[:])
  return instrs_og[:]
}

var_exists :: proc(name: string) -> Maybe(cm.n_instrs) {
  if name == "args" do return cm.n_instrs{name = "args__", type = .n_int, instr = .reg, type_num = 10}

  for i in instrs_og {
    if (i.instr == .store || i.instr == .create) && i.name == name do return i
  }

  return nil
}

fn_exists :: proc(name: string) -> Maybe(cm.n_instrs) {
  n := name
  cm.str_check(&n)
  for i in instrs_og {
    if (i.instr == .extrn || i.instr == .fn || i.instr == .fn_declare) && i.name == n do return i
  }
  return nil
}

parse_shit :: proc(l: ^lx.lexer, instrs: ^[dynamic]cm.n_instrs) {
  ins: cm.n_instrs
  cm.str_check(&l.token.str)

  #partial switch auto_cast l.token.type {

  case .close_brace:
    lx.get_token(l)
    return

  case .intlit:
    ins.instr = .push
    ins.val = auto_cast l.token.intlit
    lx.get_token(l)

  case .dqstring:
    ins.instr = .push
    ins.type = .n_str
    ins.optional = l.token.str
    lx.get_token(l)

  case .plus_sign:
    ins.instr = .add
    lx.get_token(l)
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
    } else {
      if !l.token.charlit && l.token.type != .intlit && l.token.type != .id && !l.token.charlit {
        fmt.eprintln("didn't expect this token", l.token)
        os.exit(1)
      }

      parse_shit(l, &ins.params)
    }

  case .less_than_sign:
    ins.instr = .less

    lx.get_token(l)
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
    } else {
      if !l.token.charlit && l.token.type != .intlit && l.token.type != .id && !l.token.charlit {
        fmt.eprintln("didn't expect this token", l.token)
        os.exit(1)
      }

      parse_shit(l, &ins.params)
    }

  case .greater_than_sign:
    ins.instr = .greater

    lx.get_token(l)
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
    } else {
      if !l.token.charlit && l.token.type != .intlit && l.token.type != .id && !l.token.charlit {
        fmt.eprintln("didn't expect this token", l.token)
        os.exit(1)
      }

      parse_shit(l, &ins.params)
    }


  case .asterisk:
    ins.instr = .mult
    lx.get_token(l)
    fmt.println(l.token)
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
    } else {
      if !l.token.charlit && l.token.type != .intlit && l.token.type != .id && !l.token.charlit {
        fmt.eprintln("didn't expect this token", l.token)
        os.exit(1)
      }

      parse_shit(l, &ins.params)
    }

  case .forward_slash:
    ins.instr = .div
    lx.get_token(l)
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
    } else {
      if !l.token.charlit && l.token.type != .intlit && l.token.type != .id && !l.token.charlit {
        fmt.eprintln("didn't expect this token", l.token)
        os.exit(1)
      }

      parse_shit(l, &ins.params)
    }


  case .minus_sign:
    ins.instr = .sub
    lx.get_token(l)
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
    } else {
      if !l.token.charlit && l.token.type != .intlit && l.token.type != .id && !l.token.charlit {
        fmt.eprintln("didn't expect this token", l.token)
        os.exit(1)
      }

      parse_shit(l, &ins.params)
    }

  case .percent_sign:
    ins.instr = .mod
    lx.get_token(l)
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
    } else {
      if !l.token.charlit && l.token.type != .intlit && l.token.type != .id && !l.token.charlit {
        fmt.eprintln("didn't expect this token", l.token)
        os.exit(1)
      }

      parse_shit(l, &ins.params)
    }


  case .close_parenthesis:
    return

  case .open_brace:
    lx.get_token(l)
    for l.token.type != .close_brace &&
        l.token.type != .null_char &&
        l.token.type != .either_end_or_failure {
      parse_shit(l, instrs)
    }
    // if !lx.check_type(l, .close_brace) do os.exit(1)
    lx.get_token(l)
    return

  case .open_parenthesis:
    lx.get_token(l)
    for l.token.type != .close_parenthesis &&
        l.token.type != .null_char &&
        l.token.type != .either_end_or_failure {
      parse_shit(l, instrs)
      if l.token.type == .comma_char do lx.get_token(l)
    }
    // if !lx.check_type(l, .close_parenthesis) do os.exit(1)
    lx.get_token(l)
    return

  case .eq:
    ins.instr = .eq
    lx.get_token(l)
    parse_shit(l, &ins.params)

  case .semicolon:
    lx.get_token(l)
    return

  case .notq:
    ins.instr = .noteq
    lx.get_token(l)
    parse_shit(l, &ins.params)

  case .id:
    switch l.token.str {
    case "let":
      lx.get_token(l)
      if !lx.check_type(l, .id) do os.exit(1)

      // can't use the word test appearently with fasm
      cm.str_check(&l.token.str)

      ins.instr = .store

      ins.val = 1
      ins.type_num = 1
      ins.name = l.token.str


      lx.get_token(l)
      if !lx.check_type(l, .colon) do os.exit(1)

      lx.get_token(l)

      if l.token.type == .open_bracket {
        lx.get_token(l)
        // TODO: maybe support variables here at some point when dynamic allocs are implemented
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
          parse_shit(l, &ins.params)
        }
      } else {
        ins.instr = .create
      }

      for &i in ins.params {
        if i.instr == .push && i.optional != "" && len(ins.params) == 1 {
          ins.type_num = auto_cast len(i.optional)
        }
      }

      lx.get_token(l)

    case "extrn":
      ins.instr = .extrn

      lx.get_token(l)
      if !lx.check_type(l, .id) do os.exit(1)
      ins.name = l.token.str
      if p := peek(l^); p.type != .either_end_or_failure && p.type == .dqstring {
        lx.get_token(l)
        ins.optional = l.token.str
      }
      lx.get_token(l)


    case "while":
      ins4: cm.n_instrs
      ins4.instr = .label
      ins4.offset = auto_cast label_counter
      label_counter += 1
      append(instrs, ins4)


      ins.instr = .while
      ins.offset = auto_cast label_counter
      label_counter += 1

      lx.get_token(l)
      if !lx.check_type(l, .open_parenthesis) do os.exit(1)
      parse_shit(l, &ins.params)

      append(instrs, ins)

      if !lx.check_type(l, .open_brace) do os.exit(1)
      ins2: cm.n_instrs
      ins2.instr = .block
      ins2.offset = auto_cast label_counter
      label_counter += 1

      parse_shit(l, &ins2.params)

      append(instrs, ins2)


      ins3: cm.n_instrs
      ins3.instr = .jmp
      ins3.offset = ins4.offset
      append(instrs, ins3)

      ins4.instr = .label
      ins4.offset = ins.offset
      append(instrs, ins4)

      return


    case "if":
      ins.instr = .if_
      ins.offset = auto_cast label_counter
      if_jmp := label_counter
      label_counter += 1

      lx.get_token(l)
      if !lx.check_type(l, .open_parenthesis) do os.exit(1)

      parse_shit(l, &ins.params)


      append(instrs, ins)

      ins2: cm.n_instrs
      ins2.instr = .block
      ins2.offset = auto_cast label_counter
      label_counter += 1

      parse_shit(l, &ins2.params)

      append(instrs, ins2)

      if l.token.str == "else" || peek(l^).str == "else" {
        lx.get_token(l)
        lx.get_token(l)
        // if !lx.check_type(l, .open_brace) do os.exit(1)


        ins3: cm.n_instrs
        ins3.instr = .jmp
        ins3.offset = auto_cast label_counter
        else_jmp := label_counter
        label_counter += 1

        append(instrs, ins3)

        // ---------------------------

        ins3.instr = .label
        ins3.offset = auto_cast if_jmp
        append(instrs, ins3)

        // ---------------------------

        ins3.instr = .block
        ins3.offset = auto_cast label_counter
        label_counter += 1

        // if !lx.check_type(l, .open_brace) do os.exit(1)
        parse_shit(l, &ins3.params)

        append(instrs, ins3)

        {
          ins4: cm.n_instrs
          ins4.instr = .label
          ins4.offset = auto_cast else_jmp

          append(instrs, ins4)
        }
      } else {

        ins3: cm.n_instrs
        ins3.instr = .label
        ins3.offset = auto_cast if_jmp
        append(instrs, ins3)

      }

      return

    case "$include":
      lx.get_token(l)
      if !lx.check_type(l, .dqstring) do os.exit(1)

      {
        b: strings.Builder

        spl := strings.split(l.file, "/")
        ll := len(spl)
        spl = spl[:len(spl) - 1]

        for s in spl do fmt.sbprintf(&b, "%s/", s)
        fmt.sbprintf(&b, "%s.vc", l.token.str)

        if ll == 1 do parse([]string{strings.concatenate({l.token.str, ".vc"})})
        else {
          parse({string(b.buf[:])})
        }

        strings.builder_destroy(&b)
      }
      lx.get_token(l)
      return

    case "fn":
      lx.get_token(l)
      if !lx.check_type(l, .id) do os.exit(1)

      cm.str_check(&l.token.str)

      ins.name = l.token.str

      lx.get_token(l)
      if !lx.check_type(l, .intlit) do os.exit(1)

      ins.type_num = auto_cast l.token.intlit
      ins.instr = .fn

      lx.get_token(l)

      if l.token.type == .open_brace {
        parse_shit(l, &ins.params)
      } else {
        ins.instr = .fn_declare
      }

      append(instrs, ins)
      return

    case "return":
      ins.instr = .return_
      lx.get_token(l)
    // TODO: add return argument later

    case:
      if var, f := var_exists(l.token.str).?; f {
        ins.name = var.name
        ins.instr = .assign
        ins.type = var.type
        ins.type_num = var.type_num

        lx.get_token(l)
        parse_shit(l, &ins.params)
        // if l.token.type == .open_bracket {
        //   lx.get_token(l)
        //   // TODO: support variables maybe when dynamic allocs are made


        //   if ins.params[0].instr == .load || ins.params[0].instr == .push do ins.offset = -1
        //   else {
        //     fmt.println("unreachable probably", l.token)
        //     unreachable()
        //   }

        //   lx.get_token(l)
        // }

        // if l.token.type == .pipe {
        //   ins.deref = true

        //   lx.get_token(l)
        //   if !lx.check_type(l, .id) do os.exit(1)
        //   ins.optional = l.token.str

        //   lx.get_token(l)
        // }

        // if l.token.type != .equals_sign && ins.instr != .reg {
        //   ins.instr = .load
        // } else {
        //   lx.get_token(l)

        //   for l.token.type != .semicolon &&
        //       l.token.type != .null_char &&
        //       l.token.type != .either_end_or_failure {
        //     parse_shit(l, &ins.params)
        //   }

        //   lx.get_token(l)
        // }

      } else if fn, p := fn_exists(l.token.str).?; p {

        ins.instr = .call
        ins.name = fn.name
        ins.type_num = fn.type_num

        if fn.instr == .extrn do ins.optional = "extrn"

        lx.get_token(l)
        if !lx.check_type(l, .open_parenthesis) do os.exit(1)
        parse_shit(l, &ins.params)

        for &f in ins.params {
          if f.instr == .assign do f.instr = .load
        }

        if len(ins.params) > auto_cast ins.type_num && fn.instr != .extrn {
          fmt.eprintln("too many args for the function", ins.name)
        }


      } else {
        fmt.println("------------------------")
        cm.print_instrs(instrs_og[:])
        fmt.println("------------------------")
        fmt.eprintfln("%s:%d:%d unknown id '%s'", l.file, l.row + 1, l.col, l.token.str)
        os.exit(1)

      }

    }


  case .equals_sign:
    lx.get_token(l)
    for l.token.type != .semicolon &&
        l.token.type != .null_char &&
        l.token.type != .either_end_or_failure {
      parse_shit(l, &instrs[len(instrs) - 1].params)
    }
    lx.get_token(l)
    return

  case .close_bracket:
    return

  case .open_bracket:
    lx.get_token(l)
    ins.instr = .offset
    ins.name = "tmp"
    ins.type = .n_int

    for l.token.type != .close_bracket {
      parse_shit(l, &ins.params)
      if ins.params[len(ins.params) - 1].instr == .assign {
        ins.params[len(ins.params) - 1].instr = .load
      }

    }
    lx.get_token(l)

  case .ampersand:
    lx.get_token(l)
    parse_shit(l, instrs)
    instrs[len(instrs) - 1].ptr = true
    return

  case:
    if l.token.charlit {
      ins.instr = .push
      ins.val = auto_cast l.token.type
      lx.get_token(l)
      // fmt.println(peek(l^))

    } else {
      // unknown token encountered
      fmt.eprintfln("%s:%d:%d unknown {}", l.file, l.row + 1, l.col, l.token)
      os.exit(1)
    }

  }

  append(instrs, ins)
}
