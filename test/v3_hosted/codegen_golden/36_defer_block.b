// Test 36: defer with nested blocks

func main() {
    print("a\n");
    {
        defer print("c\n");
        print("b\n");
    }
    print("d\n");
    return 0;
}
