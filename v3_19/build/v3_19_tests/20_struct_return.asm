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
_20_struct_return__Point_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__Point_sum:
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
_20_struct_return__Point_add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__Point_scale:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+24]
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__Inner_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__get_value:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, 22
    push rax
    mov rax, 20
    push rax
    call _20_struct_return__Inner_new
    add rsp, 16
    mov [rbp-16], rax
    mov [rbp-8], rdx
    lea rax, [rbp-16]
    mov rax, [rax]
    push rax
    lea rax, [rbp-8]
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
_20_struct_return__Vec2_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__get_vec:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L0
    mov rax, 20
    push rax
    mov rax, 10
    push rax
    call _20_struct_return__Vec2_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
    jmp .L1
.L0:
    mov rax, [rbp+16]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L2
    mov rax, 40
    push rax
    mov rax, 30
    push rax
    call _20_struct_return__Vec2_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
.L2:
.L1:
    mov rax, 7
    push rax
    mov rax, 5
    push rax
    call _20_struct_return__Vec2_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__Color_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__compute:
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
    push rax
    mov rax, [rbp+24]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+24]
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
_20_struct_return__Pair_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__Pair_swap:
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
    push rax
    call _20_struct_return__Pair_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__fibonacci_pair:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
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
    mov rax, 1
    push rax
    mov rax, 0
    push rax
    call _20_struct_return__Pair_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
.L4:
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, 1
    push rax
    mov rax, 1
    push rax
    call _20_struct_return__Pair_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
.L6:
    mov rax, [rbp+16]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    call _20_struct_return__fibonacci_pair
    add rsp, 8
    mov [rbp-16], rax
    mov [rbp-8], rdx
    lea rax, [rbp-16]
    mov rax, [rax]
    push rax
    lea rax, [rbp-8]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-8]
    mov rax, [rax]
    push rax
    call _20_struct_return__Pair_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__Data_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+16]
    push rax
    lea rax, [rbp-16]
    pop rbx
    mov [rax], rbx
    mov rax, [rbp+24]
    push rax
    lea rax, [rbp-8]
    pop rbx
    mov [rax], rbx
    lea rax, [rbp-16]
    mov r10, rax
    mov rax, [r10]
    mov rdx, [r10+8]
    mov rsp, rbp
    pop rbp
    ret
   xor eax, eax
    mov rsp, rbp
    pop rbp
   ret
_20_struct_return__Data_transform:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
    mov rax, [rbp+24]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L8
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    call _20_struct_return__Data_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
.L8:
    mov rax, [rbp+24]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L10
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    push rax
    call _20_struct_return__Data_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
.L10:
    mov rax, [rbp+24]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L12
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
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
    sub rax, rbx
    push rax
    call _20_struct_return__Data_new
    add rsp, 16
    mov rsp, rbp
    pop rbp
    ret
.L12:
    mov rax, [rbp+16]
    push rax
    pop rax
    add rax, 8
    mov rax, [rax]
    push rax
    mov rax, [rbp+16]
    push rax
    pop rax
    mov rax, [rax]
    push rax
    call _20_struct_return__Data_new
    add rsp, 16
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
    mov rax, 20
    push rax
    mov rax, 10
    push rax
    call _20_struct_return__Point_new
    add rsp, 16
    mov [rbp-16], rax
    mov [rbp-8], rdx
    lea rax, [rbp-16]
    push rax
    call _20_struct_return__Point_sum
    add rsp, 8
    push rax
    mov rax, 30
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L14
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
.L14:
    call _20_struct_return__get_value
    push rax
    mov rax, 42
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L16
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
.L16:
    mov rax, 10
    push rax
    mov rax, 5
    push rax
    call _20_struct_return__Point_new
    add rsp, 16
    mov [rbp-32], rax
    mov [rbp-24], rdx
    mov rax, 7
    push rax
    mov rax, 3
    push rax
    call _20_struct_return__Point_new
    add rsp, 16
    mov [rbp-48], rax
    mov [rbp-40], rdx
    lea rax, [rbp-48]
    push rax
    lea rax, [rbp-32]
    push rax
    call _20_struct_return__Point_add
    add rsp, 16
    mov [rbp-64], rax
    mov [rbp-56], rdx
    mov rax, 2
    push rax
    lea rax, [rbp-64]
    push rax
    call _20_struct_return__Point_scale
    add rsp, 16
    mov [rbp-80], rax
    mov [rbp-72], rdx
    lea rax, [rbp-80]
    mov rax, [rax]
    push rax
    lea rax, [rbp-72]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    mov rax, 50
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L18
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
.L18:
    mov rax, 1
    push rax
    call _20_struct_return__get_vec
    add rsp, 8
    mov [rbp-96], rax
    mov [rbp-88], rdx
    mov rax, 2
    push rax
    call _20_struct_return__get_vec
    add rsp, 8
    mov [rbp-112], rax
    mov [rbp-104], rdx
    mov rax, 3
    push rax
    call _20_struct_return__get_vec
    add rsp, 8
    mov [rbp-128], rax
    mov [rbp-120], rdx
    lea rax, [rbp-96]
    mov rax, [rax]
    push rax
    lea rax, [rbp-88]
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
    lea rax, [rbp-104]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-128]
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
    mov [rbp-136], rax
    mov rax, [rbp-136]
    push rax
    mov rax, 112
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L20
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
.L20:
    mov rax, 200
    push rax
    mov rax, 100
    push rax
    call _20_struct_return__Color_new
    add rsp, 16
    mov [rbp-152], rax
    mov [rbp-144], rdx
    mov rax, 75
    push rax
    mov rax, 50
    push rax
    call _20_struct_return__Color_new
    add rsp, 16
    mov [rbp-168], rax
    mov [rbp-160], rdx
    lea rax, [rbp-152]
    push rax
    lea rax, [rbp-32]
    push rax
    call _20_struct_return__compute
    add rsp, 16
    push rax
    lea rax, [rbp-168]
    push rax
    lea rax, [rbp-48]
    push rax
    call _20_struct_return__compute
    add rsp, 16
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-176], rax
    mov rax, [rbp-176]
    push rax
    mov rax, 450
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L22
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
.L22:
    mov rax, 20
    push rax
    mov rax, 10
    push rax
    call _20_struct_return__Pair_new
    add rsp, 16
    mov [rbp-192], rax
    mov [rbp-184], rdx
    lea rax, [rbp-192]
    push rax
    call _20_struct_return__Pair_swap
    add rsp, 8
    mov [rbp-208], rax
    mov [rbp-200], rdx
    lea rax, [rbp-208]
    mov rax, [rax]
    push rax
    mov rax, 20
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jnz .L26
    lea rax, [rbp-200]
    mov rax, [rax]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    setne al
    movzx rax, al
    jmp .L27
.L26:
    mov eax, 1
.L27:
    test rax, rax
    jz .L24
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
.L24:
    mov rax, 5
    push rax
    call _20_struct_return__fibonacci_pair
    add rsp, 8
    mov [rbp-224], rax
    mov [rbp-216], rdx
    lea rax, [rbp-224]
    mov rax, [rax]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setne al
    movzx rax, al
    test rax, rax
    jz .L28
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
.L28:
    mov rax, 3
    push rax
    mov rax, 5
    push rax
    call _20_struct_return__Data_new
    add rsp, 16
    mov [rbp-240], rax
    mov [rbp-232], rdx
    mov rax, 0
    mov [rbp-248], rax
    mov rax, 0
    mov [rbp-256], rax
.L30:
    mov rax, [rbp-256]
    push rax
    mov rax, 10
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    test rax, rax
    jz .L32
    mov rax, [rbp-256]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    xor rdx, rdx
    div rbx
    mov rax, rdx
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-264], rax
    mov rax, [rbp-264]
    push rax
    lea rax, [rbp-240]
    push rax
    call _20_struct_return__Data_transform
    add rsp, 16
    push rax
    lea rax, [rbp-240]
    pop rbx
    mov r8, rax  ; save dest addr
    pop rbx  ; discard rvalue
    mov rcx, [rax]
    mov [r8], rcx
    mov rcx, [rax+8]
    mov [r8+8], rcx
    mov rax, [rbp-248]
    push rax
    lea rax, [rbp-240]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-232]
    mov rax, [rax]
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-248]
    pop rbx
    mov [rax], rbx
.L31:
    mov rax, [rbp-256]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    push rax
    lea rax, [rbp-256]
    pop rbx
    mov [rax], rbx
    jmp .L30
.L32:
    mov rax, [rbp-248]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L33
    mov rax, 8
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
