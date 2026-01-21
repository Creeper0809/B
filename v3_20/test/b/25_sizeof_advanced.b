// test_sizeof_advanced.b - Advanced sizeof() tests with nested structs
// Mode: ssa
// Opt: O1
import std.io;

struct Inner {
    a: u8;
    b: u16;
    c: u32;
}

struct Outer {
    first: Inner;
    second: Inner;
    ptr: *u64;
}

func test_sizeof_in_expr() -> u64 {
    println("=== sizeof in expressions ===\n", 32);
    
    // sizeof in arithmetic
    var total: u64 = sizeof(u64) + sizeof(u32) + sizeof(u16) + sizeof(u8);
    print("total size = ", 13);
    print_u64(total);
    println(" (expected 15)\n", 16);
    
    // sizeof in comparison
    if (sizeof(*u8) == sizeof(*u64)) {
        println("Pointer sizes are equal (correct)\n", 36);
    } else {
        println("ERROR: Pointer sizes differ!\n", 31);
    }
    
    // sizeof as array bound calculation
    var item_size: u64 = sizeof(u64);
    var array_bytes: u64 = 128;
    var num_items: u64 = array_bytes / item_size;
    print("Can fit ", 8);
    print_u64(num_items);
    println(" items (expected 16)\n", 22);
    
    return 0;
}

func test_nested_structs() -> u64 {
    println("\n=== Nested struct sizes ===\n", 30);
    
    var s_inner: u64 = sizeof(Inner);
    print("sizeof(Inner) = ", 16);
    print_u64(s_inner);
    println(" (u8+u16+u32 = 1+2+4 = 7)\n", 27);
    
    var s_outer: u64 = sizeof(Outer);
    print("sizeof(Outer) = ", 16);
    print_u64(s_outer);
    println(" (Inner+Inner+*u64 = 7+7+8 = 22)\n", 35);
    
    // Validation
    if (s_inner == 7) {
        println("Inner size correct!\n", 21);
    } else {
        println("ERROR: Inner size wrong!\n", 27);
    }
    
    if (s_outer == 22) {
        println("Outer size correct!\n", 21);
    } else {
        println("ERROR: Outer size wrong!\n", 27);
    }
    
    return 0;
}

func test_pointer_arithmetic() -> u64 {
    println("\n=== sizeof for pointer arithmetic ===\n", 41);
    
    // Allocate buffer for 10 u64 values
    var count: u64 = 10;
    var buffer_size: u64 = count * sizeof(u64);
    print("Buffer size for 10 u64s: ", 26);
    print_u64(buffer_size);
    println(" bytes\n", 8);
    
    // Size of different types for offset calculation
    print("Offset of 5 u64s: ", 18);
    print_u64(5 * sizeof(u64));
    println(" bytes\n", 8);
    
    print("Offset of 5 u32s: ", 18);
    print_u64(5 * sizeof(u32));
    println(" bytes\n", 8);
    
    print("Offset of 5 u16s: ", 18);
    print_u64(5 * sizeof(u16));
    println(" bytes\n", 8);
    
    print("Offset of 5 u8s: ", 17);
    print_u64(5 * sizeof(u8));
    println(" bytes\n", 8);
    
    return 0;
}

func main() -> u64 {
    println("========================================\n", 42);
    println("sizeof() Advanced Tests for v3_15\n", 36);
    println("========================================\n", 42);
    
    test_sizeof_in_expr();
    test_nested_structs();
    test_pointer_arithmetic();
    
    println("\n========================================\n", 43);
    println("All advanced sizeof tests completed!\n", 39);
    println("========================================\n", 42);
    
    return 0;
}
