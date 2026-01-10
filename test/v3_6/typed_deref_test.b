// v3_6 Typed Dereference Test
// Phase 5: Test type-aware memory access with *ptr syntax

func main() {
    // Allocate memory for tests
    var mem;
    mem = heap_alloc(64);
    
    // Test 1: u8 pointer - 1 byte access
    var p8: *u8;
    p8 = (*u8)mem;
    
    // Write individual bytes using *ptr
    *p8 = 65;             // 'A'
    *(p8 + 1) = 66;       // 'B'
    *(p8 + 2) = 67;       // 'C'
    *(p8 + 3) = 68;       // 'D'
    
    // Read using typed dereference
    var b0: u8;
    b0 = *p8;
    print_u64(b0);  // Expected: 65
    print_nl();
    
    // p8 + 1 moves by 1 byte (u8 size)
    var b1: u8;
    b1 = *(p8 + 1);
    print_u64(b1);  // Expected: 66
    print_nl();
    
    // Test 2: i64 pointer - 8 byte access
    var p64: *i64;
    p64 = (*i64)(mem + 16);
    
    // Write 64-bit values
    *p64 = 1000;
    *(p64 + 1) = 2000;
    
    // Read back
    var v0: i64;
    v0 = *p64;
    print_u64(v0);  // Expected: 1000
    print_nl();
    
    var v1: i64;
    v1 = *(p64 + 1);
    print_u64(v1);  // Expected: 2000
    print_nl();
    
    return 0;
}
