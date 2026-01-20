// util.b - Utility functions for v3.8

import std.io;
import std.str;
import std.path;
import std.char;

// ============================================
// Error Handling
// ============================================

func panic() {
    emit_stderr("[PANIC] Compiler error - exiting", 33);
    emit_stderr_nl();
    print_stack_trace();
    var x = *(0);
}

func emit_stderr(s, len) {
    sys_write(2, s, len);
}

func emit_stderr_nl() {
    var nl = heap_alloc(1);
    *(*u8)nl = 10;
    sys_write(2, nl, 1);
}

func warn(msg, len) {
    emit_stderr("[WARN] ", 7);
    emit_stderr(msg, len);
    emit_stderr_nl();
}

// ============================================
// Output Utilities
// ============================================

func emit_char(c) {
    var buf = heap_alloc(1);
    *(*u8)buf = c;
    sys_write(1, buf, 1);
}

func emit_u64(n) {
    if (n == 0) {
        emit("0", 1);
        return;
    }
    var buf = heap_alloc(32);
    var i = 0;
    var t = n;
    while (t > 0) {
        *(*u8)(buf + i) = 48 + (t % 10);
        t = t / 10;
        i = i + 1;
    }
    var j = i - 1;
    while (j >= 0) {
        sys_write(1, buf + j, 1);
        j = j - 1;
    }
}

func emit_i64(n) {
    if (n < 0) {
        emit("-", 1);
        emit_u64(0 - n);
    } else {
        emit_u64(n);
    }
}

func emit_nl() {
    var nl = heap_alloc(1);
    *(*u8)nl = 10;
    sys_write(1, nl, 1);
}

// ============================================
// Stack Trace (재진입 방지 가드 포함)
// ============================================

const STACK_TRACE_MAX_DEPTH = 2048;

struct TraceEntry {
    func_name_ptr: u64,
    func_name_len: u64,
    file_name_ptr: u64,
    file_name_len: u64,
    line: u64,
}

var g_trace_stack: u64 = 0;  // Vec of TraceEntry
var g_trace_depth: u64 = 0;
var g_in_trace_logic: u64 = 0;  // 재진입 방지 가드

func push_trace(func_name: u64, file_name: u64, line: u64) {
    // 재진입 방지: 이미 트레이스 로직 안에 있으면 즉시 리턴
    if (g_in_trace_logic) {
        return;
    }
    
    // 가드 잠금
    g_in_trace_logic = 1;
    
    // 초기화
    if (g_trace_stack == 0) {
        g_trace_stack = vec_new();
        g_trace_depth = 0;
    }
    
    // 깊이 제한
    if (g_trace_depth >= STACK_TRACE_MAX_DEPTH) {
        g_in_trace_logic = 0;
        return;
    }
    
    // TraceEntry 생성
    var entry: *TraceEntry = (*TraceEntry)heap_alloc(40);  // 8*5=40
    entry->func_name_ptr = func_name;
    entry->func_name_len = str_len(func_name);
    entry->file_name_ptr = file_name;
    entry->file_name_len = str_len(file_name);
    entry->line = line;
    
    vec_push(g_trace_stack, (u64)entry);
    g_trace_depth = g_trace_depth + 1;
    
    // 가드 해제
    g_in_trace_logic = 0;
}

func pop_trace() {
    // 재진입 방지
    if (g_in_trace_logic) {
        return;
    }
    
    g_in_trace_logic = 1;
    
    if (g_trace_stack == 0) {
        g_in_trace_logic = 0;
        return;
    }
    
    if (g_trace_depth == 0) {
        g_in_trace_logic = 0;
        return;
    }
    
    vec_pop(g_trace_stack);
    g_trace_depth = g_trace_depth - 1;
    
    g_in_trace_logic = 0;
}

func print_stack_trace() {
    if (g_in_trace_logic) {
        return;
    }
    
    g_in_trace_logic = 1;
    
    emit_stderr("\n========== STACK TRACE ==========\n", 36);
    
    if (g_trace_stack == 0) {
        emit_stderr("(no trace data)\n", 16);
        g_in_trace_logic = 0;
        return;
    }
    
    var i: u64 = g_trace_depth;
    while (i > 0) {
        i = i - 1;
        var entry: *TraceEntry = (*TraceEntry)vec_get(g_trace_stack, i);
        
        emit_stderr("  at ", 5);
        emit_stderr(entry->func_name_ptr, entry->func_name_len);
        emit_stderr(" (", 2);
        emit_stderr(entry->file_name_ptr, entry->file_name_len);
        emit_stderr(":", 1);
        emit_u64_stderr(entry->line);
        emit_stderr(")\n", 2);
    }
    
    emit_stderr("=================================\n", 34);
    
    g_in_trace_logic = 0;
}

func emit_u64_stderr(n: u64) {
    if (n == 0) {
        emit_stderr("0", 1);
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
        sys_write(2, buf + j, 1);
        j = j - 1;
    }
}

// ============================================
// Source Code Context Printing (for errors)
// ============================================

func print_source_line(src_ptr: u64, src_len: u64, target_line: u64) {
    if (src_ptr == 0) { return; }
    
    var line: u64 = 1;
    var line_start: u64 = 0;
    var i: u64 = 0;
    
    // Find the target line
    while (i < src_len) {
        if (line == target_line) {
            // Found target line, find its end
            line_start = i;
            while (i < src_len) {
                if (*(*u8)(src_ptr + i) == 10) { break; }
                i = i + 1;
            }
            // Print line number
            emit_stderr("  ", 2);
            emit_u64_stderr(line);
            emit_stderr(" | ", 3);
            // Print line content
            emit_stderr(src_ptr + line_start, i - line_start);
            emit_stderr_nl();
            return;
        }
        
        if (*(*u8)(src_ptr + i) == 10) {
            line = line + 1;
        }
        i = i + 1;
    }
}

func print_error_caret(col: u64) {
    emit_stderr("    | ", 6);
    var i: u64 = 1;
    while (i < col) {
        emit_stderr(" ", 1);
        i = i + 1;
    }
    emit_stderr("^\n", 2);
}

func print_source_context(src_ptr: u64, src_len: u64, line: u64, col: u64) {
    if (src_ptr == 0) { return; }
    
    emit_stderr_nl();
    
    // Print previous line for context
    if (line > 1) {
        print_source_line(src_ptr, src_len, line - 1);
    }
    
    // Print error line
    print_source_line(src_ptr, src_len, line);
    
    // Print caret
    print_error_caret(col);
    
    // Print next line for context
    print_source_line(src_ptr, src_len, line + 1);
    
    emit_stderr_nl();
}


