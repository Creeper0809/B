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
_19_impl_basic__PointBasic_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__PointBasic_sum:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
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
_19_impl_basic__PointBasic_distance_squared:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-8], rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-16]
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
_19_impl_basic__Rect_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Rect_area:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
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
_19_impl_basic__Counter_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Counter_increment:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Counter_add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Counter_multiply:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Counter_get:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Vec2_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Vec2_add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Vec2_scale:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Vec2_magnitude_squared:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
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
_19_impl_basic__Math_factorial:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L39
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L39:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call _19_impl_basic__Math_factorial
    add rsp, 8
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
_19_impl_basic__Math_fibonacci:
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
    jz .L41
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L41:
    mov rax, [rbp+16]
    push rax
    mov rax, 1
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
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call _19_impl_basic__Math_fibonacci
    add rsp, 8
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call _19_impl_basic__Math_fibonacci
    add rsp, 8
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
_19_impl_basic__Math_power:
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
    jz .L45
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L45:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    call _19_impl_basic__Math_power
    add rsp, 16
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
_19_impl_basic__Data_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Data_get_value:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Data_double:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__sum_array:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 0
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
.L47:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L49
    mov rax, [rbp+16]
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
    mov [rbp-24], rax
    mov rax, [rbp-24]
    mov [rbp-32], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    push rax
    call _19_impl_basic__Data_get_value
    add rsp, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L48:
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
    jmp .L47
.L49:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_sub:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_mul:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_div:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L50
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
.L50:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_mod:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L52
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
.L52:
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_square:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Calculator_get:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Pair_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_19_impl_basic__Pair_sum:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
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
_19_impl_basic__Pair_product:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
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
_19_impl_basic__process_pairs:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 7
    push rax
    mov rax, 5
    push rax
    lea rax, [rbp-16]
    push rax
    call _19_impl_basic__Pair_init
    add rsp, 24
    mov rax, 4
    push rax
    mov rax, 3
    push rax
    lea rax, [rbp-32]
    push rax
    call _19_impl_basic__Pair_init
    add rsp, 24
    lea rax, [rbp-16]
    push rax
    call _19_impl_basic__Pair_sum
    add rsp, 8
    mov [rbp-40], rax
    lea rax, [rbp-32]
    push rax
    call _19_impl_basic__Pair_sum
    add rsp, 8
    mov [rbp-48], rax
    lea rax, [rbp-32]
    push rax
    call _19_impl_basic__Pair_product
    add rsp, 8
    mov [rbp-56], rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-48]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-56]
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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 20
    push rax
    mov rax, 10
    push rax
    lea rax, [rbp-16]
    push rax
    call _19_impl_basic__PointBasic_init
    add rsp, 24
    mov rax, 4
    push rax
    mov rax, 3
    push rax
    lea rax, [rbp-32]
    push rax
    call _19_impl_basic__PointBasic_init
    add rsp, 24
    lea rax, [rbp-16]
    push rax
    call _19_impl_basic__PointBasic_sum
    add rsp, 8
    mov [rbp-40], rax
    lea rax, [rbp-32]
    push rax
    lea rax, [rbp-16]
    push rax
    call _19_impl_basic__PointBasic_distance_squared
    add rsp, 16
    mov [rbp-48], rax
    mov rax, [rbp-40]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L54
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L54:
    mov rax, [rbp-48]
    push rax
    mov rax, 305
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L56
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L56:
    mov rax, 7
    push rax
    mov rax, 3
    push rax
    lea rax, [rbp-64]
    push rax
    call _19_impl_basic__Rect_init
    add rsp, 24
    lea rax, [rbp-64]
    push rax
    call _19_impl_basic__Rect_area
    add rsp, 8
    push rax
    mov rax, 21
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L58
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L58:
    mov rax, 5
    push rax
    lea rax, [rbp-72]
    push rax
    call _19_impl_basic__Counter_init
    add rsp, 16
    lea rax, [rbp-72]
    push rax
    call _19_impl_basic__Counter_increment
    add rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-72]
    push rax
    call _19_impl_basic__Counter_add
    add rsp, 16
    mov rax, 2
    push rax
    lea rax, [rbp-72]
    push rax
    call _19_impl_basic__Counter_multiply
    add rsp, 16
    lea rax, [rbp-72]
    push rax
    call _19_impl_basic__Counter_get
    add rsp, 8
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L60:
    mov rax, 4
    push rax
    mov rax, 3
    push rax
    call _19_impl_basic__Vec2_new
    add rsp, 16
    mov [rbp-88], rax
    mov [rbp-80], rdx
    mov rax, 2
    push rax
    mov rax, 1
    push rax
    call _19_impl_basic__Vec2_new
    add rsp, 16
    mov [rbp-104], rax
    mov [rbp-96], rdx
    lea rax, [rbp-104]
    push rax
    lea rax, [rbp-88]
    push rax
    call _19_impl_basic__Vec2_add
    add rsp, 16
    mov [rbp-120], rax
    mov [rbp-112], rdx
    mov rax, 2
    push rax
    lea rax, [rbp-120]
    push rax
    call _19_impl_basic__Vec2_scale
    add rsp, 16
    mov [rbp-136], rax
    mov [rbp-128], rdx
    lea rax, [rbp-136]
    push rax
    call _19_impl_basic__Vec2_magnitude_squared
    add rsp, 8
    push rax
    mov rax, 208
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L62
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L62:
    mov rax, 5
    push rax
    call _19_impl_basic__Math_factorial
    add rsp, 8
    push rax
    mov rax, 120
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L64
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L64:
    mov rax, 7
    push rax
    call _19_impl_basic__Math_fibonacci
    add rsp, 8
    push rax
    mov rax, 13
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L66:
    mov rax, 5
    push rax
    mov rax, 2
    push rax
    call _19_impl_basic__Math_power
    add rsp, 16
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L68
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L68:
    mov rax, 24
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-144], rax
    mov rax, [rbp-144]
    mov [rbp-152], rax
    mov rax, [rbp-144]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-160], rax
    mov rax, [rbp-144]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-168], rax
    mov rax, 10
    push rax
    mov rax, [rbp-152]
    push rax
    call _19_impl_basic__Data_init
    add rsp, 16
    mov rax, 20
    push rax
    mov rax, [rbp-160]
    push rax
    call _19_impl_basic__Data_init
    add rsp, 16
    mov rax, 12
    push rax
    mov rax, [rbp-168]
    push rax
    call _19_impl_basic__Data_init
    add rsp, 16
    mov rax, [rbp-152]
    push rax
    call _19_impl_basic__Data_get_value
    add rsp, 8
    push rax
    mov rax, [rbp-160]
    push rax
    call _19_impl_basic__Data_get_value
    add rsp, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-168]
    push rax
    call _19_impl_basic__Data_get_value
    add rsp, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-176], rax
    mov rax, [rbp-176]
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L70
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
.L70:
    mov rax, [rbp-152]
    push rax
    call _19_impl_basic__Data_double
    add rsp, 8
    mov rax, [rbp-160]
    push rax
    call _19_impl_basic__Data_double
    add rsp, 8
    mov rax, [rbp-168]
    push rax
    call _19_impl_basic__Data_double
    add rsp, 8
    mov rax, 3
    push rax
    mov rax, [rbp-144]
    push rax
    call _19_impl_basic__sum_array
    add rsp, 16
    mov [rbp-184], rax
    mov rax, [rbp-184]
    push rax
    mov rax, 84
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L72
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L72:
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_init
    add rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_add
    add rsp, 16
    mov rax, 5
    push rax
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_mul
    add rsp, 16
    mov rax, 8
    push rax
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_sub
    add rsp, 16
    mov rax, 3
    push rax
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_add
    add rsp, 16
    mov rax, 3
    push rax
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_div
    add rsp, 16
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_square
    add rsp, 8
    mov rax, 100
    push rax
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_mod
    add rsp, 16
    mov rax, 17
    push rax
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_add
    add rsp, 16
    lea rax, [rbp-192]
    push rax
    call _19_impl_basic__Calculator_get
    add rsp, 8
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L74
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L74:
    call _19_impl_basic__process_pairs
    push rax
    mov rax, 31
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L76
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L76:
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
