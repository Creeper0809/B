section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_types:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 30
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 40
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-32]
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
