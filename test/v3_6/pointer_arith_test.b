// v3_6 Pointer Arithmetic Test
// Phase 3: Test C-style pointer arithmetic with *ptr syntax

func main() {
    // Allocate an array of 4 i64 values (32 bytes)
    var arr;
    arr = heap_alloc(32);
    
    // Cast to typed pointer
    var p: *i64;
    p = (*i64)arr;
    
    // Initialize array using *ptr dereference
    *p = 10;
    *(p + 1) = 20;
    *(p + 2) = 30;
    *(p + 3) = 40;
    
    // Test 1: Access using pointer dereference
    var v0: i64;
    v0 = *p;
    print_u64(v0);
    print_nl();
    
    // p + 1 should be arr + 8 (scaled by 8)
    var v1: i64;
    v1 = *(p + 1);
    print_u64(v1);
    print_nl();
    
    // p + 2 should be arr + 16
    var v2: i64;
    v2 = *(p + 2);
    print_u64(v2);
    print_nl();
    
    // p + 3 should be arr + 24
    var v3: i64;
    v3 = *(p + 3);
    print_u64(v3);
    print_nl();
    
    // Test 2: Sum all elements using pointer arithmetic
    var sum: i64;
    sum = 0;
    var i: i64;
    i = 0;
    while (i < 4) {
        sum = sum + *(p + i);
        i = i + 1;
    }
    print_u64(sum);
    print_nl();
    
    return 0;
}
