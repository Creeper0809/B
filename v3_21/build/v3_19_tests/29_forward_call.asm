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
.Lssa_0_0:
    mov rax, 41
    mov rdi, rax
    call _29_forward_call__add_one
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_1
    jmp .Lssa_0_2
.Lssa_0_1:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_2
.Lssa_0_2:
    mov rax, 42
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_29_forward_call__add_one:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_3:
    mov rax, rdi
    mov rax, rax
    add rax, 1
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
