package naned

import "core:c"
import "core:mem"
import "core:os"
import "core:strings"

string_to_type :: proc(s: string) -> (type: n_types, err: bool) {
  switch s {
  case "int":
    return .n_int, false
  case "char":
    return .n_char, false
  case "string":
    return .n_string, false
  case "bool":
    return .n_bool, false
  case "float":
    return .n_float, false
  case "void":
    return .n_void, false
  case:
    return .n_not_a_type, true
  }
}


fn_is_unique :: proc(f: ^fn, fns: []fn) -> bool {
  for &func in fns {
    if f.name == func.name do return false
  }
  return true
}


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
