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
std_os__os_sys_brk:
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
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_os__os_sys_write:
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
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__io_get_output_fd:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_24_24:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__heap_alloc:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_25_25:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__println:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_30_30:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
std_io__print_u64:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_31_31:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
_23_sizeof__print_result:
    push rbp
    mov rbp, rsp
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_33_33:
    mov rax, [rbp-1048]
    mov rbx, [rbp-1040]
    mov rcx, [rbp-1032]
    push rax
    push rbx
    push rcx
    pop rdi
    pop rsi
    call std_io__println
    pop rax
    push rax
    pop rdi
    call std_io__print_u64
    lea rax, [rel _str0]
    mov rbx, 1
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
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
    sub rsp, 1088
    mov [rbp-1032], rdi
    mov [rbp-1040], rsi
    mov [rbp-1048], rdx
    mov [rbp-1056], rcx
    mov [rbp-1064], r8
    mov [rbp-1072], r9
.Lssa_34_34:
    lea rax, [rel _str1]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 1
    lea rbx, [rel _str2]
    mov rcx, 14
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    mov rax, 2
    lea rbx, [rel _str3]
    mov rcx, 15
    push rax
    push rax
    push rcx
    push rbx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rax
    mov rbx, 4
    lea rcx, [rel _str4]
    mov rdx, 15
    push rax
    push rbx
    push rbx
    push rdx
    push rcx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rbx
    pop rax
    mov rcx, 8
    lea rdx, [rel _str5]
    mov r8, 15
    push rax
    push rbx
    push rcx
    push rcx
    push r8
    push rdx
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rcx
    pop rbx
    pop rax
    mov rdx, 8
    lea r8, [rel _str6]
    mov r9, 15
    push rax
    push rbx
    push rcx
    push rdx
    push rdx
    push r9
    push r8
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea r8, [rel _str7]
    mov r9, 24
    push rax
    push rbx
    push rcx
    push rdx
    push r9
    push r8
    pop rdi
    pop rsi
    call std_io__println
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r8, 8
    lea r9, [rel _str8]
    mov r10, 15
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r8
    push r10
    push r9
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r9, 8
    lea r10, [rel _str9]
    mov r11, 16
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r9
    push r11
    push r10
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r10, 8
    lea r11, [rel _str10]
    mov rax, 17
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push rax
    push r11
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r10
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea r11, [rel _str11]
    mov rax, 23
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push r11
    pop rdi
    pop rsi
    call std_io__println
    pop r10
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov r11, 16
    lea rax, [rel _str12]
    mov rax, 17
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r11
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 32
    lea rax, [rel _str13]
    mov rax, 16
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 2
    lea rax, [rel _str14]
    mov rax, 23
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea rax, [rel _str15]
    mov rax, 28
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 8
    lea rax, [rel _str16]
    mov rax, 18
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 8
    lea rax, [rel _str17]
    mov rax, 17
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    push rax
    pop rdi
    pop rsi
    pop rdx
    call _23_sizeof__print_result
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    lea rax, [rel _str18]
    mov rax, 21
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 1
    mov rax, 0
    cmp rax, 0
    jne .Lssa_34_35
    jmp .Lssa_34_36
.Lssa_34_35:
    lea rax, [rel _str19]
    mov rax, 32
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rax, 0
    mov rax, rax
    jmp .Lssa_34_36
.Lssa_34_36:
    cmp rax, 2
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_37
    jmp .Lssa_34_38
.Lssa_34_37:
    lea rax, [rel _str20]
    mov rax, 33
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push rax
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    mov rax, 0
    mov rax, rax
    jmp .Lssa_34_38
.Lssa_34_38:
    cmp rbx, 4
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_39
    jmp .Lssa_34_40
.Lssa_34_39:
    lea rax, [rel _str21]
    mov rbx, 33
    push rcx
    push rdx
    push r8
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_40
.Lssa_34_40:
    cmp rcx, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_41
    jmp .Lssa_34_42
.Lssa_34_41:
    lea rax, [rel _str22]
    mov rbx, 33
    push rdx
    push r8
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_42
.Lssa_34_42:
    cmp rdx, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_43
    jmp .Lssa_34_44
.Lssa_34_43:
    lea rax, [rel _str23]
    mov rbx, 33
    push r8
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    pop r8
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_44
.Lssa_34_44:
    cmp r8, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_45
    jmp .Lssa_34_46
.Lssa_34_45:
    lea rax, [rel _str24]
    mov rbx, 34
    push r9
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    pop r9
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_46
.Lssa_34_46:
    cmp r9, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_47
    jmp .Lssa_34_48
.Lssa_34_47:
    lea rax, [rel _str25]
    mov rbx, 35
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r10
    pop r11
    pop r10
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_48
.Lssa_34_48:
    cmp r10, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_49
    jmp .Lssa_34_50
.Lssa_34_49:
    lea rax, [rel _str26]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    pop r11
    pop r11
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_50
.Lssa_34_50:
    cmp r11, 16
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_51
    jmp .Lssa_34_52
.Lssa_34_51:
    lea rax, [rel _str27]
    mov rbx, 37
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_52
.Lssa_34_52:
    cmp rax, 32
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_53
    jmp .Lssa_34_54
.Lssa_34_53:
    lea rax, [rel _str28]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_54
.Lssa_34_54:
    cmp rax, 2
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_55
    jmp .Lssa_34_56
.Lssa_34_55:
    lea rax, [rel _str29]
    mov rbx, 42
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_56
.Lssa_34_56:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_57
    jmp .Lssa_34_58
.Lssa_34_57:
    lea rax, [rel _str30]
    mov rbx, 37
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    mov rbx, rax
    jmp .Lssa_34_58
.Lssa_34_58:
    cmp rax, 8
    setne al
    movzx rax, al
    cmp rax, 0
    jne .Lssa_34_59
    jmp .Lssa_34_60
.Lssa_34_59:
    lea rax, [rel _str31]
    mov rbx, 36
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    mov rax, 0
    jmp .Lssa_34_60
.Lssa_34_60:
    cmp rax, 0
    jne .Lssa_34_61
    jmp .Lssa_34_63
.Lssa_34_61:
    lea rax, [rel _str32]
    mov rbx, 27
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_62
.Lssa_34_62:
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
.Lssa_34_63:
    lea rax, [rel _str33]
    mov rbx, 28
    push rbx
    push rax
    pop rdi
    pop rsi
    call std_io__println
    jmp .Lssa_34_62
.Lssa_34_64:
    mov rax, rax
.Lssa_34_65:
    mov rax, rax
.Lssa_34_66:
    mov rbx, rax
.Lssa_34_67:
.Lssa_34_68:
.Lssa_34_69:
.Lssa_34_70:
.Lssa_34_71:
.Lssa_34_72:
.Lssa_34_73:
.Lssa_34_74:
.Lssa_34_75:
.Lssa_34_76:
    mov rax, rbx
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

section .data
_str0: db 10,0
_str1: db 61,61,61,32,80,114,105,109,105,116,105,118,101,32,84,121,112,101,115,32,61,61,61,10,0
_str2: db 115,105,122,101,111,102,40,117,56,41,32,61,32,0
_str3: db 115,105,122,101,111,102,40,117,49,54,41,32,61,32,0
_str4: db 115,105,122,101,111,102,40,117,51,50,41,32,61,32,0
_str5: db 115,105,122,101,111,102,40,117,54,52,41,32,61,32,0
_str6: db 115,105,122,101,111,102,40,105,54,52,41,32,61,32,0
_str7: db 10,61,61,61,32,80,111,105,110,116,101,114,32,84,121,112,101,115,32,61,61,61,10,0
_str8: db 115,105,122,101,111,102,40,42,117,56,41,32,61,32,0
_str9: db 115,105,122,101,111,102,40,42,117,54,52,41,32,61,32,0
_str10: db 115,105,122,101,111,102,40,42,42,117,54,52,41,32,61,32,0
_str11: db 10,61,61,61,32,83,116,114,117,99,116,32,84,121,112,101,115,32,61,61,61,10,0
_str12: db 115,105,122,101,111,102,40,80,111,105,110,116,41,32,61,32,0
_str13: db 115,105,122,101,111,102,40,82,101,99,116,41,32,61,32,0
_str14: db 115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,61,32,0
_str15: db 10,61,61,61,32,80,111,105,110,116,101,114,32,116,111,32,83,116,114,117,99,116,32,61,61,61,10,0
_str16: db 115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,61,32,0
_str17: db 115,105,122,101,111,102,40,42,82,101,99,116,41,32,61,32,0
_str18: db 10,61,61,61,32,86,97,108,105,100,97,116,105,111,110,32,61,61,61,10,0
_str19: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,56,41,32,115,104,111,117,108,100,32,98,101,32,49,10,0
_str20: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,49,54,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str21: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,51,50,41,32,115,104,111,117,108,100,32,98,101,32,52,10,0
_str22: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str23: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,105,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str24: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,56,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str25: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str26: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,42,117,54,52,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str27: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,49,54,10,0
_str28: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,51,50,10,0
_str29: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,83,109,97,108,108,83,116,114,117,99,116,41,32,115,104,111,117,108,100,32,98,101,32,50,10,0
_str30: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,80,111,105,110,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str31: db 69,82,82,79,82,58,32,115,105,122,101,111,102,40,42,82,101,99,116,41,32,115,104,111,117,108,100,32,98,101,32,56,10,0
_str32: db 65,108,108,32,115,105,122,101,111,102,32,116,101,115,116,115,32,80,65,83,83,69,68,33,10,0
_str33: db 83,111,109,101,32,115,105,122,101,111,102,32,116,101,115,116,115,32,70,65,73,76,69,68,33,10,0

section .bss
_gvar_std_os__g_syscall_arg0: resq 1
_gvar_std_os__g_syscall_arg1: resq 1
_gvar_std_os__g_syscall_arg2: resq 1
_gvar_std_os__g_syscall_arg3: resq 1
_gvar_std_os__g_syscall_ret: resq 1
_gvar_std_io__heap_inited: resq 1
_gvar_std_io__heap_brk: resq 1
_gvar_std_io__g_out_fd: resq 1
