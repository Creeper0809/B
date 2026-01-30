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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_0_0:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_2_2:
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rel _gvar__39_ssa_call_basic__g]
    mov rbx, 0
    mov [rax], rbx
    mov rax, 2
    mov rbx, 3
    push rbx
    push rax
    pop rdi
    pop rsi
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
    mov rax, 4
    mov rbx, 6
    push rbx
    push rax
    pop rdi
    pop rsi
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
