section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
get_sum:
    push rbp
    mov rbp, rsp
    mov rax, 10
    push rax
    mov rax, 20
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
    sub rsp, 8
    call get_sum
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
