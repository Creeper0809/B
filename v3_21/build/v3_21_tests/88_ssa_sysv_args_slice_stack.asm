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
_88_ssa_sysv_args_slice_stack__sum_mix:
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
    mov rax, [rbp+24]
    lea rbx, [rbp-16]
    mov rcx, [rbp-1072]
    mov [rbx], rcx
    mov rcx, [rbp+16]
    mov rbx, rbx
    add rbx, 8
    mov [rbx], rcx
    mov rbx, [rbp-1064]
    mov rcx, [rbp-1056]
    mov rdx, [rbp-1048]
    mov r8, [rbp-1040]
    mov r9, [rbp-1032]
    add r8, r9
    add rdx, r8
    add rcx, rdx
    add rbx, rcx
    lea rcx, [rbp-16]
    mov rcx, [rcx]
    mov rcx, rcx
    add rcx, 0
    mov rcx, [rcx]
    mov rbx, rbx
    add rbx, rcx
    lea rcx, [rbp-16]
    mov rcx, [rcx]
    mov rcx, rcx
    add rcx, 8
    mov rcx, [rcx]
    mov rbx, rbx
    add rbx, rcx
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
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 0
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov rbx, 20
    mov [rax], rbx
    mov rax, 1
    mov rbx, 2
    mov rcx, 3
    mov rdx, 4
    mov r8, 5
    lea r9, [rbp-16]
    mov r10, 2
    mov r11, 6
    push r11
    push r10
    push r9
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
    pop r9
    call _88_ssa_sysv_args_slice_stack__sum_mix
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
