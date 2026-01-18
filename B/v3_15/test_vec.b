// test_vec.b - Simple test for Vec

import std.io;
import std.vec;

func main() -> u64 {
    var v: u64 = vec_new(10);
    println("Vec created");
    return 0;
}
