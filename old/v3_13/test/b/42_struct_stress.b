// Test: Stress test - large struct with many fields
// Expect exit code: 42

struct BigData {
    f0: u64;
    f1: u64;
    f2: u64;
    f3: u64;
    f4: u64;
    f5: u64;
    f6: u64;
    f7: u64;
    f8: u64;
    f9: u64;
}

func main(argc, argv) {
    var data: BigData;
    var ptr: *BigData;
    ptr = &data;
    
    // Initialize all fields
    ptr->f0 = 1;
    ptr->f1 = 2;
    ptr->f2 = 3;
    ptr->f3 = 4;
    ptr->f4 = 5;
    ptr->f5 = 6;
    ptr->f6 = 7;
    ptr->f7 = 8;
    ptr->f8 = 9;
    ptr->f9 = 3;  // 1+2+3+4+5+6+7+8+9+3 = 48
    
    // Modify some fields
    data.f0 = data.f0 + 1;  // 2
    data.f9 = data.f9 - 8;  // -5
    
    // Sum: 2+2+3+4+5+6+7+8+9-5 = 41... wait, need 42
    // Let's adjust: 2+2+3+4+5+6+7+8+9-4 = 42
    data.f9 = -4;
    
    var sum = ptr->f0 + ptr->f1 + ptr->f2 + ptr->f3 + ptr->f4;
    sum = sum + ptr->f5 + ptr->f6 + ptr->f7 + ptr->f8 + ptr->f9;
    
    return sum;
}
