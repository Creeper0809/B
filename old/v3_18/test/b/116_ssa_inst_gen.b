// Expect exit code: 0

func main() -> i64 {
    var a = 1;
    var b = 2;
    var c = a + b;

    if (c > 2) {
        c = c - 1;
    } else {
        c = c + 1;
    }

    while (c < 5) {
        c = c + 1;
    }

    return 0;
}
