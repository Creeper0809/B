// scratch: call v3h_codegen_program

import v3_hosted.codegen;

func main() {
	var prog = 0;
	var bytes = v3h_codegen_program(prog);
	if (bytes == 0) { return 0; }
	return 0;
}
