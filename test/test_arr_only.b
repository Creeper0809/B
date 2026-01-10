func main() -> u64 {
    var arr: [3]u64;
    arr[$0] = 10;
    arr[$1] = 20;
    arr[$2] = 30;
    return arr[$0] + arr[$1] + arr[$2];
}
