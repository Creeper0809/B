// v1 driver entry (minimal skeleton)
// Roadmap: docs/roadmap.md (stage 11)
//
// Goal of this file (P0/P1):
// - prove we can iterate argv safely under current basm Stage1 constraints
// - keep the pipeline functions as stubs so linking succeeds
//
// Notes about Stage1 constraints used here:
// - function args are passed in regs (rdi=argc, rsi=argv) but not bound as locals
// - no scaled indexing, so argv[i] uses (i<<3) byte offset

func compile_one() {
	// read_file -> lex -> parse -> emit -> write .asm
	// Convention: input path is passed in rdi.
	var path0;
	var src_ptr;
	var src_len;
	var lex;
	var p;

	ptr64[path0] = rdi;

	// Load source
	rdi = ptr64[path0];
	read_file(rdi);
	ptr64[src_ptr] = rax;
	ptr64[src_len] = rdx;

	// Lex + parse
	rdi = ptr64[src_ptr];
	rsi = ptr64[src_len];
	lexer_new(rdi, rsi);
	ptr64[lex] = rax;

	rdi = ptr64[lex];
	parser_new(rdi);
	ptr64[p] = rax;

	// Reset codegen globals per compile.
	asm { "mov qword [rel label_counter], 0\n" };
	vec_new(8);
	ptr64[vars_emitted] = rax;
	asm { "call consts_reset\n" };

	// Emit output.
	emit_init();
	emit_cstr("global _start\n");
	emit_cstr("section .text\n");
	emit_cstr("_start:\n");
	emit_cstr("  call main\n");
	emit_cstr("  mov rdi, rax\n");
	emit_cstr("  mov rax, 60\n");
	emit_cstr("  syscall\n");

	// Emit all function bodies.
	rdi = ptr64[p];
	asm { "call parse_program_emit_funcs\n" };

	// For now, always write to build/out.asm.
	emit_to_file("build/out.asm");
}

func main() {
	// NOTE(Stage1): do not keep argc/argv/i in registers across calls.
	// Some helpers do not reliably preserve callee-saved regs, so we store
	// loop state in stack slots and reload each iteration.
	asm {
		"push rbp\n"
		"mov rbp, rsp\n"
		"sub rsp, 32\n" // [rbp-8]=argc [rbp-16]=argv [rbp-24]=i
		"mov [rbp-8], rdi\n"
		"mov [rbp-16], rsi\n"
		"mov qword [rbp-24], 1\n" // i = 1

		".loop:\n"
		"mov rax, [rbp-24]\n" // i
		"cmp rax, [rbp-8]\n"  // argc
		"jae .done\n"
		"mov rdx, rax\n"
		"shl rdx, 3\n"         // i*8
		"mov r8, [rbp-16]\n"  // argv
		"add r8, rdx\n"
		"mov rdi, [r8]\n"     // path
		"call compile_one\n"
		"mov rax, [rbp-24]\n"
		"inc rax\n"
		"mov [rbp-24], rax\n"
		"jmp .loop\n"

		".done:\n"
		"mov rdi, 0\n"
		"call sys_exit\n"
	};
}
