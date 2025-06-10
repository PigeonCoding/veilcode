package naned

import cm "./common"
import f86_64glinux "./generator/fasm_x86_64_gcc_linux"
import f86_64linux "./generator/fasm_x86_64_linux"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:reflect"
import "core:strings"
import fg "thirdparty/flags_odin"

target_enum :: enum {
  none, // TODO: temporary will remove later when os detection is implemented
  fasm_x86_64_linux,
  // fasm_x86_64_gcc_linux, broken for now TODO: make work
}
target: target_enum = .fasm_x86_64_linux

exec_and_run_sync :: proc(cmd: []string) -> Maybe(os2.Error) {

  procc: os2.Process_Desc
  procc.stderr = os2.stderr
  procc.stdout = os2.stdout
  procc.env = nil
  procc.working_dir = ""

  procc.command = cmd
  p, err := os2.process_start(procc)
  if err != nil do return err
  _, err = os2.process_wait(p)
  if err != nil do return err
  err = os2.process_close(p)
  if err != nil do return err

  return nil
}

BUILD_FOLDER :: "./out/"


main :: proc() {

  if ODIN_OS != .Linux {
    assert(false, "not implemented for platforms that are not linux yet")
  }

  fl_cont: fg.flag_container
  fg.add_flag(
    &fl_cont,
    "target",
    "arch",
    "sets the desired target (-target list for all the targets)",
  )
  fg.add_flag(&fl_cont, "h", false, "shows this message")


  fg.check_flags(&fl_cont)
  program_name := fl_cont.remaining[0]
  fl_cont.remaining = fl_cont.remaining[1:]

  for f in fl_cont.parsed_flags {
    switch f.flag {
    case "h":
      fmt.println("Usage:", fl_cont.remaining[0], "file.nn <flags>")
      fg.print_usage(&fl_cont)
    case "target":
      switch f.value {
      case "list":
        for t in reflect.enum_field_names(target_enum) {
          if t != "none" do fmt.println(t)
        }
      case "fasm_x86_64_linux":
        target = .fasm_x86_64_linux
      }
    }
  }

  files_to_parse: [dynamic]string
  switch target {
  case .fasm_x86_64_linux:
    append(&files_to_parse, "std/linux_std.nn")
  case .none:
    fmt.assertf(false, "shouldn't happen")
  // case .fasm_x86_64_gcc_linux:
  }

  for n in fl_cont.remaining {
    if strings.ends_with(n, ".nn") {
      append(&files_to_parse, n)
    } else {
      fmt.eprintln("unknown file extention for", n, "skipping")
    }
  }

  instrs := parse(files_to_parse[:])
  // // fmt.println(instrs)

  pros: os2.Process_Desc
  to_write: string
  switch target {
  case .none:
    fmt.assertf(false, "shouldn't happen")
  case .fasm_x86_64_linux:
    to_write = f86_64linux.generate(instrs)
  // case .fasm_x86_64_gcc_linux:
  //   to_write = f86_64glinux.generate(instrs)
  //   fmt.println("currently f86_64glinux pointers are kinda broken, my bad")
  // os.exit(0)
  }

  b: strings.Builder
  cm.builder_append_string(&b, to_write)
  delete(to_write)

  // TODO: get output file from argv
  res := os.write_entire_file_or_err("./out/test.asm", b.buf[:])
  if res != nil {
    fmt.eprintln(res)
    os.exit(1)
  }


  switch target {
  case .none:
    fmt.assertf(false, "shouldn't happen")
  case .fasm_x86_64_linux:
    if exec_and_run_sync([]string{"fasm", "./out/test.asm"}) != nil do os.exit(1)
  // case .fasm_x86_64_gcc_linux:
  //   if exec_and_run_sync([]string{"fasm", "./out/test.asm"}) != nil do os.exit(1)
  //   if exec_and_run_sync([]string{"cc", "./out/test.o", "-g", "-no-pie", "-o", "out/test"}) != nil do os.exit(1)
  }
}
