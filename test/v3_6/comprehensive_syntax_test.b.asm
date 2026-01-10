section .text
global _start
_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall
test_types:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
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
    mov rax, 30
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 40
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, 50
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
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
    mov rax, [rbp-32]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp-40]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-48]
    push rax
    mov rax, 150
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
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_const:
    push rbp
    mov rbp, rsp
    mov rax, 100
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L2
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L2:
    mov rax, 10
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L4:
    mov rax, 42
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L6:
    sub rsp, 8
    mov rax, 100
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 90
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, 13
    mov rsp, rbp
    pop rbp
    ret
.L8:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_arithmetic:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    mov rax, 20
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 3
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
    mov rax, 23
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L10
    mov rax, 20
    mov rsp, rbp
    pop rbp
    ret
.L10:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, 17
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, 21
    mov rsp, rbp
    pop rbp
    ret
.L12:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, 60
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 22
    mov rsp, rbp
    pop rbp
    ret
.L14:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, 6
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, 23
    mov rsp, rbp
    pop rbp
    ret
.L16:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 26
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 24
    mov rsp, rbp
    pop rbp
    ret
.L18:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, 46
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 25
    mov rsp, rbp
    pop rbp
    ret
.L20:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_comparison:
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
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, 30
    mov rsp, rbp
    pop rbp
    ret
.L22:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L24
    jmp .L25
.L24:
    mov rax, 31
    mov rsp, rbp
    pop rbp
    ret
.L25:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L26
    jmp .L27
.L26:
    mov rax, 32
    mov rsp, rbp
    pop rbp
    ret
.L27:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L28
    mov rax, 33
    mov rsp, rbp
    pop rbp
    ret
.L28:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L30
    jmp .L31
.L30:
    mov rax, 34
    mov rsp, rbp
    pop rbp
    ret
.L31:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L32
    mov rax, 35
    mov rsp, rbp
    pop rbp
    ret
.L32:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L34
    jmp .L35
.L34:
    mov rax, 36
    mov rsp, rbp
    pop rbp
    ret
.L35:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L36
    mov rax, 37
    mov rsp, rbp
    pop rbp
    ret
.L36:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L38
    jmp .L39
.L38:
    mov rax, 38
    mov rsp, rbp
    pop rbp
    ret
.L39:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L40
    jmp .L41
.L40:
    mov rax, 39
    mov rsp, rbp
    pop rbp
    ret
.L41:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L42
    mov rax, 40
    mov rsp, rbp
    pop rbp
    ret
.L42:
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L44
    jmp .L45
.L44:
    mov rax, 41
    mov rsp, rbp
    pop rbp
    ret
.L45:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L46
    jmp .L47
.L46:
    mov rax, 42
    mov rsp, rbp
    pop rbp
    ret
.L47:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L48
    mov rax, 43
    mov rsp, rbp
    pop rbp
    ret
.L48:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_if_simple:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L50
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L50:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_if_else:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L52
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .L53
.L52:
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
.L53:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_if_elif:
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
    jz .L54
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .L55
.L54:
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L56
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    jmp .L57
.L56:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L57:
.L55:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_if_all:
    push rbp
    mov rbp, rsp
    mov rax, 5
    push rax
    call test_if_simple
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L58
    mov rax, 50
    mov rsp, rbp
    pop rbp
    ret
.L58:
    mov rax, 0
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call test_if_simple
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, 51
    mov rsp, rbp
    pop rbp
    ret
.L60:
    mov rax, 5
    push rax
    call test_if_else
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L62
    mov rax, 52
    mov rsp, rbp
    pop rbp
    ret
.L62:
    mov rax, 0
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call test_if_else
    add rsp, 8
    push rax
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L64
    mov rax, 53
    mov rsp, rbp
    pop rbp
    ret
.L64:
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call test_if_elif
    add rsp, 8
    push rax
    mov rax, 0
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, 54
    mov rsp, rbp
    pop rbp
    ret
.L66:
    mov rax, 0
    push rax
    call test_if_elif
    add rsp, 8
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L68
    mov rax, 55
    mov rsp, rbp
    pop rbp
    ret
.L68:
    mov rax, 1
    push rax
    call test_if_elif
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L70
    mov rax, 56
    mov rsp, rbp
    pop rbp
    ret
.L70:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_while_count:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L72:
    mov rax, [rbp-16]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L73
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L72
.L73:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_while_sum:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, 1
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L74:
    mov rax, [rbp-16]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L75
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L74
.L75:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_while_nested:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L76:
    mov rax, [rbp-16]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L77
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L78:
    mov rax, [rbp-24]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L79
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    jmp .L78
.L79:
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L76
.L77:
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_while_all:
    push rbp
    mov rbp, rsp
    call test_while_count
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L80
    mov rax, 60
    mov rsp, rbp
    pop rbp
    ret
.L80:
    call test_while_sum
    push rax
    mov rax, 55
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L82
    mov rax, 61
    mov rsp, rbp
    pop rbp
    ret
.L82:
    call test_while_nested
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L84
    mov rax, 62
    mov rsp, rbp
    pop rbp
    ret
.L84:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_ptr_basic:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 42
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    mov rax, [rax]
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L86
    mov rax, 70
    mov rsp, rbp
    pop rbp
    ret
.L86:
    mov rax, 100
    push rax
    mov rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L88
    mov rax, 71
    mov rsp, rbp
    pop rbp
    ret
.L88:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_ptr_chain:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-8]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-16]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-24]
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-32]
    mov rax, [rax]
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-40]
    mov rax, [rax]
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    mov rax, [rbp-48]
    mov rax, [rax]
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-56]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L90
    mov rax, 72
    mov rsp, rbp
    pop rbp
    ret
.L90:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
modify_via_ptr:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    pop rbx
    mov [rax], rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_ptr_param:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 99
    push rax
    lea rax, [rbp-8]
    push rax
    call modify_via_ptr
    add rsp, 16
    mov rax, [rbp-8]
    push rax
    mov rax, 99
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L92
    mov rax, 73
    mov rsp, rbp
    pop rbp
    ret
.L92:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_ptr_all:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    call test_ptr_basic
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
    jz .L94
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L94:
    call test_ptr_chain
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
    jz .L96
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L96:
    call test_ptr_param
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
    jz .L98
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L98:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_array_index:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 30
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 40
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    sub rsp, 8
    lea rax, [rbp-32]
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-40]
    mov rax, [rax]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L100
    mov rax, 80
    mov rsp, rbp
    pop rbp
    ret
.L100:
    sub rsp, 8
    mov rax, [rbp-40]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-48]
    mov rax, [rax]
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L102
    mov rax, 81
    mov rsp, rbp
    pop rbp
    ret
.L102:
    sub rsp, 8
    mov rax, [rbp-40]
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-56]
    mov rax, [rax]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L104
    mov rax, 82
    mov rsp, rbp
    pop rbp
    ret
.L104:
    sub rsp, 8
    mov rax, [rbp-40]
    push rax
    mov rax, 24
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-64]
    mov rax, [rax]
    push rax
    mov rax, 40
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L106
    mov rax, 83
    mov rsp, rbp
    pop rbp
    ret
.L106:
    mov rax, 200
    push rax
    mov rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 200
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L108
    mov rax, 84
    mov rsp, rbp
    pop rbp
    ret
.L108:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_complex_expr:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    sub rsp, 8
    sub rsp, 8
    mov rax, 5
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 17
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L110
    mov rax, 90
    mov rsp, rbp
    pop rbp
    ret
.L110:
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
    mov rax, 16
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L112
    mov rax, 91
    mov rsp, rbp
    pop rbp
    ret
.L112:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, 25
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L114
    mov rax, 92
    mov rsp, rbp
    pop rbp
    ret
.L114:
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
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-24]
    mov rbx, rax
    pop rax
    cqo
    idiv rbx
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L116
    mov rax, 93
    mov rsp, rbp
    pop rbp
    ret
.L116:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
inc:
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
double:
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
square:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+16]
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
test_call_chain:
    push rbp
    mov rbp, rsp
    mov rax, 0
    push rax
    call inc
    add rsp, 8
    push rax
    call inc
    add rsp, 8
    push rax
    call inc
    add rsp, 8
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L118
    mov rax, 100
    mov rsp, rbp
    pop rbp
    ret
.L118:
    mov rax, 1
    push rax
    call double
    add rsp, 8
    push rax
    call double
    add rsp, 8
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L120
    mov rax, 101
    mov rsp, rbp
    pop rbp
    ret
.L120:
    mov rax, 2
    push rax
    call square
    add rsp, 8
    push rax
    call square
    add rsp, 8
    push rax
    mov rax, 16
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L122
    mov rax, 102
    mov rsp, rbp
    pop rbp
    ret
.L122:
    mov rax, 3
    push rax
    call square
    add rsp, 8
    push rax
    call inc
    add rsp, 8
    push rax
    call double
    add rsp, 8
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L124
    mov rax, 103
    mov rsp, rbp
    pop rbp
    ret
.L124:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
sum_recursive:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L126
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.L126:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call sum_recursive
    add rsp, 8
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
power:
    push rbp
    mov rbp, rsp
    mov rax, [rbp+24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L128
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L128:
    mov rax, [rbp+16]
    push rax
    mov rax, [rbp+24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    call power
    add rsp, 16
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
test_recursive:
    push rbp
    mov rbp, rsp
    mov rax, 10
    push rax
    call sum_recursive
    add rsp, 8
    push rax
    mov rax, 55
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L130
    mov rax, 110
    mov rsp, rbp
    pop rbp
    ret
.L130:
    mov rax, 5
    push rax
    call sum_recursive
    add rsp, 8
    push rax
    mov rax, 15
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L132
    mov rax, 111
    mov rsp, rbp
    pop rbp
    ret
.L132:
    mov rax, 5
    push rax
    mov rax, 2
    push rax
    call power
    add rsp, 16
    push rax
    mov rax, 32
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L134
    mov rax, 112
    mov rsp, rbp
    pop rbp
    ret
.L134:
    mov rax, 3
    push rax
    mov rax, 3
    push rax
    call power
    add rsp, 16
    push rax
    mov rax, 27
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L136
    mov rax, 113
    mov rsp, rbp
    pop rbp
    ret
.L136:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
test_scope:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov rax, 10
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L138
    sub rsp, 8
    mov rax, 20
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-16]
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L140
    mov rax, 120
    mov rsp, rbp
    pop rbp
    ret
.L140:
    mov rax, 30
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L138:
    mov rax, [rbp-8]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L142
    mov rax, 121
    mov rsp, rbp
    pop rbp
    ret
.L142:
    sub rsp, 8
    mov rax, 0
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
.L144:
    mov rax, [rbp-24]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L145
    sub rsp, 8
    mov rax, 100
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    jmp .L144
.L145:
    mov rax, [rbp-24]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L146
    mov rax, 122
    mov rsp, rbp
    pop rbp
    ret
.L146:
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
    call test_types
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
    jz .L148
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L148:
    call test_const
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
    jz .L150
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L150:
    call test_arithmetic
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
    jz .L152
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L152:
    call test_comparison
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
    jz .L154
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L154:
    call test_if_all
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
    jz .L156
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L156:
    call test_while_all
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
    jz .L158
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L158:
    call test_ptr_all
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
    jz .L160
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L160:
    call test_array_index
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
    jz .L162
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L162:
    call test_complex_expr
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
    jz .L164
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L164:
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
    jz .L166
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L166:
    call test_recursive
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
    jz .L168
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L168:
    call test_scope
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
    jz .L170
    mov rax, [rbp-8]
    mov rsp, rbp
    pop rbp
    ret
.L170:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
