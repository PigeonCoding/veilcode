package naned

import "core:fmt"
import "core:os"
import "core:strings"

builder_append_string :: proc(b: ^strings.Builder, str: string) {
  for s in str {
    if s < 255 do append(&b.buf, auto_cast s)
    else {
      fmt.eprintln("there was a non ascii character in the file")
      os.exit(1)
    }
  }
}

// NOTE: linux x86_64 calling convention
//   ints:   RDI, RSI, RDX, RCX, R8, and R9 
//   floats: XMM0 to XMM7
//   ret:    RAX for int XMM0 for float
generate_fasm_x86_64_linux :: proc(instrs: []n_instrs, store_num: int) -> string {
  res: strings.Builder
  builder_append_string(&res, "format ELF64\n")

  builder_append_string(&res, "section \".text\" executable\n")
  builder_append_string(&res, "public main\n")
  // builder_append_string(&res, "public _start\n")
  builder_append_string(&res, "main:\n")
  // builder_append_string(&res, "_start:\n")


  generate_fasm_x86_64_linux_instr(instrs, &res)

  builder_append_string(&res, "  mov rax, 60\n")
  builder_append_string(&res, "  mov rdi, 0\n")
  builder_append_string(&res, "  syscall\n")

  builder_append_string(&res, "section \".data\"\n")
  for instr in instrs {
    if instr.instr == .store {
      builder_append_string(&res, instr.name)
      builder_append_string(&res, ": db \"12345678\"\n")
    }
  }

  return string(res.buf[:])
}


get_arg_num_from_call :: proc(instrs: []n_instrs) -> int {
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

tmp: int = 0
generate_fasm_x86_64_linux_instr :: proc(instrs: []n_instrs, b: ^strings.Builder) {
  syscall_reg_list := [?]string{"rax", "rdi", "rsi", "rdx", "r10", "r8", "r9"}
  for instr in instrs {
    if len(instr.params) != 0 {
      generate_fasm_x86_64_linux_instr(instr.params[:], b)
    }

    #partial switch instr.instr {
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
      fmt.sbprintf(b, "  pop QWORD[%s]\n", instr.name)
    case .load:
      fmt.sbprintf(b, "  push QWORD[%s]\n", instr.name)
    // case .compiler_stuff:
    //   tmp = auto_cast instr.val
    case .syscall:
      arg_num := get_arg_num_from_call(instr.params[:])

      for i in 0 ..< arg_num {
        fmt.sbprintf(b, "  pop %s\n", syscall_reg_list[ arg_num - i - 1])
      }
      fmt.sbprintf(b, "  syscall\n")
    case:
      fmt.println("curent state:", string(b.buf[:]))
      fmt.println("-------------------------------------------")
      fmt.eprintln("unimplemented", instr.instr)
      os.exit(1)
    }
  }

  // fmt.sbprintf(b, ";----------------------\n")


}

main :: proc() {

  if ODIN_OS != .Linux {
    assert(false, "not implemented for platforms that are not linux")
  }

  instrs, store_num := parse({"test.nn"})
  // fmt.println(instrs)

  fmt.println(generate_fasm_x86_64_linux(instrs, store_num))

}
