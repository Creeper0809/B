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
_32_ssa_for_switch__calc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rbx, 0
    mov rcx, 0
    mov rdx, rcx
    mov rcx, rbx
    jmp .Lssa_0_1
.Lssa_0_1:
    push rax
    cmp rdx, rax
    setl al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_2
    jmp .Lssa_0_4
.Lssa_0_2:
    mov rbx, 2
    push rax
    cmp rdx, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_5
    jmp .Lssa_0_6
.Lssa_0_3:
    lea rbx, [rbp-16]
    mov rbx, 1
    add rbx, rdx
    mov rdx, rbx
    jmp .Lssa_0_1
.Lssa_0_4:
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
.Lssa_0_5:
    jmp .Lssa_0_3
.Lssa_0_6:
    mov rbx, 0
    push rax
    cmp rdx, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_9
    jmp .Lssa_0_12
.Lssa_0_7:
    jmp .Lssa_0_6
.Lssa_0_8:
    mov rcx, rbx
    jmp .Lssa_0_3
.Lssa_0_9:
    lea rbx, [rbp-8]
    mov rbx, 1
    add rbx, rcx
    jmp .Lssa_0_8
.Lssa_0_10:
    lea rbx, [rbp-8]
    mov rbx, 10
    add rbx, rcx
    jmp .Lssa_0_8
.Lssa_0_11:
    lea rbx, [rbp-8]
    mov rbx, 100
    add rbx, rcx
    jmp .Lssa_0_8
.Lssa_0_12:
    mov rbx, 1
    push rax
    cmp rdx, rbx
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_10
    jmp .Lssa_0_13
.Lssa_0_13:
    jmp .Lssa_0_11
.Lssa_0_14:
.Lssa_0_15:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_16:
    mov rax, rdi
    mov rax, rsi
    mov rax, 4
    mov rdi, rax
    call _32_ssa_for_switch__calc
    mov rbx, 111
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_17
    jmp .Lssa_1_18
.Lssa_1_17:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_18
.Lssa_1_18:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
