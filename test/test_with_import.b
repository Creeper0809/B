// Main with import
import test_helper;

func main() -> u64 {
    var a: u64 = 10;
    var b: u64 = 20;
    var sum = helper_add(a, b);
    var prod = helper_mul(sum, 2);
    return prod; // (10 + 20) * 2 = 60
}
