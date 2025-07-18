package veilcode_common

n_instrs_enum :: enum {
  nun,
  push,
  create,
  store,
  assign,
  load,
  call,
  add,
  sub,
  mult,
  div,
  mod,
  jmp,
  nothing,
  if_,
  label,
  eq,
  noteq,
  block,
  extrn,
  fn,
  reg,
}

n_types :: enum {
  n_none,
  n_ptr,
  n_int,
  n_char,
  n_str,
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
  optional: string,
  deref:    bool,
}
