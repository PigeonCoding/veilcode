// v0.2
// changelog v0.2:
// - added a mandatory init_container function that initializes the hashmap
// - added the get_flag_value to get the result of a flag (either nil or a pointer to the value)
// - added the flag_prefix to flag_container (aka indicated that this is a flag the '-' is the default)
// - added part of the hashmap implementation from https://github.com/CobbCoding1/odin-hashmap
package flag

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

flag_val_types :: union {
  int,
  string,
  bool,
}

flag_t :: struct {
  flag:        string,
  value:       flag_val_types,
  description: string,
}

flag_container :: struct {
  flags_map:         Map(^flag_t),
  private_flag_list: [dynamic]flag_t,
  remaining:         []string,
  flag_prefix:       string,
}

init_container :: proc(cont: ^flag_container) {
  cont.flags_map = map_init(^flag_t)
}

// if flag_prefix is left empty it will default to '-'
add_flag :: proc(
  container: ^flag_container,
  flag_name: string,
  initial_val: flag_val_types,
  description: string,
) {
  t: flag_t
  t.flag = flag_name
  t.value = initial_val
  t.description = description

  append(&container.private_flag_list, t)
}

// this function does not modify os.args
check_flags :: proc(container: ^flag_container) {
  rem: [dynamic]string

  if container.flag_prefix == "" do container.flag_prefix = "-"

  arg_i := 0
  for arg_i < len(os.args) {

    if os.args[arg_i] == "---" {
      break
    }

    if strings.starts_with(os.args[arg_i], container.flag_prefix) {
      yes := false
      for &f in container.private_flag_list {
        if os.args[arg_i][len(container.flag_prefix):] == f.flag {
          yes = false
          switch v in f.value {
          case bool:
            yes = true
          case int:
            arg_i += 1
            if os.args[arg_i][0] == '-' || (os.args[arg_i][0] >= '0' && os.args[arg_i][0] <= '9') {
              f.value = strconv.atoi(os.args[arg_i])
              yes = true
            }
          case string:
            arg_i += 1
            yes = true
            f.value = os.args[arg_i]
          }

          if yes do map_insert(&container.flags_map, f.flag, &f)

        }
      }
      if !yes {
        fmt.eprintln("unknown flag", os.args[arg_i])
        os.exit(1)
      }
    } else {
      append(&rem, os.args[arg_i])
    }
    arg_i += 1
  }

  for i in arg_i ..< len(os.args) {
    append(&rem, os.args[i])
  }

  container.remaining = rem[:]
}

get_flag_value :: proc(cont: ^flag_container, name: string) -> ^any {
  // TODO: the user has to manually cast it to the correct type
  // maybe find a way to return the correct type directly?
  res := map_get(&cont.flags_map, name)
  switch _ in res {
  case Errors:
    return nil
  case ^flag_t:
    return auto_cast &res.(^flag_t).value
  }
  return nil
}

print_usage :: proc(container: ^flag_container) {
  max_len := 0

  for f in container.private_flag_list {
    if len(f.flag) > max_len {
      max_len = len(f.flag)
    }
  }

  for f in container.private_flag_list {
    t: string
    switch v in f.value {
    case int:
      t = "(int)   "
    case bool:
      t = "(bool)  "
    case string:
      t = "(string)"
    }

    fmt.printfln(
      "%-*.s: {}",
      max_len + 1 + 9,
      strings.concatenate({"-", f.flag, t}),
      f.description,
    )
  }
}

free_flag_container :: proc(container: ^flag_container) {
  delete(container.private_flag_list)
  delete(container.remaining)
  delete(container.flags_map.data)
}

// ------------------------------------ 
// hashmap implementation from https://github.com/CobbCoding1/odin-hashmap/
// (not copied in full)


Errors :: enum {
  OK,
  NotInMap,
  MapFull,
}

@(private)
PRIME :: 7

@(private)
capacity :: 32

@(private)
Data_Union :: union($T: typeid) {
  T,
  Errors,
}

@(private)
Data :: struct($T: typeid) {
  val:         T,
  key:         string,
  unavailable: bool,
}

@(private)
Map :: struct($T: typeid) {
  data: [dynamic]Data(T),
}

@(private)
hash :: proc(n: string) -> int {
  result: int = PRIME
  for ch in n {
    result = result * 31 + int(ch)
  }
  return result
}

@(private)
map_init :: proc($T: typeid) -> Map(T) {
  hashmap: Map(T)
  hashmap.data = make([dynamic]Data(T), capacity)
  return hashmap
}

@(private)
map_insert :: proc(hashmap: ^Map($T), key: string, val: T) -> Errors {
  index := hash(key) % cap(hashmap.data)

  data := Data(T){val, key, true}

  iterated_by := 0
  for hashmap.data[index].unavailable == true {
    if iterated_by >= cap(hashmap.data) {return Errors.MapFull}
    index += 1
    iterated_by += 1
    if index >= cap(hashmap.data) {index = 0}
  }

  assign_at(&hashmap.data, index, data)
  return Errors.OK
}

@(private)
map_get :: proc(hashmap: ^Map($T), key: string) -> Data_Union(T) {
  index := hash(key) % cap(hashmap.data)

  iterated_by := 0
  for hashmap.data[index].key != key {
    if hashmap.data[index].unavailable {
      return Errors.NotInMap
    }
    if iterated_by >= cap(hashmap.data) {return Errors.MapFull}
    index += 1
    iterated_by += 1
    if index >= cap(hashmap.data) {index = 0}
  }

  return hashmap.data[index].val
}