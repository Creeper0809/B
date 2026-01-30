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
_06_control_flow__classify_number:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L0
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    sub rax, rbx
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L2
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L2:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L0:
    mov rax, [rbp+16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L4:
    mov rax, [rbp+16]
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L6:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_06_control_flow__test_else_if:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 85
    mov [rbp-8], rax
    mov rax, 0
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 90
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, 1
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L9
.L8:
    mov rax, [rbp-8]
    push rax
    mov rax, 80
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L10
    mov rax, 2
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L11
.L10:
    mov rax, [rbp-8]
    push rax
    mov rax, 70
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, 3
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L13
.L12:
    mov rax, [rbp-8]
    push rax
    mov rax, 60
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setge al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 4
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    jmp .L15
.L14:
    mov rax, 5
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L15:
.L13:
.L11:
.L9:
    mov rax, [rbp-16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L16:
    mov rax, 5
    mov [rbp-24], rax
    mov rax, 10
    mov [rbp-32], rax
    mov rax, 0
    mov [rbp-40], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 1
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L19
.L18:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 2
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L21
.L20:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L24
    mov rax, 3
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L25
.L24:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L26
    mov rax, 4
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
    jmp .L27
.L26:
    mov rax, [rbp-32]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L28
    mov rax, 5
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
.L28:
.L27:
.L25:
.L22:
.L21:
.L19:
    mov rax, [rbp-40]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L30
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L30:
    mov rax, 7
    mov [rbp-48], rax
    mov rax, 0
    mov [rbp-56], rax
    mov rax, [rbp-48]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L32
    mov rax, 10
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L33
.L32:
    mov rax, [rbp-48]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L34
    mov rax, 20
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L35
.L34:
    mov rax, [rbp-48]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L36
    mov rax, 30
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L37
.L36:
    mov rax, [rbp-48]
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L38
    mov rax, 40
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L39
.L38:
    mov rax, [rbp-48]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L40
    mov rax, 50
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L41
.L40:
    mov rax, [rbp-48]
    push rax
    mov rax, 6
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L42
    mov rax, 60
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L43
.L42:
    mov rax, [rbp-48]
    push rax
    mov rax, 7
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L44
    mov rax, 70
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L45
.L44:
    mov rax, [rbp-48]
    push rax
    mov rax, 8
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L46
    mov rax, 80
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L47
.L46:
    mov rax, [rbp-48]
    push rax
    mov rax, 9
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L48
    mov rax, 90
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    jmp .L49
.L48:
    mov rax, 100
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
.L49:
.L47:
.L45:
.L43:
.L41:
.L39:
.L37:
.L35:
.L33:
    mov rax, [rbp-56]
    push rax
    mov rax, 70
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L50
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L50:
    mov rax, 15
    mov [rbp-64], rax
    mov rax, 0
    mov [rbp-72], rax
    mov rax, [rbp-64]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L52
    mov rax, 1
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
    jmp .L53
.L52:
    mov rax, [rbp-64]
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L54
    mov rax, 2
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
    jmp .L55
.L54:
    mov rax, [rbp-64]
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L56
    mov rax, 3
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
.L56:
.L55:
.L53:
    mov rax, [rbp-72]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L58
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L58:
    mov rax, 10
    mov [rbp-80], rax
    mov rax, 20
    mov [rbp-88], rax
    mov rax, 0
    mov [rbp-96], rax
    mov rax, [rbp-80]
    push rax
    mov rax, [rbp-88]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L60
    mov rax, 1
    push rax
    lea rax, [rbp-96]
    pop rbx
    mov [rax], rbx
    jmp .L61
.L60:
    mov rax, [rbp-80]
    push rax
    mov rax, [rbp-88]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L62
    mov rax, 2
    push rax
    lea rax, [rbp-96]
    pop rbx
    mov [rax], rbx
    jmp .L63
.L62:
    mov rax, [rbp-80]
    push rax
    mov rax, [rbp-88]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, 200
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L64
    mov rax, 3
    push rax
    lea rax, [rbp-96]
    pop rbx
    mov [rax], rbx
    jmp .L65
.L64:
    mov rax, 4
    push rax
    lea rax, [rbp-96]
    pop rbx
    mov [rax], rbx
.L65:
.L63:
.L61:
    mov rax, [rbp-96]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L66
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L66:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_06_control_flow__bump:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_06_control_flow__crash:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 123
    push rax
    mov rax, 0
    pop rbx
    mov [rax], rbx
    mov rax, 1
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
    mov rax, 1
    mov [rbp-8], rax
    mov rax, 1
    mov [rbp-16], rax
    mov rax, 0
    mov [rbp-24], rax
    mov rax, 1
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L68:
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L69
    mov rax, 1
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
.L70:
    mov rax, [rbp-16]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L71
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-24]
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
    jmp .L70
.L71:
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
    jmp .L68
.L69:
    mov rax, [rbp-24]
    push rax
    mov rax, 225
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L72
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L72:
    mov rax, 0
    mov [rbp-32], rax
    mov rax, 1
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
.L74:
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L76
    mov rax, [rbp-32]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
.L75:
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
    jmp .L74
.L76:
    mov rax, [rbp-32]
    push rax
    mov rax, 55
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L77
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L77:
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    mov [rbp-40], rax
.L79:
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L80
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L81
    jmp .L80
.L81:
    mov rax, [rbp-40]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-40]
    pop rbx
    mov [rax], rbx
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
    jmp .L79
.L80:
    mov rax, [rbp-40]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L83
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L83:
    mov rax, 0
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    mov [rbp-48], rax
.L85:
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L86
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
    mov rax, [rbp-8]
    push rax
    mov rax, 2
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
    sete al
    movzx rax, al
    test rax, rax
    jz .L87
    jmp .L85
.L87:
    mov rax, [rbp-48]
    push rax
    mov rax, [rbp-8]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-48]
    pop rbx
    mov [rax], rbx
    jmp .L85
.L86:
    mov rax, [rbp-48]
    push rax
    mov rax, 25
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L89
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L89:
    mov rax, 0
    push rax
    mov rax, 200
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call _06_control_flow__classify_number
    add rsp, 8
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L91
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L91:
    mov rax, 0
    push rax
    mov rax, 50
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call _06_control_flow__classify_number
    add rsp, 8
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L93
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L93:
    mov rax, 0
    push rax
    call _06_control_flow__classify_number
    add rsp, 8
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L95
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L95:
    mov rax, 50
    push rax
    call _06_control_flow__classify_number
    add rsp, 8
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L97
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L97:
    mov rax, 200
    push rax
    call _06_control_flow__classify_number
    add rsp, 8
    push rax
    mov rax, 4
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L99
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
.L99:
    call _06_control_flow__test_else_if
    mov [rbp-56], rax
    mov rax, [rbp-56]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L101
    mov rax, 10
    mov rsp, rbp
    pop rbp
    ret
.L101:
    mov rax, 0
    mov [rbp-64], rax
    mov rax, 0
    test rax, rax
    jz .L105
    lea rax, [rbp-64]
    push rax
    call _06_control_flow__bump
    add rsp, 8
    test rax, rax
    setne al
    movzx rax, al
    jmp .L106
.L105:
    xor eax, eax
.L106:
    test rax, rax
    jz .L103
    mov rax, 99
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L103:
    mov rax, 1
    test rax, rax
    jnz .L109
    lea rax, [rbp-64]
    push rax
    call _06_control_flow__bump
    add rsp, 8
    test rax, rax
    setne al
    movzx rax, al
    jmp .L110
.L109:
    mov eax, 1
.L110:
    test rax, rax
    jz .L107
.L107:
    mov rax, 0
    test rax, rax
    jnz .L113
    lea rax, [rbp-64]
    push rax
    call _06_control_flow__bump
    add rsp, 8
    test rax, rax
    setne al
    movzx rax, al
    jmp .L114
.L113:
    mov eax, 1
.L114:
    test rax, rax
    jz .L111
.L111:
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L115
    mov rax, 11
    mov rsp, rbp
    pop rbp
    ret
.L115:
    mov rax, 0
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    test rax, rax
    jz .L117
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
.L117:
    mov rax, 0
    test rax, rax
    jz .L119
    mov rax, 99
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L119:
    mov rax, 1
    test rax, rax
    jz .L123
    mov rax, 0
    test rax, rax
    setne al
    movzx rax, al
    jmp .L124
.L123:
    xor eax, eax
.L124:
    test rax, rax
    jz .L121
    mov rax, 123
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L121:
    mov rax, 0
    test rax, rax
    jnz .L127
    mov rax, 1
    test rax, rax
    setne al
    movzx rax, al
    jmp .L128
.L127:
    mov eax, 1
.L128:
    test rax, rax
    jz .L125
    mov rax, [rbp-64]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
.L125:
    mov rax, [rbp-64]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L129
    mov rax, 12
    mov rsp, rbp
    pop rbp
    ret
.L129:
    mov rax, 0
    test rax, rax
    jz .L133
    call _06_control_flow__crash
    test rax, rax
    setne al
    movzx rax, al
    jmp .L134
.L133:
    xor eax, eax
.L134:
    test rax, rax
    jz .L131
    mov rax, 13
    mov rsp, rbp
    pop rbp
    ret
.L131:
    mov rax, 1
    test rax, rax
    jnz .L137
    call _06_control_flow__crash
    test rax, rax
    setne al
    movzx rax, al
    jmp .L138
.L137:
    mov eax, 1
.L138:
    test rax, rax
    jz .L135
.L135:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
