// test_sizeof_simple.b - Simple sizeof test
// Mode: ssa
// Opt: O1
import std.io;

struct Point {
    x: u64;
    y: u64;
}

func main() -> u64 {
    println("Testing sizeof...\n", 19);
    
    var s1: u64 = sizeof(u8);
    print("sizeof(u8) = ", 13);
    print_u64(s1);
    println("\n", 1);
    
    var s2: u64 = sizeof(u64);
    print("sizeof(u64) = ", 14);
    print_u64(s2);
    println("\n", 1);
    
    var s3: u64 = sizeof(*u64);
    print("sizeof(*u64) = ", 15);
    print_u64(s3);
    println("\n", 1);
    
    var s4: u64 = sizeof(Point);
    print("sizeof(Point) = ", 16);
    print_u64(s4);
    println("\n", 1);
    
    println("Done!\n", 7);
    return 0;
}
