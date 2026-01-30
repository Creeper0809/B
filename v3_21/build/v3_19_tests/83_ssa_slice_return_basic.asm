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
_83_ssa_slice_return_basic__get_slice:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    lea rax, [rbp-24]
    mov rax, rax
    add rax, 0
    mov rbx, 1
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rax, rax
    add rax, 8
    mov rbx, 2
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rax, rax
    add rax, 16
    mov rbx, 3
    mov [rax], rbx
    mov rax, 3
    mov rdx, rax
    xor eax, eax
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
    push rax
    call _83_ssa_slice_return_basic__get_slice
    mov rbx, [rsp]
    mov [rbx], rax
    mov [rbx+8], rdx
    add rsp, 8
    lea rax, [rbp-16]
    mov rax, [rax]
    mov rax, rax
    add rax, 0
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rbx, [rbx]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-16]
    mov rbx, [rbx]
    mov rbx, rbx
    add rbx, 16
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
