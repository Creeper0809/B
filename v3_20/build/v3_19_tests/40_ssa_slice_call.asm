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
_40_ssa_slice_call__first_byte:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    lea rax, [rbp-9223372036854775792]
    mov rax, [rax]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_40_ssa_slice_call__last_byte:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdx
    lea rbx, [rbp-9223372036854775792]
    mov rbx, [rbx]
    mov rcx, 1
    mov rax, rax
    sub rax, rcx
    add rax, rbx
    movzx rax, byte [rax]
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
.Lssa_2_2:
    mov rax, rdi
    mov rax, rsi
    lea rax, [rel _str0]
    mov rbx, 3
    mov rdi, rbx
    mov rsi, rax
    call _40_ssa_slice_call__first_byte
    mov rbx, 65
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_3
    jmp .Lssa_2_4
.Lssa_2_3:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_4
.Lssa_2_4:
    mov rax, 3
    lea rbx, [rel _str1]
    mov rcx, 3
    mov rdi, rax
    mov rsi, rcx
    mov rdx, rbx
    call _40_ssa_slice_call__last_byte
    mov rbx, 90
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_5
    jmp .Lssa_2_6
.Lssa_2_5:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_6
.Lssa_2_6:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 65,66,67,0
_str1: db 88,89,90,0
