// v1 std (stage 2): file IO helpers
// Roadmap: docs/roadmap.md (stage 3: source loading)
// Depends on: std0 (sys_open/sys_read/sys_close/sys_fstat/panic), std1 (heap_alloc), Slice
// Planned:
// - read_file(path_cstr) -> (rax=ptr, rdx=len)

func read_file(path) {
	// Read entire file into memory.
	// Convention: input path pointer is passed in rdi (NUL-terminated C-string)
	// Returns: rax=ptr, rdx=len
	// Notes:
	// - allocates a fresh buffer per file (callers keep the returned slice)
	// - uses sys_fstat to get file size, then sys_read loop to handle short reads

	asm {
		// Stack frame (relative to rsp after reservation):
		// [rsp+0]  = fd
		// [rsp+8]  = size
		// [rsp+16] = buf
		// [rsp+24] = total
		// [rsp+32] = path
		// [rsp+48..191] = stbuf (144 bytes)
		"sub rsp, 192\n"
		"mov [rsp+32], rdi\n"

		// fd = sys_open(path, O_RDONLY=0, mode=0)
		"mov rdi, [rsp+32]\n"
		"xor rsi, rsi\n"
		"xor rdx, rdx\n"
		"call sys_open\n"
		"test rax, rax\n"
		"jns .open_ok\n"
		"call die_read_file_open_fail\n"
		".open_ok:\n"
		"mov [rsp+0], rax\n"

		// sys_fstat(fd, stbuf)
		"mov rdi, [rsp+0]\n"
		"lea rsi, [rsp+48]\n"
		"call sys_fstat\n"
		"test rax, rax\n"
		"jns .fstat_ok\n"
		"call die_read_file_fstat_fail\n"
		".fstat_ok:\n"

		// size = *(u64*)(stbuf + 48)
		"mov r9, [rsp+96]\n"
		"mov [rsp+8], r9\n"

		// buf = heap_alloc(size + 1)
		"mov rdi, r9\n"
		"inc rdi\n"
		"call heap_alloc\n"
		"test rax, rax\n"
		"jnz .alloc_ok\n"
		"call die_read_file_oom\n"
		".alloc_ok:\n"
		"mov [rsp+16], rax\n"

		// buf[size] = 0
		"mov rcx, [rsp+8]\n"
		"mov r8,  [rsp+16]\n"
		"mov byte [r8+rcx], 0\n"

		// total = 0
		"mov qword [rsp+24], 0\n"

		// read loop
		".loop:\n"
		"mov r10, [rsp+24]\n"     // total
		"mov r11, [rsp+8]\n"      // size
		"cmp r10, r11\n"
		"jae .done\n"

		// remaining = size - total
		"mov rdx, r11\n"
		"sub rdx, r10\n"

		// sys_read(fd, buf+total, remaining)
		"mov rdi, [rsp+0]\n"      // fd
		"mov r8,  [rsp+16]\n"     // buf
		"lea rsi, [r8+r10]\n"     // buf+total
		"call sys_read\n"
		"test rax, rax\n"
		"jz .done\n"              // EOF
		"js .read_err\n"          // negative => error

		// total += rax
		"add r10, rax\n"
		"mov [rsp+24], r10\n"
		"jmp .loop\n"

		".read_err:\n"
		"call die_read_file_read_fail\n"

		".done:\n"
		// close(fd)
		"mov rdi, [rsp+0]\n"
		"call sys_close\n"

		// return (buf, total)
		"mov rax, [rsp+16]\n"
		"mov rdx, [rsp+24]\n"
		"add rsp, 192\n"
	};
}
