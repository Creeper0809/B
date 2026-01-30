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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_2_14:
    mov rax, [rbp-1032]
    mov rbx, 0
    mov rcx, rbx
    jmp .Lssa_2_15
.Lssa_2_15:
    mov rbx, rax
    add rbx, rcx
    movzx rbx, byte [rbx]
    push rax
    cmp rbx, 0
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_2_16
    jmp .Lssa_2_17
.Lssa_2_16:
    mov rbx, rcx
    add rbx, 1
    mov rcx, rbx
    jmp .Lssa_2_15
.Lssa_2_17:
    mov rax, rcx
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_5_20:
    mov rax, [rbp-1032]
    lea rbx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rbx], rax
    mov rax , 12
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    syscall
    mov [ rel _gvar_std_os__g_syscall_ret ] , rax
    lea rax, [rel _gvar_std_os__g_syscall_ret]
    mov rax, [rax]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_6_21:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    lea rdx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rdx], rcx
    lea rcx, [rel _gvar_std_os__g_syscall_arg1]
    mov [rcx], rbx
    lea rbx, [rel _gvar_std_os__g_syscall_arg2]
    mov [rbx], rax
    mov rax , 1
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
    mov rdx , [ rel _gvar_std_os__g_syscall_arg2 ]
    syscall
    mov [ rel _gvar_std_os__g_syscall_ret ] , rax
    lea rax, [rel _gvar_std_os__g_syscall_ret]
    mov rax, [rax]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_18_37:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    push rax
    push rbx
    push rcx
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_24_43:
    lea rax, [rel _gvar_std_io__g_out_fd]
    mov rax, [rax]
    cmp rax, 0
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_24_44
    jmp .Lssa_24_45
.Lssa_24_44:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_24_45
.Lssa_24_45:
    lea rax, [rel _gvar_std_io__g_out_fd]
    mov rax, [rax]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_25_46:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_25_47
    jmp .Lssa_25_48
.Lssa_25_47:
    mov rbx, 0
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_25_48
.Lssa_25_48:
    lea rbx, [rel _gvar_std_io__heap_inited]
    mov rbx, [rbx]
    push rax
    cmp rbx, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_25_49
    jmp .Lssa_25_50
.Lssa_25_49:
    lea rbx, [rel _gvar_std_io__heap_brk]
    mov rcx, 0
    push rax
    push rbx
    push rcx
    pop rdi
    call std_os__os_sys_brk
    mov rcx, rax
    pop rbx
    pop rax
    mov [rbx], rcx
    lea rbx, [rel _gvar_std_io__heap_inited]
    mov rcx, 1
    mov [rbx], rcx
    jmp .Lssa_25_50
.Lssa_25_50:
    lea rbx, [rel _gvar_std_io__heap_brk]
    mov rbx, [rbx]
    add rax, rbx
    push rax
    push rbx
    push rax
    pop rdi
    call std_os__os_sys_brk
    mov rcx, rax
    pop rbx
    pop rax
    push rax
    cmp rcx, rax
    setl al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_25_51
    jmp .Lssa_25_52
.Lssa_25_51:
    mov rcx, 0
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_25_52
.Lssa_25_52:
    lea rcx, [rel _gvar_std_io__heap_brk]
    mov [rcx], rax
    mov rax, rbx
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_27_54:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    mov rcx, 0
    mov rdx, rcx
    jmp .Lssa_27_55
.Lssa_27_55:
    push rax
    cmp rdx, rax
    setl al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_27_56
    jmp .Lssa_27_57
.Lssa_27_56:
    mov rcx, rbx
    add rcx, rdx
    movzx rcx, byte [rcx]
    push rax
    cmp rcx, 0
    sete al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_27_58
    jmp .Lssa_27_59
.Lssa_27_57:
    push rbx
    push rcx
    call std_io__io_get_output_fd
    pop rcx
    pop rbx
    push rcx
    push rbx
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_27_58:
    mov rcx, rdx
    jmp .Lssa_27_57
.Lssa_27_59:
    mov rcx, rdx
    add rcx, 1
    mov rdx, rcx
    jmp .Lssa_27_55
.Lssa_27_60:
    jmp .Lssa_27_59
.Lssa_27_215:
    mov rcx, rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_util__emit_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_55_182:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_55_183
    jmp .Lssa_55_184
.Lssa_55_183:
    lea rbx, [rel _str0]
    mov rcx, 1
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__emit
    pop rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_55_184
.Lssa_55_184:
    mov rbx, 32
    push rax
    push rbx
    pop rdi
    call std_io__heap_alloc
    mov rbx, rax
    pop rax
    mov rcx, 0
    mov r8, rax
    mov rdx, rcx
    jmp .Lssa_55_185
.Lssa_55_185:
    cmp r8, 0
    setg al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_55_186
    jmp .Lssa_55_187
.Lssa_55_186:
    mov rax, rbx
    add rax, rdx
    push rax
    push rdx
    mov rax, r8
    cqo
    mov rcx, 10
    idiv rcx
    mov rcx, rdx
    pop rdx
    pop rax
    add rcx, 48
    mov byte [rax], cl
    push rdx
    mov rax, r8
    cqo
    push rcx
    mov rcx, 10
    idiv rcx
    pop rcx
    pop rdx
    mov rcx, rdx
    add rcx, 1
    mov r8, rax
    mov rdx, rcx
    jmp .Lssa_55_185
.Lssa_55_187:
    mov rax, rdx
    sub rax, 1
    mov r8, rax
    jmp .Lssa_55_188
.Lssa_55_188:
    cmp r8, 0
    setge al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_55_189
    jmp .Lssa_55_190
.Lssa_55_189:
    mov rax, 1
    mov rcx, rbx
    add rcx, r8
    mov rdx, 1
    push rbx
    push r8
    push rdx
    push rcx
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
    pop r8
    pop rbx
    mov rax, r8
    sub rax, 1
    mov r8, rax
    jmp .Lssa_55_188
.Lssa_55_190:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_util__emit_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_57_200:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    setl al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_57_201
    jmp .Lssa_57_203
.Lssa_57_201:
    lea rbx, [rel _str1]
    mov rcx, 1
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__emit
    pop rax
    mov rax, 0
    sub rax, rax
    push rax
    pop rdi
    call std_util__emit_u64
    jmp .Lssa_57_202
.Lssa_57_202:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_57_203:
    push rax
    pop rdi
    call std_util__emit_u64
    jmp .Lssa_57_202
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_util__emit_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_59_208:
    mov rax, 1
    push rax
    pop rdi
    call std_io__heap_alloc
    mov rbx, 10
    mov byte [rax], bl
    mov rbx, 1
    mov rcx, 1
    push rcx
    push rax
    push rbx
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_60_209:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rel _str2]
    mov rbx, 20
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str3]
    mov rbx, 21
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str4]
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
    lea rax, [rel _str5]
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
    lea rax, [rel _str6]
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
    lea rax, [rel _str7]
    mov rbx, 22
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str8]
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
    lea rax, [rel _str9]
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
    lea rax, [rel _str10]
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
    lea rax, [rel _str11]
    mov rbx, 19
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str12]
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
    lea rax, [rel _str13]
    mov rbx, 25
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 1
    cmp rax, 0
    jne .Lssa_60_210
    jmp .Lssa_60_211
.Lssa_60_210:
    lea rax, [rel _str14]
    mov rbx, 12
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    jmp .Lssa_60_211
.Lssa_60_211:
    mov rax, 1
    cmp rax, 0
    jne .Lssa_60_212
    jmp .Lssa_60_213
.Lssa_60_212:
    lea rax, [rel _str15]
    mov rbx, 13
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    jmp .Lssa_60_213
.Lssa_60_213:
    lea rax, [rel _str16]
    mov rbx, 23
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    lea rax, [rel _str17]
    lea rbx, [rel _str18]
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
_str0: db 48,0
_str1: db 45,0
_str2: db 84,101,115,116,105,110,103,32,101,100,103,101,32,99,97,115,101,115,58,10,0
_str3: db 10,49,46,32,90,101,114,111,32,111,112,101,114,97,116,105,111,110,115,58,10,0
_str4: db 48,32,43,32,49,48,32,61,32,0
_str5: db 48,32,42,32,49,48,32,61,32,0
_str6: db 49,48,32,45,32,49,48,32,61,32,0
_str7: db 10,50,46,32,78,101,103,97,116,105,118,101,32,110,117,109,98,101,114,115,58,10,0
_str8: db 45,49,48,32,43,32,40,45,53,41,32,61,32,0
_str9: db 45,49,48,32,45,32,40,45,53,41,32,61,32,0
_str10: db 45,49,48,32,42,32,40,45,53,41,32,61,32,0
_str11: db 10,51,46,32,76,97,114,103,101,32,110,117,109,98,101,114,115,58,10,0
_str12: db 49,48,48,48,48,48,48,32,43,32,50,48,48,48,48,48,48,32,61,32,0
_str13: db 10,52,46,32,66,111,117,110,100,97,114,121,32,99,111,110,100,105,116,105,111,110,115,58,10,0
_str14: db 49,32,62,32,48,58,32,116,114,117,101,10,0
_str15: db 48,32,61,61,32,48,58,32,116,114,117,101,10,0
_str16: db 10,53,46,32,83,116,114,105,110,103,32,111,112,101,114,97,116,105,111,110,115,58,10,0
_str17: db 116,101,115,116,0
_str18: db 83,116,114,105,110,103,32,108,101,110,103,116,104,58,32,0

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
