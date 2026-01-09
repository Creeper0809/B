import file;
import v3_hosted.lexer;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func cstr_len(p) {
	var i = 0;
	while (ptr8[p] != 0) {
		i = i + 1;
		p = p + 1;
	}
	return i;
}

func main(argc, argv) {
	if (argc < 2) { return 1; }
	var path = ptr64[argv + 8];
	var p = read_file(path);
	if (p == 0) { return 2; }
	var n = cstr_len(p);
	return 0;
}
