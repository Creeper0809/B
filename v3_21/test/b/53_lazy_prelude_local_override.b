// Test 53: Lazy prelude keeps local override
// Expect exit code: 0

func str_len(p: *u8) -> i64 {
    return 7;
}

func main(argc, argv) {
    var n: i64 = str_len("abc");
    if (n != 7) { return 1; }
    return 0;
}
