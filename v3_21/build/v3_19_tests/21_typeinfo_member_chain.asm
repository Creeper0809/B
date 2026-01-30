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
    mov rax, rdi
    mov rax, rsi
    lea rax, [rbp-8]
    mov rbx, 0
    mov [rax], rbx
    lea rax, [rbp-24]
    mov [rax], rax
    lea rax, [rbp-24]
    mov rax, rax
    add rax, 8
    lea rbx, [rbp-8]
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rbx, 0
    mov [rax], rbx
    mov rbx, rax
    add rbx, 8
    mov rbx, [rbx]
    mov rcx, 42
    mov [rbx], rcx
    mov rbx, [rax]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    mov rax, [rax]
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
