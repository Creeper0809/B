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
_28_type_basics__test_array_basic:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 10
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 30
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 40
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 3
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 50
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 4
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-40]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 3
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 4
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 150
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L39
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L39:
    mov rax, 100
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-40]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L41
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L41:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_char_type:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 65
    mov [rbp-1], al
    mov rax, 66
    mov [rbp-2], al
    movzx rax, byte [rbp-1]
    push rax
    mov rax, 65
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L43
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L43:
    movzx rax, byte [rbp-2]
    push rax
    mov rax, 66
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L45
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L45:
    movzx rax, byte [rbp-1]
    push rax
    movzx rax, byte [rbp-2]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-10], rax
    mov rax, [rbp-10]
    push rax
    mov rax, 131
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L47
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L47:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_char_array:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 72
    push rax
    lea rax, [rbp-6]
    push rax
    mov rax, 0
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, 101
    push rax
    lea rax, [rbp-6]
    push rax
    mov rax, 1
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, 108
    push rax
    lea rax, [rbp-6]
    push rax
    mov rax, 2
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, 108
    push rax
    lea rax, [rbp-6]
    push rax
    mov rax, 3
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, 111
    push rax
    lea rax, [rbp-6]
    push rax
    mov rax, 4
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, 0
    push rax
    lea rax, [rbp-6]
    push rax
    mov rax, 5
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], bl
    lea rax, [rbp-6]
    push rax
    mov rax, 0
    pop rbx
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 72
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L49
    mov rax, 20
    mov rsp, rbp
    pop rbp
    ret
.L49:
    lea rax, [rbp-6]
    push rax
    mov rax, 4
    pop rbx
    add rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 111
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L51
    mov rax, 21
    mov rsp, rbp
    pop rbp
    ret
.L51:
    mov rax, 0
    mov [rbp-14], rax
    mov rax, 0
    mov [rbp-22], rax
    mov rax, 0
    push rax
    lea rax, [rbp-22]
    pop rbx
    mov [rax], rbx
.L53:
    mov rax, [rbp-22]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L55
    mov rax, [rbp-14]
    push rax
    lea rax, [rbp-6]
    push rax
    mov rax, [rbp-22]
    pop rbx
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-14]
    pop rbx
    mov [rax], rbx
.L54:
    mov rax, [rbp-22]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-22]
    pop rbx
    mov [rax], rbx
    jmp .L53
.L55:
    mov rax, [rbp-14]
    push rax
    mov rax, 500
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L56
    mov rax, 22
    mov rsp, rbp
    pop rbp
    ret
.L56:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_multidim_simulation:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 1
    mov [rbp-80], rax
    mov rax, 0
    mov [rbp-88], rax
    mov rax, 0
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov [rax], rbx
.L58:
    mov rax, [rbp-88]
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, [rbp-80]
    push rax
    lea rax, [rbp-72]
    push rax
    mov rax, [rbp-88]
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
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
.L59:
    mov rax, [rbp-88]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov [rax], rbx
    jmp .L58
.L60:
    lea rax, [rbp-72]
    push rax
    mov rax, 5
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 6
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L61
    mov rax, 30
    mov rsp, rbp
    pop rbp
    ret
.L61:
    lea rax, [rbp-72]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    lea rax, [rbp-72]
    push rax
    mov rax, 4
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-72]
    push rax
    mov rax, 8
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-96], rax
    mov rax, [rbp-96]
    push rax
    mov rax, 15
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L63
    mov rax, 31
    mov rsp, rbp
    pop rbp
    ret
.L63:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_nested_array_access:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 0
    mov [rbp-88], rax
    mov rax, 0
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov [rax], rbx
.L65:
    mov rax, [rbp-88]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L67
    mov rax, [rbp-88]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-80]
    push rax
    mov rax, [rbp-88]
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
.L66:
    mov rax, [rbp-88]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov [rax], rbx
    jmp .L65
.L67:
    mov rax, 5
    mov [rbp-96], rax
    lea rax, [rbp-80]
    push rax
    mov rax, [rbp-96]
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 50
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L68
    mov rax, 40
    mov rsp, rbp
    pop rbp
    ret
.L68:
    mov rax, 3
    push rax
    lea rax, [rbp-80]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-80]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov [rbp-104], rax
    lea rax, [rbp-80]
    push rax
    mov rax, [rbp-104]
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L70
    mov rax, 41
    mov rsp, rbp
    pop rbp
    ret
.L70:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_slice_basic:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 10
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 30
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 40
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 3
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 50
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 4
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-40]
    mov [rbp-48], rax
    mov rax, [rbp-48]
    mov [rbp-64], rax
    mov rax, 5
    mov [rbp-56], rax
    lea rax, [rbp-64]
    mov rax, [rax]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L72
    mov rax, 50
    mov rsp, rbp
    pop rbp
    ret
.L72:
    lea rax, [rbp-64]
    mov rax, [rax]
    push rax
    mov rax, 4
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 50
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L74
    mov rax, 51
    mov rsp, rbp
    pop rbp
    ret
.L74:
    mov rax, 0
    mov [rbp-72], rax
    mov rax, 0
    mov [rbp-80], rax
    mov rax, 0
    push rax
    lea rax, [rbp-80]
    pop rbx
    mov [rax], rbx
.L76:
    mov rax, [rbp-80]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L78
    mov rax, [rbp-72]
    push rax
    lea rax, [rbp-64]
    mov rax, [rax]
    push rax
    mov rax, [rbp-80]
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
.L77:
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
    jmp .L76
.L78:
    mov rax, [rbp-72]
    push rax
    mov rax, 150
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L79
    mov rax, 52
    mov rsp, rbp
    pop rbp
    ret
.L79:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__sum_slice:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 0
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
    mov rax, 0
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L81:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L83
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp+16]
    mov rax, [rax]
    push rax
    mov rax, [rbp-16]
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L82:
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
    jmp .L81
.L83:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__make_slice:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rbx, rax
    mov rax, [rbp+24]
    mov rdx, rax
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_slice_struct_fields:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 1
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-40]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 10
    push rax
    lea rax, [rbp-64]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-64]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 30
    push rax
    lea rax, [rbp-64]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-64]
    mov [rbp-72], rax
    mov rax, [rbp-72]
    mov rbx, rax
    mov rax, 3
    mov rcx, rax
    lea rax, [rbp-16]
    mov [rax], rbx
    mov [rax+8], rcx
    lea rax, [rbp-40]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L84
    mov rax, 60
    mov rsp, rbp
    pop rbp
    ret
.L84:
    lea rax, [rbp-16]
    mov rax, [rax]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L86
    mov rax, 61
    mov rsp, rbp
    pop rbp
    ret
.L86:
    mov rax, 3
    push rax
    mov rax, [rbp-72]
    push rax
    call _28_type_basics__make_slice
    add rsp, 16
    mov [rbp-88], rax
    mov [rbp-80], rdx
    mov rax, 3
    push rax
    lea rax, [rbp-88]
    mov rbx, [rax+8]
    push rbx
    mov rbx, [rax]
    push rbx
    call _28_type_basics__sum_slice
    add rsp, 24
    mov [rbp-96], rax
    mov rax, [rbp-96]
    push rax
    mov rax, 60
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L88
    mov rax, 62
    mov rsp, rbp
    pop rbp
    ret
.L88:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__sum_arr:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
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
_28_type_basics__pass_arr:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_array_param_return:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 7
    push rax
    lea rax, [rbp-24]
    push rax
    mov rax, 0
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 8
    push rax
    lea rax, [rbp-24]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    mov rax, 9
    push rax
    lea rax, [rbp-24]
    push rax
    mov rax, 2
    imul rax, 8
    pop rbx
    add rax, rbx
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-24]
    push rax
    call _28_type_basics__sum_arr
    add rsp, 8
    mov [rbp-32], rax
    mov rax, [rbp-32]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L90
    mov rax, 70
    mov rsp, rbp
    pop rbp
    ret
.L90:
    lea rax, [rbp-24]
    push rax
    call _28_type_basics__pass_arr
    add rsp, 8
    mov [rbp-40], rax
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    imul rax, 8
    pop rbx
    add rax, rbx
    mov rax, [rax]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L92
    mov rax, 71
    mov rsp, rbp
    pop rbp
    ret
.L92:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_tagged_ptr_basic:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 8
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp-8]
    mov [rbp-16], rax
    mov rax, 4660
    mov [rbp-24], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 281474976710655
    mov rbx, rax
    pop rax
    and rax, rbx
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 48
    mov rbx, rax
    pop rax
    mov rcx, rbx
    shl rax, cl
    mov rbx, rax
    pop rax
    or rax, rbx
    mov [rbp-32], rax
    mov rax, [rbp-32]
    mov [rbp-40], rax
    mov rax, 55
    push rax
    mov rax, [rbp-40]
    mov rbx, 281474976710655
    and rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-40]
    mov rbx, 281474976710655
    and rax, rbx
    movzx rax, byte [rax]
    mov [rbp-48], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 55
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L94
    mov rax, 80
    mov rsp, rbp
    pop rbp
    ret
.L94:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_tagged_layout_packed_struct:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 8
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp-8]
    mov [rbp-16], rax
    mov rax, [rbp-16]
    mov [rbp-24], rax
    mov rax, 1
    mov r9, rax
    mov rax, [rbp-24]
    mov rbx, rax
    mov rdx, 1
    mov rcx, 16
    shl rdx, cl
    sub rdx, 1
    and r9, rdx
    mov rcx, 48
    shl r9, cl
    mov rdx, 1
    mov rcx, 16
    shl rdx, cl
    sub rdx, 1
    mov r10, rdx
    mov rcx, 48
    shl r10, cl
    not r10
    and rbx, r10
    or rbx, r9
    lea rax, [rbp-24]
    mov [rax], rbx
    mov rax, 77
    push rax
    mov rax, [rbp-24]
    mov rbx, 281474976710655
    and rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-24]
    mov rcx, 48
    shr rax, cl
    mov rdx, 1
    mov rcx, 16
    shl rdx, cl
    sub rdx, 1
    and rax, rdx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L96
    mov rax, 90
    mov rsp, rbp
    pop rbp
    ret
.L96:
    mov rax, [rbp-24]
    mov rbx, 281474976710655
    and rax, rbx
    movzx rax, byte [rax]
    push rax
    mov rax, 77
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L98
    mov rax, 91
    mov rsp, rbp
    pop rbp
    ret
.L98:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_28_type_basics__test_packed_bitfield_access:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 3
    mov r9, rax
    lea rax, [rbp-2]
    movzx rbx, word [rax]
    mov rdx, 1
    mov rcx, 4
    shl rdx, cl
    sub rdx, 1
    and r9, rdx
    mov rdx, 1
    mov rcx, 4
    shl rdx, cl
    sub rdx, 1
    mov r10, rdx
    not r10
    and rbx, r10
    or rbx, r9
    lea rax, [rbp-2]
    mov [rax], bx
    mov rax, 4095
    mov r9, rax
    lea rax, [rbp-2]
    movzx rbx, word [rax]
    mov rdx, 1
    mov rcx, 12
    shl rdx, cl
    sub rdx, 1
    and r9, rdx
    mov rcx, 4
    shl r9, cl
    mov rdx, 1
    mov rcx, 12
    shl rdx, cl
    sub rdx, 1
    mov r10, rdx
    mov rcx, 4
    shl r10, cl
    not r10
    and rbx, r10
    or rbx, r9
    lea rax, [rbp-2]
    mov [rax], bx
    lea rax, [rbp-2]
    movzx rax, word [rax]
    mov rdx, 1
    mov rcx, 4
    shl rdx, cl
    sub rdx, 1
    and rax, rdx
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L100
    mov rax, 100
    mov rsp, rbp
    pop rbp
    ret
.L100:
    lea rax, [rbp-2]
    movzx rax, word [rax]
    mov rcx, 4
    shr rax, cl
    mov rdx, 1
    mov rcx, 12
    shl rdx, cl
    sub rdx, 1
    and rax, rdx
    push rax
    mov rax, 4095
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L102
    mov rax, 101
    mov rsp, rbp
    pop rbp
    ret
.L102:
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
    mov rax, 0
    mov [rbp-8], rax
    call _28_type_basics__test_array_basic
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L104
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L104:
    call _28_type_basics__test_char_type
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L106
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L106:
    call _28_type_basics__test_char_array
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L108
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L108:
    call _28_type_basics__test_multidim_simulation
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L110
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L110:
    call _28_type_basics__test_nested_array_access
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L112
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L112:
    call _28_type_basics__test_slice_basic
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L114
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L114:
    call _28_type_basics__test_slice_struct_fields
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L116
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L116:
    call _28_type_basics__test_array_param_return
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L118
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L118:
    call _28_type_basics__test_tagged_ptr_basic
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L120
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L120:
    call _28_type_basics__test_tagged_layout_packed_struct
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L122
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L122:
    call _28_type_basics__test_packed_bitfield_access
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L124
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L124:
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

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
