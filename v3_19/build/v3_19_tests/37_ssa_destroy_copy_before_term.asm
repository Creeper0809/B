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
_37_ssa_destroy_copy_before_term__choose:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, [rbp+16]
    mov rbx, 0
    mov rbx, 0
    cmp rax, rbx
    setg al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_0_1
    jmp .Lssa_0_3
.Lssa_0_1:
    lea rax, [rbp+9223372036854775800]
    mov rax, 1
    mov rbx, rax
    jmp .Lssa_0_2
.Lssa_0_2:
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
.Lssa_0_3:
    lea rax, [rbp+9223372036854775800]
    mov rax, 2
    mov rbx, rax
    jmp .Lssa_0_2
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_4:
    mov rax, [rbp+16]
    mov rax, [rbp+24]
    mov rax, 1
    push rax
    push rax
    call _37_ssa_destroy_copy_before_term__choose
    add rsp, 8
    add rsp, 8
    mov rbx, 1
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_5
    jmp .Lssa_1_6
.Lssa_1_5:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_6
.Lssa_1_6:
    mov rax, 0
    push rax
    push rax
    call _37_ssa_destroy_copy_before_term__choose
    add rsp, 8
    add rsp, 8
    mov rbx, 2
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_7
    jmp .Lssa_1_8
.Lssa_1_7:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_8
.Lssa_1_8:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
