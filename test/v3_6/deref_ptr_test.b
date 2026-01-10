// Test: *ptr dereference syntax (replaces ptr64[])

func main() {
    // Allocate memory for two i64 values
    var arr;
    arr = heap_alloc(16);
    
    // Cast to typed pointer
    var p: *i64;
    p = (*i64)arr;
    
    // Write using dereference
    *p = 100;
    
    // Read using dereference
    var v: i64;
    v = *p;
    
    // Print result
    print_u64(v);
    print_nl();
    
    // Write to next element using pointer arithmetic
    var p2: *i64;
    p2 = p + 1;
    *p2 = 200;
    
    // Read back
    var v2: i64;
    v2 = *p2;
    print_u64(v2);
    print_nl();
    
    return 0;
}
