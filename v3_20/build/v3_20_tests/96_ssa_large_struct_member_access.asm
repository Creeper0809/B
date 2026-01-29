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
_96_ssa_large_struct_member_access__make_large:
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
    mov rax, [rbp-1056]
    mov rbx, [rbp-1048]
    mov rcx, [rbp-1040]
    mov rdx, [rbp-1032]
    lea r8, [rbp-24]
    mov [r8], rcx
    lea rcx, [rbp-24]
    mov rcx, rcx
    add rcx, 8
    mov [rcx], rbx
    lea rbx, [rbp-24]
    mov rbx, rbx
    add rbx, 16
    mov [rbx], rax
    lea rax, [rbp-24]
    mov rbx, [rax]
    mov [rdx], rbx
    mov rbx, rax
    add rbx, 8
    mov rcx, rdx
    add rcx, 8
    mov rbx, [rbx]
    mov [rcx], rbx
    mov rax, rax
    add rax, 16
    mov rbx, rdx
    add rbx, 16
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
.Lssa_1_1:
    lea rax, [rel _96_ssa_large_struct_member_access__make_large]
    lea rbx, [rbp-40]
    mov rcx, 1
    mov rdx, 2
    mov r8, 3
    push rax
    push rbx
    push r8
    push rdx
    push rcx
    push rbx
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call _96_ssa_large_struct_member_access__make_large
    pop rbx
    pop rax
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    lea rcx, [rbp-72]
    mov rdx, 4
    mov r8, 5
    mov r9, 6
    push rbx
    push rcx
    push r9
    push r8
    push rdx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    call rax
    pop rcx
    pop rbx
    mov rax, rcx
    add rax, 16
    mov rax, [rax]
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
