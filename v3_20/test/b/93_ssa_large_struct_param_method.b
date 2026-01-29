// Covers: SSA large struct param in method call
// Mode: ssa
// Opt: O1
// Expect exit code: 10

struct Large {
    a: i64;
    b: i64;
    c: i64;
}

struct Acc {
    bias: i64;
}

impl Acc {
    func add(self: *Acc, l: Large) -> i64 {
        return self->bias + l.a + l.b + l.c;
    }
}

func main() -> i64 {
    var a: Acc;
    a.bias = 1;

    var l: Large;
    l.a = 2;
    l.b = 3;
    l.c = 4;

    return a.add(l);
}
