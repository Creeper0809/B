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
_64_o1_slice_return__make_slice:
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
    lea rcx, [rbp-16]
    mov [rcx], rbx
    mov rbx, rcx
    add rbx, 8
    mov [rbx], rax
    lea rax, [rbp-16]
    mov rbx, [rax]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    mov rdx, rax
    mov rax, rbx
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
    mov rax, [rbp-1040]
    mov rax, [rbp-1032]
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 0
    mov rbx, 65
    mov byte [rax], bl
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 1
    mov rbx, 66
    mov byte [rax], bl
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 2
    mov rbx, 67
    mov byte [rax], bl
    lea rax, [rbp-4]
    mov rax, rax
    add rax, 3
    mov rbx, 68
    mov byte [rax], bl
    lea rax, [rbp-20]
    lea rbx, [rbp-4]
    mov rcx, 4
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    call _64_o1_slice_return__make_slice
    mov rbx, [rsp]
    mov [rbx], rax
    mov [rbx+8], rdx
    add rsp, 8
    lea rax, [rbp-20]
    mov rax, [rax]
    mov rax, rax
    add rax, 0
    movzx rax, byte [rax]
    cmp rax, 65
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
    lea rax, [rbp-20]
    mov rax, [rax]
    mov rax, rax
    add rax, 3
    movzx rax, byte [rax]
    cmp rax, 68
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
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
