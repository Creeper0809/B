// IR Test: phi elimination visibility
func main() -> i64 {
    var x: i64 = 0;
    var y: i64 = 1;
    if (y) {
        x = 1;
    } else {
        x = 2;
    }
    return x;
}
