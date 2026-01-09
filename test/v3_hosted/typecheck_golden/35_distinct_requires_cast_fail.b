// typecheck golden: distinct는 기반 타입과 혼용 금지 (캐스트 필요)

type Handle = distinct u64;

var g: Handle = 1; // error: global init type mismatch
