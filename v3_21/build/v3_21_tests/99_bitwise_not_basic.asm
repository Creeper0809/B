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
    sub rsp, 2048
    mov rax, 1
    not rax
    mov [rbp-8], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 15
    mov rbx, rax
    pop rax
    and rax, rbx
    mov [rbp-16], rax
    mov rax, [rbp-16]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
