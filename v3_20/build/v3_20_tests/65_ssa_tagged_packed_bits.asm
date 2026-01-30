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
std_str__str_eq:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_0_0:
    mov rax, [rbp-1056]
    mov rbx, [rbp-1048]
    mov rcx, [rbp-1040]
    mov rdx, [rbp-1032]
    cmp rcx, rax
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_1
    jmp .Lssa_0_2
.Lssa_0_1:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_2
.Lssa_0_2:
    mov rax, 0
    mov r9, rax
    jmp .Lssa_0_3
.Lssa_0_3:
    cmp r9, rcx
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_4
    jmp .Lssa_0_6
.Lssa_0_4:
    mov rax, rdx
    add rax, r9
    movzx rax, byte [rax]
    mov r8, rbx
    add r8, r9
    movzx r8, byte [r8]
    cmp rax, r8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_7
    jmp .Lssa_0_8
.Lssa_0_5:
    lea rax, [rbp-8]
    mov rax, 1
    add rax, r9
    mov r9, rax
    jmp .Lssa_0_3
.Lssa_0_6:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.Lssa_0_7:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_8
.Lssa_0_8:
    jmp .Lssa_0_5
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_str__str_copy:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_1_9:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    mov rdx, 0
    mov r9, rdx
    jmp .Lssa_1_10
.Lssa_1_10:
    push rax
    cmp r9, rax
    setl al
    movzx rdx, al
    pop rax
    cmp rdx, 0
    jne .Lssa_1_11
    jmp .Lssa_1_13
.Lssa_1_11:
    mov rdx, rcx
    add rdx, r9
    mov r8, rbx
    add r8, r9
    movzx r8, byte [r8]
    mov byte [rdx], r8b
    jmp .Lssa_1_12
.Lssa_1_12:
    lea rdx, [rbp-8]
    mov rdx, 1
    add rdx, r9
    mov r9, rdx
    jmp .Lssa_1_10
.Lssa_1_13:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
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
    mov rdx, rbx
    jmp .Lssa_2_15
.Lssa_2_15:
    mov rbx, rax
    add rbx, rdx
    movzx rbx, byte [rbx]
    mov rcx, 0
    push rax
    cmp rbx, rcx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_2_16
    jmp .Lssa_2_17
.Lssa_2_16:
    lea rbx, [rbp-8]
    mov rbx, 1
    add rbx, rdx
    mov rdx, rbx
    jmp .Lssa_2_15
.Lssa_2_17:
    mov rax, rdx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_str__str_concat:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_3_18:
    mov rax, [rbp-1056]
    mov rbx, [rbp-1048]
    mov rcx, [rbp-1040]
    mov rdx, [rbp-1032]
    mov r8, rcx
    add r8, rax
    mov r9, 1
    mov r8, r8
    add r8, r9
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    pop rdi
    call std_io__heap_alloc
    mov r8, rax
    pop rdx
    pop rcx
    pop rbx
    pop rax
    push rax
    push rbx
    push rcx
    push r8
    push rcx
    push rdx
    push r8
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    pop r8
    pop rcx
    pop rbx
    pop rax
    mov rdx, r8
    add rdx, rcx
    push rax
    push rcx
    push r8
    push rax
    push rbx
    push rdx
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    pop r8
    pop rcx
    pop rax
    mov rbx, r8
    add rbx, rcx
    add rax, rbx
    mov rbx, 0
    mov byte [rax], bl
    mov rax, r8
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_str__str_concat3:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_4_19:
    mov rax, [rbp-1072]
    mov rbx, [rbp-1064]
    mov rcx, [rbp-1056]
    mov rdx, [rbp-1048]
    mov r8, [rbp-1040]
    mov r9, [rbp-1032]
    mov r10, r8
    add r10, rcx
    mov r10, r10
    add r10, rax
    mov r11, 1
    mov r10, r10
    add r10, r11
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    pop rdi
    call std_io__heap_alloc
    mov r10, rax
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r8
    push r9
    push r10
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    pop r10
    pop r10
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r9, r10
    add r9, r8
    push rax
    push rbx
    push rcx
    push r8
    push rcx
    push rdx
    push r9
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    pop r10
    pop r10
    pop r8
    pop rcx
    pop rbx
    pop rax
    mov rdx, r10
    add rdx, r8
    mov rdx, rdx
    add rdx, rcx
    push rax
    push rcx
    push r8
    push rax
    push rbx
    push rdx
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    pop r10
    pop r10
    pop r8
    pop rcx
    pop rax
    mov rbx, r10
    add rbx, r8
    mov rbx, rbx
    add rbx, rcx
    add rax, rbx
    mov rbx, 0
    mov byte [rax], bl
    mov rax, r10
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
std_os__os_sys_read:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_7_22:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    lea rdx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rdx], rcx
    lea rcx, [rel _gvar_std_os__g_syscall_arg1]
    mov [rcx], rbx
    lea rbx, [rel _gvar_std_os__g_syscall_arg2]
    mov [rbx], rax
    mov rax , 0
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
std_os__os_sys_open:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_8_23:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    lea rdx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rdx], rcx
    lea rcx, [rel _gvar_std_os__g_syscall_arg1]
    mov [rcx], rbx
    lea rbx, [rel _gvar_std_os__g_syscall_arg2]
    mov [rbx], rax
    mov rax , 2
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
std_os__os_sys_close:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_9_24:
    mov rax, [rbp-1032]
    lea rbx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rbx], rax
    mov rax , 3
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
std_os__os_sys_fstat:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_10_25:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rcx], rbx
    lea rbx, [rel _gvar_std_os__g_syscall_arg1]
    mov [rbx], rax
    mov rax , 5
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
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
std_os__os_sys_fork:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_11_26:
    mov rax , 57
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
std_os__os_sys_execve:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_12_27:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    lea rdx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rdx], rcx
    lea rcx, [rel _gvar_std_os__g_syscall_arg1]
    mov [rcx], rbx
    lea rbx, [rel _gvar_std_os__g_syscall_arg2]
    mov [rbx], rax
    mov rax , 59
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
std_os__os_sys_wait4:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_13_28:
    mov rax, [rbp-1056]
    mov rbx, [rbp-1048]
    mov rcx, [rbp-1040]
    mov rdx, [rbp-1032]
    lea r8, [rel _gvar_std_os__g_syscall_arg0]
    mov [r8], rdx
    lea rdx, [rel _gvar_std_os__g_syscall_arg1]
    mov [rdx], rcx
    lea rcx, [rel _gvar_std_os__g_syscall_arg2]
    mov [rcx], rbx
    lea rbx, [rel _gvar_std_os__g_syscall_arg3]
    mov [rbx], rax
    mov rax , 61
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
    mov rdx , [ rel _gvar_std_os__g_syscall_arg2 ]
    mov r10 , [ rel _gvar_std_os__g_syscall_arg3 ]
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
std_os__os_sys_exit:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_14_29:
    mov rax, [rbp-1032]
    lea rbx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rbx], rax
    mov rax , 60
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    syscall
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_dup2:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_15_30:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rel _gvar_std_os__g_syscall_arg0]
    mov [rcx], rbx
    lea rbx, [rel _gvar_std_os__g_syscall_arg1]
    mov [rbx], rax
    mov rax , 33
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
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
std_os__os_execute:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_16_31:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    push rax
    push rbx
    call std_os__os_sys_fork
    mov rcx, rax
    pop rbx
    pop rax
    mov rdx, 0
    push rax
    cmp rcx, rdx
    setl al
    movzx rdx, al
    pop rax
    cmp rdx, 0
    jne .Lssa_16_32
    jmp .Lssa_16_33
.Lssa_16_32:
    mov rdx, 9223372036854775807
    mov rax, rdx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_16_33
.Lssa_16_33:
    mov rdx, 0
    push rax
    cmp rcx, rdx
    sete al
    movzx rdx, al
    pop rax
    cmp rdx, 0
    jne .Lssa_16_34
    jmp .Lssa_16_35
.Lssa_16_34:
    mov rdx, 0
    push rcx
    push rdx
    push rax
    push rbx
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_execve
    pop rcx
    mov rbx, 1
    push rax
    push rcx
    push rbx
    pop rdi
    call std_os__os_sys_exit
    pop rcx
    pop rax
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_16_35
.Lssa_16_35:
    mov rax, 0
    lea rbx, [rbp-24]
    mov rdx, 0
    mov r8, 0
    push rax
    push r8
    push rdx
    push rbx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_os__os_sys_wait4
    pop rax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_16_99:
    mov rax, rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_brk:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_17_36:
    mov rax, [rbp-1032]
    push rax
    pop rdi
    call std_os__os_sys_brk
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
std_io__sys_read:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_19_38:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    push rax
    push rbx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_read
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_open:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_20_39:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    push rax
    push rbx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_open
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_close:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_21_40:
    mov rax, [rbp-1032]
    push rax
    pop rdi
    call std_os__os_sys_close
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_fstat:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_22_41:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    push rax
    push rbx
    pop rdi
    pop rsi
    call std_os__os_sys_fstat
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__io_set_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_23_42:
    mov rax, [rbp-1032]
    lea rbx, [rel _gvar_std_io__g_out_fd]
    mov [rbx], rax
    mov rax, 0
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
    mov rbx, 0
    cmp rax, rbx
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
    mov rbx, 0
    push rax
    cmp rax, rbx
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
    mov rcx, 0
    push rax
    cmp rbx, rcx
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
std_io__emitln:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_26_53:
    mov rax, [rbp-1032]
    push rax
    push rax
    pop rdi
    call std_str__str_len
    mov rbx, rax
    pop rax
    push rax
    push rbx
    call std_io__io_get_output_fd
    mov rcx, rax
    pop rbx
    pop rax
    push rcx
    push rbx
    push rax
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
    mov r8, rcx
    jmp .Lssa_27_55
.Lssa_27_55:
    push rax
    cmp r8, rax
    setl al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_27_56
    jmp .Lssa_27_57
.Lssa_27_56:
    mov rcx, rbx
    add rcx, r8
    movzx rcx, byte [rcx]
    mov rdx, 0
    push rax
    cmp rcx, rdx
    sete al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_27_58
    jmp .Lssa_27_59
.Lssa_27_57:
    push rbx
    push rdx
    call std_io__io_get_output_fd
    pop rdx
    pop rbx
    push rdx
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
    lea rax, [rbp+24]
    mov rdx, r8
    jmp .Lssa_27_57
.Lssa_27_59:
    lea rcx, [rbp-8]
    mov rcx, 1
    add rcx, r8
    mov r8, rcx
    jmp .Lssa_27_55
.Lssa_27_60:
    jmp .Lssa_27_59
.Lssa_27_100:
    mov rdx, rax
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
std_io__print_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_29_62:
    call std_io__io_get_output_fd
    lea rbx, [rel _str0]
    mov rcx, 1
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
    mov rbx, 0
    push rax
    cmp rax, rbx
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
    mov rax, 0
    cmp r9, rax
    setg al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_31_68
    jmp .Lssa_31_69
.Lssa_31_68:
    mov rax, 10
    push rdx
    mov rax, r9
    cqo
    idiv rax
    mov rax, rdx
    pop rdx
    mov rcx, rbx
    add rcx, r8
    mov rdx, 48
    add rdx, rax
    mov byte [rcx], dl
    lea rcx, [rbp-32]
    mov rcx, 10
    push rax
    push rdx
    mov rax, r9
    cqo
    idiv rcx
    mov rcx, rax
    pop rdx
    pop rax
    lea rdx, [rbp-24]
    mov rdx, 1
    add rdx, r8
    mov r8, rax
    mov r9, rcx
    mov r8, rdx
    jmp .Lssa_31_67
.Lssa_31_69:
    mov rax, 1
    mov rax, r8
    sub rax, rax
    mov rdx, rax
    mov r8, rax
    jmp .Lssa_31_70
.Lssa_31_70:
    mov rax, 0
    cmp r8, rax
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
    lea rcx, [rbp-48]
    mov rcx, 1
    mov rcx, r8
    sub rcx, rcx
    mov rdx, rax
    mov r8, rcx
    jmp .Lssa_31_70
.Lssa_31_72:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_31_101:
    mov rbx, rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_32_73:
    mov rax, [rbp-1032]
    mov rbx, 0
    push rax
    cmp rax, rbx
    setl al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_32_74
    jmp .Lssa_32_76
.Lssa_32_74:
    push rax
    call std_io__io_get_output_fd
    mov rbx, rax
    pop rax
    lea rcx, [rel _str2]
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
    mov rcx, 0
    mov rax, rcx
    sub rax, rax
    push rbx
    push rax
    pop rdi
    call std_io__print_u64
    pop rbx
    mov rax, rbx
    jmp .Lssa_32_75
.Lssa_32_75:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.Lssa_32_76:
    push rax
    pop rdi
    call std_io__print_u64
    mov rax, rax
    jmp .Lssa_32_75
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_65_ssa_tagged_packed_bits__test_tagged_ptr_basic:
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
    lea rax, [rbp-8]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    mov rbx, 4660
    mov rcx, 281474976710655
    mov rax, rax
    and rax, rcx
    mov rcx, 48
    push rcx
    mov rbx, rbx
    mov rcx, rcx
    shl rbx, cl
    pop rcx
    mov rax, rax
    or rax, rbx
    mov rbx, 281474976710655
    and rbx, rax
    mov rcx, 55
    mov byte [rbx], cl
    mov rbx, 281474976710655
    and rbx, rax
    mov rcx, 0
    mov rbx, rbx
    add rbx, rcx
    mov rcx, 66
    mov byte [rbx], cl
    mov rbx, 281474976710655
    and rbx, rax
    movzx rbx, byte [rbx]
    mov rcx, 66
    push rax
    cmp rbx, rcx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_78
    jmp .Lssa_33_79
.Lssa_33_78:
    mov rbx, 1
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_79
.Lssa_33_79:
    mov rbx, 281474976710655
    mov rax, rax
    and rax, rbx
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 66
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_33_80
    jmp .Lssa_33_81
.Lssa_33_80:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_81
.Lssa_33_81:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_65_ssa_tagged_packed_bits__test_tagged_layout_packed_struct:
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
    lea rax, [rbp-8]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    mov rbx, 281474976710655
    mov rax, rax
    and rax, rbx
    mov rbx, 1
    mov rcx, 65535
    mov rbx, rbx
    and rbx, rcx
    mov rcx, 48
    push rcx
    mov rbx, rbx
    mov rcx, rcx
    shl rbx, cl
    pop rcx
    mov rcx, 65535
    mov rdx, 48
    push rax
    mov rax, rcx
    mov rcx, rdx
    shl rax, cl
    mov rcx, rax
    pop rax
    mov rdx, 0
    mov r8, 1
    mov rdx, rdx
    sub rdx, r8
    mov rcx, rcx
    xor rcx, rdx
    mov rax, rax
    and rax, rcx
    mov rax, rax
    or rax, rbx
    mov rbx, 281474976710655
    and rbx, rax
    mov rcx, 77
    mov byte [rbx], cl
    mov rbx, 48
    push rcx
    mov rcx, rbx
    mov rbx, rax
    shr rbx, cl
    pop rcx
    mov rcx, 65535
    mov rbx, rbx
    and rbx, rcx
    mov rcx, 1
    push rax
    cmp rbx, rcx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_34_83
    jmp .Lssa_34_84
.Lssa_34_83:
    mov rbx, 3
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_34_84
.Lssa_34_84:
    mov rbx, 281474976710655
    mov rax, rax
    and rax, rbx
    movzx rax, byte [rax]
    mov rbx, 77
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_85
    jmp .Lssa_34_86
.Lssa_34_85:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_34_86
.Lssa_34_86:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_65_ssa_tagged_packed_bits__test_packed_bitfield_access:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_35_87:
    lea rax, [rbp-2]
    movzx rbx, word [rax]
    mov rcx, 3
    mov rdx, 15
    mov rcx, rcx
    and rcx, rdx
    mov rdx, 15
    mov r8, 0
    mov r9, 1
    mov r8, r8
    sub r8, r9
    mov rdx, rdx
    xor rdx, r8
    mov rbx, rbx
    and rbx, rdx
    mov rbx, rbx
    or rbx, rcx
    mov word [rax], bx
    lea rax, [rbp-2]
    movzx rbx, word [rax]
    mov rcx, 4095
    mov rdx, 4095
    mov rcx, rcx
    and rcx, rdx
    mov rdx, 4
    push rax
    mov rax, rcx
    mov rcx, rdx
    shl rax, cl
    mov rcx, rax
    pop rax
    mov rdx, 4095
    mov r8, 4
    push rcx
    mov rdx, rdx
    mov rcx, r8
    shl rdx, cl
    pop rcx
    mov r8, 0
    mov r9, 1
    mov r8, r8
    sub r8, r9
    mov rdx, rdx
    xor rdx, r8
    mov rbx, rbx
    and rbx, rdx
    mov rbx, rbx
    or rbx, rcx
    mov word [rax], bx
    lea rax, [rbp-2]
    movzx rax, word [rax]
    mov rbx, 15
    mov rax, rax
    and rax, rbx
    mov rbx, 3
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_35_88
    jmp .Lssa_35_89
.Lssa_35_88:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_35_89
.Lssa_35_89:
    lea rax, [rbp-2]
    movzx rax, word [rax]
    mov rbx, 4
    push rcx
    mov rax, rax
    mov rcx, rbx
    shr rax, cl
    pop rcx
    mov rbx, 4095
    mov rax, rax
    and rax, rbx
    mov rbx, 4095
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_35_90
    jmp .Lssa_35_91
.Lssa_35_90:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_35_91
.Lssa_35_91:
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
.Lssa_36_92:
    mov rax, 0
    lea rax, [rbp-8]
    call _65_ssa_tagged_packed_bits__test_tagged_ptr_basic
    mov rbx, 0
    push rax
    cmp rax, rbx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_36_93
    jmp .Lssa_36_94
.Lssa_36_93:
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_36_94
.Lssa_36_94:
    lea rax, [rbp-8]
    call _65_ssa_tagged_packed_bits__test_tagged_layout_packed_struct
    mov rbx, 0
    push rax
    cmp rax, rbx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_36_95
    jmp .Lssa_36_96
.Lssa_36_95:
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_36_96
.Lssa_36_96:
    lea rax, [rbp-8]
    call _65_ssa_tagged_packed_bits__test_packed_bitfield_access
    mov rbx, 0
    push rax
    cmp rax, rbx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_36_97
    jmp .Lssa_36_98
.Lssa_36_97:
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_36_98
.Lssa_36_98:
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
_str2: db 45,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
