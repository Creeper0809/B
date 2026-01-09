import v3_hosted.lexer;
import v3_hosted.parser;
import v3_hosted.typecheck;
import v3_hosted.codegen;

func smoke_sys_write(fd, p, n) {
	asm {
		mov rax, 1
		syscall
	}
	return;
}

func main() { return 0; }
