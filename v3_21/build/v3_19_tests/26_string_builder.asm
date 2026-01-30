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
std_string_builder__sb_copy_bytes:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 0
    mov [rbp-8], rax
.L39:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L40
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
    jmp .L39
.L40:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__sb_ensure_cap:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 16
    mov rax, [rax]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L41
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L41:
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 16
    mov rax, [rax]
    mov [rbp-16], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L43
    mov rax, 8
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L43:
.L45:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L46
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
    jmp .L45
.L46:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L47
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L47:
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L49
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp-24]
    push rax
    call std_string_builder__sb_copy_bytes
    add rsp, 24
.L49:
    mov rax, 0
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 16
    pop rbx
    mov [rax], rbx
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_init:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L51
    mov rax, 8
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L51:
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call std_io__heap_alloc
    add rsp, 8
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
    jz .L53
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L53:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 16
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp-16]
    pop rbx
    mov [rax], bl
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 24
    push rax
    call std_io__heap_alloc
    add rsp, 8
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
    jz .L55
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L55:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    push rax
    call std_string_builder__StringBuilder_init
    add rsp, 16
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L57
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L57:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_clear:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    pop rbx
    mov [rax], bl
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_len:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_ptr:
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
std_string_builder__StringBuilder_append_bytes:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L59
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L59:
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_string_builder__sb_ensure_cap
    add rsp, 16
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L61
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L61:
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+24]
    push rax
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
    push rax
    call std_string_builder__sb_copy_bytes
    add rsp, 24
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
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
    pop rbx
    mov [rax], bl
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_append_cstr:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    call std_str__str_len
    add rsp, 8
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_string_builder__StringBuilder_append_bytes
    add rsp, 24
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_append:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_string_builder__StringBuilder_append_cstr
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
std_string_builder__StringBuilder_append_u64_dec:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 32
    push rax
    call std_io__heap_alloc
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
    mov rax, [rbp+24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L63
    mov rax, 48
    push rax
    mov rax, [rbp-8]
    pop rbx
    mov [rax], bl
    mov rax, 1
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L64
.L63:
    mov rax, [rbp+24]
    mov [rbp-24], rax
.L65:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L66
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
    jmp .L65
.L66:
.L64:
    mov rax, 0
    mov [rbp-32], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov [rbp-40], rax
.L67:
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L68
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    mov [rbp-48], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    movzx rax, byte [rax]
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    pop rbx
    mov [rax], bl
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
    jmp .L67
.L68:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp+16]
    push rax
    call std_string_builder__StringBuilder_append_bytes
    add rsp, 24
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
    mov rax, 4
    push rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_init
    add rsp, 16
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L69
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L69:
    lea rax, [rel _str71]
    push rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_append
    add rsp, 16
    mov rax, 2
    push rax
    lea rax, [rel _str72]
    push rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_append_bytes
    add rsp, 24
    mov rax, 123
    push rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_append_u64_dec
    add rsp, 16
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_ptr
    add rsp, 8
    mov [rbp-32], rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_len
    add rsp, 8
    mov [rbp-40], rax
    mov rax, 7
    push rax
    lea rax, [rel _str75]
    push rax
    mov rax, [rbp-40]
    push rax
    mov rax, [rbp-32]
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L73
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L73:
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_clear
    add rsp, 8
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_len
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L76
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L76:
    lea rax, [rel _str78]
    push rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_append
    add rsp, 16
    mov rax, 2
    push rax
    lea rax, [rel _str78]
    push rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_len
    add rsp, 8
    push rax
    lea rax, [rbp-24]
    push rax
    call std_string_builder__StringBuilder_ptr
    add rsp, 8
    push rax
    call std_str__str_eq
    add rsp, 32
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L79
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L79:
    mov rax, 42
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
_str71: db 97,98,0
_str72: db 99,100,0
_str75: db 97,98,99,100,49,50,51,0
_str78: db 120,121,0

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
