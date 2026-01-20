// Expect exit code: 68
// Covers operator precedence: + binds tighter than <<
// 1 + 2 << 1  == (1 + 2) << 1 == 6
// 1 << 2 + 1  == 1 << (2 + 1) == 8

func main(argc, argv) {
    var a;
    var b;

    a = 1 + 2 << 1;
    b = 1 << 2 + 1;

    return a * 10 + b;
}
