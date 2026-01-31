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
.Lssa_28_63:
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
.Lssa_31_84:
    mov rbx, rax
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
.Lssa_33_81:
    lea rax, [rel _str2]
    mov rbx, 19
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 1
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
    lea rax, [rel _str0]
    mov rbx, 1
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 8
    lea rbx, [rel _str4]
    mov rcx, 14
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
    lea rax, [rel _str0]
    mov rbx, 1
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 8
    lea rbx, [rel _str5]
    mov rcx, 15
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
    lea rax, [rel _str0]
    mov rbx, 1
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 16
    lea rbx, [rel _str6]
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
    lea rax, [rel _str0]
    mov rbx, 1
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    lea rax, [rel _str7]
    mov rbx, 7
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
_str2: db 84,101,115,116,105,110,103,32,115,105,122,101,111,102,46,46,46,10,0
_str3: db 115,105,122,101,111,102,40,117,56,41,32,61,32,0
_str4: db 115,105,122,101,111,102,40,117,54,52,41,32,61,32,0
_str5: db 115,105,122,101,111,102,40,42,117,54,52,41,32,61,32,0
_str6: db 115,105,122,101,111,102,40,80,111,105,110,116,41,32,61,32,0
_str7: db 68,111,110,101,33,10,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
