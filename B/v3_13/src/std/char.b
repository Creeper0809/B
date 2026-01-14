// char.b - Character classification utilities for v3.8

func is_alpha(c) {
    if (c >= 65 && c <= 90) {
        return 1;
    }
    if (c >= 97 && c <= 122) {
        return 1; 
    }
    if (c == 95) { return 1; }
    return 0;
}

func is_digit(c) {
    if (c >= 48 && c <= 57) {
        return 1;
    }
    return 0;
}

func is_alnum(c) {
    if (is_alpha(c)) { return 1; }
    if (is_digit(c)) { return 1; }
    return 0;
}

func is_whitespace(c) {
    if (c == 32) { return 1; }
    if (c == 9) { return 1; }
    if (c == 10) { return 1; }
    if (c == 13) { return 1; }
    return 0;
}
