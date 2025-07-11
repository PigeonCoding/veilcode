package veilcode_fasm_x86_64_cc_linux

import cm "../../common"
import "core:fmt"
import "core:os"
import "core:strings"

@(private)
counter := 0

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

  cm.builder_append_string(b, "section '.text' executable\n")
  cm.builder_append_string(b, "public main\n")
  cm.builder_append_string(b, "main:\n")
}

generate_fluf_end :: proc(b: ^strings.Builder, instrs: []cm.n_instrs) {
  
  cm.builder_append_string(b, "section '.data' writable\n")

  fmt.sbprintf(b, "cmp_store: db 1 dup(0)\n")
  for instr in instrs {
    if instr.instr == .store {
      cm.builder_append_string(b, instr.name)
      switch instr.type {
      case .n_char:
        fmt.sbprintf(b, ": db %d dup(0)", instr.type_num)
      case .n_int, .n_ptr:
        fmt.sbprintf(b, ": dq %d dup(0)", instr.type_num)
      case .n_none:
        fmt.eprintln(
          "this should not have happened but a variable has the type none, we are fucked",
        )
        os.exit(1)
      }
      cm.builder_append_string(b, "\n")

    }
  }

}


generate :: proc(instrs: []cm.n_instrs) -> string {
  res: strings.Builder

  generate_fluf_start(&res)

  generate_instr(instrs, &res)
  cm.builder_append_string(&res, "  mov rax, 0\n")
  cm.builder_append_string(&res, "  ret\n")

  generate_fluf_end(&res, instrs)

  fmt.println(string(res.buf[:]))
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

// r15 r14: used when doing math stuff
// r13: used for derefrencing
// r12, r11: one of stuff like comparisons (comp chaining isn't implemented yet)
// 
// TODO: maybe to it from memory 
generate_instr :: proc(instrs: []cm.n_instrs, b: ^strings.Builder) {
  syscall_reg_list := [?]string{"rax", "rdi", "rsi", "rdx", "r10", "r8", "r9"}
  for instr in instrs {
    if len(instr.params) != 0 do generate_instr(instr.params[:], b)

    if len(instr.params) == 0 && instr.instr == .store do continue

    #partial switch instr.instr {
    case .eq:
      fmt.sbprintf(b, "  pop r12\n") // num2
      fmt.sbprintf(b, "  pop r13\n") // num1
      fmt.sbprintf(b, "  cmp r13, r12\n") // num1 < = > num2
      fmt.sbprintf(b, "  je cmp_label_true_%d\n", counter)
      fmt.sbprintf(b, "  mov QWORD[cmp_store], 1\n")
      fmt.sbprintf(b, "  jmp cmp_label_false_%d\n", counter)
      fmt.sbprintf(b, "cmp_label_true_%d:\n", counter)
      fmt.sbprintf(b, "  mov QWORD[cmp_store], 0\n")
      fmt.sbprintf(b, "cmp_label_false_%d:\n", counter)
      counter += 1
    case .noteq:
      fmt.sbprintf(b, "  pop r12\n") // num2
      fmt.sbprintf(b, "  pop r13\n") // num1
      fmt.sbprintf(b, "  cmp r13, r12\n") // num1 < = > num2
      fmt.sbprintf(b, "  jne cmp_label_true_%d\n", counter)
      fmt.sbprintf(b, "  mov QWORD[cmp_store], 1\n")
      fmt.sbprintf(b, "  jmp cmp_label_false_%d\n", counter)
      fmt.sbprintf(b, "cmp_label_true_%d:\n", counter)
      fmt.sbprintf(b, "  mov QWORD[cmp_store], 0\n")
      fmt.sbprintf(b, "cmp_label_false_%d:\n", counter)
      counter += 1
    case .jmp:
      fmt.sbprintf(b, "  jmp label_s_%d\n", instr.offset)
    case .if_:
      fmt.sbprintf(b, "  mov r13, 1\n")
      fmt.sbprintf(b, "  cmp r13, [cmp_store]\n")
      fmt.sbprintf(b, "  je label_s_%d\n", instr.offset)
    case .label:
      fmt.sbprintf(b, "label_s_%d:\n", instr.offset)
    case .push:
      fmt.sbprintf(b, "  push %d\n", instr.val)
    case .add:
      if instr.name == "" {
        fmt.sbprintf(b, "  pop r15\n")
        fmt.sbprintf(b, "  add r15, %d\n", instr.val)
        fmt.sbprintf(b, "  push r15\n")
      } else {
        fmt.sbprintf(b, "  pop r15\n")
        fmt.sbprintf(b, "  pop r14\n")
        fmt.sbprintf(b, "  add r15, r14\n")
        fmt.sbprintf(b, "  push r15\n")
      }
    case .sub:
      if instr.name == "" {
        fmt.sbprintf(b, "  pop r15\n")
        fmt.sbprintf(b, "  sub r15, %d\n", instr.val)
        fmt.sbprintf(b, "  push r15\n")
      } else {
        fmt.sbprintf(b, "  pop r15\n")
        fmt.sbprintf(b, "  pop r14\n")
        fmt.sbprintf(b, "  sub r15, r14\n")
        fmt.sbprintf(b, "  push r15\n")
      }
    case .mult:
      fmt.sbprintf(b, "  mov r14, rax\n")

      fmt.sbprintf(b, "  pop rax\n")
      fmt.sbprintf(b, "  mov r15, %d\n", instr.val)
      fmt.sbprintf(b, "  mul r15\n")
      fmt.sbprintf(b, "  push rax\n")

      fmt.sbprintf(b, "  mov rax, r14\n")

    case .div:
      fmt.sbprintf(b, "  mov r15, rax\n")
      fmt.sbprintf(b, "  mov r14, rdx\n")

      fmt.sbprintf(b, "  pop rax\n")
      fmt.sbprintf(b, "  mov r13, %d\n", instr.val)

      fmt.sbprintf(b, "  xor rdx, rdx\n")
      fmt.sbprintf(b, "  div r13\n")

      fmt.sbprintf(b, "  push rax\n")

      fmt.sbprintf(b, "  mov rax, r15\n")
      fmt.sbprintf(b, "  mov rdx, r14\n")
    case .store:
      fmt.sbprintf(b, "  pop QWORD[%s + %d]\n", instr.name, instr.offset)
    case .assign:
      if auto_cast instr.offset > instr.type_num - 1 {
        fmt.eprintln(
          "tried to access an array outside of its bounds please reconsider your life choices",
        )
        os.exit(1)
      }
      fmt.sbprintf(b, "  pop QWORD[%s + %d]\n", instr.name, instr.offset)
    case .load:
      brack := []byte{'[', ' '}
      brack2 := []byte{']', ' '}
      fmt.sbprintf(
        b,
        "  push QWORD%c%s + %d%c\n",
        brack[cast(int)instr.ptr],
        instr.name,
        instr.offset,
        brack2[cast(int)instr.ptr],
      )
    case .deref:
      fmt.sbprintf(b, "  mov r13, QWORD [%s + %d]\n", instr.name, instr.offset)
      fmt.sbprintf(b, "  push QWORD[r13]\n")
    case .syscall:
      arg_num := get_arg_num_from_call(instr.params[:])

      for i in 0 ..< arg_num {
        fmt.sbprintf(b, "  pop %s\n", syscall_reg_list[arg_num - i - 1])
      }
      fmt.sbprintf(b, "  syscall\n")
    case .nothing:
    case:
      fmt.print("curent state: \n", string(b.buf[:]))
      fmt.println("-------------------------------------------")
      fmt.eprintln("unimplemented", instr.instr)
      fmt.println(instrs)
      os.exit(1)
    }
  }

  // fmt.sbprintf(b, ";----------------------\n")


}
