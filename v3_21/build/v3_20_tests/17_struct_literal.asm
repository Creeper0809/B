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
    sub rsp, 2048
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 10
    mov [rbp-32], rax
    mov rax, 32
    mov [rbp-24], rax
    lea rax, [rbp-32]
    mov rax, [rax]
    push rax
    lea rax, [rbp-24]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L0
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L0:
    mov rax, 10
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, 32
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-48]
    mov rax, [rax]
    push rax
    lea rax, [rbp-40]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L2
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L2:
    mov rax, 10
    mov [rbp-64], rax
    mov rax, 20
    mov [rbp-56], rax
    mov rax, [rbp-64]
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    lea rax, [rbp-64]
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rax, 12
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-88]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-88]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-72]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L4:
    mov rax, 5
    mov [rbp-104], rax
    mov rax, 10
    mov [rbp-96], rax
    mov rax, 15
    mov [rbp-120], rax
    mov rax, 12
    mov [rbp-112], rax
    lea rax, [rbp-104]
    mov rax, [rax]
    push rax
    lea rax, [rbp-96]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-120]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-112]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L6:
    mov rax, 5
    mov [rbp-128], rax
    mov rax, 10
    mov [rbp-136], rax
    mov rax, [rbp-128]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-152], rax
    mov rax, [rbp-136]
    push rax
    mov rax, 22
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-144], rax
    lea rax, [rbp-152]
    mov rax, [rax]
    push rax
    lea rax, [rbp-144]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L8:
    mov rax, 5
    mov [rbp-192], rax
    mov rax, 10
    mov [rbp-184], rax
    mov rax, 7
    mov [rbp-176], rax
    mov rax, 15
    mov [rbp-168], rax
    mov rax, 5
    mov [rbp-160], rax
    lea rax, [rbp-192]
    mov rax, [rax]
    push rax
    lea rax, [rbp-184]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-176]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-168]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-160]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L10
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L10:
    lea rax, [rbp-32]
    mov [rbp-200], rax
    mov rax, [rbp-200]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp-200]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L12:
    mov rax, 5
    mov [rbp-216], rax
    mov rax, 10
    mov [rbp-208], rax
    mov rax, 20
    push rax
    lea rax, [rbp-216]
    pop rbx
    mov [rax], rbx
    mov rax, 22
    push rax
    lea rax, [rbp-208]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-216]
    mov rax, [rax]
    push rax
    lea rax, [rbp-208]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
