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
_12_asm_inline__get_value_asm:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_60_60:
    mov rax, 0
    mov rax , 42
    mov [ rbp - 8 ] , rax
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_12_asm_inline__add_asm:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_61_61:
    mov rax, rdi
    mov rax, rsi
    mov rax , [ rbp + 16 ]
    add rax , [ rbp + 24 ]
    mov [ rbp - 8 ] , rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_62_62:
    mov rax, rdi
    mov rax, rsi
    mov rax, 25
    lea rbx, [rel _str0]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    call _12_asm_inline__get_value_asm
    mov rbx, 18
    lea rcx, [rel _str1]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call std_io__emit
    pop rax
    push rax
    mov rdi, rax
    call std_util__emit_i64
    pop rax
    push rax
    call std_util__emit_nl
    pop rax
    mov rbx, 32
    mov rcx, 10
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call _12_asm_inline__add_asm
    mov rbx, rax
    pop rax
    mov rcx, 18
    lea rdx, [rel _str2]
    push rax
    push rbx
    mov rdi, rcx
    mov rsi, rdx
    call std_io__emit
    pop rbx
    pop rax
    push rax
    push rbx
    mov rdi, rbx
    call std_util__emit_i64
    pop rbx
    pop rax
    push rax
    push rbx
    call std_util__emit_nl
    pop rbx
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_62_63
    jmp .Lssa_62_64
.Lssa_62_63:
    mov rax, 15
    lea rbx, [rel _str3]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    jmp .Lssa_62_64
.Lssa_62_64:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 84,101,115,116,105,110,103,32,105,110,108,105,110,101,32,97,115,115,101,109,98,108,121,58,10,0
_str1: db 103,101,116,95,118,97,108,117,101,95,97,115,109,40,41,32,61,32,0
_str2: db 97,100,100,95,97,115,109,40,49,48,44,32,51,50,41,32,61,32,0
_str3: db 82,101,115,117,108,116,115,32,109,97,116,99,104,33,10,0

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
