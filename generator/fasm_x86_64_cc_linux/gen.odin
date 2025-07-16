package veilcode_fasm_x86_64_cc_linux

import cm "../../common"
import "core:fmt"
import "core:os"
import "core:strings"

@(private)
counter := 0
@(private)
syscall_reg_list := [?]([]string) {
  []string{"rax", "eax", "ax", "al"},
  []string{"rdi", "edi", "di", "dil"},
  []string{"rsi", "esi", "si", "sil"},
  []string{"rdx", "edx", "dx", "dl"},
  []string{"r10", "r10D", "r10W", "r10B"},
  []string{"r8", "r8D", "r8W", "r8B"},
  []string{"r9", "r9D", "r9W", "r9B"},
  // ------------------------
  []string{"rbx", "ebx", "bx", "bl"},
  []string{"rcx", "ecx", "cx", "cl"},
  []string{"r15", "r15D", "r15W", "r15B"},
  []string{"r14", "r14D", "r14W", "r14B"},
  []string{"r13", "r13D", "r13W", "r13B"},
  []string{"r12", "r12D", "r12W", "r12B"},
  []string{"r11", "r11D", "r11W", "r11B"},
}
@(private)
sys_reg_offset := [?]int{-1, 0, 0, 3}
@(private)
conv_list := [?]string{"none", "QWORD", "QWORD", "BYTE"}
@(private)
open_bracket := [?]byte{'[', ' '}
close_bracket := [?]byte{'}', ' '}

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

  fmt.sbprintf(b, "cmp_0 : dq 0\n")
  fmt.sbprintf(b, "tmp_0 : dq 0\n\n")
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

      case .n_none:
        fmt.eprintln(
          "this should not have happened but a variable has the type none, we are fucked",
        )
        os.exit(1)
      }
      // cm.builder_append_string(b, "\n")

    }
  }

}

generate_blocks :: proc(b: ^strings.Builder, instrs: []cm.n_instrs) {
  for instr in instrs {
    if instr.instr == .block {
      fmt.sbprintf(b, "block_%d:\n", instr.offset)

      generate_instr(b, instr.params[:])

      fmt.sbprintf(b, "  ret\n")
    }
  }
}

// TODO: printf only supportd 32bit ints minimum
generate :: proc(instrs: []cm.n_instrs) -> string {
  res: strings.Builder

  generate_fluf_start(&res)
  generate_vars(&res, instrs)


  cm.builder_append_string(&res, "section '.text' executable\n")

  generate_blocks(&res, instrs)

  cm.builder_append_string(&res, "public main\n")
  cm.builder_append_string(&res, "main:\n")

  generate_instr(&res, instrs)

  cm.builder_append_string(&res, "  mov rax, 0\n")
  cm.builder_append_string(&res, "  ret\n")


  fmt.println(string(res.buf[:]))
  // os.exit(1)
  return string(res.buf[:])
}


get_arg_num_from_call :: proc(instrs: []cm.n_instrs) -> int {
  arg_num := 0

  for ins in instrs {
    if len(ins.params) != 0 {
      arg_num += get_arg_num_from_call(ins.params[:])
    }

    if ins.instr == .push || ins.instr == .load || ins.instr == .deref {
      arg_num += 1
    }

  }

  return arg_num
}

// r15: ops
// r13: used for derefrencing 
// r12, r11: one of stuff like comparisons
generate_instr :: proc(
  b: ^strings.Builder,
  instrs: []cm.n_instrs,
  parent_ptr: ^cm.n_instrs = nil,
) {
  pptr := parent_ptr != nil
  // fmt.println("---------------------------------")
  for &instr, i in instrs {
    // cm.print_instrs(instrs[i:i + 1])

    #partial switch instr.instr {
    case .extrn:
      if instr.optional == "" do instr.optional = instr.name
      fmt.sbprintf(b, "  extrn '%s' as _%s\n", instr.optional, instr.name)
      fmt.sbprintf(b, "  %s = PLT _%s\n", instr.name, instr.name)

    case .assign:
      generate_instr(b, instr.params[:], &instr)

    case .sub:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -11
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  sub %s%c%s_%d%c, %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
          syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
        )

      } else {
        assert(false, "sub pushed")
      }


    case .add:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -11
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  add %s%c%s_%d%c, %s\n",
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
          syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
        )

      } else {
        assert(false, "add pushed")
      }

    case .mult:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -11
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  imul %s, %s%c%s_%d%c\n",
          syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
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
          syscall_reg_list[9][sys_reg_offset[auto_cast instr.type]],
        )

      } else {
        assert(false, "mult pushed")
      }

    case .div:
      if pptr {
        instr.name = ""
        instr.type = parent_ptr.type
        instr.offset = -2
        fmt.sbprintf(b, "  push rax\n")
        generate_instr(b, instr.params[:], &instr)
        fmt.sbprintf(
          b,
          "  xchg %s, %s%c%s_%d%c\n",
          syscall_reg_list[0][sys_reg_offset[auto_cast instr.type]],
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
          syscall_reg_list[0][sys_reg_offset[auto_cast instr.type]],
          conv_list[auto_cast parent_ptr.type],
          parent_ptr.ptr ? ' ' : '[',
          parent_ptr.name,
          parent_ptr.offset,
          parent_ptr.ptr ? ' ' : ']',
        )
        fmt.sbprintf(b, "  pop rax\n")


      } else {
        assert(false, "div pushed")
      }

      // fmt.println(string(b.buf[:]))

      // os.exit(1)


    case .push:
      if pptr {
        if parent_ptr.offset < 0 {
          if parent_ptr.offset < -1 {
            fmt.sbprintf(
              b,
              "  mov %s, %d\n",
              syscall_reg_list[-parent_ptr.offset - 2][0],
              instr.val,
            )
            parent_ptr.offset -= 1
          } else {
            fmt.sbprintf(b, "  mov %s, %d\n", parent_ptr.name, instr.val)
          }
        } else {
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
        }

      } else {
        fmt.sbprintf(b, "  push %d\n", instr.val)
      }

    case .load:
      if pptr {
        if parent_ptr.offset < 0 {

          if parent_ptr.offset < -1 {
            fmt.sbprintf(
              b,
              "  xor %s, %s\n  mov %s, %c%s_%d%c\n",
              syscall_reg_list[-parent_ptr.offset - 2][0],
              syscall_reg_list[-parent_ptr.offset - 2][0],
              syscall_reg_list[-parent_ptr.offset - 2][instr.ptr ? 0 : sys_reg_offset[auto_cast instr.type]],
              // conv_list[instr.ptr ? 1 : int(instr.type)],
              instr.ptr ? ' ' : '[',
              instr.name,
              instr.offset,
              instr.ptr ? ' ' : ']',
            )
            parent_ptr.offset -= 1
          } else {

            fmt.sbprintf(
              b,
              "  mov %s, %s_%d\n",
              parent_ptr.name,
              // conv_list[auto_cast instr.type],
              instr.name,
              instr.offset,
            )
          }
        } else {
          unreachable()
        }

      } else {
        fmt.sbprintf(
          b,
          "  push [%s]%s_%d\n",
          conv_list[auto_cast instr.type],
          instr.name,
          instr.offset,
        )
      }


    case .label:
      fmt.sbprintf(b, "label_s_%d:\n", instr.offset)

    case .jmp:
      fmt.sbprintf(b, "  jmp label_s_%d\n", instr.offset)


    case .call:
      arg_num := get_arg_num_from_call(instr.params[:])
      call_name := instr.name
      instr.name = "reg"
      instr.offset = -2
      generate_instr(b, instr.params[:], &instr)
      // for i in 0 ..< arg_num {

      //   // fmt.sbprintf(b, "  pop %s\n", syscall_reg_list[arg_num - i - 1])
      // }
      fmt.sbprintf(b, "  call %s\n", call_name)


    case .nothing:

    case:
      fmt.print("curent state: \n", string(b.buf[:]))
      fmt.println("-------------------------------------------")

      fmt.eprintln("unimplemented", instr.instr)
      os.exit(1)

    }

    // os.exit(1)

  }


  // for &instr, i in instrs {
  //   if len(instr.params) != 0 && instr.instr != .block do generate_instr(b, instr.params[:])

  //   if len(instr.params) == 0 && instr.instr == .store do continue

  //   #partial switch instr.instr {
  //   case .block:
  //     fmt.sbprintf(b, "  call block_%d\n", instr.offset)
  //   case .call:
  //     arg_num := get_arg_num_from_call(instr.params[:])

  //     for i in 0 ..< arg_num {
  //       fmt.sbprintf(b, "  pop %s\n", syscall_reg_list[arg_num - i - 1])
  //     }
  //     fmt.sbprintf(b, "  call %s\n", instr.name)

  //   case .extrn:
  //     if instr.optional == "" do instr.optional = instr.name
  //     fmt.sbprintf(b, "  extrn '%s' as _%s\n", instr.optional, instr.name)
  //     fmt.sbprintf(b, "  %s = PLT _%s\n", instr.name, instr.name)

  //   // case .eq:
  //   //   fmt.sbprintf(b, "  pop r12\n") // num2
  //   //   fmt.sbprintf(b, "  pop r11\n") // num1
  //   //   fmt.sbprintf(b, "  cmp r11, r12\n") // num1 < = > num2
  //   //   fmt.sbprintf(b, "  je cmp_label_true_%d\n", counter)
  //   //   fmt.sbprintf(b, "  mov QWORD[cmp_store], 1\n")
  //   //   fmt.sbprintf(b, "  jmp cmp_label_false_%d\n", counter)
  //   //   fmt.sbprintf(b, "cmp_label_true_%d:\n", counter)
  //   //   fmt.sbprintf(b, "  mov QWORD[cmp_store], 0\n")
  //   //   fmt.sbprintf(b, "cmp_label_false_%d:\n", counter)
  //   //   counter += 1
  //   case .noteq:
  //     fmt.sbprintf(b, "  pop r12\n") // num2
  //     fmt.sbprintf(b, "  pop r11\n") // num1
  //     fmt.sbprintf(b, "  cmp r11, r12\n") // num1 < = > num2
  //     fmt.sbprintf(b, "  setne BYTE[cmp_s]\n") // num1 < = > num2

  //     // fmt.sbprintf(b, "  jne cmp_label_true_%d\n", counter)
  //     // fmt.sbprintf(b, "  push 0\n")
  //     // fmt.sbprintf(b, "  jmp cmp_label_false_%d\n", counter)
  //     // fmt.sbprintf(b, "cmp_label_true_%d:\n", counter)
  //     // fmt.sbprintf(b, "  push 1\n")
  //     // fmt.sbprintf(b, "cmp_label_false_%d:\n", counter)
  //     counter += 1
  //   case .jmp:
  //     fmt.sbprintf(b, "  jmp label_s_%d\n", instr.offset)
  //   case .if_:
  //     fmt.sbprintf(b, "  cmp BYTE[cmp_s], 0\n")
  //     fmt.sbprintf(b, "  je label_s_%d\n", instr.offset)
  //   case .label:
  //     fmt.sbprintf(b, "label_s_%d:\n", instr.offset)
  //   case .push:
  //     fmt.sbprintf(b, "  push %d\n", instr.val)
  //   case .add:
  //     if instr.name == "" {
  //       fmt.sbprintf(b, "  pop r15\n")
  //       fmt.sbprintf(b, "  pop r14\n")
  //       fmt.sbprintf(b, "  add r15, r14\n")
  //       fmt.sbprintf(b, "  push r15\n")
  //     } else {
  //       fmt.sbprintf(b, "  pop r15\n")
  //       fmt.sbprintf(b, "  pop r14\n")
  //       fmt.sbprintf(b, "  add r15, r14\n")
  //       fmt.sbprintf(b, "  push r15\n")
  //     }
  //   case .sub:
  //     if instr.name == "" {
  //       fmt.sbprintf(b, "  pop r15\n")
  //       fmt.sbprintf(b, "  sub r15, %d\n", instr.val)
  //       fmt.sbprintf(b, "  push r15\n")
  //     } else {
  //       fmt.sbprintf(b, "  pop r15\n")
  //       fmt.sbprintf(b, "  pop r14\n")
  //       fmt.sbprintf(b, "  sub r15, r14\n")
  //       fmt.sbprintf(b, "  push r15\n")
  //     }
  //   case .mult:
  //     fmt.sbprintf(b, "  mov r14, rax\n")

  //     fmt.sbprintf(b, "  pop rax\n")
  //     fmt.sbprintf(b, "  mov r15, %d\n", instr.val)
  //     fmt.sbprintf(b, "  mul r15\n")
  //     fmt.sbprintf(b, "  push rax\n")

  //     fmt.sbprintf(b, "  mov rax, r14\n")

  //   case .div:
  //     fmt.sbprintf(b, "  mov r15, rax\n")
  //     fmt.sbprintf(b, "  mov r14, rdx\n")

  //     fmt.sbprintf(b, "  pop rax\n")
  //     fmt.sbprintf(b, "  mov r13, %d\n", instr.val)

  //     fmt.sbprintf(b, "  xor rdx, rdx\n")
  //     fmt.sbprintf(b, "  div r13\n")

  //     fmt.sbprintf(b, "  push rax\n")

  //     fmt.sbprintf(b, "  mov rax, r15\n")
  //     fmt.sbprintf(b, "  mov rdx, r14\n")
  //   case .store:
  //     fmt.sbprintf(b, "  pop QWORD[%s_%d]\n", instr.name, instr.offset)
  //   case .assign:
  //     if auto_cast instr.offset > instr.type_num - 1 {
  //       fmt.eprintln(
  //         "tried to access an array outside of its bounds please reconsider your life choices",
  //       )
  //       os.exit(1)
  //     }
  //     fmt.sbprintf(b, "  pop QWORD[%s_%d]\n", instr.name, instr.offset)
  //   case .load:
  //     brack := []byte{'[', ' '}
  //     brack2 := []byte{']', ' '}
  //     fmt.sbprintf(
  //       b,
  //       "  push QWORD%c%s_%d%c\n",
  //       brack[cast(int)instr.ptr],
  //       instr.name,
  //       instr.offset,
  //       brack2[cast(int)instr.ptr],
  //     )
  //   case .deref:
  //     fmt.sbprintf(b, "  mov r13, QWORD [%s_%d]\n", instr.name, instr.offset)
  //     fmt.sbprintf(b, "  push QWORD[r13]\n")
  //   case .syscall:
  //     arg_num := get_arg_num_from_call(instr.params[:])

  //     for i in 0 ..< arg_num {
  //       fmt.sbprintf(b, "  pop %s\n", syscall_reg_list[arg_num - i - 1])
  //     }
  //     fmt.sbprintf(b, "  syscall\n")
  //   case .nothing:
  //   case:
  //     fmt.print("curent state: \n", string(b.buf[:]))
  //     fmt.println("-------------------------------------------")
  //     fmt.eprintln("unimplemented", instr.instr)
  //     cm.print_instrs(instrs)
  //     os.exit(1)
  //   }
  // }

  // fmt.sbprintf(b, ";----------------------\n")


}
