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
_92_ssa_large_struct_param_call__sum_large:
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
    lea rax, [rbp-24]
    mov rbx, [rbp-1032]
    mov rcx, [rbx]
    mov [rax], rcx
    mov rcx, rbx
    add rcx, 8
    mov rdx, rax
    add rdx, 8
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rbx, rbx
    add rbx, 16
    mov rax, rax
    add rax, 16
    mov rbx, [rbx]
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rax, [rax]
    lea rbx, [rbp-24]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-24]
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
    lea rax, [rbp-24]
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
    lea rax, [rbp-56]
    lea rbx, [rbp-24]
    mov rcx, [rbx]
    mov [rax], rcx
    mov rcx, rbx
    add rcx, 8
    mov rdx, rax
    add rdx, 8
    mov rcx, [rcx]
    mov [rdx], rcx
    mov rbx, rbx
    add rbx, 16
    mov rcx, rax
    add rcx, 16
    mov rbx, [rbx]
    mov [rcx], rbx
    push rax
    pop rdi
    call _92_ssa_large_struct_param_call__sum_large
    lea rbx, [rbp-88]
    mov rcx, 4
    mov [rbx], rcx
    mov rcx, rbx
    add rcx, 8
    mov rdx, 5
    mov [rcx], rdx
    mov rcx, rbx
    add rcx, 16
    mov rdx, 6
    mov [rcx], rdx
    push rax
    push rbx
    pop rdi
    call _92_ssa_large_struct_param_call__sum_large
    mov rbx, rax
    pop rax
    mov rax, rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
