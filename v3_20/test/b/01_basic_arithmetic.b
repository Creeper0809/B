// Expect exit code: 0
// Mode: ssa
// Opt: O1
// Covers: basic arithmetic, bitwise/shift, comparisons, precedence, complex expressions

func main(argc, argv) {
    var a;
    var b;
    var c;
    var result;

    a = 10;
    b = 5;

    if (a + b != 15) { return 1; }
    if (a - b != 5) { return 2; }
    if (a * b != 50) { return 3; }
    if (a / b != 2) { return 4; }
    if (a % b != 0) { return 5; }

    // &, |, ^, <<, >>
    a = 42; // 0b00101010
    b = 15; // 0b00001111
    var bit_and = a & b; // 10
    var bit_or = a | b;  // 47
    var bit_xor = a ^ b; // 37
    if (((bit_and << 4) | bit_xor) >> 1 != 82) { return 6; }

    // Comparisons
    if (!(10 > 5)) { return 7; }
    if (!(10 >= 10)) { return 8; }
    if (!(5 < 10)) { return 9; }
    if (!(5 <= 5)) { return 10; }
    if (!(5 != 10)) { return 11; }
    if (!(7 == 7)) { return 12; }

    // Precedence
    var p1 = 1 + 2 << 1; // (1 + 2) << 1 = 6
    var p2 = 1 << 2 + 1; // 1 << (2 + 1) = 8
    if (p1 != 6) { return 13; }
    if (p2 != 8) { return 14; }
    if ((1 & 2 == 2) != 1) { return 15; }

    // Complex expressions
    a = 5;
    b = 10;
    c = 3;

    result = (a + b) * c; // 45
    if (result != 45) { return 16; }

    result = a + b * c; // 35
    if (result != 35) { return 17; }

    result = (a + b) / (c - 1); // 7
    if (result != 7) { return 18; }

    result = ((a + b) * c) / (c + 1) + a; // (45/4)+5 = 16
    if (result != 16) { return 19; }

    // Compound assignment + inc/dec
    var ca = 10;
    ca += 5; // 15
    if (ca != 15) { return 20; }

    var cb = 20;
    cb -= 7; // 13
    if (cb != 13) { return 21; }

    var cc = 6;
    cc *= 4; // 24
    if (cc != 24) { return 22; }

    var cd = 100;
    cd /= 5; // 20
    if (cd != 20) { return 23; }

    var ce = 17;
    ce %= 5; // 2
    if (ce != 2) { return 24; }

    var inc = 10;
    inc++;
    if (inc != 11) { return 25; }
    --inc;
    if (inc != 10) { return 26; }

    var mix = 5;
    mix += 3; // 8
    mix *= 2; // 16
    mix -= 4; // 12
    mix /= 3; // 4
    mix %= 3; // 1
    if (mix != 1) { return 27; }

    return 0;
}
