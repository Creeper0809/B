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
param_test__test:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp+16], rdi
    mov [rbp+24], rsi
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
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
    sub rsp, 1024
    mov rax, 10
    mov rdi, rax
    mov rax, 20
    mov rsi, rax
    call param_test__test
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
