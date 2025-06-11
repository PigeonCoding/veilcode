package veilcode_common

n_instrs_enum :: enum {
  nun,
  push,
  store,
  assign,
  load,
  call,
  syscall, // TODO: make this a function and just call it probably but still have this maybe?
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
  n_ptr,
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
