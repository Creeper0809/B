// v3_hosted: AST lowering (Simplified for v3 self-hosting)
//
// NOTE: Generic and comptime features have been moved to v4.
// This pass now only performs basic AST traversal for future extensions.

import v3_hosted.ast;
import vec;

// Placeholder: lower_program does nothing in simplified v3.
// Returns 0 on success.
func lower_program(prog) {
return 0;
}

// Stub for compatibility: always returns 0 (not found).
func lw_find_generic_struct_typefn_entry(prog, name_ptr, name_len) {
return 0;
}
// Stub: returns 0 (no template decl).
func lw_typefn_entry_templ_decl(e) {
	return 0;
}

// Stub: returns 0 (arity 0).
func lw_typefn_entry_arity(e) {
	return 0;
}

// Stub: returns 0 (no typefn decl).
func lw_typefn_entry_typefn_decl(e) {
	return 0;
}