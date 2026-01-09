// Test 35: defer statement smoke test

func main() {
    defer print("3\n");
    defer print("2\n");
    print("1\n");
    return 0;
}
