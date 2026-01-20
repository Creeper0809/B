// Test 75: Switch with default case and fallthrough prevention
func main() {
    // Test 1: Only default case
    var x = 123;
    switch (x) {
        default:
            print_i64(777);
            print_nl();
    }
    
    // Test 2: Case before default
    var y = 5;
    switch (y) {
        case 1:
            print_i64(1);
            print_nl();
            break;
        case 5:
            print_i64(5);
            print_nl();
            break;
        default:
            print_i64(999);
            print_nl();
    }
    
    // Test 3: Multiple statements in case
    var z = 42;
    switch (z) {
        case 42:
            print_i64(42);
            print_nl();
            print_i64(43);
            print_nl();
            break;
        default:
            print_i64(0);
            print_nl();
    }
    
    // Test 4: Nested switch
    var a = 1;
    var b = 2;
    switch (a) {
        case 1:
            switch (b) {
                case 2:
                    print_i64(12);
                    print_nl();
                    break;
                default:
                    print_i64(10);
                    print_nl();
            }
            break;
        default:
            print_i64(99);
            print_nl();
    }
    
    return 0;
}
