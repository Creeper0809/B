section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_add:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 5
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    call test_add
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 60
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    call asm_syscall
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
