package naned

import "core:fmt"
import "core:os"
import "core:strings"
import f86_64linux "./generator/fasm_x86_64_linux"

target_enum :: enum {
  fasm_x86_64_linux,
}
target: target_enum = .fasm_x86_64_linux


main :: proc() {

  if ODIN_OS != .Linux {
    assert(false, "not implemented for platforms that are not linux")
  }

  instrs := parse({"std.nn", "test.nn"})
  // fmt.println(instrs)
  switch target {
  case .fasm_x86_64_linux:
    fmt.println(f86_64linux.generate(instrs))
  }

}
