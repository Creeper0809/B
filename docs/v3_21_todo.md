# v3_21 TODO

- [x] Create v3_21 baseline from v3_20.
- [x] Replace SSA call info pointer arithmetic with struct access in builder.
- [x] Convert SSA builder arg/loop iterations from while to for.
- [x] Repair SSA builder file integrity after refactor.
- [x] Update v3_21 config.ini version fields.
- [x] Build v3_21 and pass test suite (94/94).
- [x] Stabilize SSA call_slice_store info across passes (builder/opt/mem2reg/regalloc/codegen/dump).
- [x] Refactor v3_21 main argv handling to struct-based layouts and sizeof allocations.
- [x] Fix bootstrap sizeof misparse with local layout structs; align heap_alloc; resolve runtime segfaults.
- [x] Replace SIZEOF_SSA_* usages with sizeof and remove unused constants.
- [x] Refactor std/vec to struct access and for-loop copy (sizeof(u64) elements).
- [x] Refactor std/hashmap to struct-based layout and sizeof allocations.
- [x] Refactor std/util stack trace to StackFrame struct + for-loops.
- [x] Normalize std/string_builder loop styles and sizeof(u8) buffers.
- [x] Refactor std/io print loops and remove tmp usage.
- [x] Refactor emitter/emitter state allocations and loop styles.
- [x] Normalize std/path allocations with sizeof(u8).
- [x] Convert compiler module-id helper loops to for.
