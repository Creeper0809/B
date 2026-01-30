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
_87_ssa_sysv_args_gt6__sum8:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, [rbp+24]
    mov rbx, [rbp+16]
    mov rcx, r9
    mov rdx, r8
    mov r8, rcx
    mov r9, rdx
    mov rax, rsi
    mov rax, rdi
    mov rax, rax
    add rax, rax
    add r9, rax
    add r8, r9
    add rdx, r8
    add rcx, rdx
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
    sub rsp, 1024
.Lssa_1_1:
    mov rax, 1
    mov rbx, 2
    mov rcx, 3
    mov rdx, 4
    mov r8, 5
    mov r9, 6
    mov rax, 7
    mov rax, 8
    push rax
    push rax
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
    call _87_ssa_sysv_args_gt6__sum8
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
