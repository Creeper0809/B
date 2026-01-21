// test_sizeof.b - sizeof() operator tests for v3_15
// Mode: ssa
// Opt: O1
import std.io;

struct Point {
    x: u64;
    y: u64;
}

struct Rect {
    top_left: Point;
    width: u64;
    height: u64;
}

struct SmallStruct {
    a: u8;
    b: u8;
}

func print_result(name: u64, name_len: u64, value: u64) -> u64 {
    println(name, name_len);
    print_u64(value);
    println("\n", 1);
    return 0;
}

func main() -> u64 {
    // Test primitive types
    println("=== Primitive Types ===\n", 27);
    var s_u8: u64 = sizeof(u8);
    print_result("sizeof(u8) = ", 14, s_u8);
    
    var s_u16: u64 = sizeof(u16);
    print_result("sizeof(u16) = ", 15, s_u16);
    
    var s_u32: u64 = sizeof(u32);
    print_result("sizeof(u32) = ", 15, s_u32);
    
    var s_u64: u64 = sizeof(u64);
    print_result("sizeof(u64) = ", 15, s_u64);
    
    var s_i64: u64 = sizeof(i64);
    print_result("sizeof(i64) = ", 15, s_i64);
    
    // Test pointer types
    println("\n=== Pointer Types ===\n", 24);
    var s_ptr_u8: u64 = sizeof(*u8);
    print_result("sizeof(*u8) = ", 15, s_ptr_u8);
    
    var s_ptr_u64: u64 = sizeof(*u64);
    print_result("sizeof(*u64) = ", 16, s_ptr_u64);
    
    var s_ptr_ptr: u64 = sizeof(**u64);
    print_result("sizeof(**u64) = ", 17, s_ptr_ptr);
    
    // Test struct types
    println("\n=== Struct Types ===\n", 23);
    var s_point: u64 = sizeof(Point);
    print_result("sizeof(Point) = ", 17, s_point);
    
    var s_rect: u64 = sizeof(Rect);
    print_result("sizeof(Rect) = ", 16, s_rect);
    
    var s_small: u64 = sizeof(SmallStruct);
    print_result("sizeof(SmallStruct) = ", 23, s_small);
    
    // Test pointer to struct
    println("\n=== Pointer to Struct ===\n", 28);
    var s_ptr_point: u64 = sizeof(*Point);
    print_result("sizeof(*Point) = ", 18, s_ptr_point);
    
    var s_ptr_rect: u64 = sizeof(*Rect);
    print_result("sizeof(*Rect) = ", 17, s_ptr_rect);
    
    // Validation checks
    println("\n=== Validation ===\n", 21);
    var all_ok: u64 = 1;
    
    if (s_u8 != 1) { 
        println("ERROR: sizeof(u8) should be 1\n", 32);
        all_ok = 0;
    }
    if (s_u16 != 2) { 
        println("ERROR: sizeof(u16) should be 2\n", 33);
        all_ok = 0;
    }
    if (s_u32 != 4) { 
        println("ERROR: sizeof(u32) should be 4\n", 33);
        all_ok = 0;
    }
    if (s_u64 != 8) { 
        println("ERROR: sizeof(u64) should be 8\n", 33);
        all_ok = 0;
    }
    if (s_i64 != 8) { 
        println("ERROR: sizeof(i64) should be 8\n", 33);
        all_ok = 0;
    }
    
    if (s_ptr_u8 != 8) {
        println("ERROR: sizeof(*u8) should be 8\n", 34);
        all_ok = 0;
    }
    if (s_ptr_u64 != 8) {
        println("ERROR: sizeof(*u64) should be 8\n", 35);
        all_ok = 0;
    }
    if (s_ptr_ptr != 8) {
        println("ERROR: sizeof(**u64) should be 8\n", 36);
        all_ok = 0;
    }
    
    if (s_point != 16) {
        println("ERROR: sizeof(Point) should be 16\n", 37);
        all_ok = 0;
    }
    if (s_rect != 32) {
        println("ERROR: sizeof(Rect) should be 32\n", 36);
        all_ok = 0;
    }
    if (s_small != 2) {
        println("ERROR: sizeof(SmallStruct) should be 2\n", 42);
        all_ok = 0;
    }
    
    if (s_ptr_point != 8) {
        println("ERROR: sizeof(*Point) should be 8\n", 37);
        all_ok = 0;
    }
    if (s_ptr_rect != 8) {
        println("ERROR: sizeof(*Rect) should be 8\n", 36);
        all_ok = 0;
    }
    
    if (all_ok) {
        println("All sizeof tests PASSED!\n", 27);
    } else {
        println("Some sizeof tests FAILED!\n", 28);
    }
    
    return 0;
}
