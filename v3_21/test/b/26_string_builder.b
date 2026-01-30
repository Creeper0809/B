// Test 26: StringBuilder basic operations
// Expect exit code: 42

import std.io;
import std.str;
import std.string_builder;

func main() -> i64 {
    var sb: StringBuilder;
    if (!sb.init(4)) { return 1; }
    
    sb.append("ab");
    sb.append_bytes("cd", 2);
    sb.append_u64_dec(123);
    
    var p: u64 = sb.ptr();
    var n: u64 = sb.len();
    if (!str_eq(p, n, "abcd123", 7)) { return 2; }
    
    sb.clear();
    if (sb.len() != 0) { return 3; }
    sb.append("xy");
    if (!str_eq(sb.ptr(), sb.len(), "xy", 2)) { return 4; }
    
    return 42;
}
