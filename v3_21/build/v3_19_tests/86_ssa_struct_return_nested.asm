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
_86_ssa_struct_return_nested__make_outer:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rbx, 0
    mov rax, rax
    imul rax, 2
    mov rdx, rax
    mov rax, rbx
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
.Lssa_1_1:
    lea rax, [rbp-16]
    mov rbx, 50
    push rax
    mov rdi, rbx
    call _86_ssa_struct_return_nested__make_outer
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
