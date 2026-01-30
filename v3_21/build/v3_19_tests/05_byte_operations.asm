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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 10
    push rax
    call std_io__heap_alloc
    add rsp, 8
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L39:
    mov rax, [rbp-16]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L40
    mov rax, 65
    push rax
    mov rax, [rbp-16]
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
    jmp .L39
.L40:
    mov rax, 0
    mov [rbp-24], rax
    mov rax, 0
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L41:
    mov rax, [rbp-16]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L42
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
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
    jmp .L41
.L42:
    mov rax, [rbp-24]
    push rax
    mov rax, 695
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L43
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L43:
    lea rax, [rel _str45]
    mov [rbp-32], rax
    lea rax, [rel _str46]
    mov [rbp-40], rax
    mov rax, [rbp-32]
    push rax
    call std_str__str_len
    add rsp, 8
    mov [rbp-48], rax
    mov rax, [rbp-40]
    push rax
    call std_str__str_len
    add rsp, 8
    mov [rbp-56], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L47
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L47:
    mov rax, [rbp-56]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L49
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L49:
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-32]
    push rax
    call std_str__str_concat
    add rsp, 32
    mov [rbp-64], rax
    mov rax, 12
    push rax
    lea rax, [rel _str53]
    push rax
    mov rax, 12
    push rax
    mov rax, [rbp-64]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L51
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L51:
    mov rax, 5
    push rax
    lea rax, [rel _str45]
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-32]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L54
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L54:
    mov rax, 5
    push rax
    lea rax, [rel _str58]
    push rax
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-32]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L56
    mov rax, 6
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

section .data
_str24: db 10,0
_str31: db 48,0
_str38: db 45,0
_str45: db 72,101,108,108,111,0
_str46: db 32,87,111,114,108,100,33,0
_str53: db 72,101,108,108,111,32,87,111,114,108,100,33,0
_str58: db 87,111,114,108,100,0

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
