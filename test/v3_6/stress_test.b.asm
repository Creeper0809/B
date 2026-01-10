section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_precedence:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 2
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 4
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 5
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
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
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-40]
    push rax
    mov rax, 9
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
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-48]
    push rax
    mov rax, 0
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    sub rax, rbx
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
    sub rsp, 8
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-56]
    push rax
    mov rax, 26
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
    sub rsp, 8
    mov rax, 20
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-64]
    push rax
    mov rax, 1
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
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_cmp_complex:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 10
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L10
    jmp .L11
.L10:
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L11:
    jmp .L9
.L8:
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L9:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L14
    jmp .L15
.L14:
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L15:
    jmp .L13
.L12:
    mov rax, 13
    mov rsp, rbp
    pop rbp
    ret
.L13:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L18
    jmp .L19
.L18:
    mov rax, 14
    mov rsp, rbp
    pop rbp
    ret
.L19:
    jmp .L17
.L16:
    mov rax, 15
    mov rsp, rbp
    pop rbp
    ret
.L17:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_mixed_control:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 1
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 4
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 5
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-40]
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L20:
    mov rax, [rbp-64]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L21
    sub rsp, 8
    mov rax, [rbp-56]
    push rax
    mov rax, [rbp-64]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-72]
    mov rax, [rax]
    push rax
    lea rax, [rbp-80]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-80]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-80]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
.L22:
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    jmp .L20
.L21:
    mov rax, [rbp-48]
    push rax
    mov rax, 12
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L24
    mov rax, 20
    mov rsp, rbp
    pop rbp
    ret
.L24:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
add1:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
mul2:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
sub3:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_call_chain:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 5
    push rax
    call add1
    add rsp, 8
    push rax
    call mul2
    add rsp, 8
    push rax
    call sub3
    add rsp, 8
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L26
    mov rax, 30
    mov rsp, rbp
    pop rbp
    ret
.L26:
    mov rax, 0
    push rax
    call add1
    add rsp, 8
    push rax
    call add1
    add rsp, 8
    push rax
    call add1
    add rsp, 8
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L28
    mov rax, 31
    mov rsp, rbp
    pop rbp
    ret
.L28:
    mov rax, 1
    push rax
    call mul2
    add rsp, 8
    push rax
    call mul2
    add rsp, 8
    push rax
    call mul2
    add rsp, 8
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L30
    mov rax, 32
    mov rsp, rbp
    pop rbp
    ret
.L30:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
absval:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L32
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
.L32:
    mov rax, [rbp+16]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
max:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L34
    mov rax, [rbp+16]
    mov rsp, rbp
    pop rbp
    ret
.L34:
    mov rax, [rbp+24]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
min:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L36
    mov rax, [rbp+16]
    mov rsp, rbp
    pop rbp
    ret
.L36:
    mov rax, [rbp+24]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
clamp:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L38
    mov rax, [rbp+24]
    mov rsp, rbp
    pop rbp
    ret
.L38:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+32]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L40
    mov rax, [rbp+32]
    mov rsp, rbp
    pop rbp
    ret
.L40:
    mov rax, [rbp+16]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_util_funcs:
    push rbp
    mov rbp, rsp
    mov rax, 0
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call absval
    add rsp, 8
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L42
    mov rax, 40
    mov rsp, rbp
    pop rbp
    ret
.L42:
    mov rax, 5
    push rax
    call absval
    add rsp, 8
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L44
    mov rax, 41
    mov rsp, rbp
    pop rbp
    ret
.L44:
    mov rax, 7
    push rax
    mov rax, 3
    push rax
    call max
    add rsp, 16
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L46
    mov rax, 42
    mov rsp, rbp
    pop rbp
    ret
.L46:
    mov rax, 3
    push rax
    mov rax, 7
    push rax
    call max
    add rsp, 16
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L48
    mov rax, 43
    mov rsp, rbp
    pop rbp
    ret
.L48:
    mov rax, 7
    push rax
    mov rax, 3
    push rax
    call min
    add rsp, 16
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L50
    mov rax, 44
    mov rsp, rbp
    pop rbp
    ret
.L50:
    mov rax, 3
    push rax
    mov rax, 7
    push rax
    call min
    add rsp, 16
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L52
    mov rax, 45
    mov rsp, rbp
    pop rbp
    ret
.L52:
    mov rax, 10
    push rax
    mov rax, 0
    push rax
    mov rax, 5
    push rax
    call clamp
    add rsp, 24
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L54
    mov rax, 46
    mov rsp, rbp
    pop rbp
    ret
.L54:
    mov rax, 10
    push rax
    mov rax, 0
    push rax
    mov rax, 0
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call clamp
    add rsp, 24
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L56
    mov rax, 47
    mov rsp, rbp
    pop rbp
    ret
.L56:
    mov rax, 10
    push rax
    mov rax, 0
    push rax
    mov rax, 15
    push rax
    call clamp
    add rsp, 24
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L58
    mov rax, 48
    mov rsp, rbp
    pop rbp
    ret
.L58:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
zero_val:
    push rbp
    mov rbp, rsp
    mov rax, 0
    push rax
    mov rax, [rbp+16]
    pop rbx
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_array_ops:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 99
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 88
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 77
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-8]
    push rax
    call zero_val
    add rsp, 8
    lea rax, [rbp-16]
    push rax
    call zero_val
    add rsp, 8
    lea rax, [rbp-24]
    push rax
    call zero_val
    add rsp, 8
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, 50
    mov rsp, rbp
    pop rbp
    ret
.L60:
    mov rax, [rbp-16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L62
    mov rax, 51
    mov rsp, rbp
    pop rbp
    ret
.L62:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L64
    mov rax, 52
    mov rsp, rbp
    pop rbp
    ret
.L64:
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, 10
    push rax
    mov rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-16]
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    mov rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-24]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, 30
    push rax
    mov rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, 53
    mov rsp, rbp
    pop rbp
    ret
.L66:
    mov rax, [rbp-16]
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L68
    mov rax, 54
    mov rsp, rbp
    pop rbp
    ret
.L68:
    mov rax, [rbp-24]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L70
    mov rax, 55
    mov rsp, rbp
    pop rbp
    ret
.L70:
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
    add rax, rbx
    push rax
    mov rax, 60
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L72
    mov rax, 56
    mov rsp, rbp
    pop rbp
    ret
.L72:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
is_prime:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L74
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L74:
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L76
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L76:
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L78
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L78:
    sub rsp, 8
    mov rax, 3
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L80:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L81
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L82
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L82:
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    jmp .L80
.L81:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_prime:
    push rbp
    mov rbp, rsp
    mov rax, 2
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L84
    mov rax, 60
    mov rsp, rbp
    pop rbp
    ret
.L84:
    mov rax, 3
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L86
    mov rax, 61
    mov rsp, rbp
    pop rbp
    ret
.L86:
    mov rax, 4
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L88
    mov rax, 62
    mov rsp, rbp
    pop rbp
    ret
.L88:
    mov rax, 5
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L90
    mov rax, 63
    mov rsp, rbp
    pop rbp
    ret
.L90:
    mov rax, 6
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L92
    mov rax, 64
    mov rsp, rbp
    pop rbp
    ret
.L92:
    mov rax, 7
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L94
    mov rax, 65
    mov rsp, rbp
    pop rbp
    ret
.L94:
    mov rax, 9
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L96
    mov rax, 66
    mov rsp, rbp
    pop rbp
    ret
.L96:
    mov rax, 11
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L98
    mov rax, 67
    mov rsp, rbp
    pop rbp
    ret
.L98:
    mov rax, 13
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L100
    mov rax, 68
    mov rsp, rbp
    pop rbp
    ret
.L100:
    mov rax, 15
    push rax
    call is_prime
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L102
    mov rax, 69
    mov rsp, rbp
    pop rbp
    ret
.L102:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
gcd:
    push rbp
    mov rbp, rsp
.L104:
    mov rax, [rbp+24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L105
    sub rsp, 8
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp+24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    lea rax, [rbp+16]
    pop rbx
    mov [rax], rbx
    jmp .L104
.L105:
    mov rax, [rbp+16]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_gcd:
    push rbp
    mov rbp, rsp
    mov rax, 18
    push rax
    mov rax, 48
    push rax
    call gcd
    add rsp, 16
    push rax
    mov rax, 6
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L106
    mov rax, 70
    mov rsp, rbp
    pop rbp
    ret
.L106:
    mov rax, 35
    push rax
    mov rax, 100
    push rax
    call gcd
    add rsp, 16
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L108
    mov rax, 71
    mov rsp, rbp
    pop rbp
    ret
.L108:
    mov rax, 13
    push rax
    mov rax, 17
    push rax
    call gcd
    add rsp, 16
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L110
    mov rax, 72
    mov rsp, rbp
    pop rbp
    ret
.L110:
    mov rax, 12
    push rax
    mov rax, 12
    push rax
    call gcd
    add rsp, 16
    push rax
    mov rax, 12
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L112
    mov rax, 73
    mov rsp, rbp
    pop rbp
    ret
.L112:
    mov rax, 0
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
    sub rsp, 8
    call test_precedence
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L114
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L114:
    call test_cmp_complex
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L116
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L116:
    call test_mixed_control
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L118
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L118:
    call test_call_chain
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L120
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L120:
    call test_util_funcs
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L122
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L122:
    call test_array_ops
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L124
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L124:
    call test_prime
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L126
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L126:
    call test_gcd
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L128
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L128:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
