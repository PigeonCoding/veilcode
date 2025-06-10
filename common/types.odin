package naned_common

n_instrs_enum :: enum {
  nun,
  push,
  store,
  assign,
  load,
  call,
  syscall,
  add,
  sub,
  mult,
  div,
  jmp,
  deref,
  nothing,
}

n_types :: enum {
  n_none,
  n_int,
  n_char,
}

// TODO: support floats in code
n_instrs :: struct {
  instr:    n_instrs_enum,
  name:     string,
  type:     n_types,
  type_num: uint,
  offset:   int,
  val:      i64,
  flt:      f64,
  ptr:      bool,
  params:   [dynamic]n_instrs,
}
