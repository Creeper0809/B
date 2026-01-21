# v3_20 TODO

- [x] Convert AST codegen to System V ABI for params/calls.
- [x] Ensure build script uses -asm for stage0.
- [x] Force AST codegen for asm blocks to avoid SSA mismatch (v3_19/v3_20).
- [x] Backport SysV AST codegen to v3_19 for bootstrap.
- [x] Make std/os syscalls ABI-agnostic via module-qualified global arg slots.
- [ ] Add tests for SysV ABI argument passing (slices, >6 args).
