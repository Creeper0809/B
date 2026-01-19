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
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+40]
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
    mov [rbp-8], rax
.L2:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp-8]
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
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, 0
    mov [rbp-8], rax
.L7:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L9
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
.L8:
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, 0
    mov [rbp-8], rax
.L10:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
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
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L10
.L11:
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_str__str_copy
    add rsp, 24
    mov rax, [rbp+40]
    push rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_str__str_copy
    add rsp, 24
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+40]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+56]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_str__str_copy
    add rsp, 24
    mov rax, [rbp+40]
    push rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_str__str_copy
    add rsp, 24
    mov rax, [rbp+56]
    push rax
    mov rax, [rbp+48]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_str__str_copy
    add rsp, 24
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+56]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 12
    mov rdi , [ rbp + 16 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    mov rax , 1
    mov rdi , [ rbp + 16 ]
    mov rsi , [ rbp + 24 ]
    mov rdx , [ rbp + 32 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 0
    mov rdi , [ rbp + 16 ]
    mov rsi , [ rbp + 24 ]
    mov rdx , [ rbp + 32 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 2
    mov rdi , [ rbp + 16 ]
    mov rsi , [ rbp + 24 ]
    mov rdx , [ rbp + 32 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 3
    mov rdi , [ rbp + 16 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 5
    mov rdi , [ rbp + 16 ]
    mov rsi , [ rbp + 24 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 57
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 59
    mov rdi , [ rbp + 16 ]
    mov rsi , [ rbp + 24 ]
    mov rdx , [ rbp + 32 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 61
    mov rdi , [ rbp + 16 ]
    mov rsi , [ rbp + 24 ]
    mov rdx , [ rbp + 32 ]
    mov r10 , [ rbp + 40 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax , 60
    mov rdi , [ rbp + 16 ]
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
    sub rsp, 1024
    mov rax , 33
    mov rdi , [ rbp + 16 ]
    mov rsi , [ rbp + 24 ]
    syscall
    mov [ rbp - 8 ] , rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    call std_os__os_sys_fork
    mov [rbp-8], rax
    mov rax, [rbp-8]
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
    mov rax, [rbp-8]
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
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_os__os_sys_execve
    add rsp, 24
    mov [rbp-16], rax
    mov rax, 1
    push rax
    call std_os__os_sys_exit
    add rsp, 8
    mov rax, [rbp-16]
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 0
    mov [rbp-24], rax
    mov rax, 0
    push rax
    mov rax, 0
    push rax
    lea rax, [rbp-24]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_wait4
    add rsp, 32
    mov rax, [rbp-24]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    call std_os__os_sys_brk
    add rsp, 8
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
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_os__os_sys_write
    add rsp, 24
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
    sub rsp, 1024
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_os__os_sys_read
    add rsp, 24
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
    sub rsp, 1024
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_os__os_sys_open
    add rsp, 24
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    call std_os__os_sys_close
    add rsp, 8
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
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_os__os_sys_fstat
    add rsp, 16
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
    sub rsp, 1024
    mov rax, [rbp+16]
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
    sub rsp, 1024
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
    sub rsp, 1024
    mov rax, [rbp+16]
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
    call std_os__os_sys_brk
    add rsp, 8
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
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    call std_os__os_sys_brk
    add rsp, 8
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
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
    mov rax, [rbp-16]
    push rax
    lea rax, [rel _gvar_std_io__heap_brk]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    call std_str__str_len
    add rsp, 8
    mov [rbp-8], rax
    call std_io__io_get_output_fd
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-16]
    push rax
    call std_os__os_sys_write
    add rsp, 24
    mov rax, 1
    push rax
    lea rax, [rel _str24]
    push rax
    mov rax, [rbp-16]
    push rax
    call std_os__os_sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__emit:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, 1
    push rax
    lea rax, [rel _str24]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__println:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
    mov rax, 1
    push rax
    lea rax, [rel _str24]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L25
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, 1
    push rax
    lea rax, [rel _str27]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L25:
    mov rax, 32
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-16], rax
    mov rax, 0
    mov [rbp-24], rax
    mov rax, [rbp+16]
    mov [rbp-32], rax
.L28:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L29
    mov rax, [rbp-32]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-40], rax
    mov rax, [rbp-40]
    push rax
    mov rax, 48
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
    jmp .L28
.L29:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-48], rax
.L30:
    mov rax, [rbp-48]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L31
    call std_io__io_get_output_fd
    mov [rbp-56], rax
    mov rax, 1
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-56]
    push rax
    call std_os__os_sys_write
    add rsp, 24
    mov rax, [rbp-48]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    jmp .L30
.L31:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_io__print_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L32
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, 1
    push rax
    lea rax, [rel _str34]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call std_io__print_u64
    add rsp, 8
    jmp .L33
.L32:
    mov rax, [rbp+16]
    push rax
    call std_io__print_u64
    add rsp, 8
.L33:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_char__is_alpha:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 65
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L37
    mov rax, [rbp+16]
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
    jmp .L38
.L37:
    xor eax, eax
.L38:
    test rax, rax
    jz .L35
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L35:
    mov rax, [rbp+16]
    push rax
    mov rax, 97
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L41
    mov rax, [rbp+16]
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
    jmp .L42
.L41:
    xor eax, eax
.L42:
    test rax, rax
    jz .L39
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L39:
    mov rax, [rbp+16]
    push rax
    mov rax, 95
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L43
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L43:
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 48
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L47
    mov rax, [rbp+16]
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
    jmp .L48
.L47:
    xor eax, eax
.L48:
    test rax, rax
    jz .L45
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L45:
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    call std_char__is_alpha
    add rsp, 8
    test rax, rax
    jz .L49
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L49:
    mov rax, [rbp+16]
    push rax
    call std_char__is_digit
    add rsp, 8
    test rax, rax
    jz .L51
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L51:
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L53
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L53:
    mov rax, [rbp+16]
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L55
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L55:
    mov rax, [rbp+16]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L57
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L57:
    mov rax, [rbp+16]
    push rax
    mov rax, 13
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L59
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L59:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_path__path_dirname:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
.L61:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L63
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-16]
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
    jz .L64
    mov rax, [rbp-16]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L64:
.L62:
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
    jmp .L61
.L63:
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, 2
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-24], rax
    mov rax, 46
    push rax
    mov rax, [rbp-24]
    pop rbx
    mov [rax], bl
    mov rax, 0
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-24]
    mov rsp, rbp
    pop rbp
    ret
.L66:
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-32], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-32]
    push rax
    call std_str__str_copy
    add rsp, 24
    mov rax, 0
    push rax
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-32]
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
    sub rsp, 1024
    mov rax, 1
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 47
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], bl
    mov rax, [rbp+40]
    push rax
    mov rax, [rbp+32]
    push rax
    mov rax, 1
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_concat3
    add rsp, 48
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
    sub rsp, 1024
    mov rax, 2
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 46
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], bl
    mov rax, 98
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, 2
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_concat
    add rsp, 32
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
    sub rsp, 1024
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
.L68:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L70
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-16]
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
    jz .L71
    mov rax, [rbp-16]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L71:
.L69:
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
    jmp .L68
.L70:
    mov rax, 0
    mov [rbp-24], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L73
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L73:
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-32], rax
    mov rax, [rbp-24]
    mov [rbp-40], rax
.L75:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L77
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-40]
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
    jz .L78
    mov rax, [rbp-40]
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
.L78:
.L76:
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
    jmp .L75
.L77:
    mov rax, [rbp+24]
    mov [rbp-48], rax
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L80
    mov rax, [rbp-32]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
.L80:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L82
    mov rax, [rbp-24]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
.L82:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-64], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L84
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-64]
    push rax
    call std_str__str_copy
    add rsp, 24
.L84:
    mov rax, 0
    push rax
    mov rax, [rbp-64]
    push rax
    mov rax, [rbp-56]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-64]
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
    sub rsp, 1024
    mov rax, [rel _gvar_std_util__g_stack_initialized]
    test rax, rax
    jz .L86
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L86:
    mov rax, 128
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
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
    sub rsp, 1024
    mov rax, [rel _gvar_std_util__g_stack_initialized]
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L88
    call std_util__init_stack_trace
.L88:
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 128
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L90
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L90:
    mov rax, [rbp+16]
    push rax
    call std_str__str_len
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp+24]
    push rax
    call std_str__str_len
    add rsp, 8
    mov [rbp-16], rax
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
    mov [rbp-24], rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
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
    sub rsp, 1024
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L92
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
.L92:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__print_stack_trace:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rel _gvar_std_util__g_stack_initialized]
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L94
    mov rax, 28
    push rax
    lea rax, [rel _str96]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L94:
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L97
    mov rax, 24
    push rax
    lea rax, [rel _str99]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L97:
    mov rax, 38
    push rax
    lea rax, [rel _str100]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    mov rax, [rel _gvar_std_util__g_stack_depth]
    mov [rbp-8], rax
.L101:
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L102
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
    mov rax, [rel _gvar_std_util__g_stack_frames]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-24], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-32], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-40], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-48], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, 5
    push rax
    lea rax, [rel _str103]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-24]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, 2
    push rax
    lea rax, [rel _str104]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-40]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, 1
    push rax
    lea rax, [rel _str105]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rbp-56]
    push rax
    call std_util__emit_i64_stderr
    add rsp, 8
    mov rax, 1
    push rax
    lea rax, [rel _str106]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    jmp .L101
.L102:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__set_parsing_context:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rel _gvar_std_util__g_current_func_name]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rel _gvar_std_util__g_current_func_name_len]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
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
    sub rsp, 1024
    mov rax, [rel _gvar_std_util__g_error_buffer]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L107
    mov rax, 512
    push rax
    call std_io__heap_alloc
    add rsp, 8
    push rax
    lea rax, [rel _gvar_std_util__g_error_buffer]
    pop rbx
    mov [rax], rbx
.L107:
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
    sub rsp, 1024
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rel _gvar_std_util__g_last_error_msg]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, 8
    push rax
    lea rax, [rel _str109]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    mov rax, [rbp+16]
    push rax
    lea rax, [rel _gvar_std_util__g_last_error_msg]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
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
    sub rsp, 1024
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
    jz .L110
    call std_util__emit_stderr_nl
    mov rax, 16
    push rax
    lea rax, [rel _str112]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    mov rax, 18
    push rax
    lea rax, [rel _str113]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rel _gvar_std_util__g_current_func_name_len]
    push rax
    mov rax, [rel _gvar_std_util__g_current_func_name]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, 7
    push rax
    lea rax, [rel _str114]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rel _gvar_std_util__g_current_func_line]
    push rax
    call std_util__emit_i64_stderr
    add rsp, 8
    mov rax, 1
    push rax
    lea rax, [rel _str106]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
.L110:
    call std_util__emit_stderr_nl
    mov rax, 24
    push rax
    lea rax, [rel _str115]
    push rax
    call std_util__emit_stderr
    add rsp, 16
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
    jz .L116
    call std_util__emit_stderr_nl
    mov rax, 14
    push rax
    lea rax, [rel _str118]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    mov rax, [rel _gvar_std_util__g_error_buffer_pos]
    push rax
    mov rax, [rel _gvar_std_util__g_error_buffer]
    push rax
    mov rax, 2
    push rax
    call std_io__sys_write
    add rsp, 24
    call std_util__emit_stderr_nl
.L116:
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
    sub rsp, 1024
    mov rax, [rel _gvar_std_util__g_capturing_error]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L119
    mov rax, [rel _gvar_std_util__g_error_buffer_pos]
    push rax
    mov rax, [rbp+24]
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
    jz .L121
    mov rax, 0
    mov [rbp-8], rax
.L123:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L124
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
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
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L123
.L124:
.L121:
    jmp .L120
.L119:
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    push rax
    call std_io__sys_write
    add rsp, 24
.L120:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_stderr_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 1
    push rax
    call std_io__heap_alloc
    add rsp, 8
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
    call std_io__sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__warn:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 7
    push rax
    lea rax, [rel _str125]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_char:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 1
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp+16]
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
    call std_io__sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L126
    mov rax, 1
    push rax
    lea rax, [rel _str27]
    push rax
    call std_io__emit
    add rsp, 16
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L126:
    mov rax, 32
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
    mov rax, [rbp+16]
    mov [rbp-24], rax
.L128:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L129
    mov rax, 48
    push rax
    mov rax, [rbp-24]
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
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-24]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
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
    jmp .L128
.L129:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-32], rax
.L130:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L131
    mov rax, 1
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    push rax
    call std_io__sys_write
    add rsp, 24
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    jmp .L130
.L131:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_u64_stderr:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L132
    mov rax, 1
    push rax
    lea rax, [rel _str27]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L132:
    mov rax, 32
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
    mov rax, [rbp+16]
    mov [rbp-24], rax
.L134:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L135
    mov rax, 48
    push rax
    mov rax, [rbp-24]
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
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-24]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
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
    jmp .L134
.L135:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-32], rax
.L136:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L137
    mov rax, 1
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    jmp .L136
.L137:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L138
    mov rax, 1
    push rax
    lea rax, [rel _str34]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call std_util__emit_u64
    add rsp, 8
    jmp .L139
.L138:
    mov rax, [rbp+16]
    push rax
    call std_util__emit_u64
    add rsp, 8
.L139:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_i64_stderr:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L140
    mov rax, 1
    push rax
    lea rax, [rel _str34]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call std_util__emit_u64_stderr
    add rsp, 8
    jmp .L141
.L140:
    mov rax, [rbp+16]
    push rax
    call std_util__emit_u64_stderr
    add rsp, 8
.L141:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_util__emit_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 1
    push rax
    call std_io__heap_alloc
    add rsp, 8
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
    call std_io__sys_write
    add rsp, 24
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_vec__vec_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 24
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, [rbp+16]
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
    sub rsp, 1024
    mov rax, [rbp+16]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L142
    mov rax, [rbp-16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L144
    mov rax, 4
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L144:
    mov rax, [rbp-24]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-32], rax
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-40], rax
    mov rax, 0
    mov [rbp-48], rax
.L146:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L147
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-48]
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
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-48]
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
    jmp .L146
.L147:
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp+16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
.L142:
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-8]
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
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L148
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L148:
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, 0
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
.L150:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L152
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, rax
    pop rax
    xor rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 31
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L151:
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
    jmp .L150
.L152:
    mov rax, [rbp-8]
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
    sub rsp, 1024
    mov rax, 16
    mov [rbp-8], rax
.L153:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L154
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L153
.L154:
    mov rax, 24
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-32], rax
    mov rax, 0
    mov [rbp-40], rax
.L155:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L157
    mov rax, 0
    push rax
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
.L156:
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
    jmp .L155
.L157:
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 0
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
std_hashmap__hashmap_entry_ptr:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call std_hashmap__fnv1a_hash
    add rsp, 16
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-32], rax
    mov rax, 0
    mov [rbp-40], rax
.L158:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L160
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_hashmap__hashmap_entry_ptr
    add rsp, 16
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L161
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+40]
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
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
    mov rax, [rbp+16]
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
.L161:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
.L159:
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
    jmp .L158
.L160:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_grow:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-40], rax
    mov rax, 0
    mov [rbp-48], rax
.L163:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L165
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
.L164:
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
    jmp .L163
.L165:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp+16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 0
    mov [rbp-56], rax
.L166:
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L168
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-64], rax
    mov rax, [rbp-64]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-72], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L169
    mov rax, [rbp-64]
    mov rax, [rax]
    mov [rbp-80], rax
    mov rax, [rbp-64]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-88], rax
    mov rax, [rbp-64]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-96], rax
    mov rax, [rbp-96]
    push rax
    mov rax, [rbp-88]
    push rax
    mov rax, [rbp-80]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_hashmap__hashmap_put_internal
    add rsp, 32
.L169:
.L167:
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
    jmp .L166
.L168:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_put:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-16]
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
    jz .L171
    mov rax, [rbp+16]
    push rax
    call std_hashmap__hashmap_grow
    add rsp, 8
    mov rax, [rbp+16]
    mov rax, [rax]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L171:
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call std_hashmap__fnv1a_hash
    add rsp, 16
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-40], rax
    mov rax, 0
    mov [rbp-48], rax
.L173:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L175
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_hashmap__hashmap_entry_ptr
    add rsp, 16
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-64], rax
    mov rax, [rbp-64]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L176
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+40]
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    mov rax, [rbp-56]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
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
    mov rax, [rbp+16]
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
.L176:
    mov rax, [rbp-56]
    mov rax, [rax]
    mov [rbp-72], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-80], rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-80]
    push rax
    mov rax, [rbp-72]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L178
    mov rax, [rbp+40]
    push rax
    mov rax, [rbp-56]
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
.L178:
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
.L174:
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
    jmp .L173
.L175:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_get:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call std_hashmap__fnv1a_hash
    add rsp, 16
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-32], rax
    mov rax, 0
    mov [rbp-40], rax
.L180:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L182
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_hashmap__hashmap_entry_ptr
    add rsp, 16
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L183
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L183:
    mov rax, [rbp-48]
    mov rax, [rax]
    mov [rbp-64], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-72], rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-72]
    push rax
    mov rax, [rbp-64]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L185
    mov rax, [rbp-48]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
.L185:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
.L181:
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
    jmp .L180
.L182:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_hashmap__hashmap_has:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call std_hashmap__fnv1a_hash
    add rsp, 16
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    mov [rbp-32], rax
    mov rax, 0
    mov [rbp-40], rax
.L187:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L189
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_hashmap__hashmap_entry_ptr
    add rsp, 16
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L190
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L190:
    mov rax, [rbp-48]
    mov rax, [rax]
    mov [rbp-64], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rax, [rax]
    mov [rbp-72], rax
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp-72]
    push rax
    mov rax, [rbp-64]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L192
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L192:
    mov rax, [rbp-32]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
.L188:
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
    jmp .L187
.L189:
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
    sub rsp, 1024
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 5
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 9
    push rax
    lea rax, [rel _str194]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, [rbp-24]
    push rax
    call std_util__emit_i64
    add rsp, 8
    call std_util__emit_nl
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 9
    push rax
    lea rax, [rel _str195]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, [rbp-24]
    push rax
    call std_util__emit_i64
    add rsp, 8
    call std_util__emit_nl
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 9
    push rax
    lea rax, [rel _str196]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, [rbp-24]
    push rax
    call std_util__emit_i64
    add rsp, 8
    call std_util__emit_nl
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 9
    push rax
    lea rax, [rel _str197]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, [rbp-24]
    push rax
    call std_util__emit_i64
    add rsp, 8
    call std_util__emit_nl
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 9
    push rax
    lea rax, [rel _str198]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, [rbp-24]
    push rax
    call std_util__emit_i64
    add rsp, 8
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
_str24: db 10,0
_str27: db 48,0
_str34: db 45,0
_str96: db 32,32,40,110,111,32,115,116,97,99,107,32,116,114,97,99,101,32,97,118,97,105,108,97,98,108,101,41,0
_str99: db 32,32,40,115,116,97,99,107,32,116,114,97,99,101,32,105,115,32,101,109,112,116,121,41,0
_str100: db 83,116,97,99,107,32,116,114,97,99,101,32,40,109,111,115,116,32,114,101,99,101,110,116,32,99,97,108,108,32,102,105,114,115,116,41,58,0
_str103: db 32,32,97,116,32,0
_str104: db 32,40,0
_str105: db 58,0
_str106: db 41,0
_str109: db 91,69,82,82,79,82,93,32,0
_str112: db 80,97,114,115,105,110,103,32,99,111,110,116,101,120,116,58,0
_str113: db 32,32,45,62,32,73,110,32,102,117,110,99,116,105,111,110,58,32,0
_str114: db 32,40,108,105,110,101,32,0
_str115: db 67,111,109,112,105,108,101,114,32,105,110,116,101,114,110,97,108,32,116,114,97,99,101,58,0
_str118: db 69,114,114,111,114,32,100,101,116,97,105,108,115,58,0
_str125: db 91,87,65,82,78,93,32,0
_str194: db 49,48,32,43,32,53,32,61,32,0
_str195: db 49,48,32,45,32,53,32,61,32,0
_str196: db 49,48,32,42,32,53,32,61,32,0
_str197: db 49,48,32,47,32,53,32,61,32,0
_str198: db 49,48,32,37,32,53,32,61,32,0

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
