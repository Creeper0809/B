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
.Lssa_2_2:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
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
    mov rax, 20
    lea rbx, [rel _str0]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 21
    lea rbx, [rel _str1]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 9
    lea rbx, [rel _str2]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 10
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 9
    lea rbx, [rel _str3]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 0
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 10
    lea rbx, [rel _str4]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 0
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 22
    lea rbx, [rel _str5]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 13
    lea rbx, [rel _str6]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 9223372036854775793
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 13
    lea rbx, [rel _str7]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 9223372036854775803
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 13
    lea rbx, [rel _str8]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 50
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 19
    lea rbx, [rel _str9]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 20
    lea rbx, [rel _str10]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 3000000
    mov rdi, rax
    call std_util__emit_i64
    call std_util__emit_nl
    mov rax, 25
    lea rbx, [rel _str11]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    mov rax, 1
    cmp rax, 0
    jne .Lssa_60_61
    jmp .Lssa_60_62
.Lssa_60_61:
    mov rax, 12
    lea rbx, [rel _str12]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    jmp .Lssa_60_62
.Lssa_60_62:
    mov rax, 1
    cmp rax, 0
    jne .Lssa_60_63
    jmp .Lssa_60_64
.Lssa_60_63:
    mov rax, 13
    lea rbx, [rel _str13]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    jmp .Lssa_60_64
.Lssa_60_64:
    mov rax, 23
    lea rbx, [rel _str14]
    mov rdi, rax
    mov rsi, rbx
    call std_io__emit
    lea rax, [rel _str15]
    mov rbx, 15
    lea rcx, [rel _str16]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call std_io__emit
    pop rax
    mov rdi, rax
    call std_str__str_len
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
_str0: db 84,101,115,116,105,110,103,32,101,100,103,101,32,99,97,115,101,115,58,10,0
_str1: db 10,49,46,32,90,101,114,111,32,111,112,101,114,97,116,105,111,110,115,58,10,0
_str2: db 48,32,43,32,49,48,32,61,32,0
_str3: db 48,32,42,32,49,48,32,61,32,0
_str4: db 49,48,32,45,32,49,48,32,61,32,0
_str5: db 10,50,46,32,78,101,103,97,116,105,118,101,32,110,117,109,98,101,114,115,58,10,0
_str6: db 45,49,48,32,43,32,40,45,53,41,32,61,32,0
_str7: db 45,49,48,32,45,32,40,45,53,41,32,61,32,0
_str8: db 45,49,48,32,42,32,40,45,53,41,32,61,32,0
_str9: db 10,51,46,32,76,97,114,103,101,32,110,117,109,98,101,114,115,58,10,0
_str10: db 49,48,48,48,48,48,48,32,43,32,50,48,48,48,48,48,48,32,61,32,0
_str11: db 10,52,46,32,66,111,117,110,100,97,114,121,32,99,111,110,100,105,116,105,111,110,115,58,10,0
_str12: db 49,32,62,32,48,58,32,116,114,117,101,10,0
_str13: db 48,32,61,61,32,48,58,32,116,114,117,101,10,0
_str14: db 10,53,46,32,83,116,114,105,110,103,32,111,112,101,114,97,116,105,111,110,115,58,10,0
_str15: db 116,101,115,116,0
_str16: db 83,116,114,105,110,103,32,108,101,110,103,116,104,58,32,0

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
