package naned

import cm "./common"
import f86_64linux "./generator/fasm_x86_64_linux"
import "core:fmt"
import "core:os"
import "core:strings"

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
  to_write: string
  switch target {
  case .fasm_x86_64_linux:
    to_write = f86_64linux.generate(instrs)
  }

  b: strings.Builder
  cm.builder_append_string(&b, to_write)
  delete(to_write)

  res := os.write_entire_file_or_err("./out/test.asm", b.buf[:])
  if res != nil {
    fmt.eprintln(res)
    os.exit(1)
  }

}
