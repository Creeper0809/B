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
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    call std_os__os_sys_brk
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-24]
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
    mov rax, [rbp-24]
    push rax
    lea rax, [rel _gvar_std_io__heap_brk]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
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
    jz .L26
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
    jz .L27
    mov rax, [rbp-24]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L26
.L27:
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
.L26:
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
    jz .L29
    call std_io__io_get_output_fd
    mov [rbp-16], rax
    mov rax, 1
    push rax
    lea rax, [rel _str31]
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
.L29:
    mov rax, 32
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-24], rax
    mov rax, 0
    mov [rbp-32], rax
    mov rax, [rbp-8]
    mov [rbp-40], rax
.L32:
    mov rax, [rbp-40]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L33
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
    jmp .L32
.L33:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-56], rax
.L34:
    mov rax, [rbp-56]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L35
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
    jmp .L34
.L35:
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
    jz .L36
    call std_io__io_get_output_fd
    mov [rbp-16], rax
    mov rax, 1
    push rax
    lea rax, [rel _str38]
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
    jmp .L37
.L36:
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_io__print_u64
.L37:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_new:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, 24
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_len:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_cap:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_push:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-24], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-32], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L39
    mov rax, [rbp-32]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-40], rax
    mov rax, [rbp-40]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L41
    mov rax, 4
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
.L41:
    mov rax, [rbp-40]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-48], rax
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, 0
    mov [rbp-64], rax
.L43:
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L44
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-64]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-64]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    jmp .L43
.L44:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
.L39:
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-72], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-72]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_get:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_set:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-32], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_pop:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L45
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L45:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__fnv1a_hash:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 0
    mov [rbp-24], rax
    mov rax, 0
    mov [rbp-32], rax
.L47:
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L49
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, rax
    pop rax
    xor rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 31
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L48:
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
    jmp .L47
.L49:
    mov rax, [rbp-24]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_new:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, 16
    mov [rbp-16], rax
.L50:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L51
    mov rax, [rbp-16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L50
.L51:
    mov rax, 24
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-24], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-40], rax
    mov rax, 0
    mov [rbp-48], rax
.L52:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L54
    mov rax, 0
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
.L53:
    mov rax, [rbp-48]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    jmp .L52
.L54:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_entry_ptr:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp-8]
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
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_put_internal:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-40], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-48], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__fnv1a_hash
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-64], rax
    mov rax, 0
    mov [rbp-72], rax
.L55:
    mov rax, [rbp-72]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L57
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__hashmap_entry_ptr
    mov [rbp-80], rax
    mov rax, [rbp-80]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-88], rax
    mov rax, [rbp-88]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L58
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-80]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-80]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-80]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-80]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    mov rax, [rbp-80]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L58:
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L56:
    mov rax, [rbp-72]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
    jmp .L55
.L57:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_grow:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-40], rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    call std_io__heap_alloc
    mov [rbp-48], rax
    mov rax, 0
    mov [rbp-56], rax
.L60:
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L62
    mov rax, 0
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-56]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
.L61:
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
    jmp .L60
.L62:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 0
    mov [rbp-64], rax
.L63:
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L65
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-64]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-72], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-80], rax
    mov rax, [rbp-80]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, [rbp-72]
    mov rax, [rax]
    mov [rbp-88], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-96], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-104], rax
    mov rax, [rbp-104]
    push rax
    mov rax, [rbp-96]
    push rax
    mov rax, [rbp-88]
    push rax
    mov rax, [rbp-8]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_hashmap__hashmap_put_internal
.L66:
.L64:
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    jmp .L63
.L65:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_put:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-32], rcx
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-40], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-48], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L68
    mov rax, [rbp-8]
    push rax
    pop rdi
    call std_hashmap__hashmap_grow
    mov rax, [rbp-8]
    mov rax, [rax]
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
.L68:
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__fnv1a_hash
    mov [rbp-64], rax
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-72], rax
    mov rax, 0
    mov [rbp-80], rax
.L70:
    mov rax, [rbp-80]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L72
    mov rax, [rbp-72]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__hashmap_entry_ptr
    mov [rbp-88], rax
    mov rax, [rbp-88]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-96], rax
    mov rax, [rbp-96]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L73
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-88]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-88]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-88]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-88]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    mov rax, [rbp-88]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L73:
    mov rax, [rbp-88]
    mov rax, [rax]
    mov [rbp-104], rax
    mov rax, [rbp-88]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-112], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-112]
    push rax
    mov rax, [rbp-104]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_eq
    test rax, rax
    jz .L75
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-88]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L75:
    mov rax, [rbp-72]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
.L71:
    mov rax, [rbp-80]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-80]
    pop rbx
    mov [rax], rbx
    jmp .L70
.L72:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_get:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-32], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-40], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__fnv1a_hash
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-56], rax
    mov rax, 0
    mov [rbp-64], rax
.L77:
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L79
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-32]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__hashmap_entry_ptr
    mov [rbp-72], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-80], rax
    mov rax, [rbp-80]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L80
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L80:
    mov rax, [rbp-72]
    mov rax, [rax]
    mov [rbp-88], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-96], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-96]
    push rax
    mov rax, [rbp-88]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_eq
    test rax, rax
    jz .L82
    mov rax, [rbp-72]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
.L82:
    mov rax, [rbp-56]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
.L78:
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    jmp .L77
.L79:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_has:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov rax, [rbp-8]
    mov rax, [rax]
    mov [rbp-32], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-40], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__fnv1a_hash
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-56], rax
    mov rax, 0
    mov [rbp-64], rax
.L84:
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L86
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-32]
    push rax
    pop rdi
    pop rsi
    call std_hashmap__hashmap_entry_ptr
    mov [rbp-72], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-80], rax
    mov rax, [rbp-80]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L87
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L87:
    mov rax, [rbp-72]
    mov rax, [rax]
    mov [rbp-88], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-96], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-96]
    push rax
    mov rax, [rbp-88]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_str__str_eq
    test rax, rax
    jz .L89
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L89:
    mov rax, [rbp-56]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
.L85:
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    jmp .L84
.L86:
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 4
    push rax
    pop rdi
    call std_vec__vec_new
    mov [rbp-24], rax
    mov rax, 0
    mov [rbp-32], rax
.L91:
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L92
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    call std_vec__vec_push
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
    jmp .L91
.L92:
    mov rax, [rbp-24]
    push rax
    pop rdi
    call std_vec__vec_len
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L93
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L93:
    mov rax, 0
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    call std_vec__vec_get
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L95
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L95:
    mov rax, 5
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    call std_vec__vec_get
    push rax
    mov rax, 50
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L97
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L97:
    mov rax, 999
    push rax
    mov rax, 5
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_vec__vec_set
    mov rax, 5
    push rax
    mov rax, [rbp-24]
    push rax
    pop rdi
    pop rsi
    call std_vec__vec_get
    push rax
    mov rax, 999
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L99
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L99:
    mov rax, 8
    push rax
    pop rdi
    call std_hashmap__hashmap_new
    mov [rbp-40], rax
    lea rax, [rel _str101]
    mov [rbp-48], rax
    lea rax, [rel _str102]
    mov [rbp-56], rax
    lea rax, [rel _str103]
    mov [rbp-64], rax
    mov rax, 100
    push rax
    mov rax, [rbp-48]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_hashmap__hashmap_put
    mov rax, 200
    push rax
    mov rax, [rbp-56]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_hashmap__hashmap_put
    mov rax, 300
    push rax
    mov rax, [rbp-64]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call std_hashmap__hashmap_put
    mov rax, [rbp-48]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_hashmap__hashmap_get
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L104
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L104:
    mov rax, [rbp-56]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_hashmap__hashmap_get
    push rax
    mov rax, 200
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L106
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L106:
    mov rax, [rbp-64]
    push rax
    pop rdi
    call std_str__str_len
    push rax
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_hashmap__hashmap_get
    push rax
    mov rax, 300
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L108
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L108:
    mov rax, 5
    push rax
    lea rax, [rel _str101]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_hashmap__hashmap_has
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L110
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L110:
    mov rax, 6
    push rax
    lea rax, [rel _str114]
    push rax
    mov rax, [rbp-40]
    push rax
    pop rdi
    pop rsi
    pop rdx
    call std_hashmap__hashmap_has
    test rax, rax
    jz .L112
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
.L112:
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
_str31: db 48,0
_str38: db 45,0
_str101: db 97,112,112,108,101,0
_str102: db 98,97,110,97,110,97,0
_str103: db 99,104,101,114,114,121,0
_str114: db 111,114,97,110,103,101,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
