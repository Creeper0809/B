extern func add1(x @ r12: u64) -> @ r13 u64 {
	return x + 1;
}

func main() {
	return add1(41);
}
