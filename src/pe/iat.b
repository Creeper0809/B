// pe/iat.b - Import Address Table generator
//
// Generates IAT (Import Address Table) and Import Directory for PE32+ files.

// ============================================================================
// Import Entry Structure
// ============================================================================

struct ImportEntry {
	dll_name_ptr: u64;    // Pointer to DLL name string
	dll_name_len: u64;    // Length of DLL name
	func_name_ptr: u64;   // Pointer to function name string
	func_name_len: u64;   // Length of function name
	hint: u64;            // Import hint (ordinal)
};

// Global import table
var iat_imports;          // Vec<ImportEntry>
var iat_initialized;

// Initialize IAT builder
func iat_init() {
	if (iat_initialized != 0) {
		return 0;
	}
	
	// TODO: Initialize vector when vec module is available
	iat_imports = 0;
	iat_initialized = 1;
	
	return 0;
}

// Add import entry
func iat_add_import(dll_name, dll_len, func_name, func_len, hint) {
	iat_init();
	
	// TODO: Create ImportEntry and add to vector
	// For now, placeholder
	
	return 0;
}

// ============================================================================
// Common Windows API Imports
// ============================================================================

// Add all kernel32.dll imports needed for basic I/O
func iat_add_kernel32_basics() {
	// Process control
	iat_add_import("kernel32.dll", 12, "ExitProcess", 11, 0);
	
	// File I/O
	iat_add_import("kernel32.dll", 12, "CreateFileA", 11, 0);
	iat_add_import("kernel32.dll", 12, "ReadFile", 8, 0);
	iat_add_import("kernel32.dll", 12, "WriteFile", 9, 0);
	iat_add_import("kernel32.dll", 12, "CloseHandle", 11, 0);
	iat_add_import("kernel32.dll", 12, "GetFileSizeEx", 13, 0);
	
	// Standard handles
	iat_add_import("kernel32.dll", 12, "GetStdHandle", 12, 0);
	
	// Memory management
	iat_add_import("kernel32.dll", 12, "VirtualAlloc", 12, 0);
	iat_add_import("kernel32.dll", 12, "VirtualFree", 11, 0);
	
	return 0;
}

// ============================================================================
// IAT Generation
// ============================================================================

// Calculate size needed for Import Directory + IAT
func iat_calculate_size() {
	iat_init();
	
	// TODO: Calculate based on number of imports
	// For now, estimate for kernel32.dll with 9 functions:
	//
	// Import Directory:
	//   - 1 descriptor (kernel32.dll): 20 bytes
	//   - 1 null terminator: 20 bytes
	//   Total: 40 bytes
	//
	// Import Name Table (INT):
	//   - 9 entries × 8 bytes: 72 bytes
	//   - 1 null terminator: 8 bytes
	//   Total: 80 bytes
	//
	// Import Address Table (IAT):
	//   - Same as INT: 80 bytes
	//
	// Hint/Name structures:
	//   - Each: 2 bytes (hint) + name + 1 (null) + padding
	//   - ExitProcess: 2 + 11 + 1 + 2 = 16
	//   - CreateFileA: 2 + 11 + 1 + 2 = 16
	//   - ReadFile: 2 + 8 + 1 + 1 = 12 → 14 (align)
	//   - WriteFile: 2 + 9 + 1 = 12 → 14 (align)
	//   - CloseHandle: 2 + 11 + 1 + 2 = 16
	//   - GetFileSizeEx: 2 + 13 + 1 = 16
	//   - GetStdHandle: 2 + 12 + 1 + 1 = 16
	//   - VirtualAlloc: 2 + 12 + 1 + 1 = 16
	//   - VirtualFree: 2 + 11 + 1 + 2 = 16
	//   Total: ~140 bytes
	//
	// DLL names:
	//   - "kernel32.dll\0": 13 bytes → 14 (align)
	//
	// Grand total: 40 + 80 + 80 + 140 + 14 = 354 bytes
	// Round up to 512 (file alignment): 512 bytes
	
	return 512;
}

// Write Import Directory to buffer
func iat_write_import_directory(buf, offset, base_rva) {
	// TODO: Implement in Phase 0.3
	//
	// Structure:
	// 1. Import Descriptor for kernel32.dll
	//    - OriginalFirstThunk (RVA to INT)
	//    - TimeDateStamp (0)
	//    - ForwarderChain (0)
	//    - Name (RVA to "kernel32.dll")
	//    - FirstThunk (RVA to IAT)
	//
	// 2. Null terminator descriptor
	//
	// 3. INT (Import Name Table)
	//    - RVAs to Hint/Name structures
	//    - Null terminator
	//
	// 4. Hint/Name structures
	//    - Hint (u16)
	//    - Name (null-terminated string)
	//
	// 5. DLL name strings
	//    - "kernel32.dll\0"
	
	return 0;  // Placeholder
}

// Write IAT to buffer
func iat_write_iat(buf, offset, base_rva) {
	// TODO: Implement in Phase 0.3
	//
	// IAT has same structure as INT initially
	// Windows loader will replace RVAs with actual function addresses
	//
	// For each import:
	//   ptr64[buf + offset] = RVA to Hint/Name
	//   offset += 8
	//
	// Null terminator:
	//   ptr64[buf + offset] = 0
	
	return 0;  // Placeholder
}

// ============================================================================
// IAT Usage in Codegen
// ============================================================================

// Get IAT slot index for function name
func iat_get_slot_index(func_name, func_len) {
	// TODO: Look up function in import table
	// Return index for calculating call address
	//
	// Example:
	//   ExitProcess = 0
	//   CreateFileA = 1
	//   ReadFile = 2
	//   ...
	
	return 0;  // Placeholder
}

// Generate call instruction to imported function
// Returns assembly string like: "call [rel IAT_ExitProcess]"
func iat_gen_call(func_name, func_len) {
	// TODO: Generate proper call instruction
	// For now, placeholder
	
	return 0;  // Placeholder
}
