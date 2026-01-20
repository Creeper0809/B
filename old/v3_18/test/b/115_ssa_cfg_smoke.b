// Expect exit code: 0

func main() -> i64 {
    var x = 0;
    if (x == 0) {
        x = 1;
    } else {
        x = 2;
    }

    while (x < 3) {
        x = x + 1;
        if (x == 2) {
            continue;
        }
        if (x == 3) {
            break;
        }
    }

    return 0;
}
