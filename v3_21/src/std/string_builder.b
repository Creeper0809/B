// string_builder.b - StringBuilder (byte buffer, NUL-terminated)
//
// 목적:
// - 문자열 누적/합성을 위해 동적 버퍼를 제공
// - 항상 NUL-terminated 유지
// - 포인터/길이 기반 API 제공

import std.io;
import std.str;

// StringBuilder 레이아웃 (24 bytes)
// [ptr:8][len:8][cap:8]
struct StringBuilder {
    ptr: u64;
    len: u64;
    cap: u64; // trailing NUL 제외
}

// 내부: 바이트 복사
func sb_copy_bytes(dst: u64, src: u64, n: u64) -> u64 {
    for (var i: u64 = 0; i < n; i++) {
        *(*u8)(dst + i) = *(*u8)(src + i);
    }
    return 0;
}

// 내부: 용량 확보 (추가 길이 add_len 포함)
func sb_ensure_cap(sb: *StringBuilder, add_len: u64) -> u64 {
    var need: u64 = sb->len + add_len;
    if (need <= sb->cap) { return 1; }
    
    var new_cap: u64 = sb->cap;
    if (new_cap < 8) { new_cap = 8; }
    for (; new_cap < need; new_cap = new_cap * 2) { }
    
    var new_buf: u64 = heap_alloc((new_cap + 1) * sizeof(u8));
    if (new_buf == 0) { return 0; }
    
    if (sb->len > 0) {
        sb_copy_bytes(new_buf, sb->ptr, sb->len);
    }
    *(*u8)(new_buf + sb->len) = 0;
    
    sb->ptr = new_buf;
    sb->cap = new_cap;
    return 1;
}

impl StringBuilder {
    // 초기화 (스택/힙 공용)
    func init(self: *StringBuilder, cap: u64) -> u64 {
        var c: u64 = cap;
        if (c < 8) { c = 8; }
        
        var buf: u64 = heap_alloc((c + 1) * sizeof(u8));
        if (buf == 0) { return 0; }
        
        self->ptr = buf;
        self->len = 0;
        self->cap = c;
        *(*u8)buf = 0;
        return 1;
    }

    // 생성
    func new(cap: u64) -> u64 {
        var sb: *StringBuilder = (*StringBuilder)heap_alloc(sizeof(StringBuilder));
        if (sb == 0) { return 0; }
        if (!StringBuilder_init(sb, cap)) { return 0; }
        return (u64)sb;
    }
    
    // 초기화
    func clear(self: *StringBuilder) -> u64 {
        self->len = 0;
        *(*u8)self->ptr = 0;
        return 0;
    }
    
    // 길이
    func len(self: *StringBuilder) -> u64 {
        return self->len;
    }
    
    // 포인터 (NUL-terminated)
    func ptr(self: *StringBuilder) -> u64 {
        return self->ptr;
    }
    
    // 바이트 추가
    func append_bytes(self: *StringBuilder, p: u64, n: u64) -> u64 {
        if (n == 0) { return 0; }
        
        if (!sb_ensure_cap(self, n)) { return 0; }
        
        sb_copy_bytes(self->ptr + self->len, p, n);
        self->len = self->len + n;
        *(*u8)(self->ptr + self->len) = 0;
        return 0;
    }
    
    // C 문자열 추가
    func append_cstr(self: *StringBuilder, s: u64) -> u64 {
        var n: u64 = str_len(s);
        return StringBuilder_append_bytes(self, s, n);
    }

    // append 별칭 (C 문자열)
    func append(self: *StringBuilder, s: u64) -> u64 {
        return StringBuilder_append_cstr(self, s);
    }
    
    // u64 10진수 추가
    func append_u64_dec(self: *StringBuilder, x: u64) -> u64 {
        var buf: u64 = heap_alloc(32 * sizeof(u8));
        var i: u64 = 0;
        
        if (x == 0) {
            *(*u8)buf = 48;
            i = 1;
        } else {
            var t: u64 = x;
            for (; t > 0; t = t / 10) {
                *(*u8)(buf + i) = 48 + (t % 10);
                i = i + 1;
            }
        }
        
        // reverse in place
        var j: u64 = 0;
        var k: u64 = i - 1;
        for (; j < k; ) {
            var a: u64 = *(*u8)(buf + j);
            var b: u64 = *(*u8)(buf + k);
            *(*u8)(buf + j) = b;
            *(*u8)(buf + k) = a;
            j = j + 1;
            k = k - 1;
        }
        
        return StringBuilder_append_bytes(self, buf, i);
    }
}