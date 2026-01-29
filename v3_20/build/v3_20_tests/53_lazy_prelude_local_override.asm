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
_53_lazy_prelude_local_override__str_len:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov [rbp-8], rdi
    mov rax, 7
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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    lea rax, [rel _str0]
    push rax
    pop rdi
    call _53_lazy_prelude_local_override__str_len
    mov [rbp-24], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L1
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L1:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret

section .data
_str0: db 97,98,99,0
