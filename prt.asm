format ELF64

section ".data"
msg: db "Hello, World", 10, 0

section ".text" executable
sys_write:
  mov rax, 1           ; syswrite
  mov rsi, rdi         ; move char to rsi
  mov rdi, 1           ; 1 = stdout
  ; rdx is set by the calling function 
  syscall
  ret

; rdi = addr of start | rdx = length fo str (if 0 going until \0)
print_string:
  mov rbx, rdi      ; rbx <- str(addr)
  cmp rdx, 0
  jne print_string_done_
  mov rdx, 0
print_string_jmp_:
  cmp WORD[rbx], 0
  je print_string_done_
  add rbx, 1
  add rdx, 1
  jmp print_string_jmp_
print_string_done_:
  call sys_write
  ret

public main
main:
  mov rdi, msg
  mov rdx, 0
  call print_string

  mov rax, 0
  ret
