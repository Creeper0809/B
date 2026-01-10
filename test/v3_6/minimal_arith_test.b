// Minimal pointer test

func main() {
    var x;
    x = 100;
    
    // Simple arithmetic - no pointer cast
    var y;
    y = x + 1;
    print_u64(y);
    print_nl();
    
    return 0;
}
