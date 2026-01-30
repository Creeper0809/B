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
    lea rbx, [rbp-16]
    mov rbx, rbx
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
_20_struct_return__Point_sum:
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
    mov rax, [rbp-1032]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_2_2:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-16]
    mov rdx, [rbx]
    mov r8, [rax]
    mov rdx, rdx
    add rdx, r8
    mov [rcx], rdx
    lea rcx, [rbp-16]
    mov rcx, rcx
    add rcx, 8
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_3_3:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-16]
    mov rdx, [rbx]
    mov rdx, rdx
    imul rdx, rax
    mov [rcx], rdx
    lea rcx, [rbp-16]
    mov rcx, rcx
    add rcx, 8
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_4_4:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-16]
    mov [rcx], rbx
    lea rbx, [rbp-16]
    mov rbx, rbx
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
_20_struct_return__get_value:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_5_5:
    lea rax, [rbp-16]
    mov rbx, 20
    mov rdx, 22
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_6_6:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-16]
    mov [rcx], rbx
    lea rbx, [rbp-16]
    mov rbx, rbx
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
_20_struct_return__get_vec:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_7_7:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 1
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_7_8
    jmp .Lssa_7_10
.Lssa_7_8:
    mov rax, 10
    mov rcx, 20
    push rcx
    push rax
    pop rdi
    pop rsi
    call _20_struct_return__Vec2_new
    mov rbx, rdx
    mov rdx, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_7_9
.Lssa_7_9:
    mov rax, 5
    mov rcx, 7
    push rcx
    push rax
    pop rdi
    pop rsi
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
    mov rax, 30
    mov rcx, 40
    push rcx
    push rax
    pop rdi
    pop rsi
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_8_13:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-16]
    mov [rcx], rbx
    lea rbx, [rbp-16]
    mov rbx, rbx
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
_20_struct_return__compute:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_9_14:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    mov rcx, [rbx]
    mov rbx, rbx
    add rbx, 8
    mov rbx, [rbx]
    add rbx, rcx
    mov rcx, [rax]
    mov rbx, rbx
    add rbx, rcx
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
_20_struct_return__Pair_new:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_10_15:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-16]
    mov [rcx], rbx
    lea rbx, [rbp-16]
    mov rbx, rbx
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
_20_struct_return__Pair_swap:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_11_16:
    mov rax, [rbp-1032]
    mov rcx, rax
    add rcx, 8
    mov rcx, [rcx]
    mov rax, [rax]
    push rax
    push rcx
    pop rdi
    pop rsi
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_12_17:
    mov rax, [rbp-1032]
    push rax
    cmp rax, 0
    sete al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_12_18
    jmp .Lssa_12_19
.Lssa_12_18:
    mov rbx, 0
    mov rcx, 1
    push rcx
    push rbx
    pop rdi
    pop rsi
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
    push rcx
    push rbx
    pop rdi
    pop rsi
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
    push rax
    pop rdi
    call _20_struct_return__fibonacci_pair
    mov rcx, rdx
    pop rbx
    mov [rbx], rax
    mov rax, rbx
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    mov rax, rax
    add rax, 8
    mov rax, [rax]
    lea rbx, [rbp-16]
    mov rbx, [rbx]
    lea rdx, [rbp-16]
    mov rdx, rdx
    add rdx, 8
    mov rdx, [rdx]
    mov rbx, rbx
    add rbx, rdx
    push rbx
    push rax
    pop rdi
    pop rsi
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_13_22:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    lea rcx, [rbp-16]
    mov [rcx], rbx
    lea rbx, [rbp-16]
    mov rbx, rbx
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
_20_struct_return__Data_transform:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_14_23:
    mov rax, [rbp-1040]
    mov rbx, [rbp-1032]
    push rax
    cmp rax, 1
    sete al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_14_24
    jmp .Lssa_14_25
.Lssa_14_24:
    mov rcx, [rbx]
    mov rcx, rcx
    add rcx, 1
    mov rdx, rbx
    add rdx, 8
    mov rdx, [rdx]
    mov rdx, rdx
    add rdx, 1
    push rbx
    push rdx
    push rcx
    pop rdi
    pop rsi
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
    cmp rax, 2
    sete al
    movzx rcx, al
    pop rax
    cmp rcx, 0
    jne .Lssa_14_26
    jmp .Lssa_14_27
.Lssa_14_26:
    mov rcx, [rbx]
    mov rcx, rcx
    imul rcx, 2
    mov rdx, rbx
    add rdx, 8
    mov rdx, [rdx]
    mov rdx, rdx
    imul rdx, 2
    push rbx
    push rdx
    push rcx
    pop rdi
    pop rsi
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
    cmp rax, 3
    sete al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_14_28
    jmp .Lssa_14_29
.Lssa_14_28:
    mov rax, [rbx]
    mov rcx, rbx
    add rcx, 8
    mov rcx, [rcx]
    mov rax, rax
    sub rax, rcx
    mov rcx, rbx
    add rcx, 8
    mov rcx, [rcx]
    mov rdx, [rbx]
    mov rcx, rcx
    sub rcx, rdx
    push rcx
    push rax
    pop rdi
    pop rsi
    call _20_struct_return__Data_new
    mov rbx, rdx
    mov rdx, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_14_29
.Lssa_14_29:
    mov rax, [rbx]
    mov rcx, rbx
    add rcx, 8
    mov rcx, [rcx]
    push rcx
    push rax
    pop rdi
    pop rsi
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_15_30:
    lea rax, [rbp-16]
    mov rbx, 10
    mov rdx, 20
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _20_struct_return__Point_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-16]
    push rax
    pop rdi
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
    mov rbx, 5
    mov rdx, 10
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _20_struct_return__Point_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-48]
    mov rbx, 3
    mov rdx, 7
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _20_struct_return__Point_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-64]
    lea rbx, [rbp-32]
    lea rdx, [rbp-48]
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _20_struct_return__Point_add
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-80]
    lea rbx, [rbp-64]
    mov rdx, 2
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
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
    push rbx
    pop rdi
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
    push rbx
    pop rdi
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
    push rbx
    pop rdi
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
    mov rbx, 100
    mov rdx, 200
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _20_struct_return__Color_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-168]
    mov rbx, 50
    mov rdx, 75
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
    call _20_struct_return__Color_new
    mov rbx, rax
    mov rcx, rdx
    pop rax
    mov [rax], rbx
    mov rax, rax
    add rax, 8
    mov [rax], rcx
    lea rax, [rbp-32]
    lea rbx, [rbp-152]
    push rbx
    push rax
    pop rdi
    pop rsi
    call _20_struct_return__compute
    lea rbx, [rbp-48]
    lea rcx, [rbp-168]
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
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
    mov rbx, 10
    mov rdx, 20
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
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
    push rbx
    pop rdi
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
    push rbx
    pop rdi
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
    mov rbx, 5
    mov rdx, 3
    push rax
    push rdx
    push rbx
    pop rdi
    pop rsi
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
    mov rdx, rax
    mov r8, rbx
    mov rdx, rax
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
    lea rcx, [rbp-240]
    push rax
    push rbx
    push r8
    push rax
    push rcx
    pop rdi
    pop rsi
    call _20_struct_return__Data_transform
    mov rcx, rax
    pop r8
    pop rbx
    pop rax
    mov [rbx], rcx
    mov rbx, rbx
    add rbx, 8
    mov [rbx], rdx
    lea rbx, [rbp-240]
    mov rbx, [rbx]
    add rbx, rdx
    lea rcx, [rbp-240]
    mov rcx, rcx
    add rcx, 8
    mov rcx, [rcx]
    mov rbx, rbx
    add rbx, rcx
    jmp .Lssa_15_49
.Lssa_15_49:
    mov rcx, r8
    add rcx, 1
    mov rdx, rax
    mov r8, rcx
    mov rdx, rbx
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
