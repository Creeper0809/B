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
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-8]
    mov rcx, [rax]
    mov [r8], rcx
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-24]
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    mov rax, [rbp-32]
    push rax
    pop rax
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 42
    push rax
    mov rax, [rbp-32]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    pop rax
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp-32]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    pop rax
    mov rax, [rax]
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
