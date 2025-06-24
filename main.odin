package veilcode

import cm "./common"
import c_linux "./generator/c_linux"
import f86_64linux "./generator/fasm_x86_64_linux"
import f86_64tlinux "./generator/fasm_x86_64_tcc_linux"
import bd "./out"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:reflect"
import "core:strings"
import fg "thirdparty/flags_odin"


target_enum :: enum {
  none, // TODO: temporary will remove later when os detection is implemented
  f86_64linux,
  c_linux,
  c_win64,
  f86_64tlinux,
}
target: target_enum = .f86_64linux

file_out := "nn_out"
root_path := "."

prt_usage :: proc(program_name: string, fl_cont: ^(fg.flag_container)) {
  fmt.println("Usage:", program_name, "file.nn <flags>")
  fg.print_usage(fl_cont)
}

BUILD :: true

main :: proc() {

  if ODIN_OS != .Linux && ODIN_OS != .Windows {
    assert(false, "not implemented for platforms that are not linux yet")
  }

  nostd := false

  fl_cont: fg.flag_container
  fg.add_flag(&fl_cont, "target", "", "sets the desired target (-target list for all the targets)")
  fg.add_flag(&fl_cont, "h", false, "shows this message")
  fg.add_flag(&fl_cont, "out", "", "sets the name dor the output file")
  fg.add_flag(&fl_cont, "nostd", false, "disables the standard lib")
  fg.add_flag(&fl_cont, "root_path", "", "sets a custom path for the root folder of veilcode")

  fg.init_container(&fl_cont)

  fg.check_flags(&fl_cont)
  program_name := fl_cont.remaining[0]
  fl_cont.remaining = fl_cont.remaining[1:]

  if fg.get_flag_value(&fl_cont, "h") != nil {
    prt_usage(program_name, &fl_cont)
  }

  if target_selected := fg.get_flag_value(&fl_cont, "target"); target_selected != nil {
    switch (cast(^string)target_selected)^ {
    case "list":
      for t in reflect.enum_field_names(target_enum) {
        if t != "none" do fmt.println(t)
      }
      os.exit(0)
    case "fasm_x86_64_linux":
      target = .f86_64linux
    case "c_linux":
      target = .c_linux
    case "fasm_x86_64_tcc_linux":
      target = .f86_64tlinux
    case "c_win64":
      target = .c_win64
    }
  }

  if out := fg.get_flag_value(&fl_cont, "out"); out != nil {
    file_out = (cast(^string)out)^
  }

  if fg.get_flag_value(&fl_cont, "nostd") != nil {
    nostd = true
  }

  if root := fg.get_flag_value(&fl_cont, "root_path"); root != nil {
    root_path = (cast(^string)root)^
  }

  files_to_parse: [dynamic]string
  if !nostd {
    switch target {
    case .none:
      fmt.assertf(false, "shouldn't happen")
    case .f86_64linux:
      append(&files_to_parse, strings.concatenate({root_path, "/std", "/linux_std.nn"}))
    case .c_linux:
      append(&files_to_parse, strings.concatenate({root_path, "/std", "/linux_std.nn"}))
    case .f86_64tlinux:
      append(&files_to_parse, strings.concatenate({root_path, "/std", "/linux_std.nn"}))
    case .c_win64:
      append(&files_to_parse, strings.concatenate({root_path, "/std", "/linux_std.nn"}))
    }
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

  pros: os2.Process_Desc
  to_write: string
  switch target {
  case .none:
    fmt.assertf(false, "shouldn't happen")
  case .f86_64linux:
    to_write = f86_64linux.generate(instrs)
  case .c_linux:
    to_write = c_linux.generate(instrs)
  case .f86_64tlinux:
    to_write = f86_64tlinux.generate(instrs)
  case .c_win64:
    to_write = c_linux.generate(instrs)
  }

  b: strings.Builder
  cm.builder_append_string(&b, to_write)
  delete(to_write)

  if ODIN_OS == .Windows {
    res := os.write_entire_file_or_err(strings.concatenate({file_out, ".c"}), b.buf[:])
    if res != nil {
      fmt.eprintln(res)
      os.exit(1)
    }
  } else {
    res := os.write_entire_file_or_err(file_out, b.buf[:])
    if res != nil {
      fmt.eprintln(res)
      os.exit(1)
    }
  }


  if BUILD {
    switch target {
    case .none:
      fmt.assertf(false, "shouldn't happen")
    case .f86_64linux:
      if bd.exec_and_run_sync([]string{strings.concatenate([]string{root_path, "/external/linux/fasm_linux"}), file_out}) != nil do os.exit(1)
      if bd.exec_and_run_sync([]string{"chmod", "+x", file_out}) != nil do os.exit(1)
    case .c_linux:
      if bd.exec_and_run_sync([]string{strings.concatenate([]string{root_path, "/external/linux/tcc/bin/tcc"}), "-g", file_out, "-o", file_out}) != nil do os.exit(1)
    case .f86_64tlinux:
      fmt.println("hi")
      if bd.exec_and_run_sync([]string{strings.concatenate([]string{root_path, "/external/linux/fasm_linux"}), file_out}) != nil do os.exit(1)
      if bd.exec_and_run_sync([]string{strings.concatenate([]string{root_path, "/external/linux/tcc/bin/tcc"}), "-g", strings.concatenate({file_out, ".o"}), "-o", file_out, strings.concatenate({"-L", root_path, "/external/linux/tcc/lib/tcc"})}) != nil do os.exit(1)
    case .c_win64:
      // fmt.assertf(false, "will have to rewrite stb_c_lexer in odin fot it to work")
      fmt.println(file_out)
      if bd.exec_and_run_sync([]string{strings.concatenate([]string{root_path, "/external/win64/tcc/tcc.exe"}), strings.concatenate({file_out, ".c"}), "-g", "-o", file_out, strings.concatenate({"-L", root_path, "/external/linux/tcc/tcc/lib/tcc"})}) != nil do os.exit(1)
    }
  }
}
