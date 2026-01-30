// Test 61: SSA switch const/default
// Mode: ssa
// Expect exit code: 0

const A = 5;
const B = 5;

func main(argc, argv) {
    var x: i64 = 0;

    switch (A) {
        case 1:
            x = 1;
            break;
        case B:
            x = 2;
            break;
        default:
            x = 3;
    }

    if (x != 2) { return 1; }

    switch (0) {
        default:
            x = 4;
    }

    if (x != 4) { return 2; }
    return 0;
}
