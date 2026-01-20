// Test 73: Basic switch statement
func main() {
    var x = 2;
    
    switch (x) {
        case 1:
            print_i64(100);
            print_nl();
            break;
        case 2:
            print_i64(200);
            print_nl();
            break;
        case 3:
            print_i64(300);
            print_nl();
            break;
        default:
            print_i64(999);
            print_nl();
    }
    
    // Test with variable
    var y = 1;
    switch (y) {
        case 1:
            print_i64(111);
            print_nl();
            break;
        case 2:
            print_i64(222);
            print_nl();
            break;
        default:
            print_i64(333);
            print_nl();
    }
    
    // Test default
    var z = 99;
    switch (z) {
        case 1:
            print_i64(1);
            print_nl();
            break;
        case 2:
            print_i64(2);
            print_nl();
            break;
        default:
            print_i64(888);
            print_nl();
    }
    
    return 0;
}
