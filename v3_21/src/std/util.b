// util.b - Utility functions for v3.8

import std.io;
import std.str;
import std.path;
import std.char;

// ============================================
// Stack Trace
// ============================================

// Stack frame: [func_name, func_name_len, file_name, file_name_len, line]
const STACK_TRACE_MAX_DEPTH = 128;

struct StackFrame {
	func_name: u64;
	func_name_len: u64;
	file_name: u64;
	file_name_len: u64;
	line: u64;
}

var g_stack_frames;
var g_stack_depth;
var g_stack_initialized;

var g_last_error_msg;
var g_last_error_len;

var g_error_buffer;
var g_error_buffer_pos;
var g_capturing_error;

// Parsing context (for user-facing error messages)
var g_current_func_name;
var g_current_func_name_len;
var g_current_func_line;

func init_stack_trace() {
	if (g_stack_initialized) {
		return;
	}
	g_stack_frames = heap_alloc(STACK_TRACE_MAX_DEPTH * sizeof(StackFrame));
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
    
	var frame_ptr: u64 = g_stack_frames + (g_stack_depth * sizeof(StackFrame));
	var frame: *StackFrame = (*StackFrame)frame_ptr;
	frame->func_name = func_name;
	frame->func_name_len = func_name_len;
	frame->file_name = file_name;
	frame->file_name_len = file_name_len;
	frame->line = line;
    
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
    
	for (var i: u64 = g_stack_depth; i > 0; i = i - 1) {
		var frame_index: u64 = i - 1;
		var frame_ptr: u64 = g_stack_frames + (frame_index * sizeof(StackFrame));
		var frame: *StackFrame = (*StackFrame)frame_ptr;
		var func_name: u64 = frame->func_name;
		var func_name_len: u64 = frame->func_name_len;
		var file_name: u64 = frame->file_name;
		var file_name_len: u64 = frame->file_name_len;
		var line: u64 = frame->line;
        
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

func set_parsing_context(func_name, func_name_len, line) {
	g_current_func_name = func_name;
	g_current_func_name_len = func_name_len;
	g_current_func_line = line;
}

func begin_error_capture() {
	if (g_error_buffer == 0) {
		g_error_buffer = heap_alloc(512 * sizeof(u8));
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
    
	// Print user code context first
	if (g_current_func_name != 0) {
		emit_stderr_nl();
		emit_stderr("Parsing context:", 16);
		emit_stderr_nl();
		emit_stderr("  -> In function: ", 18);
		emit_stderr(g_current_func_name, g_current_func_name_len);
		emit_stderr(" (line ", 7);
		emit_i64_stderr(g_current_func_line);
		emit_stderr(")", 1);
		emit_stderr_nl();
	}
    
	// Print compiler trace
	emit_stderr_nl();
	emit_stderr("Compiler internal trace:", 24);
	emit_stderr_nl();
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
			for (var i: u64 = 0; i < len; i++) {
				*(*u8)(g_error_buffer + g_error_buffer_pos) = *(*u8)(s + i);
				g_error_buffer_pos = g_error_buffer_pos + 1;
			}
		}
	} else {
		sys_write(2, s, len);
	}
}

func emit_stderr_nl() {
	var nl = heap_alloc(sizeof(u8));
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
	var buf = heap_alloc(sizeof(u8));
	*(*u8)buf = c;
	sys_write(1, buf, 1);
}

func emit_u64(n) {
	if (n == 0) {
		emit("0", 1);
		return;
	}
	var buf = heap_alloc(32 * sizeof(u8));
	var i = 0;
	var t = n;
	for (; t > 0; ) {
		*(*u8)(buf + i) = 48 + (t % 10);
		t = t / 10;
		i = i + 1;
	}
	var j: i64 = (i64)i - 1;
	for (; j >= 0; j = j - 1) {
		sys_write(1, buf + (u64)j, 1);
	}
}

func emit_u64_stderr(n) {
	if (n == 0) {
		emit_stderr("0", 1);
		return;
	}
	var buf = heap_alloc(32 * sizeof(u8));
	var i = 0;
	var t = n;
	for (; t > 0; ) {
		*(*u8)(buf + i) = 48 + (t % 10);
		t = t / 10;
		i = i + 1;
	}
	var j: i64 = (i64)i - 1;
	for (; j >= 0; j = j - 1) {
		emit_stderr(buf + (u64)j, 1);
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
	var nl = heap_alloc(sizeof(u8));
	*(*u8)nl = 10;
	sys_write(1, nl, 1);
}


