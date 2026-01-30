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
_78_ssa_struct_return__make_point:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_0_0:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_1_1:
    lea rax, [rbp-16]
    mov rbx, 20
    mov rdx, 22
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _78_ssa_struct_return__make_point
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
