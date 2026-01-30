// Expect exit code: 0
// Mode: ssa
// Opt: O1

func create_view(arr: *i64, len: i64) -> []i64 {
    return slice(arr, len);
}

func main() -> i64 {
    var data: [5]i64;
    data[0] = 10;
    data[1] = 20;
    data[2] = 30;
    data[3] = 40;
    data[4] = 50;

    var view: []i64 = create_view(data, 5);

    // Modify through slice
    view[2] = 99;

    // Verify modification
    if (data[2] != 99) { return 1; }
    if (view[2] != 99) { return 2; }

    return 0;
}
