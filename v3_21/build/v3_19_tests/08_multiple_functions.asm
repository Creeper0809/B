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
.L39:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L41
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
    jz .L42
    mov rax, [rbp-16]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L42:
.L40:
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
.L41:
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L44
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
.L44:
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
.L46:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L48
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
    jz .L49
    mov rax, [rbp-16]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L49:
.L47:
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
    jmp .L46
.L48:
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
    jz .L51
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
.L51:
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-32], rax
    mov rax, [rbp-24]
    mov [rbp-40], rax
.L53:
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L55
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
    jz .L56
    mov rax, [rbp-40]
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
.L56:
.L54:
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
    jmp .L53
.L55:
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
    jz .L58
    mov rax, [rbp-32]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
.L58:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, [rbp-24]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
.L60:
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
    jz .L62
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
.L62:
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
    jz .L66
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
    jmp .L67
.L66:
    xor eax, eax
.L67:
    test rax, rax
    jz .L64
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L64:
    mov rax, [rbp+16]
    push rax
    mov rax, 97
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L70
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
    jmp .L71
.L70:
    xor eax, eax
.L71:
    test rax, rax
    jz .L68
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L68:
    mov rax, [rbp+16]
    push rax
    mov rax, 95
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L72
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L72:
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
    jz .L76
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
    jmp .L77
.L76:
    xor eax, eax
.L77:
    test rax, rax
    jz .L74
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L74:
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
    jz .L78
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L78:
    mov rax, [rbp+16]
    push rax
    call std_char__is_digit
    add rsp, 8
    test rax, rax
    jz .L80
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L80:
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
    jz .L82
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L82:
    mov rax, [rbp+16]
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L84
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L84:
    mov rax, [rbp+16]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L86
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L86:
    mov rax, [rbp+16]
    push rax
    mov rax, 13
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L88
    mov rax, 1
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
std_util__init_stack_trace:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rel _gvar_std_util__g_stack_initialized]
    test rax, rax
    jz .L90
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L90:
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
    jz .L92
    call std_util__init_stack_trace
.L92:
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 128
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L94
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L94:
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
    jz .L96
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
.L96:
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
    jz .L98
    mov rax, 28
    push rax
    lea rax, [rel _str100]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L98:
    mov rax, [rel _gvar_std_util__g_stack_depth]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L101
    mov rax, 24
    push rax
    lea rax, [rel _str103]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L101:
    mov rax, 38
    push rax
    lea rax, [rel _str104]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    mov rax, [rel _gvar_std_util__g_stack_depth]
    mov [rbp-8], rax
.L105:
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L106
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
    lea rax, [rel _str107]
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
    lea rax, [rel _str108]
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
    lea rax, [rel _str109]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rbp-56]
    push rax
    call std_util__emit_i64_stderr
    add rsp, 8
    mov rax, 1
    push rax
    lea rax, [rel _str110]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    jmp .L105
.L106:
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
    jz .L111
    mov rax, 512
    push rax
    call std_io__heap_alloc
    add rsp, 8
    push rax
    lea rax, [rel _gvar_std_util__g_error_buffer]
    pop rbx
    mov [rax], rbx
.L111:
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
    lea rax, [rel _str113]
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
    jz .L114
    call std_util__emit_stderr_nl
    mov rax, 16
    push rax
    lea rax, [rel _str116]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
    mov rax, 18
    push rax
    lea rax, [rel _str117]
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
    lea rax, [rel _str118]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    mov rax, [rel _gvar_std_util__g_current_func_line]
    push rax
    call std_util__emit_i64_stderr
    add rsp, 8
    mov rax, 1
    push rax
    lea rax, [rel _str110]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    call std_util__emit_stderr_nl
.L114:
    call std_util__emit_stderr_nl
    mov rax, 24
    push rax
    lea rax, [rel _str119]
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
    jz .L120
    call std_util__emit_stderr_nl
    mov rax, 14
    push rax
    lea rax, [rel _str122]
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
.L120:
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
    jz .L123
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
    jz .L125
    mov rax, 0
    mov [rbp-8], rax
.L127:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L128
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
    jmp .L127
.L128:
.L125:
    jmp .L124
.L123:
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    push rax
    call std_io__sys_write
    add rsp, 24
.L124:
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
    lea rax, [rel _str129]
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
    jz .L130
    mov rax, 1
    push rax
    lea rax, [rel _str31]
    push rax
    call std_io__emit
    add rsp, 16
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L130:
    mov rax, 32
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
    mov rax, [rbp+16]
    mov [rbp-24], rax
.L132:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L133
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
    jmp .L132
.L133:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-32], rax
.L134:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L135
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
    jmp .L134
.L135:
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
    jz .L136
    mov rax, 1
    push rax
    lea rax, [rel _str31]
    push rax
    call std_util__emit_stderr
    add rsp, 16
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
.L136:
    mov rax, 32
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
    mov rax, [rbp+16]
    mov [rbp-24], rax
.L138:
    mov rax, [rbp-24]
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
    jmp .L138
.L139:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-32], rax
.L140:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L141
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
    jmp .L140
.L141:
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
    jz .L142
    mov rax, 1
    push rax
    lea rax, [rel _str38]
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
    jmp .L143
.L142:
    mov rax, [rbp+16]
    push rax
    call std_util__emit_u64
    add rsp, 8
.L143:
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
    jz .L144
    mov rax, 1
    push rax
    lea rax, [rel _str38]
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
    jmp .L145
.L144:
    mov rax, [rbp+16]
    push rax
    call std_util__emit_u64_stderr
    add rsp, 8
.L145:
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
_08_multiple_functions__add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L146
    mov rax, 24
    push rax
    lea rax, [rel _str148]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L146:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    call std_util__emit_i64
    add rsp, 8
    mov rax, 1
    push rax
    lea rax, [rel _str149]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, [rbp+16]
    push rax
    call std_str__str_len
    add rsp, 8
    push rax
    mov rax, [rbp+16]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, 1
    push rax
    lea rax, [rel _str149]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, [rbp+32]
    push rax
    call std_util__emit_i64
    add rsp, 8
    mov rax, 3
    push rax
    lea rax, [rel _str150]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, 1
    push rax
    lea rax, [rel _str153]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_len
    add rsp, 8
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L151
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call _08_multiple_functions__add
    add rsp, 16
    push rax
    call std_util__emit_i64
    add rsp, 8
    jmp .L152
.L151:
    mov rax, 1
    push rax
    lea rax, [rel _str38]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_len
    add rsp, 8
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L154
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call _08_multiple_functions__subtract
    add rsp, 16
    push rax
    call std_util__emit_i64
    add rsp, 8
    jmp .L155
.L154:
    mov rax, 1
    push rax
    lea rax, [rel _str158]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_len
    add rsp, 8
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L156
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call _08_multiple_functions__multiply
    add rsp, 16
    push rax
    call std_util__emit_i64
    add rsp, 8
    jmp .L157
.L156:
    mov rax, 1
    push rax
    lea rax, [rel _str161]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_len
    add rsp, 8
    push rax
    mov rax, [rbp+16]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    jz .L159
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
    call _08_multiple_functions__divide
    add rsp, 16
    push rax
    call std_util__emit_i64
    add rsp, 8
.L159:
.L157:
.L155:
.L152:
    call std_util__emit_nl
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 17
    push rax
    lea rax, [rel _str162]
    push rax
    call std_io__emit
    add rsp, 16
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str153]
    push rax
    call _08_multiple_functions__calculator
    add rsp, 24
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str38]
    push rax
    call _08_multiple_functions__calculator
    add rsp, 24
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str158]
    push rax
    call _08_multiple_functions__calculator
    add rsp, 24
    mov rax, 5
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str161]
    push rax
    call _08_multiple_functions__calculator
    add rsp, 24
    mov rax, 0
    push rax
    mov rax, 10
    push rax
    lea rax, [rel _str161]
    push rax
    call _08_multiple_functions__calculator
    add rsp, 24
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
_str100: db 32,32,40,110,111,32,115,116,97,99,107,32,116,114,97,99,101,32,97,118,97,105,108,97,98,108,101,41,0
_str103: db 32,32,40,115,116,97,99,107,32,116,114,97,99,101,32,105,115,32,101,109,112,116,121,41,0
_str104: db 83,116,97,99,107,32,116,114,97,99,101,32,40,109,111,115,116,32,114,101,99,101,110,116,32,99,97,108,108,32,102,105,114,115,116,41,58,0
_str107: db 32,32,97,116,32,0
_str108: db 32,40,0
_str109: db 58,0
_str110: db 41,0
_str113: db 91,69,82,82,79,82,93,32,0
_str116: db 80,97,114,115,105,110,103,32,99,111,110,116,101,120,116,58,0
_str117: db 32,32,45,62,32,73,110,32,102,117,110,99,116,105,111,110,58,32,0
_str118: db 32,40,108,105,110,101,32,0
_str119: db 67,111,109,112,105,108,101,114,32,105,110,116,101,114,110,97,108,32,116,114,97,99,101,58,0
_str122: db 69,114,114,111,114,32,100,101,116,97,105,108,115,58,0
_str129: db 91,87,65,82,78,93,32,0
_str148: db 69,114,114,111,114,58,32,68,105,118,105,115,105,111,110,32,98,121,32,122,101,114,111,10,0
_str149: db 32,0
_str150: db 32,61,32,0
_str153: db 43,0
_str158: db 42,0
_str161: db 47,0
_str162: db 67,97,108,99,117,108,97,116,111,114,32,116,101,115,116,58,10,0

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
