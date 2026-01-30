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
_50_ssa_call_ptr_basic__add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    mov rax, rdi
    mov rbx, rsi
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
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdi
    mov rax, rsi
    lea rax, [rel _50_ssa_call_ptr_basic__add]
    mov rbx, 8
    mov rcx, 7
    mov rdi, rbx
    mov rsi, rcx
    call rax
    mov rbx, 15
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_2
    jmp .Lssa_1_3
.Lssa_1_2:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_3
.Lssa_1_3:
    lea rax, [rel _gvar__50_ssa_call_ptr_basic__g]
    mov rbx, 9
    mov [rax], rbx
    lea rax, [rel _gvar__50_ssa_call_ptr_basic__g]
    mov rax, [rax]
    mov rbx, 9
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_4
    jmp .Lssa_1_5
.Lssa_1_4:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_5
.Lssa_1_5:
    lea rax, [rel _50_ssa_call_ptr_basic__add]
    mov rbx, 2
    mov rcx, 1
    mov rdi, rbx
    mov rsi, rcx
    call rax
    mov rbx, 3
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_1_6
    jmp .Lssa_1_7
.Lssa_1_6:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_1_7
.Lssa_1_7:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .bss
_gvar__50_ssa_call_ptr_basic__g: resq 1
