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
.Lssa_0_0:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    mov rax, 0
    mov rbx, 0
    mov rcx, rbx
    mov rbx, rax
    jmp .Lssa_0_1
.Lssa_0_1:
    cmp rbx, 10
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_2
    jmp .Lssa_0_3
.Lssa_0_2:
    mov rax, rbx
    add rax, 1
    push rax
    push rdx
    mov rax, rax
    cqo
    push rcx
    mov rcx, 2
    idiv rcx
    mov rbx, rdx
    pop rcx
    pop rdx
    pop rax
    push rax
    cmp rbx, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_0_4
    jmp .Lssa_0_5
.Lssa_0_3:
    cmp rcx, 25
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_7
    jmp .Lssa_0_8
.Lssa_0_4:
    mov rbx, rax
    jmp .Lssa_0_1
.Lssa_0_5:
    mov rbx, rcx
    add rbx, rax
    mov rcx, rbx
    mov rbx, rax
    jmp .Lssa_0_1
.Lssa_0_6:
    jmp .Lssa_0_5
.Lssa_0_7:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_8
.Lssa_0_8:
    mov rax, 0
    mov rbx, 0
    mov rcx, rax
    jmp .Lssa_0_9
.Lssa_0_9:
    cmp rbx, 10
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_10
    jmp .Lssa_0_12
.Lssa_0_10:
    cmp rbx, 5
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_13
    jmp .Lssa_0_14
.Lssa_0_11:
    mov rax, rbx
    add rax, 1
    mov rbx, rax
    jmp .Lssa_0_9
.Lssa_0_12:
    cmp rcx, 5
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_16
    jmp .Lssa_0_17
.Lssa_0_13:
    jmp .Lssa_0_11
.Lssa_0_14:
    mov rax, rcx
    add rax, 1
    mov rcx, rax
    jmp .Lssa_0_11
.Lssa_0_15:
    jmp .Lssa_0_14
.Lssa_0_16:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_0_17
.Lssa_0_17:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
