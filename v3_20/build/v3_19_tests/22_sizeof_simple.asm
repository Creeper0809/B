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
std_os__os_sys_brk:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_5_5:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_write:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_6_6:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__io_get_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_24_24:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__heap_alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_25_25:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_28_28:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__println:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_30_30:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_31_31:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_33_33:
    mov rax, 19
    lea rbx, [rel _str0]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 1
    mov rbx, 13
    lea rcx, [rel _str1]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call std_io__print
    pop rax
    mov rdi, rax
    call std_io__print_u64
    mov rax, 1
    lea rbx, [rel _str2]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 8
    mov rbx, 14
    lea rcx, [rel _str3]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call std_io__print
    pop rax
    mov rdi, rax
    call std_io__print_u64
    mov rax, 1
    lea rbx, [rel _str2]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 8
    mov rbx, 15
    lea rcx, [rel _str4]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call std_io__print
    pop rax
    mov rdi, rax
    call std_io__print_u64
    mov rax, 1
    lea rbx, [rel _str2]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 16
    mov rbx, 16
    lea rcx, [rel _str5]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call std_io__print
    pop rax
    mov rdi, rax
    call std_io__print_u64
    mov rax, 1
    lea rbx, [rel _str2]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 7
    lea rbx, [rel _str6]
    mov rdi, rax
    mov rsi, rbx
    call std_io__println
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 84,101,115,116,105,110,103,32,115,105,122,101,111,102,46,46,46,10,0
_str1: db 115,105,122,101,111,102,40,117,56,41,32,61,32,0
_str2: db 10,0
_str3: db 115,105,122,101,111,102,40,117,54,52,41,32,61,32,0
_str4: db 115,105,122,101,111,102,40,42,117,54,52,41,32,61,32,0
_str5: db 115,105,122,101,111,102,40,80,111,105,110,116,41,32,61,32,0
_str6: db 68,111,110,101,33,10,0

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
