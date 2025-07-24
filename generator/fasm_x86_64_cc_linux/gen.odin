package veilcode_fasm_x86_64_cc_linux

import cm "../../common"
import "core:fmt"
import "core:os"
import "core:strings"

prt_asm := false

@(private)
counter: uint = 0
@(private)
RDI :: 0 + 1
@(private)
RSI :: 1 + 1
@(private)
RDX :: 2 + 1
@(private)
RCX :: 3 + 1
@(private)
R8 :: 4 + 1
@(private)
R9 :: 5 + 1
@(private)
R10 :: 6 + 1
@(private)
RBX :: 7 + 1
@(private)
R15 :: 8 + 1
@(private)
R14 :: 9 + 1
@(private)
R13 :: 10 + 1
@(private)
R12 :: 11 + 1
@(private)
R11 :: 12 + 1
@(private)
RAX :: 13 + 1
syscall_reg_list := [?]([]string) {
  {},
  []string{"rdi", "edi", "di", "dil"},
  []string{"rsi", "esi", "si", "sil"},
  []string{"rdx", "edx", "dx", "dl"},
  []string{"rcx", "ecx", "cx", "cl"},
  []string{"r8", "r8D", "r8W", "r8B"},
  []string{"r9", "r9D", "r9W", "r9B"},
  // ------------------------
  []string{"r10", "r10D", "r10W", "r10B"},
  []string{"rbx", "ebx", "bx", "bl"},
  []string{"r15", "r15D", "r15W", "r15B"},
  []string{"r14", "r14D", "r14W", "r14B"},
  []string{"r13", "r13D", "r13W", "r13B"},
  []string{"r12", "r12D", "r12W", "r12B"},
  []string{"r11", "r11D", "r11W", "r11B"},
  []string{"rax", "eax", "ax", "al"},
}
@(private)
sys_reg_offset := [?]int{-1, 0, 0, 3, 3}
@(private)
conv_list := [?]string{"none", "QWORD", "QWORD", "BYTE", "QWORD"}
// @(private)
// sz_list := [?]int{0, 8, 8, 1, 8}

@(private)
s: strings.Builder

escape_str :: proc(strin: string) -> string {
  // slice.from_ptr(cast(^u8)strings.clone_to_cstring(s^), len(s))
  strings.builder_reset(&s)
  i := 0
  for i < len(strin) {
    ub := cast(u8)strin[i]
    if ub == '\\' {
      i += 1
      ub = cast(u8)strin[i]
      switch ub {
      case 'n':
        strings.write_byte(&s, '\n')
      case 'r':
        strings.write_byte(&s, '\r')
      case 't':
        strings.write_byte(&s, '\t')
      case:
        fmt.eprintfln("unknown escape character '%c'", ub)
        os.exit(1)
      }
    } else {
      strings.write_byte(&s, ub)
    }
    i += 1
  }

  str, err := strings.clone(string(s.buf[:]))
  if err != .None {
    fmt.eprintln("error in copying string builder", err)
    os.exit(1)
  }
  return str
}
// @(private)
// conv_list_bits := [?]int{-1, 64, 64, 8}
// @(private)
// conv_list_bits_offset := [?]int{-1, 4, -1, -4, -1, -1, -1, 2}

// NOTE: linux x86_64 calling convention
// ints  : RAX, RDI, RSI, RDX, RCX, R8, and R9 
// floats: XMM0 to XMM7 (128 bit)
// ret   : RAX for int XMM0 for float

// NOTE: sizes for x86_64
// `db`          : 1 byte
// `dw`          : 2 bytes
// `dd`          : 4 bytes
// `dq`          : 8 bytes
// `dt`          : 10 bytes
// `db n dup(0)` : n bytes

generate_fluf_start :: proc(b: ^strings.Builder) {
  cm.builder_append_string(b, "format ELF64\n")
}

generate_vars :: proc(b: ^strings.Builder, instrs: []cm.n_instrs) {

  cm.builder_append_string(b, "section '.data' writable\n")


  fmt.sbprintf(b, "cmp_0   : dq 0\n")
  fmt.sbprintf(b, "tmp_0   : dq 0\n")
  fmt.sbprintf(b, "trash_0 : dq 0\n\n")

  for i in 0 ..< 20 {
    fmt.sbprintf(b, "fn_args_%d : dq 0\n", i)
  }
  fmt.sbprintf(b, "\n")


  for &instr in instrs {
    if instr.instr == .store {
      instr.instr = .assign
      switch instr.type {
      case .n_char:
        for i in 0 ..< instr.type_num {
          fmt.sbprintf(b, "%s_%d: db 0\n", instr.name, i)
        }
      case .n_int, .n_ptr:
        for i in 0 ..< instr.type_num {
          fmt.sbprintf(b, "%s_%d: dq 0\n", instr.name, i)
        }
      case .n_str:
        instr.instr = .nothing
        str_i := instr.params[0]
        tmp := escape_str(str_i.optional)

        fmt.sbprintf(b, "%s_len____: db %d\n", instr.name, len(tmp))
        for i in 0 ..< len(tmp) {
          fmt.sbprintf(b, "%s_%d: db %d\n", instr.name, i, tmp[i])
        }
        fmt.sbprintf(b, "%s_%d: db 0\n", instr.name, instr.type_num)
      case .n_none:
        fmt.eprintln(
          "this should not have happened but a variable has the type none, we are fucked",
        )
        os.exit(1)
      }
      // cm.builder_append_string(b, "\n")
    } else if instr.instr == .create {
      // cm.builder_append_string(b, instr.name)
      instr.instr = .nothing
      switch instr.type {
      case .n_char:
        for i in 0 ..< instr.type_num {
          fmt.sbprintf(b, "%s_%d: db 0\n", instr.name, i)
        }
      case .n_int, .n_ptr:
        for i in 0 ..< instr.type_num {
          fmt.sbprintf(b, "%s_%d: dq 0\n", instr.name, i)
        }

      case .n_str:
        fmt.assertf(false, "dynamic string alloc not supported for now")
      case .n_none:
        fmt.eprintln(
          "this should not have happened but a variable has the type none, we are fucked",
        )
        os.exit(1)
      }
      // cm.builder_append_string(b, "\n")

    }
    //  else if instr.instr == .fn {
    //   for i in 0 ..< instr.type_num {
    //     fmt.sbprintf(b, "args_%s_%d: dq 0\n", instr.name, i)
    //   }
    // }
  }
}

generate_strs :: proc(b: ^strings.Builder, instrs: []cm.n_instrs) {
  for &instr in instrs {

    if instr.instr == .push && instr.type == .n_str {
      // str_i := instr.params[0]
      tmp := escape_str(instr.optional)
      cc := counter
      counter += 1

      fmt.sbprintf(b, "str%d_len____: db %d\n", cc, len(tmp))
      for u in 0 ..< len(tmp) {
        fmt.sbprintf(b, "str%d_%d: db %d\n", cc, u, tmp[u])
      }
      fmt.sbprintf(b, "str%d_%d: db 0\n", cc, len(tmp))

      instr.instr = .load
      instr.name = fmt.tprintf("str%d", cc)
      instr.type_num = len(tmp)
      instr.ptr = true
    }


    if len(instr.params) > 0 do generate_strs(b, instr.params[:])
  }
}

generate_blocks :: proc(b: ^strings.Builder, instrs: []cm.n_instrs) {
  for instr in instrs {
    if instr.instr == .block {
      fmt.sbprintf(b, "block_%d:\n", instr.offset)

      generate_instr(b, instr.params[:])

      fmt.sbprintf(b, "  ret\n")
    }

    if instr.instr == .fn {
      fmt.sbprintf(b, "%s:\n", instr.name)

      generate_instr(b, instr.params[:])

      fmt.sbprintf(b, "  ret\n")
    }


    if len(instr.params) > 0 do generate_blocks(b, instr.params[:])
  }

}

generate :: proc(instrs: []cm.n_instrs) -> string {
  res: strings.Builder


  generate_fluf_start(&res)
  generate_vars(&res, instrs)
  generate_strs(&res, instrs)

  cm.builder_append_string(&res, "section '.text' executable\n")

  generate_blocks(&res, instrs)

  cm.builder_append_string(&res, "public main\n")
  cm.builder_append_string(&res, "main:\n")

  cm.print_instrs(instrs)
  generate_instr(&res, instrs)

  cm.builder_append_string(&res, "  mov rax, 0\n")
  cm.builder_append_string(&res, "  ret\n")

  if prt_asm {
    fmt.println(string(res.buf[:]))
  }
  // os.exit(1)
  return string(res.buf[:])
}


get_arg_num_from_call :: proc(instrs: []cm.n_instrs) -> int {
  arg_num := 0

  for ins in instrs {
    if len(ins.params) != 0 {
      arg_num += get_arg_num_from_call(ins.params[:])
    }

    if ins.instr == .push || ins.instr == .load {
      arg_num += 1
    }

  }

  return arg_num
}

// TODO: variadic arguments
// r15: ops
// r13: used for derefrencing 
// r12, r11: one of stuff like comparisons
generate_instr :: proc(
  b: ^strings.Builder,
  instrs: []cm.n_instrs,
  parent_ptr: ^cm.n_instrs = nil,
) {
  pptr := parent_ptr != nil

  for &instr, i in instrs {
    #partial switch instr.instr {
    case .nothing, .fn_declare:
    case .extrn:
      if instr.optional == "" do instr.optional = instr.name
      fmt.sbprintf(b, "  extrn '%s' as _%s\n", instr.optional, instr.name)
      fmt.sbprintf(b, "  %s = PLT _%s\n", instr.name, instr.name)

    case .assign:
      ins: cm.n_instrs
      ins.name = "tmp"
      ins.type = instr.type
      ins.type_num = instr.type_num

      generate_instr(b, instr.params[:], &instr)


    case .push:
      fmt.println("push", instr)
      if pptr {
        if parent_ptr.offset < 0 {
          fmt.sbprintf(b, "  mov %s, %d\n", syscall_reg_list[-parent_ptr.offset][0], instr.val)
          parent_ptr.offset -= 1

        } else {
          if instr.optional == "" {
            fmt.sbprintf(
              b,
              "  mov %s%c%s_%d%c, %d\n",
              conv_list[auto_cast parent_ptr.type],
              parent_ptr.ptr ? ' ' : '[',
              parent_ptr.name,
              parent_ptr.offset,
              parent_ptr.ptr ? ' ' : ']',
              instr.val,
            )
          } else {
            fmt.sbprintf(
              b,
              "  mov %s%c%s_%d%c, \"%s\"\n",
              conv_list[auto_cast parent_ptr.type],
              parent_ptr.ptr ? ' ' : '[',
              parent_ptr.name,
              parent_ptr.offset,
              parent_ptr.ptr ? ' ' : ']',
              instr.optional,
            )

          }
        }


      } else {
        fmt.println("push push")
        unreachable()
      }

    case .sub:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -R15
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  sub %s%c%s_%d%c, %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
          syscall_reg_list[R15][sys_reg_offset[auto_cast instr.type]],
        )

      } else {
        assert(false, "sub pushed")
      }

    case .add:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -R15
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  add %s%c%s_%d%c, %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
          syscall_reg_list[R15][sys_reg_offset[auto_cast instr.type]],
        )

      } else {
        assert(false, "add pushed")
      }

    case .mult:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -R15
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  imul %s, %s%c%s_%d%c\n",
          syscall_reg_list[R15][sys_reg_offset[auto_cast instr.type]],
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
        )
        fmt.sbprintf(
          b,
          "  mov %s%c%s_%d%c, %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
          syscall_reg_list[R15][sys_reg_offset[auto_cast instr.type]],
        )

      } else {
        assert(false, "mult pushed")
      }

    case .div:
      if pptr {
        // instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -RAX
        // fmt.sbprintf(b, "  push rax\n")
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  xchg %s, %s%c%s_%d%c\n",
          syscall_reg_list[RAX][sys_reg_offset[auto_cast instr.type]],
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
        )
        fmt.sbprintf(b, "  cqo\n")
        fmt.sbprintf(
          b,
          "  idiv %s%c%s_%d%c\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
          // syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
        )
        fmt.sbprintf(
          b,
          "  xchg %s, %s%c%s_%d%c\n",
          syscall_reg_list[RAX][sys_reg_offset[auto_cast instr.type]],
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
        )
        // fmt.sbprintf(b, "  pop rax\n")


      } else {
        assert(false, "div pushed")
      }

    case .mod:
      if pptr {
        // instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -RAX
        // fmt.sbprintf(b, "  push rax\n")
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  xchg %s, %s%c%s_%d%c\n",
          syscall_reg_list[RAX][sys_reg_offset[auto_cast instr.type]],
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
        )
        fmt.sbprintf(b, "  cqo\n")
        fmt.sbprintf(
          b,
          "  idiv %s%c%s_%d%c\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
          // syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
        )
        fmt.sbprintf(
          b,
          "  xchg %s, %s%c%s_%d%c\n",
          syscall_reg_list[RDX][sys_reg_offset[auto_cast instr.type]],
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
        )
        // fmt.sbprintf(b, "  pop rax\n")


      } else {
        assert(false, "div pushed")
      }

    case .eq:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -R12

        generate_instr(b, instr.params[:], &instr)

        fmt.sbprintf(
          b,
          "  cmp %s[%s_%d], %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.name,
          parent_ptr.offset,
          syscall_reg_list[R12][sys_reg_offset[auto_cast parent_ptr.type]],
        ) // num1 < = > num2
        fmt.sbprintf(b, "  setne BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
      } else {
        fmt.println("eq pushed")
        unreachable()
      }

    case .noteq:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -R12

        generate_instr(b, instr.params[:], &instr)

        fmt.sbprintf(
          b,
          "  cmp %s[%s_%d], %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.name,
          parent_ptr.offset,
          syscall_reg_list[R12][sys_reg_offset[auto_cast parent_ptr.type]],
        ) // num1 < = > num2
        fmt.sbprintf(b, "  sete BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
      } else {
        fmt.println("noteq pushed")
        unreachable()
      }

    case .less:
      if pptr {
        // instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -R12

        generate_instr(b, instr.params[:], &instr)
        fmt.println(string(b.buf[:]))
        fmt.sbprintf(
          b,
          "  cmp %s[%s_%d], %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.name,
          parent_ptr.offset,
          syscall_reg_list[R12][sys_reg_offset[parent_ptr.type != .n_none || parent_ptr.instr != .if_ ? auto_cast parent_ptr.type : auto_cast instr.type]],
        ) // num1 < = > num2
        fmt.sbprintf(b, "  setl BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
      } else {
        fmt.println("less pushed")
        unreachable()

      }

    case .greater:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -R12

        generate_instr(b, instr.params[:], &instr)

        fmt.sbprintf(
          b,
          "  cmp %s[%s_%d], %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.name,
          parent_ptr.offset,
          syscall_reg_list[R12][sys_reg_offset[auto_cast parent_ptr.type]],
        ) // num1 < = > num2
        fmt.sbprintf(b, "  setg BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
      } else {
        fmt.println("less pushed")
        unreachable()

      }

    case .call:
      arg_num := get_arg_num_from_call(instr.params[:])
      call_name := instr.name

      for i in 0 ..< len(instr.params) {
        fmt.sbprintf(b, "  push QWORD[fn_args_%d]\n", i)
      }

      if instr.optional == "extrn" {
        i := 0
        for ins in instr.params {
          if i <= 5 {
            if ins.instr == .load {

              if len(ins.params) > 0 {
                generate_instr(b, ins.params[:])
                fmt.sbprintf(b, "  mov r15, [tmp_0]\n")
              } else {
                fmt.sbprintf(b, "  xor r15, r15\n")

              }

              if ins.ptr {
                fmt.sbprintf(b, "  add r15, %s_0\n", ins.name)

                fmt.sbprintf(
                  b,
                  "  xor %s, %s\n  mov %s, r15\n",
                  syscall_reg_list[i + 1][0],
                  syscall_reg_list[i + 1][0],
                  syscall_reg_list[i + 1][0],
                )
              } else {
                fmt.sbprintf(
                  b,
                  "  xor %s, %s\n  mov %s, %s[%s_0 + r15]\n",
                  syscall_reg_list[i + 1][0],
                  syscall_reg_list[i + 1][0],
                  syscall_reg_list[i + 1][sys_reg_offset[auto_cast ins.type]],
                  conv_list[auto_cast ins.type],
                  ins.name,
                )

              }
            } else if ins.instr == .push {
              fmt.sbprintf(b, "  mov %s, %d\n", syscall_reg_list[i + 1][0], ins.val)
            }
          } else {
            break
          }
          i += 1
        }
        // 1 2 3 4 5 | 6 7
        //     | 
        ii := len(instr.params) - 1
        // fmt.println(i, ii)
        for ii >= i {
          ins := instr.params[ii]
          if ins.instr == .load {
            fmt.sbprintf(b, "  push QWORD[%s_%d]\n", ins.name, ii)
          } else if ins.instr == .push {
            fmt.sbprintf(b, "  push %d\n", ins.val)
          }
          ii -= 1
        }
      } else {
        instr.offset = -RDI
        generate_instr(b, instr.params[:], &instr)

        if instr.type_num != 0 {
          for i in 0 ..< instr.type_num {
            fmt.sbprintf(b, "  mov QWORD[fn_args_%d], %s\n", i, syscall_reg_list[i + 1][0])
          }
        }
      }

      fmt.sbprintf(b, "  xor rax, rax\n")
      fmt.sbprintf(b, "  call %s\n", call_name)

      if instr.optional == "extrn" && len(instr.params) > 5 {
        for i in 5 ..< len(instr.params) - 1 do fmt.sbprintf(b, "  pop QWORD[trash_0]\n")
      }

      for i in 0 ..< len(instr.params) {
        fmt.sbprintf(b, "  pop QWORD[fn_args_%d]\n", len(instr.params) - i - 1)
      }


    case .load:
      if pptr {

        to_load: string

        if parent_ptr.offset < 0 {
          to_load =
            syscall_reg_list[-parent_ptr.offset][sys_reg_offset[parent_ptr.type != .n_none ? auto_cast parent_ptr.type : auto_cast instr.type]]
          fmt.sbprintf(
            b,
            "  xor %s, %s\n",
            syscall_reg_list[-parent_ptr.offset][0],
            syscall_reg_list[-parent_ptr.offset][0],
          )
          parent_ptr.offset -= 1
        } else {
          to_load = parent_ptr.name
        }


        if len(instr.params) == 0 {
          fmt.sbprintf(b, "   \n")
        } else {
          assert(false, "not implemented yet 0")
        }

        // fmt.println(string(b.buf[:]))
        // fmt.println(to_load, instr)


        os.exit(1)
      } else {
        fmt.println("load pushed")
        unreachable()
      }

    case .offset:
      fmt.println(instr)
      generate_instr(b, instr.params[:], &instr)


    case .if_:
      old_off := instr.offset
      instr.offset = -R12

      fmt.sbprintf(b, "  mov QWORD[cmp_0], 0\n")
      generate_instr(b, instr.params[:], &instr)
      fmt.sbprintf(b, "  cmp BYTE[cmp_0], 1\n")
      fmt.sbprintf(b, "  je label_%d\n", old_off)

    //   case .assign:
    //     instr.offset = 0

    //     if instr.params[0].instr == .push {
    //       instr.val = auto_cast instr.params[0].val
    //       generate_instr(b, instr.params[:], &instr)
    //     } else {

    //       numn := instr.params[0]
    //       generate_instr(b, {numn})
    //       ordered_remove(&instr.params, 0)

    //       fmt.sbprintf(b, "  pop r15\n")

    //       if numn.deref {
    //         fmt.sbprintf(b, ";; ----deref\n")
    //       } else if numn.ptr {
    //         fmt.sbprintf(b, "  mov QWORD[%s_%d], r15\n", instr.name, instr.offset)
    //       } else {
    //         old := instr.name
    //         instr.name = "tmp"
    //         instr.offset = 0

    //         generate_instr(b, instr.params[:], &instr)


    //         fmt.sbprintf(b, "  mov r14, [tmp_0]\n")

    //         fmt.sbprintf(
    //           b,
    //           "  mov %s[%s_0 + r15], %s ;hjikuihk\n",
    //           conv_list[auto_cast instr.type],
    //           old,
    //           syscall_reg_list[R14][sys_reg_offset[auto_cast instr.type]],
    //         )
    //       }


    //     }

    //   case .sub:
    //     if pptr {
    //       instr.name = ""
    //       instr.type = parent_ptr.type
    //       instr.offset = -11
    //       generate_instr(b, instr.params[:], &instr)
    //       fmt.sbprintf(
    //         b,
    //         "  sub %s%c%s_%d%c, %s\n",
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //         syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
    //       )

    //     } else {
    //       assert(false, "sub pushed")
    //     }


    //   case .add:
    //     if pptr {
    //       instr.name = ""
    //       instr.type = parent_ptr.type
    //       instr.offset = -11
    //       generate_instr(b, instr.params[:], &instr)
    //       fmt.sbprintf(
    //         b,
    //         "  add %s%c%s_%d%c, %s\n",
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //         syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
    //       )

    //     } else {
    //       assert(false, "add pushed")
    //     }

    //   case .mult:
    //     if pptr {
    //       instr.name = ""
    //       instr.type = parent_ptr.type
    //       instr.offset = -11
    //       generate_instr(b, instr.params[:], &instr)
    //       fmt.sbprintf(
    //         b,
    //         "  imul %s, %s%c%s_%d%c\n",
    //         syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //       )
    //       fmt.sbprintf(
    //         b,
    //         "  mov %s%c%s_%d%c, %s\n",
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //         syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
    //       )

    //     } else {
    //       assert(false, "mult pushed")
    //     }

    //   case .div:
    //     if pptr {
    //       instr.name = ""
    //       instr.type = parent_ptr.type
    //       instr.offset = -2
    //       fmt.sbprintf(b, "  push rax\n")
    //       generate_instr(b, instr.params[:], &instr)
    //       fmt.sbprintf(
    //         b,
    //         "  xchg %s, %s%c%s_%d%c\n",
    //         syscall_reg_list[RAX][sys_reg_offset[auto_cast instr.type]],
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //       )
    //       fmt.sbprintf(b, "  cqo\n")
    //       fmt.sbprintf(
    //         b,
    //         "  idiv %s%c%s_%d%c\n",
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //         // syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
    //       )
    //       fmt.sbprintf(
    //         b,
    //         "  xchg %s, %s%c%s_%d%c\n",
    //         syscall_reg_list[RAX][sys_reg_offset[auto_cast instr.type]],
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //       )
    //       fmt.sbprintf(b, "  pop rax\n")


    //     } else {
    //       assert(false, "div pushed")
    //     }

    //   case .mod:
    //     if pptr {
    //       instr.name = ""
    //       instr.type = parent_ptr.type
    //       instr.offset = -2
    //       fmt.sbprintf(b, "  push rax\n")
    //       generate_instr(b, instr.params[:], &instr)
    //       fmt.sbprintf(
    //         b,
    //         "  xchg %s, %s%c%s_%d%c\n",
    //         syscall_reg_list[RAX][sys_reg_offset[auto_cast instr.type]],
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //       )
    //       fmt.sbprintf(b, "  cqo\n")
    //       fmt.sbprintf(
    //         b,
    //         "  idiv %s%c%s_%d%c\n",
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //         // syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
    //       )
    //       fmt.sbprintf(
    //         b,
    //         "  xchg %s, %s%c%s_%d%c\n",
    //         syscall_reg_list[RDX][sys_reg_offset[auto_cast instr.type]],
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.ptr ? ' ' : '[',
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         parent_ptr.ptr ? ' ' : ']',
    //       )
    //       fmt.sbprintf(b, "  pop rax\n")


    //     } else {
    //       assert(false, "div pushed")
    //     }


    //   case .push:
    //     if pptr {
    //       if parent_ptr.offset < 0 {
    //         if parent_ptr.offset < -1 {
    //           fmt.sbprintf(
    //             b,
    //             "  mov %s, %d\n",
    //             syscall_reg_list[-parent_ptr.offset - 2][0],
    //             instr.val,
    //           )
    //           parent_ptr.offset -= 1
    //         } else {
    //           fmt.sbprintf(b, "  mov %s, %d\n", parent_ptr.name, instr.val)
    //         }
    //       } else {

    //         if instr.optional == "" {
    //           fmt.sbprintf(
    //             b,
    //             "  mov %s%c%s_%d%c, %d\n",
    //             conv_list[auto_cast parent_ptr.type],
    //             parent_ptr.ptr ? ' ' : '[',
    //             parent_ptr.name,
    //             parent_ptr.offset,
    //             parent_ptr.ptr ? ' ' : ']',
    //             instr.val,
    //           )
    //         } else {
    //           fmt.sbprintf(
    //             b,
    //             "  mov %s%c%s_%d%c, \"%s\"\n",
    //             conv_list[auto_cast parent_ptr.type],
    //             parent_ptr.ptr ? ' ' : '[',
    //             parent_ptr.name,
    //             parent_ptr.offset,
    //             parent_ptr.ptr ? ' ' : ']',
    //             instr.optional,
    //           )

    //         }

    //       }

    //     } else {
    //       fmt.sbprintf(b, "  push %d\n", instr.val)
    //     }

    //   case .load:
    //     if pptr {
    //       if parent_ptr.offset < 0 {
    //         if parent_ptr.offset < -1 {
    //           if len(instr.params) > 0 {
    //             if instr.params[0].instr == .push {
    //               instr.offset = auto_cast instr.params[0].val
    //               unordered_remove(&instr.params, 0)
    //               fmt.sbprintf(
    //                 b,
    //                 "  xor %s, %s\n  mov %s, %c%s_%d%c\n",
    //                 syscall_reg_list[-parent_ptr.offset - 2][0],
    //                 syscall_reg_list[-parent_ptr.offset - 2][0],
    //                 syscall_reg_list[-parent_ptr.offset - 2][instr.ptr ? 0 : sys_reg_offset[auto_cast instr.type]],
    //                 // conv_list[instr.ptr ? 1 : int(instr.type)],
    //                 instr.ptr ? ' ' : '[',
    //                 instr.name,
    //                 instr.offset,
    //                 instr.ptr ? ' ' : ']',
    //               )

    //               if len(instr.params) > 0 {
    //                 fmt.eprintln("cannot do ops in in brackets sorry")
    //                 os.exit(1)
    //               }

    //             } else {


    //               numn := instr.params[0]
    //               generate_instr(b, {numn})
    //               ordered_remove(&instr.params, 0)

    //               if len(instr.params) > 0 {
    //                 fmt.eprintln("cannot do ops in in brackets sorry")
    //                 os.exit(1)
    //               }


    //               if numn.deref {
    //                 fmt.sbprintf(b, ";----deref\n")
    //                 fmt.sbprintf(
    //                   b,
    //                   "  xor %s, %s\n",
    //                   syscall_reg_list[-parent_ptr.offset - 2][0],
    //                   syscall_reg_list[-parent_ptr.offset - 2][0],
    //                 )
    //                 fmt.sbprintf(b, "  pop r15\n")
    //                 fmt.sbprintf(b, "  mov r15, [r15]\n")
    //                 fmt.sbprintf(
    //                   b,
    //                   "  xor %s, %s\n",
    //                   syscall_reg_list[-parent_ptr.offset - 2][0],
    //                   syscall_reg_list[-parent_ptr.offset - 2][0],
    //                 )
    //                 fmt.sbprintf(
    //                   b,
    //                   "  mov %s, [%s_0 + r15]\n",
    //                   syscall_reg_list[-parent_ptr.offset - 2][instr.ptr ? 0 : sys_reg_offset[auto_cast instr.type]],
    //                   instr.name,
    //                 )


    //               } else if numn.ptr {
    //                 fmt.sbprintln(b, ";-----ptr")
    //               } else {
    //                 fmt.sbprintf(b, "  pop r15\n")
    //                 fmt.sbprintf(
    //                   b,
    //                   "  xor %s, %s\n",
    //                   syscall_reg_list[-parent_ptr.offset - 2][0],
    //                   syscall_reg_list[-parent_ptr.offset - 2][0],
    //                 )
    //                 fmt.sbprintf(
    //                   b,
    //                   "  mov %s, [%s_0 + r15]\n",
    //                   syscall_reg_list[-parent_ptr.offset - 2][instr.ptr ? 0 : sys_reg_offset[auto_cast instr.type]],
    //                   instr.name,
    //                 )
    //               }
    //             }
    //           } else {
    //             fmt.sbprintf(
    //               b,
    //               "  xor %s, %s\n  mov %s, %c%s_%d%c\n",
    //               syscall_reg_list[-parent_ptr.offset - 2][0],
    //               syscall_reg_list[-parent_ptr.offset - 2][0],
    //               syscall_reg_list[-parent_ptr.offset - 2][instr.ptr ? 0 : sys_reg_offset[auto_cast instr.type]],
    //               // conv_list[instr.ptr ? 1 : int(instr.type)],
    //               instr.ptr ? ' ' : '[',
    //               instr.name,
    //               instr.offset,
    //               instr.ptr ? ' ' : ']',
    //             )

    //           }


    //           // if instr.deref {

    //           //   if instr.optional == "char" {
    //           //     fmt.sbprintf(b, "  xor r13, r13\n")
    //           //     fmt.sbprintf(b, "  mov r13b, [%s]\n", syscall_reg_list[-parent_ptr.offset - 2][0])
    //           //     fmt.sbprintf(b, "  mov %s, r13\n", syscall_reg_list[-parent_ptr.offset - 2][0])

    //           //   } else {
    //           //     // TODO: maybe 16/32 bits later
    //           //     fmt.sbprintf(
    //           //       b,
    //           //       "  mov %s, [%s];000\n",
    //           //       syscall_reg_list[-parent_ptr.offset - 2][0],
    //           //       syscall_reg_list[-parent_ptr.offset - 2][0],
    //           //     )
    //           //   }
    //           // }

    //           parent_ptr.offset -= 1
    //         } else {
    //           fmt.sbprintf(
    //             b,
    //             "  mov %s, %s_%d\n",
    //             parent_ptr.name,
    //             // conv_list[auto_cast instr.type],
    //             instr.name,
    //             instr.offset,
    //           )
    //         }
    //       } else {
    //         fmt.sbprintf(
    //           b,
    //           "  mov %s, %c%s_%d%c\n",
    //           syscall_reg_list[R14][instr.ptr ? 0 : sys_reg_offset[auto_cast instr.type]],
    //           instr.ptr ? ' ' : '[',
    //           instr.name,
    //           instr.offset >= 0 ? instr.offset : 0,
    //           instr.ptr ? ' ' : ']',
    //         )

    //         fmt.sbprintf(
    //           b,
    //           "  mov %s[%s_%d], %s\n",
    //           conv_list[auto_cast parent_ptr.type],
    //           parent_ptr.name,
    //           parent_ptr.offset,
    //           syscall_reg_list[R14][instr.ptr ? 0 : sys_reg_offset[auto_cast parent_ptr.type]],
    //         )
    //       }

    //     } else {
    //       fmt.sbprintf(
    //         b,
    //         "  push %s%c%s_%d%c\n",
    //         conv_list[auto_cast instr.type],
    //         instr.ptr ? ' ' : '[',
    //         instr.name,
    //         instr.offset,
    //         instr.ptr ? ' ' : ']',
    //       )
    //     }

    //   case .if_:
    //     old_off := instr.offset
    //     instr.offset = -14

    //     fmt.sbprintf(b, "  mov QWORD[cmp_0], 0\n")
    //     generate_instr(b, instr.params[:], &instr)
    //     fmt.sbprintf(b, "  cmp BYTE[cmp_0], 1\n")
    //     fmt.sbprintf(b, "  je label_%d\n", old_off)

    //   case .while:
    //     old_off := instr.offset
    //     instr.offset = -14

    //     fmt.sbprintf(b, "  mov QWORD[cmp_0], 0\n")
    //     generate_instr(b, instr.params[:], &instr)
    //     fmt.sbprintf(b, "  cmp BYTE[cmp_0], 1\n")
    //     fmt.sbprintf(b, "  je label_%d\n", old_off)


    //   case .label:
    //     fmt.sbprintf(b, "label_%d:\n", instr.offset)

    //   case .jmp:
    //     fmt.sbprintf(b, "  jmp label_%d\n", instr.offset)

    //   case .fn:

    //   case .block:
    //     fmt.sbprintf(b, "  xor rax, rax\n")
    //     fmt.sbprintf(b, "  call block_%d\n", instr.offset)

    //   case .call:
    //     arg_num := get_arg_num_from_call(instr.params[:])
    //     call_name := instr.name

    //     for i in 0 ..< len(instr.params) {
    //       fmt.sbprintf(b, "  push QWORD[fn_args_%d]\n", i)
    //     }

    //     if len(instr.params) > 5 && instr.optional == "extrn" {

    //       i := 0
    //       for ins in instr.params {
    //         if i <= 5 {
    //           if ins.instr == .load {
    //             fmt.sbprintf(b, "  mov %s, QWORD[%s_%d]\n", syscall_reg_list[i][0], ins.name, i)
    //           } else if ins.instr == .push {
    //             fmt.sbprintf(b, "  mov %s, %d\n", syscall_reg_list[i][0], ins.val)
    //           }
    //         } else {
    //           break
    //         }
    //         i += 1
    //       }
    //       // 1 2 3 4 5 | 6 7
    //       //     | 
    //       ii := len(instr.params) - 1
    //       // fmt.println(i, ii)
    //       for ii >= i {
    //         ins := instr.params[ii]
    //         if ins.instr == .load {
    //           fmt.sbprintf(b, "  push QWORD[%s_%d]\n", ins.name, ii)
    //         } else if ins.instr == .push {
    //           fmt.sbprintf(b, "  push %d\n", ins.val)
    //         }
    //         ii -= 1
    //       }
    //     } else {
    //       instr.offset = -2
    //       generate_instr(b, instr.params[:], &instr)

    //       if instr.type_num != 0 {
    //         for i in 0 ..< instr.type_num {
    //           fmt.sbprintf(b, "  mov QWORD[fn_args_%d], %s\n", i, syscall_reg_list[i][0])
    //         }
    //       }
    //     }


    //     fmt.sbprintf(b, "  xor rax, rax\n")
    //     fmt.sbprintf(b, "  call %s\n", call_name)

    //     if instr.optional == "extrn" && len(instr.params) > 5 {
    //       for i in 5 ..< len(instr.params) - 1 do fmt.sbprintf(b, "  pop QWORD[trash_0]\n")
    //     }

    //     for i in 0 ..< len(instr.params) {
    //       fmt.sbprintf(b, "  pop QWORD[fn_args_%d]\n", len(instr.params) - i - 1)
    //     }


    //     if pptr {
    //       fmt.sbprintf(
    //         b,
    //         "  mov %s[%s_%d] ,%s\n",
    //         conv_list[auto_cast parent_ptr.type],
    //         parent_ptr.name,
    //         parent_ptr.offset,
    //         syscall_reg_list[RAX][sys_reg_offset[auto_cast parent_ptr.type]],
    //       )
    //     }

    //   case .nothing, .fn_declare:
    //   case .return_:
    //     fmt.sbprintf(b, "  ret\n")

    //   case .less:
    //     if pptr {
    //       if parent_ptr.offset < 0 {
    //         if parent_ptr.offset < -1 {
    //           instr.name = ""
    //           instr.type = parent_ptr.type
    //           instr.offset = -13

    //           generate_instr(b, instr.params[:], &instr)

    //           fmt.sbprintf(b, "  cmp r12, r11\n") // num1 < = > num2
    //           fmt.sbprintf(b, "  setl BYTE[cmp_0]\n")
    //         }
    //       } else {

    //         instr.name = ""
    //         instr.type = parent_ptr.type
    //         instr.offset = -13

    //         generate_instr(b, instr.params[:], &instr)

    //         fmt.sbprintf(
    //           b,
    //           "  cmp %s[%s_%d], %s\n",
    //           conv_list[auto_cast parent_ptr.type],
    //           parent_ptr.name,
    //           parent_ptr.offset,
    //           syscall_reg_list[R13][sys_reg_offset[auto_cast parent_ptr.type]],
    //         ) // num1 < = > num2
    //         fmt.sbprintf(b, "  setl BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
    //       }
    //     } else {
    //       generate_instr(b, instr.params[:])
    //       fmt.sbprintf(b, "  pop r12\n") // num2
    //       fmt.sbprintf(b, "  pop r11\n") // num1
    //       fmt.sbprintf(b, "  cmp r11, r12\n") // num1 < = > num2
    //       fmt.sbprintf(b, "  setl BYTE[cmp_0]\n")
    //     }

    //   case .greater:
    //     if pptr {
    //       if parent_ptr.offset < 0 {
    //         if parent_ptr.offset < -1 {
    //           instr.name = ""
    //           instr.type = parent_ptr.type
    //           instr.offset = -13

    //           generate_instr(b, instr.params[:], &instr)

    //           fmt.sbprintf(b, "  cmp r12, r11\n") // num1 < = > num2
    //           fmt.sbprintf(b, "  setg BYTE[cmp_0]\n")
    //         }
    //       } else {

    //         instr.name = ""
    //         instr.type = parent_ptr.type
    //         instr.offset = -13

    //         generate_instr(b, instr.params[:], &instr)

    //         fmt.sbprintf(
    //           b,
    //           "  cmp %s[%s_%d], %s\n",
    //           conv_list[auto_cast parent_ptr.type],
    //           parent_ptr.name,
    //           parent_ptr.offset,
    //           syscall_reg_list[R13][sys_reg_offset[auto_cast parent_ptr.type]],
    //         ) // num1 < = > num2
    //         fmt.sbprintf(b, "  setg BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
    //       }
    //     } else {
    //       generate_instr(b, instr.params[:])
    //       fmt.sbprintf(b, "  pop r12\n") // num2
    //       fmt.sbprintf(b, "  pop r11\n") // num1
    //       fmt.sbprintf(b, "  cmp r11, r12\n") // num1 < = > num2
    //       fmt.sbprintf(b, "  setg BYTE[cmp_0]\n")
    //     }

    //   case .noteq:
    //     if pptr {
    //       if parent_ptr.offset < 0 {
    //         if parent_ptr.offset < -1 {
    //           instr.name = ""
    //           instr.type = parent_ptr.type
    //           instr.offset = -13

    //           generate_instr(b, instr.params[:], &instr)

    //           fmt.sbprintf(b, "  cmp r12, r11\n") // num1 < = > num2
    //           fmt.sbprintf(b, "  sete BYTE[cmp_0]\n")
    //         }
    //       } else {

    //         instr.name = ""
    //         instr.type = parent_ptr.type
    //         instr.offset = -13

    //         generate_instr(b, instr.params[:], &instr)

    //         fmt.sbprintf(
    //           b,
    //           "  cmp %s[%s_%d], %s\n",
    //           conv_list[auto_cast parent_ptr.type],
    //           parent_ptr.name,
    //           parent_ptr.offset,
    //           syscall_reg_list[R13][sys_reg_offset[auto_cast parent_ptr.type]],
    //         ) // num1 < = > num2
    //         fmt.sbprintf(b, "  sete BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
    //       }
    //     } else {
    //       generate_instr(b, instr.params[:])
    //       fmt.sbprintf(b, "  pop r12\n") // num2
    //       fmt.sbprintf(b, "  pop r11\n") // num1
    //       fmt.sbprintf(b, "  cmp r11, r12\n") // num1 < = > num2
    //       fmt.sbprintf(b, "  sete BYTE[cmp_0]\n")
    //     }

    //   case .eq:
    //     if pptr {
    //       if parent_ptr.offset < 0 {
    //         if parent_ptr.offset < -1 {
    //           instr.name = ""
    //           instr.type = parent_ptr.type
    //           instr.offset = -13

    //           generate_instr(b, instr.params[:], &instr)

    //           fmt.sbprintf(b, "  cmp r12, r11\n") // num1 < = > num2
    //           fmt.sbprintf(b, "  mov QWORD[cmp_0], 0\n")
    //           fmt.sbprintf(b, "  setne BYTE[cmp_0]\n")
    //         }
    //       } else {
    //         instr.name = ""
    //         instr.type = parent_ptr.type
    //         instr.offset = -13

    //         generate_instr(b, instr.params[:], &instr)

    //         fmt.sbprintf(
    //           b,
    //           "  cmp %s[%s_%d], %s\n",
    //           conv_list[auto_cast parent_ptr.type],
    //           parent_ptr.name,
    //           parent_ptr.offset,
    //           syscall_reg_list[R13][sys_reg_offset[auto_cast parent_ptr.type]],
    //         ) // num1 < = > num2
    //         fmt.sbprintf(b, "  setne BYTE[%s_%d]\n", parent_ptr.name, parent_ptr.offset)
    //       }
    //     } else {
    //       generate_instr(b, instr.params[:])
    //       fmt.sbprintf(b, "  pop r12\n") // num2
    //       fmt.sbprintf(b, "  pop r11\n") // num1
    //       fmt.sbprintf(b, "  cmp r11, r12\n") // num1 < = > num2
    //       fmt.sbprintf(b, "  setne BYTE[cmp_0]\n")
    //     }

    case:
      fmt.print("curent state: \n", string(b.buf[:]))
      fmt.println("-------------------------------------------")

      fmt.eprintln("unimplemented", instr.instr)
      os.exit(1)

    }
  }
}
