package veilcode

import cm "common"
import "core:fmt"
import "core:strings"

postprocess :: proc(instrs: []cm.n_instrs, fn: ^cm.n_instrs = nil) {
  for &i, index in instrs {
    if i.instr == .fn do postprocess(i.params[:], &i)
    if i.instr == .load && i.name == "args__" && fn != nil do i.name = strings.concatenate({"args_", fn.name})
    if len(i.params) > 0 do postprocess(i.params[:], fn)
  }
}
