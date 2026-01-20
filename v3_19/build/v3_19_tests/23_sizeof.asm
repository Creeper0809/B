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
    mov rax, 0
    mov [rbp-8], rax
.L25:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L26
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
    sete al
    movzx rax, al
    test rax, rax
    jz .L27
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp+24]
    pop rbx
    mov [rax], rbx
    jmp .L26
.L27:
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
    jmp .L25
.L26:
    call std_io__io_get_output_fd
    mov [rbp-16], rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-16]
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
    jz .L29
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, 1
    push rax
    lea rax, [rel _str31]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_os__os_sys_write
    add rsp, 24
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L29:
    mov rax, 32
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-16], rax
    mov rax, 0
    mov [rbp-24], rax
    mov rax, [rbp+16]
    mov [rbp-32], rax
.L32:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L33
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
    jmp .L32
.L33:
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-48], rax
.L34:
    mov rax, [rbp-48]
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
    jmp .L34
.L35:
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
    jz .L36
    call std_io__io_get_output_fd
    mov [rbp-8], rax
    mov rax, 1
    push rax
    lea rax, [rel _str38]
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
    jmp .L37
.L36:
    mov rax, [rbp+16]
    push rax
    call std_io__print_u64
    add rsp, 8
.L37:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_23_sizeof__print_result:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, [rbp+32]
    push rax
    call std_io__print_u64
    add rsp, 8
    mov rax, 1
    push rax
    lea rax, [rel _str24]
    push rax
    call std_io__println
    add rsp, 16
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
    mov rax, 27
    push rax
    lea rax, [rel _str39]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 1
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 14
    push rax
    lea rax, [rel _str40]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 2
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 15
    push rax
    lea rax, [rel _str41]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 4
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 15
    push rax
    lea rax, [rel _str42]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 8
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    mov rax, 15
    push rax
    lea rax, [rel _str43]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 8
    mov [rbp-40], rax
    mov rax, [rbp-40]
    push rax
    mov rax, 15
    push rax
    lea rax, [rel _str44]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 24
    push rax
    lea rax, [rel _str45]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 8
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 15
    push rax
    lea rax, [rel _str46]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 8
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 16
    push rax
    lea rax, [rel _str47]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 8
    mov [rbp-64], rax
    mov rax, [rbp-64]
    push rax
    mov rax, 17
    push rax
    lea rax, [rel _str48]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 23
    push rax
    lea rax, [rel _str49]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 16
    mov [rbp-72], rax
    mov rax, [rbp-72]
    push rax
    mov rax, 17
    push rax
    lea rax, [rel _str50]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 32
    mov [rbp-80], rax
    mov rax, [rbp-80]
    push rax
    mov rax, 16
    push rax
    lea rax, [rel _str51]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 2
    mov [rbp-88], rax
    mov rax, [rbp-88]
    push rax
    mov rax, 23
    push rax
    lea rax, [rel _str52]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 28
    push rax
    lea rax, [rel _str53]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 8
    mov [rbp-96], rax
    mov rax, [rbp-96]
    push rax
    mov rax, 18
    push rax
    lea rax, [rel _str54]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 8
    mov [rbp-104], rax
    mov rax, [rbp-104]
    push rax
    mov rax, 17
    push rax
    lea rax, [rel _str55]
    push rax
    call _23_sizeof__print_result
    add rsp, 24
    mov rax, 21
    push rax
    lea rax, [rel _str56]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 1
    mov [rbp-112], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L57
    mov rax, 32
    push rax
    lea rax, [rel _str59]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L57:
    mov rax, [rbp-16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, 33
    push rax
    lea rax, [rel _str62]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L60:
    mov rax, [rbp-24]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L63
    mov rax, 33
    push rax
    lea rax, [rel _str65]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L63:
    mov rax, [rbp-32]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, 33
    push rax
    lea rax, [rel _str68]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L66:
    mov rax, [rbp-40]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L69
    mov rax, 33
    push rax
    lea rax, [rel _str71]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L69:
    mov rax, [rbp-48]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L72
    mov rax, 34
    push rax
    lea rax, [rel _str74]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L72:
    mov rax, [rbp-56]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L75
    mov rax, 35
    push rax
    lea rax, [rel _str77]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L75:
    mov rax, [rbp-64]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L78
    mov rax, 36
    push rax
    lea rax, [rel _str80]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L78:
    mov rax, [rbp-72]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L81
    mov rax, 37
    push rax
    lea rax, [rel _str83]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L81:
    mov rax, [rbp-80]
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L84
    mov rax, 36
    push rax
    lea rax, [rel _str86]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L84:
    mov rax, [rbp-88]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L87
    mov rax, 42
    push rax
    lea rax, [rel _str89]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L87:
    mov rax, [rbp-96]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L90
    mov rax, 37
    push rax
    lea rax, [rel _str92]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L90:
    mov rax, [rbp-104]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L93
    mov rax, 36
    push rax
    lea rax, [rel _str95]
    push rax
    call std_io__println
    add rsp, 16
    mov rax, 0
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
.L93:
    mov rax, [rbp-112]
    test rax, rax
    jz .L96
    mov rax, 27
    push rax
    lea rax, [rel _str98]
    push rax
    call std_io__println
    add rsp, 16
    jmp .L97
.L96:
    mov rax, 28
    push rax
    lea rax, [rel _str99]
    push rax
    call std_io__println
    add rsp, 16
.L97:
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
_str39: db 61,61,61,32,80,114,105,109,105,116,105,118,101,32,84,121,112,101,115,32,61,61,61,10,0
_str40: db 115,105,122,101,111,102,40,117,56,41,32,61,32,0
_str41: db 115,105,122,101,111,102,40,117,49,54,41,32,61,32,0
_str42: db 115,105,122,101,111,102,40,117,51,50,41,32,61,32,0
_str43: db 115,105,122,101,111,102,40,117,54,52,41,32,61,32,0
_str44: db 115,105,122,101,111,102,40,105,54,52,41,32,61,32,0
_str45: db 10,61,61,61,32,80,111,105,110,116,101,114,32,84,121,112,101,115,32,61,61,61,10,0
_str46: db 115,105,122,101,111,102,40,42,117,56,41,32,61,32,0
_str47: db 115,105,122,101,111,102,40,42,117,54,52,41,32,61,32,0
_str48: db 115,105,122,101,111,102,40,42,42,117,54,52,41,32,61,32,0
_str49: db 10,61,61,61,32,83,116,114,117,99,116,32,84,121,112,101,115,32,61,61,61,10,0
_str50: db 115,105,122,101,111,102,40,80,111,105,110,116,41,32,61,32,0
_str51: db 115,105,122,101,111,102,40,82,101,99,116,41,32,61,32,0
_str52: db 115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,61,32,0
_str53: db 10,61,61,61,32,80,111,105,110,116,101,114,32,116,111,32,83,116,114,117,99,116,32,61,61,61,10,0
_str54: db 115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,61,32,0
_str55: db 115,105,122,101,111,102,40,42,82,101,99,116,41,32,61,32,0
_str56: db 10,61,61,61,32,86,97,108,105,100,97,116,105,111,110,32,61,61,61,10,0
_str59: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,56,41,32,115,104,111,117,108,100,32,98,101,32,49,10,0
_str62: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,49,54,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str65: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,51,50,41,32,115,104,111,117,108,100,32,98,101,32,52,10,0
_str68: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str71: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,105,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str74: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,56,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str77: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str80: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str83: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,49,54,10,0
_str86: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,51,50,10,0
_str89: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str92: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str95: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str98: db 65,108,108,32,115,105,122,101,111,102,32,116,101,115,116,115,32,80,65,83,83,69,68,33,10,0
_str99: db 83,111,109,101,32,115,105,122,101,111,102,32,116,101,115,116,115,32,70,65,73,76,69,68,33,10,0

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
