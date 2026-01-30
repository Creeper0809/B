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
.Lssa_5_5:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_write:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_6_6:
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
    mov rax, rdi
    mov rax, rsi
    mov rax, 19
    lea rbx, [rel _str0]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 11
    lea rbx, [rel _str1]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 100
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 11
    lea rbx, [rel _str2]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 10
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 16
    lea rbx, [rel _str3]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 42
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 90
    mov rbx, 22
    lea rcx, [rel _str4]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call std_io__emit
    pop rax
    mov rdi, rax
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
_str0: db 84,101,115,116,105,110,103,32,99,111,110,115,116,97,110,116,115,58,10,0
_str1: db 77,65,88,95,83,73,90,69,32,61,32,0
_str2: db 77,73,78,95,83,73,90,69,32,61,32,0
_str3: db 68,69,70,65,85,76,84,95,86,65,76,85,69,32,61,32,0
_str4: db 77,65,88,95,83,73,90,69,32,45,32,77,73,78,95,83,73,90,69,32,61,32,0

section .bss
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
