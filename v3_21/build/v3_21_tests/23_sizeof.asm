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
.Lssa_5_21:
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
.Lssa_6_22:
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
.Lssa_24_44:
    lea rax, [rel _gvar_std_io__g_out_fd]
    mov rax, [rax]
    cmp rax, 0
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_24_45
    jmp .Lssa_24_46
.Lssa_24_45:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_24_46
.Lssa_24_46:
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
.Lssa_25_47:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_25_48
    jmp .Lssa_25_49
.Lssa_25_48:
    mov rbx, 0
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_25_49
.Lssa_25_49:
    mov rbx, 9223372036854775800
    mov rax, rax
    add rax, 7
    mov rax, rax
    and rax, 9223372036854775800
    lea rcx, [rel _gvar_std_io__heap_inited]
    mov rcx, [rcx]
    push rax
    cmp rcx, 0
    sete al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_25_50
    jmp .Lssa_25_51
.Lssa_25_50:
    lea rcx, [rel _gvar_std_io__heap_brk]
    mov rdx, 0
    push rax
    push rbx
    push rcx
    push rdx
    pop rdi
    call std_os__os_sys_brk
    mov rdx, rax
    pop rcx
    pop rbx
    pop rax
    mov [rcx], rdx
    lea rcx, [rel _gvar_std_io__heap_inited]
    mov rdx, 1
    mov [rcx], rdx
    jmp .Lssa_25_51
.Lssa_25_51:
    lea rcx, [rel _gvar_std_io__heap_brk]
    mov rcx, [rcx]
    mov rcx, rcx
    add rcx, 7
    and rbx, rcx
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
    jne .Lssa_25_52
    jmp .Lssa_25_53
.Lssa_25_52:
    mov rcx, 0
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_25_53
.Lssa_25_53:
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
.Lssa_30_65:
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
.Lssa_31_66:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_31_67
    jmp .Lssa_31_68
.Lssa_31_67:
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
    jmp .Lssa_31_68
.Lssa_31_68:
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
    jmp .Lssa_31_69
.Lssa_31_69:
    cmp r9, 0
    setg al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_31_70
    jmp .Lssa_31_72
.Lssa_31_70:
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
    jmp .Lssa_31_71
.Lssa_31_71:
    mov r8, rax
    mov r9, rcx
    mov r8, rdx
    jmp .Lssa_31_69
.Lssa_31_72:
    mov rax, r8
    sub rax, 1
    mov rdx, rax
    mov r8, rax
    jmp .Lssa_31_73
.Lssa_31_73:
    cmp r8, 0
    setge al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_31_74
    jmp .Lssa_31_76
.Lssa_31_74:
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
    jmp .Lssa_31_75
.Lssa_31_75:
    mov rcx, r8
    sub rcx, 1
    mov rdx, rax
    mov r8, rcx
    jmp .Lssa_31_73
.Lssa_31_76:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_31_114:
    mov rbx, rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_23_sizeof__print_result:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_33_81:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    push rax
    push rbx
    push rcx
    pop rdi
    pop rsi
    call std_io__println
    pop rax
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str0]
    mov rbx, 1
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
.Lssa_34_82:
    lea rax, [rel _str2]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 1
    lea rbx, [rel _str3]
    mov rcx, 14
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    mov rax, 2
    lea rbx, [rel _str4]
    mov rcx, 15
    push rax
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rax
    mov rbx, 4
    lea rcx, [rel _str5]
    mov rdx, 15
    push rax
    push rbx
    push rbx
    push rdx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rbx
    pop rax
    mov rcx, 8
    lea rdx, [rel _str6]
    mov r8, 15
    push rax
    push rbx
    push rcx
    push rcx
    push r8
    push rdx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rcx
    pop rbx
    pop rax
    mov rdx, 8
    lea r8, [rel _str7]
    mov r9, 15
    push rax
    push rbx
    push rcx
    push rdx
    push rdx
    push r9
    push r8
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea r8, [rel _str8]
    mov r9, 24
    push rax
    push rbx
    push rcx
    push rdx
    push r9
    push r8
    pop rdi
    pop rsi
    call std_io__println
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r8, 8
    lea r9, [rel _str9]
    mov r10, 15
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r8
    push r10
    push r9
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r9, 8
    lea r10, [rel _str10]
    mov r11, 16
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r9
    push r11
    push r10
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r10, 8
    lea r11, [rel _str11]
    mov rax, 17
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push rax
    push r11
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r10
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea r11, [rel _str12]
    mov rax, 23
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push r11
    pop rdi
    pop rsi
    call std_io__println
    pop r10
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r11, 16
    lea rax, [rel _str13]
    mov rax, 17
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r11
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 32
    lea rax, [rel _str14]
    mov rax, 16
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 2
    lea rax, [rel _str15]
    mov rax, 23
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea rax, [rel _str16]
    mov rax, 28
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 8
    lea rax, [rel _str17]
    mov rax, 18
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 8
    lea rax, [rel _str18]
    mov rax, 17
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea rax, [rel _str19]
    mov rax, 21
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 1
    mov rax, 0
    cmp rax, 0
    jne .Lssa_34_83
    jmp .Lssa_34_84
.Lssa_34_83:
    lea rax, [rel _str20]
    mov rax, 32
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 0
    mov rax, rax
    jmp .Lssa_34_84
.Lssa_34_84:
    cmp rax, 2
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_85
    jmp .Lssa_34_86
.Lssa_34_85:
    lea rax, [rel _str21]
    mov rax, 33
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    mov rax, 0
    mov rax, rax
    jmp .Lssa_34_86
.Lssa_34_86:
    cmp rbx, 4
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_87
    jmp .Lssa_34_88
.Lssa_34_87:
    lea rax, [rel _str22]
    mov rbx, 33
    push rcx
    push rdx
    push r8
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_88
.Lssa_34_88:
    cmp rcx, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_89
    jmp .Lssa_34_90
.Lssa_34_89:
    lea rax, [rel _str23]
    mov rbx, 33
    push rdx
    push r8
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_90
.Lssa_34_90:
    cmp rdx, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_91
    jmp .Lssa_34_92
.Lssa_34_91:
    lea rax, [rel _str24]
    mov rbx, 33
    push r8
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_92
.Lssa_34_92:
    cmp r8, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_93
    jmp .Lssa_34_94
.Lssa_34_93:
    lea rax, [rel _str25]
    mov rbx, 34
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_94
.Lssa_34_94:
    cmp r9, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_95
    jmp .Lssa_34_96
.Lssa_34_95:
    lea rax, [rel _str26]
    mov rbx, 35
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_96
.Lssa_34_96:
    cmp r10, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_97
    jmp .Lssa_34_98
.Lssa_34_97:
    lea rax, [rel _str27]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r11
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_98
.Lssa_34_98:
    cmp r11, 16
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_99
    jmp .Lssa_34_100
.Lssa_34_99:
    lea rax, [rel _str28]
    mov rbx, 37
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_100
.Lssa_34_100:
    cmp rax, 32
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_101
    jmp .Lssa_34_102
.Lssa_34_101:
    lea rax, [rel _str29]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_102
.Lssa_34_102:
    cmp rax, 2
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_103
    jmp .Lssa_34_104
.Lssa_34_103:
    lea rax, [rel _str30]
    mov rbx, 42
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_104
.Lssa_34_104:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_105
    jmp .Lssa_34_106
.Lssa_34_105:
    lea rax, [rel _str31]
    mov rbx, 37
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_106
.Lssa_34_106:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_107
    jmp .Lssa_34_108
.Lssa_34_107:
    lea rax, [rel _str32]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    jmp .Lssa_34_108
.Lssa_34_108:
    cmp rax, 0
    jne .Lssa_34_109
    jmp .Lssa_34_111
.Lssa_34_109:
    lea rax, [rel _str33]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_110
.Lssa_34_110:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.Lssa_34_111:
    lea rax, [rel _str34]
    mov rbx, 28
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_110
.Lssa_34_115:
    mov rax, rax
.Lssa_34_116:
    mov rax, rax
.Lssa_34_117:
    mov rbx, rax
.Lssa_34_118:
.Lssa_34_119:
.Lssa_34_120:
.Lssa_34_121:
.Lssa_34_122:
.Lssa_34_123:
.Lssa_34_124:
.Lssa_34_125:
.Lssa_34_126:
.Lssa_34_127:
    mov rax, rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 10,0
_str1: db 48,0
_str2: db 61,61,61,32,80,114,105,109,105,116,105,118,101,32,84,121,112,101,115,32,61,61,61,10,0
_str3: db 115,105,122,101,111,102,40,117,56,41,32,61,32,0
_str4: db 115,105,122,101,111,102,40,117,49,54,41,32,61,32,0
_str5: db 115,105,122,101,111,102,40,117,51,50,41,32,61,32,0
_str6: db 115,105,122,101,111,102,40,117,54,52,41,32,61,32,0
_str7: db 115,105,122,101,111,102,40,105,54,52,41,32,61,32,0
_str8: db 10,61,61,61,32,80,111,105,110,116,101,114,32,84,121,112,101,115,32,61,61,61,10,0
_str9: db 115,105,122,101,111,102,40,42,117,56,41,32,61,32,0
_str10: db 115,105,122,101,111,102,40,42,117,54,52,41,32,61,32,0
_str11: db 115,105,122,101,111,102,40,42,42,117,54,52,41,32,61,32,0
_str12: db 10,61,61,61,32,83,116,114,117,99,116,32,84,121,112,101,115,32,61,61,61,10,0
_str13: db 115,105,122,101,111,102,40,80,111,105,110,116,41,32,61,32,0
_str14: db 115,105,122,101,111,102,40,82,101,99,116,41,32,61,32,0
_str15: db 115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,61,32,0
_str16: db 10,61,61,61,32,80,111,105,110,116,101,114,32,116,111,32,83,116,114,117,99,116,32,61,61,61,10,0
_str17: db 115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,61,32,0
_str18: db 115,105,122,101,111,102,40,42,82,101,99,116,41,32,61,32,0
_str19: db 10,61,61,61,32,86,97,108,105,100,97,116,105,111,110,32,61,61,61,10,0
_str20: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,56,41,32,115,104,111,117,108,100,32,98,101,32,49,10,0
_str21: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,49,54,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str22: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,51,50,41,32,115,104,111,117,108,100,32,98,101,32,52,10,0
_str23: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str24: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,105,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str25: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,56,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str26: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str27: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str28: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,49,54,10,0
_str29: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,51,50,10,0
_str30: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str31: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str32: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str33: db 65,108,108,32,115,105,122,101,111,102,32,116,101,115,116,115,32,80,65,83,83,69,68,33,10,0
_str34: db 83,111,109,101,32,115,105,122,101,111,102,32,116,101,115,116,115,32,70,65,73,76,69,68,33,10,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
