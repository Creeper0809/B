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
.Lssa_0_0:
    mov rax, rdi
    mov rbx, rsi
    mov rcx, rdx
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_16_struct_basic__get_sum:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    mov rax, rdi
    mov rbx, [rax]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
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
.Lssa_2_2:
    mov rax, rdi
    mov rax, rsi
    lea rax, [rbp-16]
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov rbx, 32
    mov [rax], rbx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 42
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
    lea rax, [rbp-16]
    mov rbx, 20
    mov [rax], rbx
    mov rbx, rax
    add rbx, 8
    mov rcx, 22
    mov [rbx], rcx
    mov rbx, [rax]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    add rax, rbx
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_5
    jmp .Lssa_2_6
.Lssa_2_5:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_6
.Lssa_2_6:
    lea rax, [rbp-48]
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-48]
    mov rax, rax
    add rax, 8
    mov rbx, 15
    mov [rax], rbx
    lea rax, [rbp-48]
    mov rax, rax
    add rax, 16
    mov rbx, 17
    mov [rax], rbx
    lea rax, [rbp-48]
    mov rax, [rax]
    lea rbx, [rbp-48]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-48]
    mov rbx, rbx
    add rbx, 16
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_7
    jmp .Lssa_2_8
.Lssa_2_7:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_8
.Lssa_2_8:
    lea rax, [rbp-64]
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-64]
    mov rax, rax
    add rax, 8
    mov rbx, 12
    mov [rax], rbx
    lea rax, [rbp-88]
    mov rbx, 5
    mov [rax], rbx
    lea rax, [rbp-88]
    mov rax, rax
    add rax, 8
    mov rbx, 7
    mov [rax], rbx
    lea rax, [rbp-88]
    mov rax, rax
    add rax, 16
    mov rbx, 8
    mov [rax], rbx
    lea rax, [rbp-64]
    mov rax, [rax]
    lea rbx, [rbp-64]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-88]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-88]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-88]
    mov rbx, rbx
    add rbx, 16
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_9
    jmp .Lssa_2_10
.Lssa_2_9:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_10
.Lssa_2_10:
    lea rax, [rbp-104]
    mov rbx, 22
    mov rcx, 20
    push rax
    mov rdi, rbx
    mov rsi, rcx
    mov rdx, rax
    call _16_struct_basic__set_point
    pop rax
    mov rdi, rax
    call _16_struct_basic__get_sum
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_11
    jmp .Lssa_2_12
.Lssa_2_11:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_12
.Lssa_2_12:
    lea rax, [rbp-128]
    mov rbx, 5
    mov [rax], rbx
    lea rax, [rbp-128]
    mov rax, rax
    add rax, 8
    mov rbx, 7
    mov [rax], rbx
    lea rax, [rbp-144]
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-144]
    mov rax, rax
    add rax, 8
    mov rbx, 12
    mov [rax], rbx
    lea rax, [rbp-160]
    mov rbx, 3
    mov [rax], rbx
    lea rax, [rbp-160]
    mov rax, rax
    add rax, 8
    mov rbx, 5
    mov [rax], rbx
    lea rax, [rbp-128]
    mov rax, [rax]
    lea rbx, [rbp-128]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-144]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-144]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-160]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-160]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_13
    jmp .Lssa_2_14
.Lssa_2_13:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_14
.Lssa_2_14:
    lea rax, [rbp-176]
    mov rbx, 0
    mov [rax], rbx
    lea rax, [rbp-176]
    mov rax, rax
    add rax, 8
    mov rbx, 1
    mov [rax], rbx
    lea rax, [rbp-192]
    mov rbx, 0
    mov [rax], rbx
    lea rax, [rbp-192]
    mov rax, rax
    add rax, 8
    mov rbx, 1
    mov [rax], rbx
    lea rax, [rbp-208]
    mov rbx, 0
    mov [rax], rbx
    lea rax, [rbp-208]
    mov rax, rax
    add rax, 8
    mov rbx, 1
    mov [rax], rbx
    mov rax, 0
    mov rcx, rax
    jmp .Lssa_2_15
.Lssa_2_15:
    cmp rcx, 10
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_16
    jmp .Lssa_2_18
.Lssa_2_16:
    lea rax, [rbp-176]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    cmp rax, 0
    jne .Lssa_2_19
    jmp .Lssa_2_20
.Lssa_2_17:
    mov rax, rcx
    add rax, 1
    mov rcx, rax
    jmp .Lssa_2_15
.Lssa_2_18:
    mov rax, 0
    mov rcx, rax
    jmp .Lssa_2_21
.Lssa_2_19:
    lea rax, [rbp-176]
    lea rbx, [rbp-176]
    mov rbx, [rbx]
    mov rbx, rbx
    add rbx, 1
    mov [rax], rbx
    jmp .Lssa_2_20
.Lssa_2_20:
    jmp .Lssa_2_17
.Lssa_2_21:
    cmp rcx, 15
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_22
    jmp .Lssa_2_24
.Lssa_2_22:
    lea rax, [rbp-192]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    cmp rax, 0
    jne .Lssa_2_25
    jmp .Lssa_2_26
.Lssa_2_23:
    mov rax, rcx
    add rax, 1
    mov rcx, rax
    jmp .Lssa_2_21
.Lssa_2_24:
    mov rax, 0
    mov rcx, rax
    jmp .Lssa_2_27
.Lssa_2_25:
    lea rax, [rbp-192]
    lea rbx, [rbp-192]
    mov rbx, [rbx]
    mov rbx, rbx
    add rbx, 1
    mov [rax], rbx
    jmp .Lssa_2_26
.Lssa_2_26:
    jmp .Lssa_2_23
.Lssa_2_27:
    cmp rcx, 17
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_28
    jmp .Lssa_2_30
.Lssa_2_28:
    lea rax, [rbp-208]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    cmp rax, 0
    jne .Lssa_2_31
    jmp .Lssa_2_32
.Lssa_2_29:
    mov rax, rcx
    add rax, 1
    mov rcx, rax
    jmp .Lssa_2_27
.Lssa_2_30:
    lea rax, [rbp-176]
    mov rax, [rax]
    lea rbx, [rbp-192]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-208]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_33
    jmp .Lssa_2_34
.Lssa_2_31:
    lea rax, [rbp-208]
    lea rbx, [rbp-208]
    mov rbx, [rbx]
    mov rbx, rbx
    add rbx, 1
    mov [rax], rbx
    jmp .Lssa_2_32
.Lssa_2_32:
    jmp .Lssa_2_29
.Lssa_2_33:
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_34
.Lssa_2_34:
    lea rax, [rbp-248]
    mov rbx, 10
    mov [rax], rbx
    lea rax, [rbp-264]
    mov rbx, 15
    mov [rax], rbx
    lea rax, [rbp-280]
    mov rbx, 17
    mov [rax], rbx
    lea rax, [rbp-248]
    mov rax, rax
    add rax, 8
    lea rbx, [rbp-264]
    mov [rax], rbx
    lea rax, [rbp-264]
    mov rax, rax
    add rax, 8
    lea rbx, [rbp-280]
    mov [rax], rbx
    lea rax, [rbp-280]
    mov rax, rax
    add rax, 8
    mov rbx, 0
    mov [rax], rbx
    mov rax, 0
    lea rbx, [rbp-248]
    mov rcx, rbx
    mov rbx, rax
    jmp .Lssa_2_35
.Lssa_2_35:
    cmp rcx, 0
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_36
    jmp .Lssa_2_37
.Lssa_2_36:
    mov rax, [rcx]
    add rax, rbx
    mov rbx, rcx
    add rbx, 8
    mov rbx, [rbx]
    mov rcx, rbx
    mov rbx, rax
    jmp .Lssa_2_35
.Lssa_2_37:
    cmp rbx, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_38
    jmp .Lssa_2_39
.Lssa_2_38:
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_39
.Lssa_2_39:
    lea rax, [rbp-376]
    mov rbx, 1
    mov [rax], rbx
    mov rbx, rax
    add rbx, 8
    mov rcx, 2
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 16
    mov rcx, 3
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 24
    mov rcx, 4
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 32
    mov rcx, 5
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 40
    mov rcx, 6
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 48
    mov rcx, 7
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 56
    mov rcx, 8
    mov [rbx], rcx
    mov rbx, rax
    add rbx, 64
    mov rcx, 4
    mov [rbx], rcx
    mov rax, rax
    add rax, 72
    mov rbx, 2
    mov [rax], rbx
    lea rax, [rbp-376]
    mov rax, [rax]
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 16
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 24
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 32
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 40
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 48
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 56
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 64
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-376]
    mov rbx, rbx
    add rbx, 72
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_2_40
    jmp .Lssa_2_41
.Lssa_2_40:
    mov rax, 9
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_2_41
.Lssa_2_41:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
