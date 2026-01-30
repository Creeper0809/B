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
_85_ssa_struct_return_method__Counter_get:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    lea rbx, [rbp-8]
    mov rax, [rax]
    mov [rbx], rax
    lea rax, [rbp-8]
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_85_ssa_struct_return_method__Counter_inc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdi
    lea rbx, [rbp-8]
    mov rax, [rax]
    mov rax, rax
    add rax, 1
    mov [rbx], rax
    lea rax, [rbp-8]
    mov rax, [rax]
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
.Lssa_2_2:
    lea rax, [rbp-8]
    mov rbx, 99
    mov [rax], rbx
    lea rax, [rbp-16]
    lea rbx, [rbp-8]
    push rax
    mov rdi, rbx
    call _85_ssa_struct_return_method__Counter_inc
    mov rbx, rax
    pop rax
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
