// Test 08: String Operations
import std.io;
import std.emit;
import std.str;

func main(argc, argv) {
    var s1;
    var s2;
    var s3;
    var len1;
    var len2;
    
    s1 = "Hello";
    s2 = " World!";
    
    len1 = str_len(s1);
    len2 = str_len(s2);
    
    emit("s1 = ", 5);
    emit(s1, len1);
    emit(" (len=", 6);
    emit_i64(len1);
    emit(")\n", 2);
    
    emit("s2 = ", 5);
    emit(s2, len2);
    emit(" (len=", 6);
    emit_i64(len2);
    emit(")\n", 2);
    
    // Concatenate
    s3 = str_concat(s1, len1, s2, len2);
    emit("Concatenated: ", 14);
    emit(s3, str_len(s3));
    emit_nl();
    
    // String comparison
    if (str_eq(s1, len1, "Hello", 5)) {
        emit("s1 equals 'Hello'\n", 18);
    }
    
    if (!str_eq(s1, len1, "World", 5)) {
        emit("s1 does not equal 'World'\n", 27);
    }
    
    return 0;
}
