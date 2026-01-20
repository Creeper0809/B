// Expect exit code: 1
// Covers precedence: == binds tighter than &
// 1 & 2 == 2  == 1 & (2 == 2) == 1

func main(argc, argv) {
    var x;
    x = 1 & 2 == 2;
    return x;
}
