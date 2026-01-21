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
_39_ssa_call_basic__add:
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
_39_ssa_call_basic__inc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    lea rax, [rel _gvar__39_ssa_call_basic__g]
    lea rbx, [rel _gvar__39_ssa_call_basic__g]
    mov rbx, [rbx]
    mov rcx, 1
    mov rbx, rbx
    add rbx, rcx
    mov [rax], rbx
    lea rax, [rel _gvar__39_ssa_call_basic__g]
    mov rax, [rax]
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
    lea rax, [rel _gvar__39_ssa_call_basic__g]
    mov rbx, 0
    mov [rax], rbx
    mov rax, 3
    mov rbx, 2
    mov rdi, rax
    mov rsi, rbx
    call _39_ssa_call_basic__add
    mov rbx, 5
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
    call _39_ssa_call_basic__inc
    mov rbx, 1
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_5
    jmp .Lssa_2_6
.Lssa_2_5:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_6
.Lssa_2_6:
    mov rax, 6
    mov rbx, 4
    mov rdi, rax
    mov rsi, rbx
    call _39_ssa_call_basic__add
    mov rbx, 10
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_7
    jmp .Lssa_2_8
.Lssa_2_7:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_8
.Lssa_2_8:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .bss
_gvar__39_ssa_call_basic__g: resq 1
