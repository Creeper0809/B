// Expect exit code: 82
// Covers: &, |, ^, <<, >>

func main(argc, argv) {
    var a;
    var b;
    var c;
    var d;
    var e;

    a = 42;          // 0b00101010
    b = 15;          // 0b00001111
    c = a & b;       // 10
    d = a | b;       // 47
    e = a ^ b;       // 37

    // ((10 << 4) | 37) >> 1 = 82
    return ((c << 4) | e) >> 1;
}
