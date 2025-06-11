package builder

import "core:os/os2"
import "core:fmt"

DEBUG :: true

build_stb_c_lexer :: proc() {
  if ODIN_OS == .Linux {
    if exec_and_run_sync(
         []string {
           "external/tcc_linux",
           "-x",
           "c",
           "-c",
           "-g",
           "../thirdparty/stb_c_lexer/stb_c_lexer.h",
           "-o",
           "../thirdparty/stb_c_lexer/stb_c_lexer_linux64.o",
           "-DSTB_C_LEXER_IMPLEMENTATION",
         },
       ) !=
       nil {
      os2.exit(1)
    }
  } else {
    fmt.eprintln("fuck windows")
    os2.exit(1)
  }
}

main :: proc() {
  b: odin_cmd_builder
  b.main_cmd = .build
  if ODIN_OS == .Linux {
    b.flags.out = "veilcode"
  } else {
    fmt.println("unsupported os", ODIN_OS)
    os2.exit(1)
  }
  b.directory = "."
  b.flags.thread_count = 4
  if DEBUG {
    b.flags.debug = true
  } else {
    b.flags.optimization = .speed
  }

  cmd := build_cmd(&b)

  if exec_and_run_sync(cmd[:]) != nil do os2.exit(1)

  if exec_and_run_async([]string{"rm", os2.args[0]}) != nil do os2.exit(1)

}