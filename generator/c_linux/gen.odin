package veilcode_c_linux

import cm "../../common"
import "core:fmt"
import "core:strings"

generate :: proc(instrs: []cm.n_instrs) -> string {
  s: strings.Builder

  cm.builder_append_string(&s, "int main(int argc, char** argv) {\n")


  for &instr in instrs {
    if instr.instr == .store {
      // cm.builder_append_string(&s, instr.name)
      switch instr.type {
      case .n_char:
        fmt.sbprintf(&s, "  char %s[%d]", instr.name, instr.type_num)
      case .n_int:
        fmt.sbprintf(&s, "  int %s[%d]", instr.name, instr.type_num)
      case .n_ptr:
        fmt.sbprintf(&s, "  void* %s[%d]", instr.name, instr.type_num)
      // fmt.sbprintf(&s, "int", instr.type_num)
      case .n_none:
        fmt.eprintln(
          "this should not have happened but a variable has the type none we are fucked",
        )
      // os.exit(1)
      }

      cm.builder_append_string(&s, ";\n")
      instr.instr = .assign

    }
  }

  // fmt.println(instrs)

  generate_instrs(instrs, &s)
  cm.builder_append_string(&s, "  return 0;\n")
  cm.builder_append_string(&s, ";\n")
  cm.builder_append_string(&s, "}")

  fmt.println(string(s.buf[:]))
  // fmt.assertf(false, "not now")

  return string(s.buf[:])
}

@(private)
generate_instrs :: proc(instrs: []cm.n_instrs, s: ^strings.Builder) {

  for ins in instrs {
    #partial switch ins.instr {
    case .store, .assign:
      fmt.sbprint(s, ";\n")
      if len(ins.params) != 0 {
        fmt.sbprintf(s, "  %s[%d] = ", ins.name, ins.offset)
      }
    case .push:
      fmt.sbprintf(s, "%d ", ins.val)
    case .load:
      if ins.ptr {
        fmt.sbprint(s, "&")
      }
      fmt.sbprintf(s, "%s[%d] ", ins.name, ins.offset)
    case .add:
      if ins.val != 0 do fmt.sbprintf(s, "+ %d ", ins.val)
      else do fmt.sbprint(s, "+ ")
    case .sub:
      if ins.val != 0 do fmt.sbprintf(s, "- %d ", ins.val)
      else do fmt.sbprint(s, "- ")
    case .mult:
      if ins.val != 0 do fmt.sbprintf(s, "* %d ", ins.val)
      else do fmt.sbprint(s, "* ")
    case .div:
      if ins.val != 0 do fmt.sbprintf(s, "/ %d ", ins.val)
      else do fmt.sbprint(s, "/ ")
    case .jmp:
    case .deref:
      fmt.println(ins)
    case .nothing:
    case .call:
      case .syscall:
      fmt.sbprint(s, ";\n")
      fmt.println("syscall not for now")
      continue
    case .nun:
    }

    if len(ins.params) > 0 {
      generate_instrs(ins.params[:], s)
    }
  }


}
