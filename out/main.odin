package builder

import "core:fmt"
import "core:os/os2"
import "core:strings"

DEBUG := true

build_stb_c_lexer :: proc() {
  if ODIN_OS == .Linux {
    if err := exec_and_run_sync(
    []string {
      // "external/linux/tcc/bin/tcc",
      "cc",
      "-x",
      "c",
      "-c",
      "-g",
      "thirdparty/stb_c_lexer/stb_c_lexer.h",
      "-o",
      "thirdparty/stb_c_lexer/stb_c_lexer_linux64.o",
      "-DSTB_C_LEXER_IMPLEMENTATION",
    },
    ); err != nil {
      fmt.println(err)
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
    b.flags.out = "out/veilcode"
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
  build_stb_c_lexer()
  if exec_and_run_sync(cmd[:]) != nil do os2.exit(1)
  if exec_and_run_sync([]string{"chmod", "+x", strings.concatenate({b.directory, "/", b.flags.out})}) != nil do os2.exit(1)

  if ODIN_OS == .Windows {
    if exec_and_run_async([]string{"rm", os2.args[0]}) != nil do os2.exit(1)
  }
}
