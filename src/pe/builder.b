// pe/builder.b - PE32+ binary builder
//
// Generates complete PE32+ executable files from code/data sections.

import pe.format;

// ============================================================================
// DOS Header + Stub
// ============================================================================

// Generate DOS header with stub program
// The stub prints "This program cannot be run in DOS mode."
func pe_write_dos_header(buf) {
	// DOS header (64 bytes)
	// Signature: "MZ"
	ptr16[buf + 0] = 23117;  // 0x5A4D "MZ"
	
	// Last page bytes
	ptr16[buf + 2] = 144;  // 0x0090
	
	// Pages in file
	ptr16[buf + 4] = 3;
	
	// Relocations
	ptr16[buf + 6] = 0;
	
	// Header size in paragraphs
	ptr16[buf + 8] = 4;
	
	// Min/Max paragraphs
	ptr16[buf + 10] = 0;
	ptr16[buf + 12] = 65535;
	
	// Initial SS:SP
	ptr16[buf + 14] = 0;
	ptr16[buf + 16] = 184;  // 0x00B8
	
	// Checksum
	ptr16[buf + 18] = 0;
	
	// Initial CS:IP
	ptr32[buf + 20] = 0;
	
	// Relocation table offset
	ptr16[buf + 24] = 64;  // 0x0040
	
	// Overlay number
	ptr16[buf + 26] = 0;
	
	// Reserved (28 bytes)
	var i = 28;
	while (i < 60) {
		ptr8[buf + i] = 0;
		i = i + 1;
	}
	
	// PE header offset (at 0x3C)
	ptr32[buf + 60] = 128;  // PE header starts at offset 128 (0x80)
	
	// DOS stub (64 bytes, from offset 64 to 128)
	// Simple stub: int 21h to exit
	ptr8[buf + 64] = 14;   // push cs
	ptr8[buf + 65] = 31;   // pop ds
	ptr8[buf + 66] = 186;  // mov dx, ...
	ptr16[buf + 67] = 14;  // offset to message
	ptr8[buf + 69] = 180;  // mov ah, 09h
	ptr8[buf + 70] = 9;
	ptr8[buf + 71] = 205;  // int 21h
	ptr8[buf + 72] = 33;
	ptr8[buf + 73] = 184;  // mov ax, 4C01h
	ptr16[buf + 74] = 19457;
	ptr8[buf + 76] = 205;  // int 21h
	ptr8[buf + 77] = 33;
	
	// Message: "This program cannot be run in DOS mode.\r\r\n$"
	var msg = "This program cannot be run in DOS mode.\r\r\n$";
	var msg_len = 44;
	i = 0;
	while (i < msg_len) {
		ptr8[buf + 78 + i] = ptr8[msg + i];
		i = i + 1;
	}
	
	// Padding to 128 bytes
	i = 78 + msg_len;
	while (i < 128) {
		ptr8[buf + i] = 0;
		i = i + 1;
	}
	
	return 128;  // Return size written
}

// ============================================================================
// PE Headers
// ============================================================================

// Write PE signature + COFF header + Optional header
func pe_write_headers(buf, offset, num_sections, code_size, data_size, entry_rva) {
	var start = offset;
	
	// PE Signature (4 bytes): "PE\0\0"
	ptr32[buf + offset] = 17744;  // 0x00004550
	offset = offset + 4;
	
	// COFF Header (20 bytes)
	// Machine
	ptr16[buf + offset] = 34404;  // AMD64 (0x8664)
	offset = offset + 2;
	
	// NumberOfSections
	ptr16[buf + offset] = num_sections;
	offset = offset + 2;
	
	// TimeDateStamp
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// PointerToSymbolTable
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// NumberOfSymbols
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// SizeOfOptionalHeader
	ptr16[buf + offset] = 240;  // PE32+ optional header size
	offset = offset + 2;
	
	// Characteristics
	ptr16[buf + offset] = 34;  // EXECUTABLE_IMAGE | LARGE_ADDRESS_AWARE
	offset = offset + 2;
	
	// Optional Header (240 bytes)
	// Magic (PE32+ = 0x020B)
	ptr16[buf + offset] = 523;
	offset = offset + 2;
	
	// Linker version
	ptr8[buf + offset] = 14;      // Major
	ptr8[buf + offset + 1] = 0;   // Minor
	offset = offset + 2;
	
	// SizeOfCode
	ptr32[buf + offset] = code_size;
	offset = offset + 4;
	
	// SizeOfInitializedData
	ptr32[buf + offset] = data_size;
	offset = offset + 4;
	
	// SizeOfUninitializedData
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// AddressOfEntryPoint
	ptr32[buf + offset] = entry_rva;
	offset = offset + 4;
	
	// BaseOfCode
	ptr32[buf + offset] = 4096;  // First section RVA
	offset = offset + 4;
	
	// ImageBase (8 bytes for PE32+)
	ptr64[buf + offset] = 5368709120;  // 0x140000000
	offset = offset + 8;
	
	// SectionAlignment
	ptr32[buf + offset] = 4096;
	offset = offset + 4;
	
	// FileAlignment
	ptr32[buf + offset] = 512;
	offset = offset + 4;
	
	// OS version
	ptr16[buf + offset] = 6;      // Major
	ptr16[buf + offset + 2] = 0;  // Minor
	offset = offset + 4;
	
	// Image version
	ptr16[buf + offset] = 0;
	ptr16[buf + offset + 2] = 0;
	offset = offset + 4;
	
	// Subsystem version
	ptr16[buf + offset] = 6;      // Major
	ptr16[buf + offset + 2] = 0;  // Minor
	offset = offset + 4;
	
	// Win32VersionValue
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// SizeOfImage (calculated later)
	ptr32[buf + offset] = 0;  // TODO: Calculate
	offset = offset + 4;
	
	// SizeOfHeaders
	ptr32[buf + offset] = 512;  // Aligned to file alignment
	offset = offset + 4;
	
	// CheckSum
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// Subsystem (Console)
	ptr16[buf + offset] = 3;
	offset = offset + 2;
	
	// DllCharacteristics
	ptr16[buf + offset] = 352;  // DYNAMIC_BASE | NX_COMPAT
	offset = offset + 2;
	
	// Stack reserve/commit (8 bytes each)
	ptr64[buf + offset] = 1048576;      // 1 MB reserve
	ptr64[buf + offset + 8] = 4096;     // 4 KB commit
	offset = offset + 16;
	
	// Heap reserve/commit (8 bytes each)
	ptr64[buf + offset] = 1048576;      // 1 MB reserve
	ptr64[buf + offset + 8] = 4096;     // 4 KB commit
	offset = offset + 16;
	
	// LoaderFlags
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// NumberOfRvaAndSizes
	ptr32[buf + offset] = 16;
	offset = offset + 4;
	
	// Data Directories (16 entries × 8 bytes = 128 bytes)
	// For now, all zeros (TODO: fill Import Directory)
	var i = 0;
	while (i < 128) {
		ptr8[buf + offset + i] = 0;
		i = i + 1;
	}
	offset = offset + 128;
	
	return offset - start;  // Return size written
}

// ============================================================================
// Section Headers
// ============================================================================

// Write section header
func pe_write_section_header(buf, offset, name, virt_size, virt_addr, raw_size, raw_offset, characteristics) {
	// Name (8 bytes, null-padded)
	var i = 0;
	while (i < 8) {
		if (i < ptr64[name + 8]) {  // name length
			ptr8[buf + offset + i] = ptr8[ptr64[name + 0] + i];
		} else {
			ptr8[buf + offset + i] = 0;
		}
		i = i + 1;
	}
	offset = offset + 8;
	
	// VirtualSize
	ptr32[buf + offset] = virt_size;
	offset = offset + 4;
	
	// VirtualAddress
	ptr32[buf + offset] = virt_addr;
	offset = offset + 4;
	
	// SizeOfRawData
	ptr32[buf + offset] = raw_size;
	offset = offset + 4;
	
	// PointerToRawData
	ptr32[buf + offset] = raw_offset;
	offset = offset + 4;
	
	// PointerToRelocations
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// PointerToLinenumbers
	ptr32[buf + offset] = 0;
	offset = offset + 4;
	
	// NumberOfRelocations
	ptr16[buf + offset] = 0;
	offset = offset + 2;
	
	// NumberOfLinenumbers
	ptr16[buf + offset] = 0;
	offset = offset + 2;
	
	// Characteristics
	ptr32[buf + offset] = characteristics;
	offset = offset + 4;
	
	return 40;  // Section header size
}

// ============================================================================
// PE Builder (Placeholder for Phase 0.3)
// ============================================================================

// Generate complete PE32+ file
func pe_build(text_data, text_len, data_data, data_len, entry_offset) {
	// TODO: Full implementation in Phase 0.3
	//
	// For now, return null to indicate "not implemented"
	// This will be filled in when we integrate with codegen
	
	return 0;
}
