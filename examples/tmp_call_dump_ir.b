// scratch: just call v3h_codegen_program_dump_ir

import v3_hosted.codegen;

func main() {
	var prog = 0;
	var bytes = v3h_codegen_program_dump_ir(prog);
	if (bytes == 0) { return 0; }
	return 0;
}
