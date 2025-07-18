package veilcode_common

import "core:c"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

builder_append_string :: proc(b: ^strings.Builder, str: string) {
  fmt.sbprint(b, str)
}

str_check :: proc(s: ^string) {
  switch s^ {
  case "test":
    fmt.eprintln("cannot name something test")
    os.exit(1)
    // s^ = "test____this_should_be_fixed_maybe"
  }
}

string_to_type :: proc(s: string) -> n_types {
  switch s {
  case "int":
    return .n_int
  case "char":
    return .n_char
  case "ptr":
    return .n_ptr
  case "str":
    return .n_str
  // case "bool":
  //   return .n_bool
  // case "float":
  //   return .n_float
  case:
    return .n_none
  }
}

print_instrs :: proc(instrs: []n_instrs, indent: u8 = 0) {
  for i in instrs {
    for u in 0 ..< indent do fmt.print("   ")
    fmt.printfln(
      "instr: {}, name: '%s', type: {}, type_num: %d, offset: %d, val: %d, flt: %f, ptr: {}, deref: {} optional: '%s'",
      i.instr,
      i.name,
      i.type,
      i.type_num,
      i.offset,
      i.val,
      i.flt,
      i.ptr,
      i.deref,
      i.optional,
    )
    if len(i.params) > 0 {
      print_instrs(i.params[:], indent + 1)
    }
  }
}

// fn_is_unique :: proc(f: ^fn, fns: []fn) -> bool {
//   for &func in fns {
//     if f.name == func.name do return false
//   }
//   return true
// }


clone_ptr_string :: proc(ptr: ^c.char, sz: int) -> string {
  n := strings.string_from_ptr(auto_cast ptr, sz)
  buf := make([]c.char, len(n))
  mem.copy(&buf[0], ptr, len(n))

  return string(buf)
}

read_file :: proc(file: string) -> (res: []c.char, err: os.Error) {
  file, ferr := os.open(file)
  if ferr != nil {
    return make([]c.char, 0), ferr
  }
  defer os.close(file)

  buff_size, _ := os.file_size(file)
  buf := make([]c.char, buff_size)
  for {
    n, _ := os.read(file, buf)
    if n == 0 do break
  }

  return buf, nil
}
