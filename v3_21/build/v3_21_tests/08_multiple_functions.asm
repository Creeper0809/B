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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L0
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L0:
    mov rax, 0
    mov [rbp-40], rax
.L2:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L5
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L5:
.L3:
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L2
.L4:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_str__str_copy:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, 0
    mov [rbp-32], rax
.L7:
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L9
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
.L8:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    jmp .L7
.L9:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_str__str_len:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, 0
    mov [rbp-16], rax
.L10:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L11
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L10
.L11:
    mov rax, [rbp-16]
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-40], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    mov rax, 0
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-40]
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx
    mov [rbp-40], r8
    mov [rbp-48], r9
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-56], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-56]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    mov rax, 0
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-56]
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
    sub rsp, 2048
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
    sub rsp, 2048
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
std_os__os_sys_read:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
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
    mov rax , 0
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
std_os__os_sys_open:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
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
    mov rax , 2
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
std_os__os_sys_close:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_os__g_syscall_arg0]
    pop rbx
    mov [rax], rbx
    mov rax , 3
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
std_os__os_sys_fstat:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
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
    mov rax , 5
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
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
std_os__os_sys_fork:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax , 57
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
std_os__os_sys_execve:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
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
    mov rax , 59
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
std_os__os_sys_wait4:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx
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
    mov rax, [rbp-32]
    push rax
    lea rax, [rel _gvar_std_os__g_syscall_arg3]
    pop rbx
    mov [rax], rbx
    mov rax , 61
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
    mov rdx , [ rel _gvar_std_os__g_syscall_arg2 ]
    mov r10 , [ rel _gvar_std_os__g_syscall_arg3 ]
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
std_os__os_sys_exit:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_os__g_syscall_arg0]
    pop rbx
    mov [rax], rbx
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
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
    mov rax , 33
    mov rdi , [ rel _gvar_std_os__g_syscall_arg0 ]
    mov rsi , [ rel _gvar_std_os__g_syscall_arg1 ]
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
std_os__os_execute:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    call std_os__os_sys_fork
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, -1
    mov rsp, rbp
    pop rbp
    ret
.L12:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 0
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_execve
    mov [rbp-32], rax
    mov rax, 1
    push rax
    pop rdi
    call std_os__os_sys_exit
    mov rax, [rbp-32]
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 0
    mov [rbp-40], rax
    mov rax, 0
    push rax
    mov rax, 0
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_os__os_sys_wait4
    mov rax, [rbp-40]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__sys_brk:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_io__g_out_fd]
    pop rbx
    mov [rax], rbx
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
    sub rsp, 2048
    mov rax, [rel _gvar_std_io__g_out_fd]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L16:
    mov rax, [rel _gvar_std_io__g_out_fd]
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L18:
    mov rax, 0
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    and rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rel _gvar_std_io__heap_inited]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 0
    push rax
    pop rdi
    call std_os__os_sys_brk
    push rax
    lea rax, [rel _gvar_std_io__heap_brk]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    lea rax, [rel _gvar_std_io__heap_inited]
    pop rbx
    mov [rax], rbx
.L20:
    mov rax, [rel _gvar_std_io__heap_brk]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    and rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    mov [rbp-40], rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    pop rdi
    call std_os__os_sys_brk
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L22:
    mov rax, [rbp-48]
    push rax
    lea rax, [rel _gvar_std_io__heap_brk]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-40]
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_str__str_len
    mov [rbp-16], rax
    call std_io__io_get_output_fd
    mov [rbp-24], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    mov rax, 1
    push rax
    lea rax, [rel _str24]
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__emit:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 0
    mov [rbp-24], rax
.L25:
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L27
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L28
    mov rax, [rbp-24]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L27
.L28:
.L26:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    jmp .L25
.L27:
    call std_io__io_get_output_fd
    mov [rbp-32], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    call std_io__io_get_output_fd
    mov [rbp-24], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, 1
    push rax
    lea rax, [rel _str24]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__println:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    call std_io__io_get_output_fd
    mov [rbp-24], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    mov rax, 1
    push rax
    lea rax, [rel _str24]
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L30
    call std_io__io_get_output_fd
    mov [rbp-16], rax
    mov rax, 1
    push rax
    lea rax, [rel _str32]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L30:
    mov rax, 32
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-24], rax
    mov rax, 0
    mov [rbp-32], rax
    mov rax, [rbp-8]
    mov [rbp-40], rax
.L33:
    mov rax, [rbp-40]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L35
    mov rax, [rbp-40]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 48
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-40]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
.L34:
    jmp .L33
.L35:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-56], rax
.L36:
    mov rax, [rbp-56]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L38
    call std_io__io_get_output_fd
    mov [rbp-64], rax
    mov rax, 1
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-56]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-64]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
.L37:
    mov rax, [rbp-56]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L36
.L38:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L39
    call std_io__io_get_output_fd
    mov [rbp-16], rax
    mov rax, 1
    push rax
    lea rax, [rel _str41]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_os__os_sys_write
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    pop rdi
    call std_io__print_u64
    jmp .L40
.L39:
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_io__print_u64
.L40:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_path__path_dirname:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-24], rax
    mov rax, 0
    mov [rbp-32], rax
.L42:
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L44
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 47
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L45
    mov rax, [rbp-32]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L45:
.L43:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    jmp .L42
.L44:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L47
    mov rax, 2
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-40], rax
    mov rax, 46
    push rax
    mov rax, [rbp-40]
    pop rbx
    mov [rax], bl
    mov rax, 0
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-40]
    mov rsp, rbp
    pop rbp
    ret
.L47:
    mov rax, [rbp-24]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-48], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-48]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
    mov rax, 0
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-48]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_path__path_join:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx
    mov rax, 1
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-40], rax
    mov rax, 47
    push rax
    mov rax, [rbp-40]
    pop rbx
    mov [rax], bl
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9
    call std_str__str_concat3
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_path__module_to_path:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 2
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-24], rax
    mov rax, 46
    push rax
    mov rax, [rbp-24]
    pop rbx
    mov [rax], bl
    mov rax, 98
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, 2
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_concat
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_path__path_basename_noext:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-24], rax
    mov rax, 0
    mov [rbp-32], rax
.L49:
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L51
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 47
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L52
    mov rax, [rbp-32]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L52:
.L50:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    jmp .L49
.L51:
    mov rax, 0
    mov [rbp-40], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L54
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
.L54:
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-48], rax
    mov rax, [rbp-40]
    mov [rbp-56], rax
.L56:
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L58
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-56]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 46
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L59
    mov rax, [rbp-56]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
.L59:
.L57:
    mov rax, [rbp-56]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L56
.L58:
    mov rax, [rbp-16]
    mov [rbp-64], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L61
    mov rax, [rbp-48]
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L61:
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L63
    mov rax, [rbp-40]
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L63:
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-72], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-80], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L65
    mov rax, [rbp-72]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-80]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_str__str_copy
.L65:
    mov rax, 0
    push rax
    mov rax, [rbp-80]
    push rax
    mov rax, [rbp-72]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-80]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_char__is_alpha:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 65
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L69
    mov rax, [rbp-8]
    push rax
    mov rax, 90
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    setne al
    movzx rax, al
    jmp .L70
.L69:
    xor eax, eax
.L70:
    test rax, rax
    jz .L67
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L67:
    mov rax, [rbp-8]
    push rax
    mov rax, 97
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L73
    mov rax, [rbp-8]
    push rax
    mov rax, 122
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    setne al
    movzx rax, al
    jmp .L74
.L73:
    xor eax, eax
.L74:
    test rax, rax
    jz .L71
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L71:
    mov rax, [rbp-8]
    push rax
    mov rax, 95
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L75
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L75:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_char__is_digit:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 48
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L79
    mov rax, [rbp-8]
    push rax
    mov rax, 57
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    setne al
    movzx rax, al
    jmp .L80
.L79:
    xor eax, eax
.L80:
    test rax, rax
    jz .L77
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L77:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_char__is_alnum:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_char__is_alpha
    test rax, rax
    jz .L81
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L81:
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_char__is_digit
    test rax, rax
    jz .L83
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L83:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_char__is_whitespace:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L85
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L85:
    mov rax, [rbp-8]
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L87
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L87:
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L89
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L89:
    mov rax, [rbp-8]
    push rax
    mov rax, 13
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L91
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L91:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__init_stack_trace:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, [rel _gvar_std_util__g_stack_initialized]
    test rax, rax
    jz .L93
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L93:
    mov rax, 128
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    push rax
    lea rax, [rel _gvar_std_util__g_stack_frames]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    lea rax, [rel _gvar_std_util__g_stack_depth]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    lea rax, [rel _gvar_std_util__g_stack_initialized]
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__push_trace:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rel _gvar_std_util__g_stack_initialized]
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L95
    call std_util__init_stack_trace
.L95:
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 128
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L97
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L97:
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_str__str_len
    mov [rbp-32], rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    call std_str__str_len
    mov [rbp-40], rax
    mov rax, [rel _gvar_std_util__g_stack_frames]
    push rax
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-48], rax
    mov rax, [rbp-48]
    mov [rbp-56], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-56]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-56]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-56]
    push rax
    pop rax
    add rax, 16
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-56]
    push rax
    pop rax
    add rax, 24
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-56]
    push rax
    pop rax
    add rax, 32
    pop rbx
    mov [rax], rbx
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rel _gvar_std_util__g_stack_depth]
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__pop_trace:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L99
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rel _gvar_std_util__g_stack_depth]
    pop rbx
    mov [rax], rbx
.L99:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__print_stack_trace:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, [rel _gvar_std_util__g_stack_initialized]
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L101
    mov rax, 28
    push rax
    lea rax, [rel _str103]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L101:
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L104
    mov rax, 24
    push rax
    lea rax, [rel _str106]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L104:
    mov rax, 38
    push rax
    lea rax, [rel _str107]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
    mov rax, [rel _gvar_std_util__g_stack_depth]
    mov [rbp-8], rax
.L108:
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L110
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-16], rax
    mov rax, [rel _gvar_std_util__g_stack_frames]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-24]
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    pop rax
    mov rax, [rax]
    mov [rbp-40], rax
    mov rax, [rbp-32]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov [rbp-48], rax
    mov rax, [rbp-32]
    push rax
    pop rax
    add rax, 16
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, [rbp-32]
    push rax
    pop rax
    add rax, 24
    mov rax, [rax]
    mov [rbp-64], rax
    mov rax, [rbp-32]
    push rax
    pop rax
    add rax, 32
    mov rax, [rax]
    mov [rbp-72], rax
    mov rax, 5
    push rax
    lea rax, [rel _str111]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, 2
    push rax
    lea rax, [rel _str112]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-56]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, 1
    push rax
    lea rax, [rel _str113]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, [rbp-72]
    push rax
    pop rdi
    call std_util__emit_i64_stderr
    mov rax, 1
    push rax
    lea rax, [rel _str114]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
.L109:
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L108
.L110:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__set_parsing_context:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_util__g_current_func_name]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    lea rax, [rel _gvar_std_util__g_current_func_name_len]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    lea rax, [rel _gvar_std_util__g_current_func_line]
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__begin_error_capture:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, [rel _gvar_std_util__g_error_buffer]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L115
    mov rax, 512
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    push rax
    lea rax, [rel _gvar_std_util__g_error_buffer]
    pop rbx
    mov [rax], rbx
.L115:
    mov rax, 0
    push rax
    lea rax, [rel _gvar_std_util__g_error_buffer_pos]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    lea rax, [rel _gvar_std_util__g_capturing_error]
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__end_error_capture:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, 0
    push rax
    lea rax, [rel _gvar_std_util__g_capturing_error]
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__set_error_context:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_util__g_last_error_msg]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    lea rax, [rel _gvar_std_util__g_last_error_len]
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_error:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 8
    push rax
    lea rax, [rel _str117]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
    mov rax, [rbp-8]
    push rax
    lea rax, [rel _gvar_std_util__g_last_error_msg]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    lea rax, [rel _gvar_std_util__g_last_error_len]
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__panic:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    call std_util__end_error_capture
    mov rax, [rel _gvar_std_util__g_current_func_name]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L118
    call std_util__emit_stderr_nl
    mov rax, 16
    push rax
    lea rax, [rel _str120]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
    mov rax, 18
    push rax
    lea rax, [rel _str121]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, [rel _gvar_std_util__g_current_func_name_len]
    push rax
    mov rax, [rel _gvar_std_util__g_current_func_name]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, 7
    push rax
    lea rax, [rel _str122]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, [rel _gvar_std_util__g_current_func_line]
    push rax
    pop rdi
    call std_util__emit_i64_stderr
    mov rax, 1
    push rax
    lea rax, [rel _str114]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
.L118:
    call std_util__emit_stderr_nl
    mov rax, 24
    push rax
    lea rax, [rel _str123]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
    call std_util__print_stack_trace
    mov rax, [rel _gvar_std_util__g_error_buffer_pos]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L124
    call std_util__emit_stderr_nl
    mov rax, 14
    push rax
    lea rax, [rel _str126]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
    mov rax, [rel _gvar_std_util__g_error_buffer_pos]
    push rax
    mov rax, [rel _gvar_std_util__g_error_buffer]
    push rax
    mov rax, 2
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
    call std_util__emit_stderr_nl
.L124:
    call std_util__emit_stderr_nl
    mov rax, 0
    mov rax, [rax]
    mov [rbp-8], rax
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_stderr:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rel _gvar_std_util__g_capturing_error]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L127
    mov rax, [rel _gvar_std_util__g_error_buffer_pos]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 512
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L129
    mov rax, 0
    mov [rbp-24], rax
.L131:
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L133
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, [rel _gvar_std_util__g_error_buffer]
    push rax
    mov rax, [rel _gvar_std_util__g_error_buffer_pos]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rel _gvar_std_util__g_error_buffer_pos]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rel _gvar_std_util__g_error_buffer_pos]
    pop rbx
    mov [rax], rbx
.L132:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    jmp .L131
.L133:
.L129:
    jmp .L128
.L127:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
.L128:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_stderr_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, 1
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-8], rax
    mov rax, 10
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], bl
    mov rax, 1
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__warn:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 7
    push rax
    lea rax, [rel _str134]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    call std_util__emit_stderr_nl
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_char:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, 1
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    pop rbx
    mov [rax], bl
    mov rax, 1
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L135
    mov rax, 1
    push rax
    lea rax, [rel _str32]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L135:
    mov rax, 32
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-16], rax
    mov rax, 0
    mov [rbp-24], rax
    mov rax, [rbp-8]
    mov [rbp-32], rax
.L137:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L139
    mov rax, 48
    push rax
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L138:
    jmp .L137
.L139:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-40], rax
.L140:
    mov rax, [rbp-40]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L142
    mov rax, 1
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
.L141:
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L140
.L142:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_u64_stderr:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L143
    mov rax, 1
    push rax
    lea rax, [rel _str32]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L143:
    mov rax, 32
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-16], rax
    mov rax, 0
    mov [rbp-24], rax
    mov rax, [rbp-8]
    mov [rbp-32], rax
.L145:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L147
    mov rax, 48
    push rax
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L146:
    jmp .L145
.L147:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-40], rax
.L148:
    mov rax, [rbp-40]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L150
    mov rax, 1
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
.L149:
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L148
.L150:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L151
    mov rax, 1
    push rax
    lea rax, [rel _str41]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    pop rdi
    call std_util__emit_u64
    jmp .L152
.L151:
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_util__emit_u64
.L152:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_i64_stderr:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L153
    mov rax, 1
    push rax
    lea rax, [rel _str41]
    push rax
    pop rdi
    pop rsi
    call std_util__emit_stderr
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    pop rdi
    call std_util__emit_u64_stderr
    jmp .L154
.L153:
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_util__emit_u64_stderr
.L154:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, 1
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-8], rax
    mov rax, 10
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], bl
    mov rax, 1
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_io__sys_write
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_08_multiple_functions__add:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_08_multiple_functions__subtract:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_08_multiple_functions__multiply:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_08_multiple_functions__divide:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L155
    mov rax, 24
    push rax
    lea rax, [rel _str157]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L155:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_08_multiple_functions__calculator:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-16]
    push rax
    pop rdi
    call std_util__emit_i64
    mov rax, 1
    push rax
    lea rax, [rel _str158]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 1
    push rax
    lea rax, [rel _str158]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, [rbp-24]
    push rax
    pop rdi
    call std_util__emit_i64
    mov rax, 3
    push rax
    lea rax, [rel _str159]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 1
    push rax
    lea rax, [rel _str162]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_eq
    test rax, rax
    jz .L160
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call _08_multiple_functions__add
    push rax
    pop rdi
    call std_util__emit_i64
    jmp .L161
.L160:
    mov rax, 1
    push rax
    lea rax, [rel _str41]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_eq
    test rax, rax
    jz .L163
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call _08_multiple_functions__subtract
    push rax
    pop rdi
    call std_util__emit_i64
    jmp .L164
.L163:
    mov rax, 1
    push rax
    lea rax, [rel _str167]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_eq
    test rax, rax
    jz .L165
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call _08_multiple_functions__multiply
    push rax
    pop rdi
    call std_util__emit_i64
    jmp .L166
.L165:
    mov rax, 1
    push rax
    lea rax, [rel _str170]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_eq
    test rax, rax
    jz .L168
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call _08_multiple_functions__divide
    push rax
    pop rdi
    call std_util__emit_i64
.L168:
.L166:
.L164:
.L161:
    call std_util__emit_nl
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 17
    push rax
    lea rax, [rel _str171]
    push rax
    pop rdi
    pop rsi
    call std_io__emit
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str162]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _08_multiple_functions__calculator
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str41]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _08_multiple_functions__calculator
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str167]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _08_multiple_functions__calculator
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str170]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _08_multiple_functions__calculator
    mov rax, 0
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str170]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _08_multiple_functions__calculator
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret

section .data
_str24: db 10,0
_str32: db 48,0
_str41: db 45,0
_str103: db 32,32,40,110,111,32,115,116,97,99,107,32,116,114,97,99,101,32,97,118,97,105,108,97,98,108,101,41,0
_str106: db 32,32,40,115,116,97,99,107,32,116,114,97,99,101,32,105,115,32,101,109,112,116,121,41,0
_str107: db 83,116,97,99,107,32,116,114,97,99,101,32,40,109,111,115,116,32,114,101,99,101,110,116,32,99,97,108,108,32,102,105,114,115,116,41,58,0
_str111: db 32,32,97,116,32,0
_str112: db 32,40,0
_str113: db 58,0
_str114: db 41,0
_str117: db 91,69,82,82,79,82,93,32,0
_str120: db 80,97,114,115,105,110,103,32,99,111,110,116,101,120,116,58,0
_str121: db 32,32,45,62,32,73,110,32,102,117,110,99,116,105,111,110,58,32,0
_str122: db 32,40,108,105,110,101,32,0
_str123: db 67,111,109,112,105,108,101,114,32,105,110,116,101,114,110,97,108,32,116,114,97,99,101,58,0
_str126: db 69,114,114,111,114,32,100,101,116,97,105,108,115,58,0
_str134: db 91,87,65,82,78,93,32,0
_str157: db 69,114,114,111,114,58,32,68,105,118,105,115,105,111,110,32,98,121,32,122,101,114,111,10,0
_str158: db 32,0
_str159: db 32,61,32,0
_str162: db 43,0
_str167: db 42,0
_str170: db 47,0
_str171: db 67,97,108,99,117,108,97,116,111,114,32,116,101,115,116,58,10,0

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
