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
_94_ssa_large_struct_param_call_ptr__sum_large:
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
    mov rbx, 3
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rax, rax
    add rax, 8
    mov rbx, 4
    mov [rax], rbx
    lea rax, [rbp-24]
    mov rax, rax
    add rax, 16
    mov rbx, 5
    mov [rax], rbx
    lea rax, [rel _94_ssa_large_struct_param_call_ptr__sum_large]
    lea rbx, [rbp-64]
    lea rcx, [rbp-24]
    mov rdx, [rcx]
    mov [rbx], rdx
    mov rdx, rcx
    add rdx, 8
    mov r8, rbx
    add r8, 8
    mov rdx, [rdx]
    mov [r8], rdx
    mov rcx, rcx
    add rcx, 16
    mov rdx, rbx
    add rdx, 16
    mov rcx, [rcx]
    mov [rdx], rcx
    push rax
    push rbx
    pop rdi
    call rax
    mov rbx, rax
    pop rax
    lea rcx, [rbp-96]
    mov rdx, 1
    mov [rcx], rdx
    mov rdx, rcx
    add rdx, 8
    mov r8, 2
    mov [rdx], r8
    mov rdx, rcx
    add rdx, 16
    mov r8, 3
    mov [rdx], r8
    push rbx
    push rcx
    pop rdi
    call rax
    pop rbx
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
