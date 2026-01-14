// Expect exit code: 25
// Covers: continue in while loop

func main(argc, argv) {
    var i;
    var sum;

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
    return sum;
}
