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
_16_struct_basic__set_point:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+32]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_16_struct_basic__get_sum:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
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
main:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 10
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, 32
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, [rax]
    push rax
    lea rax, [rbp-8]
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
    lea rax, [rbp-16]
    push rax
    lea rax, [rbp-24]
    pop rbx
    mov [rax], rbx
    mov rax, 20
    push rax
    mov rax, [rbp-24]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 22
    push rax
    mov rax, [rbp-24]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-24]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp-24]
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
    jz .L2
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L2:
    mov rax, 10
    push rax
    lea rax, [rbp-48]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 15
    push rax
    lea rax, [rbp-48]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, 17
    push rax
    lea rax, [rbp-32]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-48]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    lea rax, [rbp-48]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-32]
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
    mov rax, 10
    push rax
    lea rax, [rbp-64]
    pop rbx
    mov [rax], rbx
    mov rax, 12
    push rax
    lea rax, [rbp-56]
    pop rbx
    mov [rax], rbx
    mov rax, 5
    push rax
    lea rax, [rbp-88]
    pop rbx
    mov [rax], rbx
    mov rax, 7
    push rax
    lea rax, [rbp-80]
    pop rbx
    mov [rax], rbx
    mov rax, 8
    push rax
    lea rax, [rbp-72]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-64]
    mov rax, [rax]
    push rax
    lea rax, [rbp-56]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-88]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-80]
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
    jz .L6
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L6:
    lea rax, [rbp-104]
    push rax
    lea rax, [rbp-112]
    pop rbx
    mov [rax], rbx
    mov rax, 22
    push rax
    mov rax, 20
    push rax
    mov rax, [rbp-112]
    push rax
    call _16_struct_basic__set_point
    add rsp, 24
    mov rax, [rbp-112]
    push rax
    call _16_struct_basic__get_sum
    add rsp, 8
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
    push rax
    lea rax, [rbp-128]
    pop rbx
    mov [rax], rbx
    mov rax, 7
    push rax
    lea rax, [rbp-120]
    pop rbx
    mov [rax], rbx
    mov rax, 10
    push rax
    lea rax, [rbp-144]
    pop rbx
    mov [rax], rbx
    mov rax, 12
    push rax
    lea rax, [rbp-136]
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    lea rax, [rbp-160]
    pop rbx
    mov [rax], rbx
    mov rax, 5
    push rax
    lea rax, [rbp-152]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-128]
    mov rax, [rax]
    push rax
    lea rax, [rbp-120]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-144]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-136]
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
    lea rax, [rbp-152]
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
    mov rax, 0
    push rax
    lea rax, [rbp-176]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    lea rax, [rbp-168]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    lea rax, [rbp-192]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    lea rax, [rbp-184]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    lea rax, [rbp-208]
    pop rbx
    mov [rax], rbx
    mov rax, 1
    push rax
    lea rax, [rbp-200]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    mov [rbp-216], rax
.L12:
    mov rax, [rbp-216]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L14
    lea rax, [rbp-168]
    mov rax, [rax]
    test rax, rax
    jz .L15
    lea rax, [rbp-176]
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-176]
    pop rbx
    mov [rax], rbx
.L15:
.L13:
    mov rax, [rbp-216]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-216]
    pop rbx
    mov [rax], rbx
    jmp .L12
.L14:
    mov rax, 0
    mov [rbp-224], rax
.L17:
    mov rax, [rbp-224]
    push rax
    mov rax, 15
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L19
    lea rax, [rbp-184]
    mov rax, [rax]
    test rax, rax
    jz .L20
    lea rax, [rbp-192]
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-192]
    pop rbx
    mov [rax], rbx
.L20:
.L18:
    mov rax, [rbp-224]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-224]
    pop rbx
    mov [rax], rbx
    jmp .L17
.L19:
    mov rax, 0
    mov [rbp-232], rax
.L22:
    mov rax, [rbp-232]
    push rax
    mov rax, 17
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L24
    lea rax, [rbp-200]
    mov rax, [rax]
    test rax, rax
    jz .L25
    lea rax, [rbp-208]
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-208]
    pop rbx
    mov [rax], rbx
.L25:
.L23:
    mov rax, [rbp-232]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-232]
    pop rbx
    mov [rax], rbx
    jmp .L22
.L24:
    lea rax, [rbp-176]
    mov rax, [rax]
    push rax
    lea rax, [rbp-192]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
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
    jz .L27
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L27:
    mov rax, 10
    push rax
    lea rax, [rbp-248]
    pop rbx
    mov [rax], rbx
    mov rax, 15
    push rax
    lea rax, [rbp-264]
    pop rbx
    mov [rax], rbx
    mov rax, 17
    push rax
    lea rax, [rbp-280]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-264]
    push rax
    lea rax, [rbp-240]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-280]
    push rax
    lea rax, [rbp-256]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    push rax
    lea rax, [rbp-272]
    pop rbx
    mov [rax], rbx
    mov rax, 0
    mov [rbp-288], rax
    lea rax, [rbp-248]
    mov [rbp-296], rax
.L29:
    mov rax, [rbp-296]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L30
    mov rax, [rbp-288]
    push rax
    mov rax, [rbp-296]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-288]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-296]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    lea rax, [rbp-296]
    pop rbx
    mov [rax], rbx
    jmp .L29
.L30:
    mov rax, [rbp-288]
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L31
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
.L31:
    lea rax, [rbp-376]
    mov [rbp-384], rax
    mov rax, 1
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 8
    pop rbx
    mov [rax], rbx
    mov rax, 3
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 16
    pop rbx
    mov [rax], rbx
    mov rax, 4
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 24
    pop rbx
    mov [rax], rbx
    mov rax, 5
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 32
    pop rbx
    mov [rax], rbx
    mov rax, 6
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 40
    pop rbx
    mov [rax], rbx
    mov rax, 7
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 48
    pop rbx
    mov [rax], rbx
    mov rax, 8
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 56
    pop rbx
    mov [rax], rbx
    mov rax, 4
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 64
    pop rbx
    mov [rax], rbx
    mov rax, 2
    push rax
    mov rax, [rbp-384]
    push rax
    pop rax
    add rax, 72
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-376]
    mov rax, [rax]
    push rax
    lea rax, [rbp-368]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-360]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-352]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-344]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-392], rax
    mov rax, [rbp-392]
    push rax
    lea rax, [rbp-336]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-328]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-320]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-312]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-304]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-392]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp-392]
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L33
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
.L33:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
