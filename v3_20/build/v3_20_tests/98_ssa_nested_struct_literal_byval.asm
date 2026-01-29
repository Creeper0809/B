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
_98_ssa_nested_struct_literal_byval__sum_outer:
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
    lea rax, [rbp-32]
    mov rbx, [rbp-1032]
    mov rcx, [rbx]
    mov [rax], rcx
    mov rcx, rbx
    add rcx, 8
    mov rdx, rax
    add rdx, 8
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rcx, rbx
    add rcx, 16
    mov rdx, rax
    add rdx, 16
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rbx, rbx
    add rbx, 24
    mov rax, rax
    add rax, 24
    mov rbx, [rbx]
    mov [rax], rbx
    lea rax, [rbp-32]
    mov rax, [rax]
    lea rbx, [rbp-32]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-32]
    mov rbx, rbx
    add rbx, 16
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-32]
    mov rbx, rbx
    add rbx, 24
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
    lea rax, [rbp-32]
    mov rbx, 1
    mov [rax], rbx
    mov rbx, rax
    add rbx, 8
    mov rcx, 2
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 16
    mov rcx, 3
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 24
    mov rcx, 4
    mov [rbx], rcx
    push rax
    pop rdi
    call _98_ssa_nested_struct_literal_byval__sum_outer
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
