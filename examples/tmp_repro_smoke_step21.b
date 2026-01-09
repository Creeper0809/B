import v3_hosted.codegen;
import v3_hosted.lexer;
import v3_hosted.parser;
import v3_hosted.typecheck;

func main() {
	return 0;
}

// Returns: rax=Bytes* where Bytes = {ptr,len}
func read_file_bytes(path) {
	asm {
		sub rsp, 16
		mov [rsp+0], rdi
		mov rdi, [rsp+0]
		call read_file
		mov [rsp+0], rax
		mov [rsp+8], rdx
		mov rdi, 16
		call heap_alloc
		test rax, rax
		jz .oom
		mov rcx, [rsp+0]
		mov [rax+0], rcx
		mov rcx, [rsp+8]
		mov [rax+8], rcx
		xor edx, edx
		add rsp, 16
		jmp .done
		.oom:
		xor eax, eax
		xor edx, edx
		add rsp, 16
		.done:
	}
	return;
}
