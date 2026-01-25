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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_5_5:
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
.Lssa_6_6:
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
.Lssa_24_24:
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
.Lssa_25_25:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_28_28:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__println:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_30_30:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_31_31:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_25_sizeof_advanced__test_sizeof_in_expr:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_33_33:
    lea rax, [rel _str0]
    mov rbx, 32
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 15
    lea rbx, [rel _str1]
    mov rcx, 13
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__print
    pop rax
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str2]
    mov rbx, 16
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 1
    cmp rax, 0
    jne .Lssa_33_34
    jmp .Lssa_33_36
.Lssa_33_34:
    lea rax, [rel _str3]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_33_35
.Lssa_33_35:
    mov rax, 16
    lea rbx, [rel _str4]
    mov rcx, 8
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__print
    pop rax
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str5]
    mov rbx, 22
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.Lssa_33_36:
    lea rax, [rel _str6]
    mov rbx, 31
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_33_35
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_25_sizeof_advanced__test_nested_structs:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_34_37:
    lea rax, [rel _str7]
    mov rbx, 30
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 7
    lea rbx, [rel _str8]
    mov rcx, 16
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__print
    pop rax
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str9]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 22
    lea rbx, [rel _str10]
    mov rcx, 16
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__print
    pop rax
    push rax
    push rax
    pop rdi
    call std_io__print_u64
    pop rax
    lea rbx, [rel _str11]
    mov rcx, 35
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__println
    pop rax
    mov rbx, 1
    cmp rbx, 0
    jne .Lssa_34_38
    jmp .Lssa_34_40
.Lssa_34_38:
    lea rbx, [rel _str12]
    mov rcx, 21
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__println
    pop rax
    jmp .Lssa_34_39
.Lssa_34_39:
    cmp rax, 22
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_41
    jmp .Lssa_34_43
.Lssa_34_40:
    lea rbx, [rel _str13]
    mov rcx, 27
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__println
    pop rax
    jmp .Lssa_34_39
.Lssa_34_41:
    lea rax, [rel _str14]
    mov rbx, 21
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_42
.Lssa_34_42:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.Lssa_34_43:
    lea rax, [rel _str15]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_42
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_25_sizeof_advanced__test_pointer_arithmetic:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_35_44:
    lea rax, [rel _str16]
    mov rbx, 41
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 80
    lea rbx, [rel _str17]
    mov rcx, 26
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__print
    pop rax
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str18]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str19]
    mov rbx, 18
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__print
    mov rax, 40
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str18]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str20]
    mov rbx, 18
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__print
    mov rax, 20
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str18]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str21]
    mov rbx, 18
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__print
    mov rax, 10
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str18]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str22]
    mov rbx, 17
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__print
    mov rax, 5
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str18]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
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
.Lssa_36_45:
    lea rax, [rel _str23]
    mov rbx, 42
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str24]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str23]
    mov rbx, 42
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    call _25_sizeof_advanced__test_sizeof_in_expr
    call _25_sizeof_advanced__test_nested_structs
    call _25_sizeof_advanced__test_pointer_arithmetic
    lea rax, [rel _str25]
    mov rbx, 43
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str26]
    mov rbx, 39
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str23]
    mov rbx, 42
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 61,61,61,32,115,105,122,101,111,102,32,105,110,32,101,120,112,114,101,115,115,105,111,110,115,32,61,61,61,10,0
_str1: db 116,111,116,97,108,32,115,105,122,101,32,61,32,0
_str2: db 32,40,101,120,112,101,99,116,101,100,32,49,53,41,10,0
_str3: db 80,111,105,110,116,101,114,32,115,105,122,101,115,32,97,114,101,32,101,113,117,97,108,32,40,99,111,114,114,101,99,116,41,10,0
_str4: db 67,97,110,32,102,105,116,32,0
_str5: db 32,105,116,101,109,115,32,40,101,120,112,101,99,116,101,100,32,49,54,41,10,0
_str6: db 69,82,82,79,82,58,32,80,111,105,110,116,101,114,32,115,105,122,101,115,32,100,105,102,102,101,114,33,10,0
_str7: db 10,61,61,61,32,78,101,115,116,101,100,32,115,116,114,117,99,116,32,115,105,122,101,115,32,61,61,61,10,0
_str8: db 115,105,122,101,111,102,40,73,110,110,101,114,41,32,61,32,0
_str9: db 32,40,117,56,43,117,49,54,43,117,51,50,32,61,32,49,43,50,43,52,32,61,32,55,41,10,0
_str10: db 115,105,122,101,111,102,40,79,117,116,101,114,41,32,61,32,0
_str11: db 32,40,73,110,110,101,114,43,73,110,110,101,114,43,42,117,54,52,32,61,32,55,43,55,43,56,32,61,32,50,50,41,10,0
_str12: db 73,110,110,101,114,32,115,105,122,101,32,99,111,114,114,101,99,116,33,10,0
_str13: db 69,82,82,79,82,58,32,73,110,110,101,114,32,115,105,122,101,32,119,114,111,110,103,33,10,0
_str14: db 79,117,116,101,114,32,115,105,122,101,32,99,111,114,114,101,99,116,33,10,0
_str15: db 69,82,82,79,82,58,32,79,117,116,101,114,32,115,105,122,101,32,119,114,111,110,103,33,10,0
_str16: db 10,61,61,61,32,115,105,122,101,111,102,32,102,111,114,32,112,111,105,110,116,101,114,32,97,114,105,116,104,109,101,116,105,99,32,61,61,61,10,0
_str17: db 66,117,102,102,101,114,32,115,105,122,101,32,102,111,114,32,49,48,32,117,54,52,115,58,32,0
_str18: db 32,98,121,116,101,115,10,0
_str19: db 79,102,102,115,101,116,32,111,102,32,53,32,117,54,52,115,58,32,0
_str20: db 79,102,102,115,101,116,32,111,102,32,53,32,117,51,50,115,58,32,0
_str21: db 79,102,102,115,101,116,32,111,102,32,53,32,117,49,54,115,58,32,0
_str22: db 79,102,102,115,101,116,32,111,102,32,53,32,117,56,115,58,32,0
_str23: db 61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,10,0
_str24: db 115,105,122,101,111,102,40,41,32,65,100,118,97,110,99,101,100,32,84,101,115,116,115,32,102,111,114,32,118,51,95,49,53,10,0
_str25: db 10,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,10,0
_str26: db 65,108,108,32,97,100,118,97,110,99,101,100,32,115,105,122,101,111,102,32,116,101,115,116,115,32,99,111,109,112,108,101,116,101,100,33,10,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
