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
_91_ssa_struct_return_large_chain__make_large:
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
    mov rax, [rbp-1064]
    mov rbx, [rbp-1056]
    mov rcx, [rbp-1048]
    mov rdx, [rbp-1040]
    mov r8, [rbp-1032]
    mov [r8], rdx
    mov rdx, r8
    add rdx, 8
    mov [rdx], rcx
    mov rcx, r8
    add rcx, 16
    mov [rcx], rbx
    mov rbx, r8
    add rbx, 24
    mov [rbx], rax
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_91_ssa_struct_return_large_chain__forward_large:
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
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-32]
    mov rdx, rax
    add rdx, 1
    mov r8, rax
    add r8, 2
    mov r9, rax
    add r9, 3
    push rbx
    push r9
    push r8
    push rdx
    push rax
    push rcx
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    call _91_ssa_struct_return_large_chain__make_large
    pop rbx
    lea rax, [rbp-32]
    mov rcx, [rax]
    mov [rbx], rcx
    mov rcx, rax
    add rcx, 8
    mov rdx, rbx
    add rdx, 8
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rcx, rax
    add rcx, 16
    mov rdx, rbx
    add rdx, 16
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rax, rax
    add rax, 24
    mov rbx, rbx
    add rbx, 24
    mov rax, [rax]
    mov [rbx], rax
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_2_2:
    lea rax, [rbp-32]
    mov rbx, 1
    mov rcx, 2
    mov rdx, 3
    mov r8, 4
    push r8
    push rdx
    push rcx
    push rbx
    push rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    call _91_ssa_struct_return_large_chain__make_large
    lea rax, [rbp-64]
    mov rbx, 10
    push rbx
    push rax
    pop rdi
    pop rsi
    call _91_ssa_struct_return_large_chain__forward_large
    lea rax, [rbp-64]
    mov rax, [rax]
    lea rbx, [rbp-64]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-64]
    mov rbx, rbx
    add rbx, 16
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-64]
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
