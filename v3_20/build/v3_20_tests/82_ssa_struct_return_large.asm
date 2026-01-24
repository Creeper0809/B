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
_82_ssa_struct_return_large__make_large:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov [rbp-32], r8
    push rdi
    mov rax, [rbp-8]
    pop rdi
    mov [rdi], rax
    push rdi
    mov rax, [rbp-16]
    pop rdi
    mov [rdi+8], rax
    push rdi
    mov rax, [rbp-24]
    pop rdi
    mov [rdi+16], rax
    push rdi
    mov rax, [rbp-32]
    pop rdi
    mov [rdi+24], rax
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
    mov rax, 90
    push rax
    mov rax, 30
    push rax
    mov rax, 20
    push rax
    mov rax, 10
    push rax
    lea rdi, [rbp-32]
    pop rsi
    pop rdx
    pop rcx
    pop r8
    call _82_ssa_struct_return_large__make_large
    lea rax, [rbp-32]
    mov rax, [rax]
    push rax
    lea rax, [rbp-24]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
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
