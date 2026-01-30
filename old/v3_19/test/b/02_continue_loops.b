// Expect exit code: 0
// Mode: ssa
// Opt: O1
// Covers: continue in while/for loops

func main(argc, argv) {
    var i;
    var sum;
    var count;

    i = 0;
    sum = 0;

    while (i < 10) {
        i = i + 1;
        if (i % 2 == 0) {
            continue;
        }
        sum = sum + i;
    }

    // 1+3+5+7+9 = 25
    if (sum != 25) { return 1; }

    count = 0;
    for (i = 0; i < 10; i = i + 1) {
        if (i < 5) {
            continue;
        }
        count = count + 1;
    }

    // i = 5..9 => 5 iterations
    if (count != 5) { return 2; }

    return 0;
}
