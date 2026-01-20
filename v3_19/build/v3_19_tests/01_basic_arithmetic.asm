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
    sub rsp, 1024
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 5
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 15
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
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, 5
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
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, 50
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
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    mov rax, 2
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
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    mov rax, 0
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
    mov rax, 42
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 15
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    and rax, rbx
    mov [rbp-40], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    or rax, rbx
    mov [rbp-48], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    xor rax, rbx
    mov [rbp-56], rax
    mov rax, [rbp-40]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    mov rcx, rbx
    shl rax, cl
    push rax
    mov rax, [rbp-56]
    mov rbx, rax
    pop rax
    or rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    mov rcx, rbx
    shr rax, cl
    push rax
    mov rax, 82
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
    mov rax, 10
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L12:
    mov rax, 10
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, 5
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
.L16:
    mov rax, 5
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L18:
    mov rax, 5
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L20:
    mov rax, 7
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    setz al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L22:
    mov rax, 1
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    mov rcx, rbx
    shl rax, cl
    mov [rbp-64], rax
    mov rax, 1
    push rax
    mov rax, 2
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rbx, rax
    pop rax
    mov rcx, rbx
    shl rax, cl
    mov [rbp-72], rax
    mov rax, [rbp-64]
    push rax
    mov rax, 6
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L24
    mov rax, 13
    mov rsp, rbp
    pop rbp
    ret
.L24:
    mov rax, [rbp-72]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L26
    mov rax, 14
    mov rsp, rbp
    pop rbp
    ret
.L26:
    mov rax, 1
    push rax
    mov rax, 2
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    mov rbx, rax
    pop rax
    and rax, rbx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L28
    mov rax, 15
    mov rsp, rbp
    pop rbp
    ret
.L28:
    mov rax, 5
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 10
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, 45
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L30
    mov rax, 16
    mov rsp, rbp
    pop rbp
    ret
.L30:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, 35
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L32
    mov rax, 17
    mov rsp, rbp
    pop rbp
    ret
.L32:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L34
    mov rax, 18
    mov rsp, rbp
    pop rbp
    ret
.L34:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-32]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L36
    mov rax, 19
    mov rsp, rbp
    pop rbp
    ret
.L36:
    mov rax, 10
    mov [rbp-80], rax
    mov rax, [rbp-80]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-80]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-80]
    push rax
    mov rax, 15
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L38
    mov rax, 20
    mov rsp, rbp
    pop rbp
    ret
.L38:
    mov rax, 20
    mov [rbp-88], rax
    mov rax, [rbp-88]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-88]
    push rax
    mov rax, 13
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L40
    mov rax, 21
    mov rsp, rbp
    pop rbp
    ret
.L40:
    mov rax, 6
    mov [rbp-96], rax
    mov rax, [rbp-96]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-96]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-96]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L42
    mov rax, 22
    mov rsp, rbp
    pop rbp
    ret
.L42:
    mov rax, 100
    mov [rbp-104], rax
    mov rax, [rbp-104]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-104]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-104]
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L44
    mov rax, 23
    mov rsp, rbp
    pop rbp
    ret
.L44:
    mov rax, 17
    mov [rbp-112], rax
    mov rax, [rbp-112]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-112]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L46
    mov rax, 24
    mov rsp, rbp
    pop rbp
    ret
.L46:
    mov rax, 10
    mov [rbp-120], rax
    mov rax, [rbp-120]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-120]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-120]
    push rax
    mov rax, 11
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L48
    mov rax, 25
    mov rsp, rbp
    pop rbp
    ret
.L48:
    mov rax, [rbp-120]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-120]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-120]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L50
    mov rax, 26
    mov rsp, rbp
    pop rbp
    ret
.L50:
    mov rax, 5
    mov [rbp-128], rax
    mov rax, [rbp-128]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-128]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-128]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-128]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-128]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-128]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-128]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    push rax
    lea rax, [rbp-128]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-128]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    lea rax, [rbp-128]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-128]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L52
    mov rax, 27
    mov rsp, rbp
    pop rbp
    ret
.L52:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
