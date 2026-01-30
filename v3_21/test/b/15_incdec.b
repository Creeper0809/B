// Expect exit code: 0
// Mode: ssa
// Opt: O1

func main() {
    var x;
    x = 1;

    x++;
    if (x != 2) { return 1; }

    ++x;
    if (x != 3) { return 2; }

    x--;
    if (x != 2) { return 3; }

    --x;
    if (x != 1) { return 4; }

    // for-update sugar
    var i;
    i = 0;
    for (; i < 3; i++) {
    }
    if (i != 3) { return 5; }

    return 0;
}
