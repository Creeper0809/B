// Expect exit code: 5
// Covers: continue in for loop (should jump to update)

func main(argc, argv) {
    var i;
    var count;

    count = 0;

    for (i = 0; i < 10; i = i + 1) {
        if (i < 5) {
            continue;
        }
        count = count + 1;
    }

    // i = 5..9 => 5 iterations
    return count;
}
