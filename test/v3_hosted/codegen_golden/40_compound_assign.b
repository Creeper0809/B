// Test compound assignment and increment/decrement (Phase 6.1)

func main() {
    var x: u64 = 10;
    
    // compound assignment
    x += 5;     // x = 15
    print_u64(x);
    
    x -= 3;     // x = 12
    print_u64(x);
    
    x *= 2;     // x = 24
    print_u64(x);
    
    x /= 4;     // x = 6
    print_u64(x);
    
    x %= 5;     // x = 1
    print_u64(x);
    
    // increment/decrement
    x++;        // x = 2
    print_u64(x);
    
    x++;        // x = 3
    print_u64(x);
    
    x--;        // x = 2
    print_u64(x);
    
    // bitwise compound assignment
    var y: u64 = 15;
    y &= 7;     // y = 7
    print_u64(y);
    
    y |= 8;     // y = 15
    print_u64(y);
    
    y ^= 3;     // y = 12
    print_u64(y);
    
    y <<= 2;    // y = 48
    print_u64(y);
    
    y >>= 1;    // y = 24
    print_u64(y);
}
