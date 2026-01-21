// Expect exit code: 0
// Mode: ssa
// Opt: O1
// Covers: recursion (factorial/fibonacci)

func factorial(n) {
    if (n <= 1) { return 1; }
    return n * factorial(n - 1);
}

func fib(n) {
    if (n < 2) { return n; }
    return fib(n - 1) + fib(n - 2);
}

func main(argc, argv) {
    if (factorial(5) != 120) { return 1; }
    if (fib(10) != 55) { return 2; }
    return 0;
}
