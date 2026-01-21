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
std_str__str_eq:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_0_0:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_str__str_copy:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_1_1:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_str__str_len:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_2_2:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_str__str_concat:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_3_3:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_str__str_concat3:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_4_4:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_brk:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_5_5:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_write:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_6_6:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_read:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_7_7:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_open:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_8_8:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_close:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_9_9:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_fstat:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_10_10:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_fork:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_11_11:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_execve:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_12_12:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_wait4:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_13_13:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_exit:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_14_14:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_dup2:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_15_15:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_execute:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_16_16:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_brk:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_17_17:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_write:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_18_18:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_read:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_19_19:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_open:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_20_20:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_close:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_21_21:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__sys_fstat:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_22_22:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__io_set_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_23_23:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__io_get_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_24_24:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__heap_alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_25_25:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__emitln:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_26_26:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__emit:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_27_27:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_28_28:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_29_29:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__println:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_30_30:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_31_31:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_i64:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_32_32:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_65_ssa_tagged_packed_bits__test_tagged_ptr_basic:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_33_33:
    lea rax, [rbp-8]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    mov rbx, 4660
    mov rcx, 281474976710655
    mov rax, rax
    and rax, rcx
    mov rcx, 48
    push rcx
    mov rbx, rbx
    mov rcx, rcx
    shl rbx, cl
    pop rcx
    mov rax, rax
    or rax, rbx
    mov rbx, 281474976710655
    and rbx, rax
    mov rcx, 55
    mov byte [rbx], cl
    mov rbx, 281474976710655
    and rbx, rax
    mov rcx, 0
    mov rbx, rbx
    add rbx, rcx
    mov rcx, 66
    mov byte [rbx], cl
    mov rbx, 281474976710655
    and rbx, rax
    movzx rbx, byte [rbx]
    mov rcx, 66
    push rax
    cmp rbx, rcx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_33_34
    jmp .Lssa_33_35
.Lssa_33_34:
    mov rbx, 1
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_35
.Lssa_33_35:
    mov rbx, 281474976710655
    mov rax, rax
    and rax, rbx
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    movzx rax, byte [rax]
    mov rbx, 66
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_33_36
    jmp .Lssa_33_37
.Lssa_33_36:
    mov rax, 2
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_33_37
.Lssa_33_37:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_65_ssa_tagged_packed_bits__test_tagged_layout_packed_struct:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_34_38:
    lea rax, [rbp-8]
    mov rbx, 0
    mov rax, rax
    add rax, rbx
    mov rbx, 281474976710655
    mov rax, rax
    and rax, rbx
    mov rbx, 1
    mov rcx, 65535
    mov rbx, rbx
    and rbx, rcx
    mov rcx, 48
    push rcx
    mov rbx, rbx
    mov rcx, rcx
    shl rbx, cl
    pop rcx
    mov rcx, 65535
    mov rdx, 48
    push rax
    mov rax, rcx
    mov rcx, rdx
    shl rax, cl
    mov rcx, rax
    pop rax
    mov rdx, 0
    mov r8, 1
    mov rdx, rdx
    sub rdx, r8
    mov rcx, rcx
    xor rcx, rdx
    mov rax, rax
    and rax, rcx
    mov rax, rax
    or rax, rbx
    mov rbx, 281474976710655
    and rbx, rax
    mov rcx, 77
    mov byte [rbx], cl
    mov rbx, 48
    push rcx
    mov rcx, rbx
    mov rbx, rax
    shr rbx, cl
    pop rcx
    mov rcx, 65535
    mov rbx, rbx
    and rbx, rcx
    mov rcx, 1
    push rax
    cmp rbx, rcx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_34_39
    jmp .Lssa_34_40
.Lssa_34_39:
    mov rbx, 3
    mov rax, rbx
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_34_40
.Lssa_34_40:
    mov rbx, 281474976710655
    mov rax, rax
    and rax, rbx
    movzx rax, byte [rax]
    mov rbx, 77
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_41
    jmp .Lssa_34_42
.Lssa_34_41:
    mov rax, 4
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_34_42
.Lssa_34_42:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_65_ssa_tagged_packed_bits__test_packed_bitfield_access:
    push rbp
    mov rbp, rsp
    sub rsp, 1024
.Lssa_35_43:
    lea rax, [rbp-2]
    movzx rbx, word [rax]
    mov rcx, 3
    mov rdx, 15
    mov rcx, rcx
    and rcx, rdx
    mov rdx, 15
    mov r8, 0
    mov r9, 1
    mov r8, r8
    sub r8, r9
    mov rdx, rdx
    xor rdx, r8
    mov rbx, rbx
    and rbx, rdx
    mov rbx, rbx
    or rbx, rcx
    mov word [rax], bx
    lea rax, [rbp-2]
    movzx rbx, word [rax]
    mov rcx, 4095
    mov rdx, 4095
    mov rcx, rcx
    and rcx, rdx
    mov rdx, 4
    push rax
    mov rax, rcx
    mov rcx, rdx
    shl rax, cl
    mov rcx, rax
    pop rax
    mov rdx, 4095
    mov r8, 4
    push rcx
    mov rdx, rdx
    mov rcx, r8
    shl rdx, cl
    pop rcx
    mov r8, 0
    mov r9, 1
    mov r8, r8
    sub r8, r9
    mov rdx, rdx
    xor rdx, r8
    mov rbx, rbx
    and rbx, rdx
    mov rbx, rbx
    or rbx, rcx
    mov word [rax], bx
    lea rax, [rbp-2]
    movzx rax, word [rax]
    mov rbx, 15
    mov rax, rax
    and rax, rbx
    mov rbx, 3
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_35_44
    jmp .Lssa_35_45
.Lssa_35_44:
    mov rax, 5
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_35_45
.Lssa_35_45:
    lea rax, [rbp-2]
    movzx rax, word [rax]
    mov rbx, 4
    push rcx
    mov rax, rax
    mov rcx, rbx
    shr rax, cl
    pop rcx
    mov rbx, 4095
    mov rax, rax
    and rax, rbx
    mov rbx, 4095
    cmp rax, rbx
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_35_46
    jmp .Lssa_35_47
.Lssa_35_46:
    mov rax, 6
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_35_47
.Lssa_35_47:
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
    sub rsp, 1024
.Lssa_36_48:
    mov rax, 0
    lea rax, [rbp-8]
    call _65_ssa_tagged_packed_bits__test_tagged_ptr_basic
    mov rbx, 0
    push rax
    cmp rax, rbx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_36_49
    jmp .Lssa_36_50
.Lssa_36_49:
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_36_50
.Lssa_36_50:
    lea rax, [rbp-8]
    call _65_ssa_tagged_packed_bits__test_tagged_layout_packed_struct
    mov rbx, 0
    push rax
    cmp rax, rbx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_36_51
    jmp .Lssa_36_52
.Lssa_36_51:
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_36_52
.Lssa_36_52:
    lea rax, [rbp-8]
    call _65_ssa_tagged_packed_bits__test_packed_bitfield_access
    mov rbx, 0
    push rax
    cmp rax, rbx
    setne al
    movzx rbx, al
    pop rax
    cmp rbx, 0
    jne .Lssa_36_53
    jmp .Lssa_36_54
.Lssa_36_53:
    mov rsp, rbp
    pop rbp
    ret
    jmp .Lssa_36_54
.Lssa_36_54:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .bss
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
