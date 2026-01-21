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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_33_33:
    mov rax, rdi
    mov rax, rsi
    mov rax, 0
    cmp rax, 0
    jne .Lssa_33_34
    jmp .Lssa_33_35
.Lssa_33_34:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_35
.Lssa_33_35:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
