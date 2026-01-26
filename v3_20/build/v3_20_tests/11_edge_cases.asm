default rel
section .text
global _start
_start:
    pop rdi          ; argc
    mov rsi, rsp     ; argv
    push rsi
    push rdi
    call main
    mov rdi, rax
    mov rax, 60
    syscall
std_str__str_len:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov rax, 0
    mov [rbp-16], rax
.L0:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L1
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L0
.L1:
    mov rax, [rbp-16]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_os__os_sys_brk:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_os__g_syscall_arg0]
    pop rbx
    mov [rax], rbx
    mov rax , 12
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    syscall
    mov [ rel _gvar_std_os__g_syscall_ret ] , rax
    mov rax, [rel _gvar_std_os__g_syscall_ret]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_os__os_sys_write:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_os__g_syscall_arg0]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    lea rax, [rel _gvar_std_os__g_syscall_arg1]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    lea rax, [rel _gvar_std_os__g_syscall_arg2]
    pop rbx
    mov [rax], rbx
    mov rax , 1
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
    mov rdx , [ rel _gvar_std_os__g_syscall_arg2 ]
    syscall
    mov [ rel _gvar_std_os__g_syscall_ret ] , rax
    mov rax, [rel _gvar_std_os__g_syscall_ret]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__sys_write:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__io_get_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rel _gvar_std_io__g_out_fd]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L2
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L2:
    mov rax, [rel _gvar_std_io__g_out_fd]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__heap_alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L4:
    mov rax, [rel _gvar_std_io__heap_inited]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, 0
    push rax
    pop rdi
    call std_os__os_sys_brk
    push rax
    lea rax, [rel _gvar_std_io__heap_brk]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    lea rax, [rel _gvar_std_io__heap_inited]
    pop rbx
    mov [rax], rbx
.L6:
    mov rax, [rel _gvar_std_io__heap_brk]
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    call std_os__os_sys_brk
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L8:
    mov rax, [rbp-24]
    push rax
    lea rax, [rel _gvar_std_io__heap_brk]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__emit:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 0
    mov [rbp-24], rax
.L10:
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L11
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, [rbp-24]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L11
.L12:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    jmp .L10
.L11:
    call std_io__io_get_output_fd
    mov [rbp-32], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 1
    push rax
    lea rax, [rel _str16]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 32
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-16], rax
    mov rax, 0
    mov [rbp-24], rax
    mov rax, [rbp-8]
    mov [rbp-32], rax
.L17:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 48
    push rax
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    jmp .L17
.L18:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-40], rax
.L19:
    mov rax, [rbp-40]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 1
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L19
.L20:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L21
    mov rax, 1
    push rax
    lea rax, [rel _str23]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    pop rdi
    call std_util__emit_u64
    jmp .L22
.L21:
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_util__emit_u64
.L22:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 1
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-8], rax
    mov rax, 10
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], bl
    mov rax, 1
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_60_60:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rel _str24]
    mov rbx, 20
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str25]
    mov rbx, 21
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str26]
    mov rbx, 9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 10
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str27]
    mov rbx, 9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 0
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str28]
    mov rbx, 10
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 0
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str29]
    mov rbx, 22
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str30]
    mov rbx, 13
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 9223372036854775793
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str31]
    mov rbx, 13
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 9223372036854775803
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str32]
    mov rbx, 13
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 50
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str33]
    mov rbx, 19
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str34]
    mov rbx, 20
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 3000000
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str35]
    mov rbx, 25
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 1
    cmp rax, 0
    jne .Lssa_60_61
    jmp .Lssa_60_62
.Lssa_60_61:
    lea rax, [rel _str36]
    mov rbx, 12
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    jmp .Lssa_60_62
.Lssa_60_62:
    mov rax, 1
    cmp rax, 0
    jne .Lssa_60_63
    jmp .Lssa_60_64
.Lssa_60_63:
    lea rax, [rel _str37]
    mov rbx, 13
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    jmp .Lssa_60_64
.Lssa_60_64:
    lea rax, [rel _str38]
    mov rbx, 23
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str39]
    lea rbx, [rel _str40]
    mov rcx, 15
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__emit
    pop rax
    push rax
    pop rdi
    call std_str__str_len
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str16: db 48,0
_str23: db 45,0
_str24: db 84,101,115,116,105,110,103,32,101,100,103,101,32,99,97,115,101,115,58,10,0
_str25: db 10,49,46,32,90,101,114,111,32,111,112,101,114,97,116,105,111,110,115,58,10,0
_str26: db 48,32,43,32,49,48,32,61,32,0
_str27: db 48,32,42,32,49,48,32,61,32,0
_str28: db 49,48,32,45,32,49,48,32,61,32,0
_str29: db 10,50,46,32,78,101,103,97,116,105,118,101,32,110,117,109,98,101,114,115,58,10,0
_str30: db 45,49,48,32,43,32,40,45,53,41,32,61,32,0
_str31: db 45,49,48,32,45,32,40,45,53,41,32,61,32,0
_str32: db 45,49,48,32,42,32,40,45,53,41,32,61,32,0
_str33: db 10,51,46,32,76,97,114,103,101,32,110,117,109,98,101,114,115,58,10,0
_str34: db 49,48,48,48,48,48,48,32,43,32,50,48,48,48,48,48,48,32,61,32,0
_str35: db 10,52,46,32,66,111,117,110,100,97,114,121,32,99,111,110,100,105,116,105,111,110,115,58,10,0
_str36: db 49,32,62,32,48,58,32,116,114,117,101,10,0
_str37: db 48,32,61,61,32,48,58,32,116,114,117,101,10,0
_str38: db 10,53,46,32,83,116,114,105,110,103,32,111,112,101,114,97,116,105,111,110,115,58,10,0
_str39: db 116,101,115,116,0
_str40: db 83,116,114,105,110,103,32,108,101,110,103,116,104,58,32,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
_gvar_std_util__g_stack_frames: resq 1
_gvar_std_util__g_stack_depth: resq 1
_gvar_std_util__g_stack_initialized: resq 1
_gvar_std_util__g_last_error_msg: resq 1
_gvar_std_util__g_last_error_len: resq 1
_gvar_std_util__g_error_buffer: resq 1
_gvar_std_util__g_error_buffer_pos: resq 1
_gvar_std_util__g_capturing_error: resq 1
_gvar_std_util__g_current_func_name: resq 1
_gvar_std_util__g_current_func_name_len: resq 1
_gvar_std_util__g_current_func_line: resq 1
