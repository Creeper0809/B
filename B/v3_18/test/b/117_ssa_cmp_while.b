// Expect exit code: 0

func main() -> i64 {
    var x = 0;
    var y = 3;

    if (x == 0) {
        x = x + 1;
    }

    if (y != 0) {
        y = y - 1;
    }

    while (x < 3) {
        x = x + 1;
    }

    if (x >= 3) {
        return 0;
    }

    return 1;
}
