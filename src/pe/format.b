// pe/format.b - PE32+ (Portable Executable) file format structures
//
// Reference: Microsoft PE/COFF Specification
// https://docs.microsoft.com/en-us/windows/win32/debug/pe-format
//
// PE32+ is the 64-bit variant of the PE format used by Windows executables.

// ============================================================================
// DOS Header (IMAGE_DOS_HEADER)
// ============================================================================

// Offset 0x00, size 64 bytes
// First structure in every PE file for DOS compatibility
const DOS_HEADER_SIZE = 64;
const DOS_SIGNATURE = 23117;  // "MZ" (0x5A4D)
const DOS_PE_OFFSET = 60;      // Offset to PE header (at offset 0x3C)

// ============================================================================
// PE Signature
// ============================================================================

const PE_SIGNATURE = 17744;  // "PE\0\0" (0x00004550)

// ============================================================================
// COFF File Header (IMAGE_FILE_HEADER)
// ============================================================================

// Offset after PE signature, size 20 bytes
const COFF_HEADER_SIZE = 20;

// Machine types
const IMAGE_FILE_MACHINE_AMD64 = 34404;  // 0x8664 (x64)

// Characteristics flags
const IMAGE_FILE_EXECUTABLE_IMAGE = 2;        // 0x0002 (file is executable)
const IMAGE_FILE_LARGE_ADDRESS_AWARE = 32;   // 0x0020 (can handle >2GB addresses)

// ============================================================================
// Optional Header (IMAGE_OPTIONAL_HEADER64)
// ============================================================================

// Size: 240 bytes (for PE32+)
const OPTIONAL_HEADER_SIZE = 240;

// Magic values
const IMAGE_NT_OPTIONAL_HDR64_MAGIC = 523;  // 0x020B (PE32+)

// Subsystem values
const IMAGE_SUBSYSTEM_WINDOWS_CUI = 3;  // Console application

// DLL Characteristics
const IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE = 64;      // 0x0040 (ASLR)
const IMAGE_DLLCHARACTERISTICS_NX_COMPAT = 256;        // 0x0100 (DEP)
const IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE = 32768;  // 0x8000

// ============================================================================
// Section Header (IMAGE_SECTION_HEADER)
// ============================================================================

// Size: 40 bytes per section
const SECTION_HEADER_SIZE = 40;

// Section characteristics
const IMAGE_SCN_CNT_CODE = 32;                    // 0x00000020 (.text)
const IMAGE_SCN_CNT_INITIALIZED_DATA = 64;       // 0x00000040 (.data, .rdata)
const IMAGE_SCN_CNT_UNINITIALIZED_DATA = 128;    // 0x00000080 (.bss)
const IMAGE_SCN_MEM_EXECUTE = 536870912;         // 0x20000000 (executable)
const IMAGE_SCN_MEM_READ = 1073741824;           // 0x40000000 (readable)
const IMAGE_SCN_MEM_WRITE = 2147483648;          // 0x80000000 (writable)

// ============================================================================
// Import Directory
// ============================================================================

// IMAGE_IMPORT_DESCRIPTOR size: 20 bytes
const IMPORT_DESCRIPTOR_SIZE = 20;

// ============================================================================
// Data Directory Indices
// ============================================================================

const IMAGE_DIRECTORY_ENTRY_IMPORT = 1;    // Import table

// ============================================================================
// Standard PE Layout
// ============================================================================

// Base address for PE32+ executables
const IMAGE_BASE = 5368709120;  // 0x140000000 (standard for x64)

// Section alignment (memory)
const SECTION_ALIGNMENT = 4096;  // 4 KB

// File alignment (disk)
const FILE_ALIGNMENT = 512;  // 512 bytes

// ============================================================================
// Helper Functions
// ============================================================================

// Align value up to alignment boundary
func pe_align(value, alignment) {
	var remainder = value % alignment;
	if (remainder == 0) {
		return value;
	}
	return value + alignment - remainder;
}

// Calculate size of headers (DOS + PE + COFF + Optional + Sections)
func pe_headers_size(num_sections) {
	// DOS header (64) + PE sig (4) + COFF (20) + Optional (240) + Section headers
	var base = 64 + 4 + 20 + 240;
	return base + (num_sections * 40);
}

// ============================================================================
// PE Builder State
// ============================================================================

// Global state for PE generation
var pe_text_rva;
var pe_text_size;
var pe_data_rva;
var pe_data_size;
var pe_rdata_rva;
var pe_rdata_size;
var pe_idata_rva;
var pe_idata_size;

// Entry point RVA
var pe_entry_rva;

// Import table state
var pe_import_names;    // Vec of imported function names
var pe_import_dlls;     // Vec of DLL names

// Initialize PE builder
func pe_init() {
	pe_text_rva = 0;
	pe_text_size = 0;
	pe_data_rva = 0;
	pe_data_size = 0;
	pe_rdata_rva = 0;
	pe_rdata_size = 0;
	pe_idata_rva = 0;
	pe_idata_size = 0;
	pe_entry_rva = 0;
	
	// TODO: Initialize vectors when needed
	pe_import_names = 0;
	pe_import_dlls = 0;
	
	return 0;
}

// Add imported function (for IAT generation)
func pe_add_import(dll_name, dll_len, func_name, func_len) {
	// TODO: Store in vectors for IAT generation (Phase 0.3)
	return 0;
}

// Calculate Import Address Table size
func pe_iat_size() {
	// TODO: Calculate based on number of imports (Phase 0.3)
	// For now, reserve space for common imports
	// Each entry: 8 bytes (RVA to import name)
	// Terminator: 8 bytes (null)
	// Estimate: 10 functions + terminator = 88 bytes
	return 88;
}

// ============================================================================
// PE File Generation (Skeleton)
// ============================================================================

// Generate complete PE32+ file
// Returns: (ptr, len) of PE binary data
func pe_generate(text_data, text_len, data_data, data_len) {
	// TODO: Implement full PE generation (Phase 0.3)
	// For now, this is a placeholder
	//
	// Steps:
	// 1. Calculate section sizes and RVAs
	// 2. Write DOS header + stub
	// 3. Write PE signature
	// 4. Write COFF header
	// 5. Write Optional header
	// 6. Write Section headers (.text, .data, .rdata, .idata)
	// 7. Write section contents
	// 8. Write Import Directory & IAT
	
	return 0;  // (ptr=0, len=0) - not implemented yet
}
