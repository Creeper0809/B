// util.b - Utility functions for v3.8

import std.io;
import std.str;
import std.path;
import std.char;

// ============================================
// Stack Trace
// ============================================

// Stack frame: [func_name:8][func_name_len:8][file_name:8][file_name_len:8][line:8] = 40 bytes
const STACK_TRACE_MAX_DEPTH = 128;
const STACK_FRAME_SIZE = 40;

var g_stack_frames;
var g_stack_depth;
var g_stack_initialized;

var g_last_error_msg;
var g_last_error_len;

var g_error_buffer;
var g_error_buffer_pos;
var g_capturing_error;

func init_stack_trace() {
    if (g_stack_initialized) {
        return;
    }
    g_stack_frames = heap_alloc(STACK_TRACE_MAX_DEPTH * STACK_FRAME_SIZE);
    g_stack_depth = 0;
    g_stack_initialized = 1;
}

func push_trace(func_name, file_name, line) {
    if (!g_stack_initialized) {
        init_stack_trace();
    }
    
    if (g_stack_depth >= STACK_TRACE_MAX_DEPTH) {
        return;
    }
    
    var func_name_len = str_len(func_name);
    var file_name_len = str_len(file_name);
    
    var frame_ptr = g_stack_frames + (g_stack_depth * STACK_FRAME_SIZE);
    *(*u64)(frame_ptr + 0) = func_name;
    *(*u64)(frame_ptr + 8) = func_name_len;
    *(*u64)(frame_ptr + 16) = file_name;
    *(*u64)(frame_ptr + 24) = file_name_len;
    *(*u64)(frame_ptr + 32) = line;
    
    g_stack_depth = g_stack_depth + 1;
}

func pop_trace() {
    if (g_stack_depth > 0) {
        g_stack_depth = g_stack_depth - 1;
    }
}

func print_stack_trace() {
    if (!g_stack_initialized) {
        emit_stderr("  (no stack trace available)", 28);
        emit_stderr_nl();
        return;
    }
    
    if (g_stack_depth == 0) {
        emit_stderr("  (stack trace is empty)", 24);
        emit_stderr_nl();
        return;
    }
    
    emit_stderr("Stack trace (most recent call first):", 38);
    emit_stderr_nl();
    
    var i = g_stack_depth;
    while (i > 0) {
        i = i - 1;
        
        var frame_ptr = g_stack_frames + (i * STACK_FRAME_SIZE);
        var func_name = *(*u64)(frame_ptr + 0);
        var func_name_len = *(*u64)(frame_ptr + 8);
        var file_name = *(*u64)(frame_ptr + 16);
        var file_name_len = *(*u64)(frame_ptr + 24);
        var line = *(*u64)(frame_ptr + 32);
        
        emit_stderr("  at ", 5);
        emit_stderr(func_name, func_name_len);
        emit_stderr(" (", 2);
        emit_stderr(file_name, file_name_len);
        emit_stderr(":", 1);
        emit_i64_stderr(line);
        emit_stderr(")", 1);
        emit_stderr_nl();
    }
}

// ============================================
// Error Handling
// ============================================

func begin_error_capture() {
    if (g_error_buffer == 0) {
        g_error_buffer = heap_alloc(512);
    }
    g_error_buffer_pos = 0;
    g_capturing_error = 1;
}

func end_error_capture() {
    g_capturing_error = 0;
}

func set_error_context(msg, len) {
    g_last_error_msg = msg;
    g_last_error_len = len;
}

func emit_error(msg, len) {
    emit_stderr("[ERROR] ", 8);
    emit_stderr(msg, len);
    emit_stderr_nl();
    g_last_error_msg = msg;
    g_last_error_len = len;
}

func panic() {
    end_error_capture();
    print_stack_trace();
    
    if (g_error_buffer_pos > 0) {
        emit_stderr_nl();
        emit_stderr("Error details:", 14);
        emit_stderr_nl();
        sys_write(2, g_error_buffer, g_error_buffer_pos);
        emit_stderr_nl();
    }
    emit_stderr_nl();
    var x = *(0);
}

func emit_stderr(s, len) {
    if (g_capturing_error != 0) {
        if (g_error_buffer_pos + len < 512) {
            var i = 0;
            while (i < len) {
                *(*u8)(g_error_buffer + g_error_buffer_pos) = *(*u8)(s + i);
                g_error_buffer_pos = g_error_buffer_pos + 1;
                i = i + 1;
            }
        }
    } else {
        sys_write(2, s, len);
    }
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

func emit_u64_stderr(n) {
    if (n == 0) {
        emit_stderr("0", 1);
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
        emit_stderr(buf + j, 1);
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

func emit_i64_stderr(n) {
    if (n < 0) {
        emit_stderr("-", 1);
        emit_u64_stderr(0 - n);
    } else {
        emit_u64_stderr(n);
    }
}

func emit_nl() {
    var nl = heap_alloc(1);
    *(*u8)nl = 10;
    sys_write(1, nl, 1);
}


