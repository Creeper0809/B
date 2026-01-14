// util.b - Utility functions for v3.8

import std.io;
import std.str;
import std.path;
import std.char;

// ============================================
// Error Handling
// ============================================

func panic() -> u64 {
    emit("[PANIC] Compiler error - exiting", 32);
    emit_nl();
    var x: u64 = *(0);
}

func emit_stderr(s: u64, len: u64) -> u64 {
    sys_write(2, s, len);
}

func emit_stderr_nl() -> u64 {
    var nl: u64 = heap_alloc(1);
    *(*u8)nl = 10;
    sys_write(2, nl, 1);
}

func warn(msg: u64, len: u64) -> u64 {
    emit_stderr("[WARN] ", 7);
    emit_stderr(msg, len);
    emit_stderr_nl();
}

// ============================================
// Output Utilities
// ============================================

func emit_char(c: u64) -> u64 {
    var buf: u64 = heap_alloc(1);
    *(*u8)buf = c;
    sys_write(1, buf, 1);
}

func emit_u64(n: u64) -> u64 {
    if (n == 0) {
        emit("0", 1);
        return;
    }
    var buf: u64 = heap_alloc(32);
    var i: u64 = 0;
    var t: u64 = n;
    while (t > 0) {
        *(*u8)(buf + i) = 48 + (t % 10);
        t = t / 10;
        i = i + 1;
    }
    var j: u64 = i - 1;
    while (j >= 0) {
        sys_write(1, buf + j, 1);
        j = j - 1;
    }
}

func emit_i64(n: u64) -> u64 {
    if (n < 0) {
        emit("-", 1);
        emit_u64(0 - n);
    } else {
        emit_u64(n);
    }
}

func emit_nl() -> u64 {
    var nl: u64 = heap_alloc(1);
    *(*u8)nl = 10;
    sys_write(1, nl, 1);
}


