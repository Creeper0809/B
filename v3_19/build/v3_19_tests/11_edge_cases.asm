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
    mov rbx, 20
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str1]
    mov rbx, 21
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str2]
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
    lea rax, [rel _str3]
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
    lea rax, [rel _str4]
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
    lea rax, [rel _str5]
    mov rbx, 22
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str6]
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
    lea rax, [rel _str7]
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
    lea rax, [rel _str8]
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
    lea rax, [rel _str9]
    mov rbx, 19
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str10]
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
    lea rax, [rel _str11]
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
    lea rax, [rel _str12]
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
    lea rax, [rel _str13]
    mov rbx, 13
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    jmp .Lssa_60_64
.Lssa_60_64:
    lea rax, [rel _str14]
    mov rbx, 23
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str15]
    lea rbx, [rel _str16]
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
