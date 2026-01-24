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
.Lssa_18_18:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__io_get_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_24_24:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__heap_alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_25_25:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__emit:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_27_27:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_util__emit_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_55_55:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_util__emit_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_57_57:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_util__emit_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_59_59:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_60_60:
    mov rax, rsi
    mov rax, rdi
    lea rax, [rel _str0]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 11
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    lea rax, [rel _str1]
    mov rbx, 9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 15
    push rax
    pop rdi
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 18
    lea rbx, [rel _str2]
    mov rcx, 23
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__emit
    pop rax
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
_str0: db 76,105,110,101,32,54,58,32,0
_str1: db 76,105,110,101,32,49,48,58,32,0
_str2: db 76,105,110,101,32,49,52,32,115,116,111,114,101,100,32,105,110,32,118,97,114,58,32,0

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
