package veilcode

import cm "./common"
import c_linux "./generator/c_linux"
import f86_64linux "./generator/fasm_x86_64_linux"
import f86_64tlinux "./generator/fasm_x86_64_tcc_linux"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:reflect"
import "core:strings"
import fg "thirdparty/flags_odin"

target_enum :: enum {
  none, // TODO: temporary will remove later when os detection is implemented
  fasm_x86_64_linux,
  c_linux,
  c_win64,
  fasm_x86_64_tcc_linux, // broken for now TODO: make work
}
target: target_enum = .fasm_x86_64_linux

exec_and_run_sync :: proc(cmd: []string) -> Maybe(os2.Error) {

  procc: os2.Process_Desc
  procc.stderr = os2.stderr
  procc.stdout = os2.stdout
  procc.env = nil
  procc.working_dir = ""

  fmt.println("[CMD]:", cmd)

  procc.command = cmd
  p, err := os2.process_start(procc)
  if err != nil do return err
  _, err = os2.process_wait(p)
  if err != nil do return err
  err = os2.process_close(p)
  if err != nil do return err

  return nil
}

file_out := "nn_out"

prt_usage :: proc(program_name: string, fl_cont: ^(fg.flag_container)) {
  fmt.println("Usage:", program_name, "file.nn <flags>")
  fg.print_usage(fl_cont)
}

main :: proc() {

  if ODIN_OS != .Linux && ODIN_OS != .Windows {
    assert(false, "not implemented for platforms that are not linux yet")
  }

  nostd := false

  fl_cont: fg.flag_container
  fg.add_flag(
    &fl_cont,
    "target",
    "arch",
    "sets the desired target (-target list for all the targets)",
  )
  fg.add_flag(&fl_cont, "h", false, "shows this message")
  fg.add_flag(&fl_cont, "out", "", "sets the name dor the output file")
  fg.add_flag(&fl_cont, "nostd", false, "disables the standard lib")


  fg.check_flags(&fl_cont)
  program_name := fl_cont.remaining[0]
  fl_cont.remaining = fl_cont.remaining[1:]

  // fmt.println(fl_cont)

  for f in fl_cont.parsed_flags {
    switch f.flag {
    case "h":
      prt_usage(program_name, &fl_cont)
      os.exit(0)
    case "target":
      switch f.value {
      case "list":
        for t in reflect.enum_field_names(target_enum) {
          if t != "none" do fmt.println(t)
        }
        os.exit(0)
      case "fasm_x86_64_linux":
        target = .fasm_x86_64_linux
      case "c_linux":
        target = .c_linux
      case "fasm_x86_64_tcc_linux":
        target = .fasm_x86_64_tcc_linux
      case "c_win64":
        target = .c_win64
      }

    case "out":
      file_out = f.value.(string)
    case "nostd":
      nostd = true
    }

  }

  files_to_parse: [dynamic]string
  switch target {
  case .fasm_x86_64_linux:
    append(&files_to_parse, "std/linux_std.nn")
  case .none:
    fmt.assertf(false, "shouldn't happen")
  case .c_linux:
    append(&files_to_parse, "std/linux_std.nn")
  case .fasm_x86_64_tcc_linux:
    append(&files_to_parse, "std/linux_std.nn")
  case .c_win64:
    append(&files_to_parse, "std/linux_std.nn")
  // nostd = true
  }

  for n in fl_cont.remaining {
    if n == "---" do break

    if strings.starts_with(n, "-") {
      fmt.eprintln("unknown flag", n)
      prt_usage(program_name, &fl_cont)
      os.exit(1)
    }

    if strings.ends_with(n, ".nn") {
      append(&files_to_parse, n)
    } else {
      fmt.eprintln("unknown file extention for", n, "skipping")
    }
  }

  if (nostd && len(files_to_parse) == 0) || (!nostd && len(files_to_parse) == 1) {
    fmt.eprintln("no file provided")
    prt_usage(program_name, &fl_cont)
    os.exit(1)
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
  case .c_linux:
    to_write = c_linux.generate(instrs)
  case .fasm_x86_64_tcc_linux:
    to_write = f86_64tlinux.generate(instrs)
  case .c_win64:
    to_write = c_linux.generate(instrs)
  }

  b: strings.Builder
  cm.builder_append_string(&b, to_write)
  delete(to_write)

  res := os.write_entire_file_or_err(file_out, b.buf[:])
  if res != nil {
    fmt.eprintln(res)
    os.exit(1)
  }


  switch target {
  case .none:
    fmt.assertf(false, "shouldn't happen")
  case .fasm_x86_64_linux:
    if exec_and_run_sync([]string{"external/fasm_linux", file_out}) != nil do os.exit(1)
    if exec_and_run_sync([]string{"chmod", "+x", file_out}) != nil do os.exit(1)
  case .c_linux:
    if exec_and_run_sync([]string{"external/tcc_linux", "-g", file_out, "-o", file_out}) != nil do os.exit(1)
  case .fasm_x86_64_tcc_linux:
    if exec_and_run_sync([]string{"external/fasm_linux", file_out}) != nil do os.exit(1)
    if exec_and_run_sync([]string{"external/tcc_linux", strings.concatenate({file_out, ".o"}), "-g", "-o", file_out}) != nil do os.exit(1)
  case .c_win64:
    fmt.assertf(false, "will have to rewrite stb_c_lexer in odin fot it to work")
    if exec_and_run_sync([]string{"external/tcc_win64.exe", file_out, "-g", "-o", file_out}) != nil do os.exit(1)
  }
}
