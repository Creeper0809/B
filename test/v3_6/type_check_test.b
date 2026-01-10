// v3_6 Type Checking Test
// Phase 4: Test implicit type conversion warnings

func main() {
    // Test 1: Same type - no warning
    var a: i64;
    a = 42;
    print_u64(a);
    print_nl();
    
    // Test 2: Different integer types - warning expected
    var b: u8;
    b = 256;  // Warning: implicit conversion i64 -> u8
    print_u64(b);
    print_nl();
    
    // Test 3: Pointer types
    var arr;
    arr = heap_alloc(32);
    
    var p: *i64;
    p = (*i64)arr;  // No warning - explicit cast
    *p = 100;
    
    var v: i64;
    v = *p;
    print_u64(v);
    print_nl();
    
    // Test 4: Pointer to different type - warning expected
    var q: *u8;
    q = (*i64)arr;  // Warning: implicit conversion *i64 -> *u8
    
    print_u64(42);  // Success marker
    print_nl();
    
    return 0;
}
