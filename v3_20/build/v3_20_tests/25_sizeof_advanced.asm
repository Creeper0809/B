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
.Lssa_28_61:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    push rax
    push rbx
    call std_io__io_get_output_fd
    mov rcx, rax
    pop rbx
    pop rax
    push rax
    push rbx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
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
.Lssa_30_63:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    push rax
    push rbx
    call std_io__io_get_output_fd
    mov rcx, rax
    pop rbx
    pop rax
    push rcx
    push rax
    push rbx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    pop rcx
    lea rax, [rel _str0]
    mov rbx, 1
    push rbx
    push rax
    push rcx
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
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
.Lssa_31_64:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_31_65
    jmp .Lssa_31_66
.Lssa_31_65:
    push rax
    call std_io__io_get_output_fd
    mov rbx, rax
    pop rax
    lea rcx, [rel _str1]
    mov rdx, 1
    push rax
    push rbx
    push rdx
    push rcx
    push rbx
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    pop rbx
    pop rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_31_66
.Lssa_31_66:
    mov rbx, 32
    push rax
    push rbx
    pop rdi
    call std_io__heap_alloc
    mov rbx, rax
    pop rax
    mov rcx, 0
    mov r8, rax
    mov r9, rax
    mov r8, rcx
    jmp .Lssa_31_67
.Lssa_31_67:
    cmp r9, 0
    setg al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_31_68
    jmp .Lssa_31_69
.Lssa_31_68:
    push rdx
    mov rax, r9
    cqo
    push rcx
    mov rcx, 10
    idiv rcx
    mov rax, rdx
    pop rcx
    pop rdx
    mov rcx, rbx
    add rcx, r8
    mov rdx, rax
    add rdx, 48
    mov byte [rcx], dl
    push rax
    push rdx
    mov rax, r9
    cqo
    mov rcx, 10
    idiv rcx
    mov rcx, rax
    pop rdx
    pop rax
    mov rdx, r8
    add rdx, 1
    mov r8, rax
    mov r9, rcx
    mov r8, rdx
    jmp .Lssa_31_67
.Lssa_31_69:
    mov rax, r8
    sub rax, 1
    mov rdx, rax
    mov r8, rax
    jmp .Lssa_31_70
.Lssa_31_70:
    cmp r8, 0
    setge al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_31_71
    jmp .Lssa_31_72
.Lssa_31_71:
    push rbx
    push r8
    call std_io__io_get_output_fd
    pop r8
    pop rbx
    mov rcx, rbx
    add rcx, r8
    mov rdx, 1
    push rax
    push rbx
    push r8
    push rdx
    push rcx
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    pop r8
    pop rbx
    pop rax
    mov rcx, r8
    sub rcx, 1
    mov rdx, rax
    mov r8, rcx
    jmp .Lssa_31_70
.Lssa_31_72:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_31_92:
    mov rbx, rax
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
.Lssa_33_77:
    lea rax, [rel _str2]
    mov rbx, 32
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 15
    lea rbx, [rel _str3]
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
    lea rax, [rel _str4]
    mov rbx, 16
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 1
    cmp rax, 0
    jne .Lssa_33_78
    jmp .Lssa_33_80
.Lssa_33_78:
    lea rax, [rel _str5]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_33_79
.Lssa_33_79:
    mov rax, 16
    lea rbx, [rel _str6]
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
    lea rax, [rel _str7]
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
.Lssa_33_80:
    lea rax, [rel _str8]
    mov rbx, 31
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_33_79
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
.Lssa_34_81:
    lea rax, [rel _str9]
    mov rbx, 30
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 7
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
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str11]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 22
    lea rbx, [rel _str12]
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
    lea rbx, [rel _str13]
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
    jne .Lssa_34_82
    jmp .Lssa_34_84
.Lssa_34_82:
    lea rbx, [rel _str14]
    mov rcx, 21
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__println
    pop rax
    jmp .Lssa_34_83
.Lssa_34_83:
    cmp rax, 22
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_85
    jmp .Lssa_34_87
.Lssa_34_84:
    lea rbx, [rel _str15]
    mov rcx, 27
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call std_io__println
    pop rax
    jmp .Lssa_34_83
.Lssa_34_85:
    lea rax, [rel _str16]
    mov rbx, 21
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_86
.Lssa_34_86:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.Lssa_34_87:
    lea rax, [rel _str17]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_86
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
.Lssa_35_88:
    lea rax, [rel _str18]
    mov rbx, 41
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 80
    lea rbx, [rel _str19]
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
    lea rax, [rel _str20]
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
    mov rax, 40
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str20]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str22]
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
    lea rax, [rel _str20]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str23]
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
    lea rax, [rel _str20]
    mov rbx, 8
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str24]
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
    lea rax, [rel _str20]
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
.Lssa_36_89:
    lea rax, [rel _str25]
    mov rbx, 42
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str26]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str25]
    mov rbx, 42
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    call _25_sizeof_advanced__test_sizeof_in_expr
    call _25_sizeof_advanced__test_nested_structs
    call _25_sizeof_advanced__test_pointer_arithmetic
    lea rax, [rel _str27]
    mov rbx, 43
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str28]
    mov rbx, 39
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str25]
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
_str0: db 10,0
_str1: db 48,0
_str2: db 61,61,61,32,115,105,122,101,111,102,32,105,110,32,101,120,112,114,101,115,115,105,111,110,115,32,61,61,61,10,0
_str3: db 116,111,116,97,108,32,115,105,122,101,32,61,32,0
_str4: db 32,40,101,120,112,101,99,116,101,100,32,49,53,41,10,0
_str5: db 80,111,105,110,116,101,114,32,115,105,122,101,115,32,97,114,101,32,101,113,117,97,108,32,40,99,111,114,114,101,99,116,41,10,0
_str6: db 67,97,110,32,102,105,116,32,0
_str7: db 32,105,116,101,109,115,32,40,101,120,112,101,99,116,101,100,32,49,54,41,10,0
_str8: db 69,82,82,79,82,58,32,80,111,105,110,116,101,114,32,115,105,122,101,115,32,100,105,102,102,101,114,33,10,0
_str9: db 10,61,61,61,32,78,101,115,116,101,100,32,115,116,114,117,99,116,32,115,105,122,101,115,32,61,61,61,10,0
_str10: db 115,105,122,101,111,102,40,73,110,110,101,114,41,32,61,32,0
_str11: db 32,40,117,56,43,117,49,54,43,117,51,50,32,61,32,49,43,50,43,52,32,61,32,55,41,10,0
_str12: db 115,105,122,101,111,102,40,79,117,116,101,114,41,32,61,32,0
_str13: db 32,40,73,110,110,101,114,43,73,110,110,101,114,43,42,117,54,52,32,61,32,55,43,55,43,56,32,61,32,50,50,41,10,0
_str14: db 73,110,110,101,114,32,115,105,122,101,32,99,111,114,114,101,99,116,33,10,0
_str15: db 69,82,82,79,82,58,32,73,110,110,101,114,32,115,105,122,101,32,119,114,111,110,103,33,10,0
_str16: db 79,117,116,101,114,32,115,105,122,101,32,99,111,114,114,101,99,116,33,10,0
_str17: db 69,82,82,79,82,58,32,79,117,116,101,114,32,115,105,122,101,32,119,114,111,110,103,33,10,0
_str18: db 10,61,61,61,32,115,105,122,101,111,102,32,102,111,114,32,112,111,105,110,116,101,114,32,97,114,105,116,104,109,101,116,105,99,32,61,61,61,10,0
_str19: db 66,117,102,102,101,114,32,115,105,122,101,32,102,111,114,32,49,48,32,117,54,52,115,58,32,0
_str20: db 32,98,121,116,101,115,10,0
_str21: db 79,102,102,115,101,116,32,111,102,32,53,32,117,54,52,115,58,32,0
_str22: db 79,102,102,115,101,116,32,111,102,32,53,32,117,51,50,115,58,32,0
_str23: db 79,102,102,115,101,116,32,111,102,32,53,32,117,49,54,115,58,32,0
_str24: db 79,102,102,115,101,116,32,111,102,32,53,32,117,56,115,58,32,0
_str25: db 61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,10,0
_str26: db 115,105,122,101,111,102,40,41,32,65,100,118,97,110,99,101,100,32,84,101,115,116,115,32,102,111,114,32,118,51,95,49,53,10,0
_str27: db 10,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,10,0
_str28: db 65,108,108,32,97,100,118,97,110,99,101,100,32,115,105,122,101,111,102,32,116,101,115,116,115,32,99,111,109,112,108,101,116,101,100,33,10,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
