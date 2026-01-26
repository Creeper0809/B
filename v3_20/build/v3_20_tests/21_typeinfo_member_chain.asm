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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_0_0:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rbp-8]
    mov rbx, 0
    mov [rax], rbx
    lea rax, [rbp-24]
    lea rbx, [rbp-8]
    mov rbx, [rbx]
    mov [rax], rbx
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
