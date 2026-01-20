// Expect exit code: 0

func side_effect(x: i64) -> i64 {
    return x;
}

func main() -> i64 {
    var a = 0;
    var b = 1;

    if (a != 0 && side_effect(1) == 1) {
        return 2;
    }

    var x = (a != 0) || (b == 1);
    if (x == 0) {
        return 3;
    }

    return 0;
}
