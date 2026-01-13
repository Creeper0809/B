// Test: 디버그 - 토큰 스트림만 확인
import std.io;
import std.vec;
import types;
import lexer;

func main(argc, argv) {
    var src = "struct Point { x: i64; y: i64; } func main(argc, argv) { return 42; }";
    var src_len = str_len(src);
    
    var tokens = lex_text(src, src_len, "test.b", 7);
    var n_tokens = vec_len(tokens);
    
    var i = 0;
    while (i < n_tokens) {
        var tok = vec_get(tokens, i);
        var kind = *(tok);
        println_i64(kind);
        i = i + 1;
    }
    
    return 0;
}
