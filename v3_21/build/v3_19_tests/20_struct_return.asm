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
.Lssa_0_0:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov [rcx], rax
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov [rax], rbx
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
_20_struct_return__Point_sum:
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
_20_struct_return__Point_add:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_2_2:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov rdx, [rax]
    mov r8, [rbx]
    mov rdx, rdx
    add rdx, r8
    mov [rcx], rdx
    lea rcx, [rbp-16]
    mov rcx, rcx
    add rcx, 8
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    mov [rcx], rax
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
_20_struct_return__Point_scale:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_3_3:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov rdx, [rax]
    mov rdx, rdx
    imul rdx, rbx
    mov [rcx], rdx
    lea rcx, [rbp-16]
    mov rcx, rcx
    add rcx, 8
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    mov rax, rax
    imul rax, rbx
    mov [rcx], rax
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
_20_struct_return__Inner_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_4_4:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov [rcx], rax
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov [rax], rbx
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
_20_struct_return__get_value:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_5_5:
    lea rax, [rbp-16]
    mov rbx, 22
    mov rdx, 20
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Inner_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
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
.Lssa_6_6:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov [rcx], rax
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov [rax], rbx
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
_20_struct_return__get_vec:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_7_7:
    mov rax, rdi
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_7_8
    jmp .Lssa_7_10
.Lssa_7_8:
    mov rax, 20
    mov rcx, 10
    mov rdi, rax
    mov rsi, rcx
    call _20_struct_return__Vec2_new
    mov rbx, rdx
    mov rdx, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_7_9
.Lssa_7_9:
    mov rax, 7
    mov rcx, 5
    mov rdi, rax
    mov rsi, rcx
    call _20_struct_return__Vec2_new
    mov rbx, rdx
    mov rdx, rbx
    mov rsp, rbp
    pop rbp
    ret
.Lssa_7_10:
    cmp rax, 2
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_7_11
    jmp .Lssa_7_12
.Lssa_7_11:
    mov rax, 40
    mov rcx, 30
    mov rdi, rax
    mov rsi, rcx
    call _20_struct_return__Vec2_new
    mov rbx, rdx
    mov rdx, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_7_12
.Lssa_7_12:
    jmp .Lssa_7_9
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_20_struct_return__Color_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_8_13:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov [rcx], rax
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov [rax], rbx
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
_20_struct_return__compute:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_9_14:
    mov rax, rdi
    mov rbx, rsi
    mov rcx, [rax]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    add rax, rcx
    mov rcx, [rbx]
    mov rax, rax
    add rax, rcx
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
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
.Lssa_10_15:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov [rcx], rax
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov [rax], rbx
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
_20_struct_return__Pair_swap:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_11_16:
    mov rax, rdi
    mov rcx, [rax]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    mov rdi, rcx
    mov rsi, rax
    call _20_struct_return__Pair_new
    mov rbx, rdx
    mov rdx, rbx
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
.Lssa_12_17:
    mov rax, rdi
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_12_18
    jmp .Lssa_12_19
.Lssa_12_18:
    mov rbx, 1
    mov rcx, 0
    mov rdi, rbx
    mov rsi, rcx
    call _20_struct_return__Pair_new
    mov rbx, rax
    mov rax, rdx
    mov rdx, rax
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_12_19
.Lssa_12_19:
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_12_20
    jmp .Lssa_12_21
.Lssa_12_20:
    mov rbx, 1
    mov rcx, 1
    mov rdi, rbx
    mov rsi, rcx
    call _20_struct_return__Pair_new
    mov rbx, rax
    mov rax, rdx
    mov rdx, rax
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_12_21
.Lssa_12_21:
    lea rbx, [rbp-16]
    mov rax, rax
    sub rax, 1
    push rbx
    mov rdi, rax
    call _20_struct_return__fibonacci_pair
    mov rcx, rdx
    pop rbx
    mov [rbx], rax
    mov rax, rbx
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-16]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rdi, rax
    mov rsi, rbx
    call _20_struct_return__Pair_new
    mov rcx, rdx
    mov rdx, rcx
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
.Lssa_13_22:
    mov rax, rdi
    mov rbx, rsi
    lea rcx, [rbp-16]
    mov [rcx], rax
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov [rax], rbx
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
_20_struct_return__Data_transform:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_14_23:
    mov rax, rdi
    mov rbx, rsi
    push rax
    cmp rbx, 1
    sete al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_14_24
    jmp .Lssa_14_25
.Lssa_14_24:
    mov rcx, rax
    add rcx, 8
    mov rcx, [rcx]
    mov rcx, rcx
    add rcx, 1
    mov rdx, [rax]
    mov rdx, rdx
    add rdx, 1
    push rbx
    mov rdi, rcx
    mov rsi, rdx
    call _20_struct_return__Data_new
    mov rcx, rax
    mov rax, rdx
    pop rbx
    mov rdx, rax
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_14_25
.Lssa_14_25:
    push rax
    cmp rbx, 2
    sete al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_14_26
    jmp .Lssa_14_27
.Lssa_14_26:
    mov rcx, rax
    add rcx, 8
    mov rcx, [rcx]
    mov rcx, rcx
    imul rcx, 2
    mov rdx, [rax]
    mov rdx, rdx
    imul rdx, 2
    push rbx
    mov rdi, rcx
    mov rsi, rdx
    call _20_struct_return__Data_new
    mov rcx, rax
    mov rax, rdx
    pop rbx
    mov rdx, rax
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_14_27
.Lssa_14_27:
    push rax
    cmp rbx, 3
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_14_28
    jmp .Lssa_14_29
.Lssa_14_28:
    mov rbx, rax
    add rbx, 8
    mov rbx, [rbx]
    mov rcx, [rax]
    mov rbx, rbx
    sub rbx, rcx
    mov rcx, [rax]
    mov rdx, rax
    add rdx, 8
    mov rdx, [rdx]
    mov rcx, rcx
    sub rcx, rdx
    mov rdi, rbx
    mov rsi, rcx
    call _20_struct_return__Data_new
    mov rbx, rax
    mov rax, rdx
    mov rdx, rax
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_14_29
.Lssa_14_29:
    mov rcx, rax
    add rcx, 8
    mov rcx, [rcx]
    mov rax, [rax]
    mov rdi, rcx
    mov rsi, rax
    call _20_struct_return__Data_new
    mov rbx, rdx
    mov rdx, rbx
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
.Lssa_15_30:
    lea rax, [rbp-16]
    mov rbx, 20
    mov rdx, 10
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Point_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rdi, rax
    call _20_struct_return__Point_sum
    cmp rax, 30
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_31
    jmp .Lssa_15_32
.Lssa_15_31:
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_32
.Lssa_15_32:
    call _20_struct_return__get_value
    cmp rax, 42
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_33
    jmp .Lssa_15_34
.Lssa_15_33:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_34
.Lssa_15_34:
    lea rax, [rbp-32]
    mov rbx, 10
    mov rdx, 5
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Point_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-48]
    mov rbx, 7
    mov rdx, 3
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Point_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-64]
    lea rbx, [rbp-48]
    lea rdx, [rbp-32]
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Point_add
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-80]
    mov rbx, 2
    lea rdx, [rbp-64]
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Point_scale
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-80]
    mov rax, [rax]
    lea rbx, [rbp-80]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 50
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_35
    jmp .Lssa_15_36
.Lssa_15_35:
    mov rax, 3
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_36
.Lssa_15_36:
    lea rax, [rbp-96]
    mov rbx, 1
    push rax
    mov rdi, rbx
    call _20_struct_return__get_vec
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-112]
    mov rbx, 2
    push rax
    mov rdi, rbx
    call _20_struct_return__get_vec
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-128]
    mov rbx, 3
    push rax
    mov rdi, rbx
    call _20_struct_return__get_vec
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-96]
    mov rax, [rax]
    lea rbx, [rbp-96]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-112]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-112]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-128]
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    lea rbx, [rbp-128]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, rbx
    cmp rax, 112
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_37
    jmp .Lssa_15_38
.Lssa_15_37:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_38
.Lssa_15_38:
    lea rax, [rbp-152]
    mov rbx, 200
    mov rdx, 100
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Color_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-168]
    mov rbx, 75
    mov rdx, 50
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Color_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-152]
    lea rbx, [rbp-32]
    mov rdi, rax
    mov rsi, rbx
    call _20_struct_return__compute
    lea rbx, [rbp-168]
    lea rcx, [rbp-48]
    push rax
    mov rdi, rbx
    mov rsi, rcx
    call _20_struct_return__compute
    mov rbx, rax
    pop rax
    mov rax, rax
    add rax, rbx
    cmp rax, 450
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_39
    jmp .Lssa_15_40
.Lssa_15_39:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_40
.Lssa_15_40:
    lea rax, [rbp-192]
    mov rbx, 20
    mov rdx, 10
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Pair_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-208]
    lea rbx, [rbp-192]
    push rax
    mov rdi, rbx
    call _20_struct_return__Pair_swap
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-208]
    mov rax, [rax]
    cmp rax, 20
    setne al
    movzx rax, al
    mov rbx, 1
    cmp rax, 0
    jne .Lssa_15_42
    jmp .Lssa_15_41
.Lssa_15_41:
    lea rax, [rbp-208]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    cmp rax, 10
    setne al
    movzx rax, al
    cmp rax, 0
    setne al
    movzx rax, al
    mov rax, rax
    jmp .Lssa_15_42
.Lssa_15_42:
    cmp rax, 0
    jne .Lssa_15_43
    jmp .Lssa_15_44
.Lssa_15_43:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_44
.Lssa_15_44:
    lea rax, [rbp-224]
    mov rbx, 5
    push rax
    mov rdi, rbx
    call _20_struct_return__fibonacci_pair
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-224]
    mov rax, [rax]
    cmp rax, 5
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_45
    jmp .Lssa_15_46
.Lssa_15_45:
    mov rax, 7
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_46
.Lssa_15_46:
    lea rax, [rbp-240]
    mov rbx, 3
    mov rdx, 5
    push rax
    mov rdi, rbx
    mov rsi, rdx
    call _20_struct_return__Data_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    mov rax, 0
    mov rbx, 0
    mov r8, rax
    mov r8, rbx
    mov rdx, rax
    mov rax, rax
    jmp .Lssa_15_47
.Lssa_15_47:
    cmp r8, 10
    setl al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_48
    jmp .Lssa_15_50
.Lssa_15_48:
    push rdx
    mov rax, r8
    cqo
    push rcx
    mov rcx, 3
    idiv rcx
    mov rax, rdx
    pop rcx
    pop rdx
    mov rax, rax
    add rax, 1
    lea rbx, [rbp-240]
    push rax
    push rdx
    push r8
    mov rdi, rax
    mov rsi, rbx
    call _20_struct_return__Data_transform
    mov rbx, rax
    pop r8
    pop rdx
    pop rax
    lea rcx, [rbp-240]
    mov rcx, [rcx]
    add rcx, rdx
    lea rdx, [rbp-240]
    mov rdx, rdx
    add rdx, 8
    mov rdx, [rdx]
    mov rcx, rcx
    add rcx, rdx
    jmp .Lssa_15_49
.Lssa_15_49:
    mov rdx, r8
    add rdx, 1
    mov r8, rax
    mov r8, rdx
    mov rdx, rcx
    mov rax, rbx
    jmp .Lssa_15_47
.Lssa_15_50:
    cmp rdx, 0
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_15_51
    jmp .Lssa_15_52
.Lssa_15_51:
    mov rax, 8
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_15_52
.Lssa_15_52:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.Lssa_15_53:
    mov rax, rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
