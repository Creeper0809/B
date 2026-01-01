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
	// placeholder for: read_file -> lex -> parse -> emit -> write .asm
	// For now, just echo the input path to prove argv plumbing works.
	// Convention: input path is passed in rdi.
	print_str(rdi);
	print_str("\n");
}

func main() {
	alias rdi : argc;
	alias rsi : argv;

	// Preserve process args across calls (rdi/rsi are caller-saved and used for call args).
	alias r12 : argc0;
	alias r13 : argv0;

	// Important: rcx is clobbered by `syscall`, so don't use it for loop counters.
	alias r14 : i;
	alias rdx : off;
	alias r8  : addr;
	alias rbx : path;

	argc0 = argc;
	argv0 = argv;

	// Skip argv[0] (program name). If no inputs, just exit(0).
	i = 1;

	while (i < argc0) {
		off = i;
		off <<= 3; // *8 bytes per pointer

		addr = argv0;
		addr += off;
		path = ptr64[addr];

		rdi = path;
		compile_one();
		i += 1;
	}

	sys_exit(0);
}
