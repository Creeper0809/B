import file;
import v3_hosted.lexer;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	alias rdx : n_reg;
	var p = read_file(path);
	var n = n_reg;
	if (p == 0) { return 2; }
	return 0;
}
