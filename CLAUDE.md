# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**B Language Compiler** - A self-hosting compiler for the B language (Basm), which is designed as a "high-level assembly" language with explicit control over registers and memory while maintaining C-like readability. This is step 2 toward building Bpp.

The project follows a versioned development approach with the current active version being **v3_19**. Each version is self-hosting and uses the previous version to bootstrap itself.

## Build Commands

### Building the Current Version (v3_19)

The primary build script handles compilation, self-hosting verification, and testing:

```bash
cd v3_19
bash build_and_test.sh
```

This script performs:
1. Compiles v3_19 source using the previous version's compiler
2. Self-hosting stage 1: Compiles itself with stage0
3. Self-hosting stage 2: Compiles itself with stage1
4. Verifies stage1 and stage2 produce identical assembly
5. Runs the test suite
6. Generates executables in `bin/` and assembly in `build/`

### Running Tests Only

```bash
cd v3_19
bash test/run_tests.sh ../bin/v3_19_stage1
```

Test files are located in `v3_19/test/b/` and use naming convention `##_feature_name.b`. Tests include directives:
- `// Expect exit code: N` - Expected exit code
- `// Mode: ssa|nossa` - Code generation mode
- `// Opt: O0|O1` - Optimization level

### Manual Compilation

```bash
# Compile to assembly
./bin/v3_19_stage1 -asm source.b > output.asm

# Compile and dump SSA IR
./bin/v3_19_stage1 -dump-ssa source.b

# Compile and dump 3-address IR
./bin/v3_19_stage1 -dump-ir source.b

# Compile with O1 optimizations
./bin/v3_19_stage1 -O1 -asm source.b > output.asm

# Full build pipeline
./bin/v3_19_stage1 source.b        # Creates source.s, source.o, source.out
nasm -felf64 source.s -o source.o
ld source.o -o source.out
```

## Architecture

### Two-Path Code Generation

The compiler supports **two distinct code generation paths**:

1. **AST-based Codegen** (older, simpler):
   - Direct translation from AST to assembly
   - Located in `v3_19/src/emitter/` directory
   - Files: `gen_expr.b`, `gen_stmt.b`, `emitter.b`, `symtab.b`, `typeinfo.b`
   - Always implement features here FIRST before SSA

2. **SSA-based Codegen** (newer, optimizable):
   - Constructs SSA IR from AST, then generates assembly
   - Located in `v3_19/src/ssa/` directory
   - Key files:
     - `builder.b` - Builds SSA IR from AST
     - `codegen.b` - Generates assembly from SSA IR
     - `mem2reg.b` - Promotion of stack allocations to SSA values
     - `regalloc.b` - Register allocation
     - `opt_o1.b` - Optimization passes (constant prop, DCE)
     - `dump.b` - IR dumping for debugging

### Compiler Pipeline

```
Source (.b) → Lexer → Parser → AST
                                ↓
                    ┌───────────┴────────────┐
                    ↓                        ↓
              AST Emitter                SSA Builder
             (emitter/*.b)              (ssa/builder.b)
                    ↓                        ↓
                Assembly                  SSA IR
                                            ↓
                                    SSA Optimizations
                                      (ssa/opt_o1.b)
                                            ↓
                                    SSA Codegen
                                    (ssa/codegen.b)
                                            ↓
                                        Assembly
```

### Directory Structure

```
v3_19/
├── src/
│   ├── main.b           - Entry point, CLI arg parsing
│   ├── compiler.b       - Module loading, file I/O, global state
│   ├── lexer.b          - Tokenization
│   ├── ast.b            - AST node definitions
│   ├── types.b          - Type system definitions
│   ├── codegen.b        - Top-level codegen dispatch
│   ├── opt.b            - Optimization level control
│   ├── ssa.b            - SSA entry points
│   ├── parser/          - Parsing (decl.b, stmt.b, expr.b, type.b, util.b)
│   ├── emitter/         - AST-based code generation
│   ├── ssa/             - SSA IR construction and codegen
│   └── std/             - Standard library (vec, str, hashmap, io, etc.)
├── test/
│   ├── b/               - Test programs (##_name.b)
│   ├── ir/              - IR transformation tests
│   └── run_tests.sh     - Test runner
├── build/               - Build artifacts (.asm, .o files)
├── config.ini           - Version configuration
├── build_and_test.sh    - Main build script
└── syntax.md            - Language syntax reference

bin/                     - Compiled binaries
├── v3_19_stage0         - Compiled by previous version
├── v3_19_stage1         - Self-hosted (use this for development)
└── v3_*_stage*          - Other version stages

old/v3_*/                - Previous versions (archived)
```

### Module System

The compiler supports a module/import system:
- `import module.name` - Imports from `v3_19/src/` directory
- `import std.vec` - Loads `v3_19/src/std/vec.b`
- Module resolution is controlled by `compiler.b`
- Global state tracks loaded modules, functions, structs, consts
- Symbol mangling uses module prefixes to avoid conflicts

## Critical Workflow

**ALWAYS follow this implementation order:**

1. **Implement AST-based version FIRST** (in `emitter/`)
   - Simpler, direct code generation
   - Easier to test and debug
   - Files: `gen_expr.b`, `gen_stmt.b`

2. **Write tests** in `v3_19/test/b/`
   - Test the AST version with `Mode: nossa`
   - Verify correctness before moving to SSA

3. **Only then implement SSA version** (in `ssa/`)
   - Add SSA IR construction in `builder.b`
   - Add codegen support in `codegen.b`
   - Test with `Mode: ssa`

**Do not skip the AST implementation step.** This is a hard requirement in the project workflow.

## Coding Standards

From `.github/instructions/common.instructions.md`:

### Core Philosophy
- **Explicit Control**: No hidden control flow or allocations. All side effects must be explicit.
- **Zero-Overhead**: Prefer simple logic over abstractions. Use flat data structures.
- **No Generic Names**: Avoid `tmp`, `temp`. Use descriptive variable names.

### Function Design
- **Single Responsibility Principle**: One function = one task
- **Flatten Logic**: Use guard clauses to avoid deep nesting
  ```b
  // Bad
  if (A) { if (B) { ... } }

  // Good
  if (!A) { return; }
  if (!B) { return; }
  ...
  ```

### Control Flow
- **Prefer switch/match over if-else chains** for enums/constants
  - Enables O(1) jump table optimization
  - Ensures case coverage

### Debugging
- **Maximize debug output** - Compiler logic is hard to trace
- Print "Entering function X", "Token consumed: Y", "AST Created: Z"
- Wrap in `if (DEBUG_FLAG) { ... }`
- Error messages must include file, line, column, and token context

### Data Structures
- Use `enum` for constants instead of integer macros
- Use `struct` for composite data
- Use `*tagged` pointers for tagged unions (limited support)

## Post-Implementation Tasks

After completing ANY coding task, you **MUST**:

1. **Update TODO List**: `/docs/v3_19_todo.md`
   - Mark completed tasks with `[x]`
   - Add new tasks if the work reveals future requirements

2. **Write Devlog**: `/pages/devlog-YYYY-MM-DD.md`
   - **Required** for all coding tasks
   - **Comprehensive detail required when a Phase is completed**
   - Use STAR format:
     - **Situation**: Why was this needed? What problem?
     - **Task**: Implementation goals, technical requirements
     - **Action**: Code changes, files modified, challenges, troubleshooting
     - **Result**: How it works, architecture decisions, test results

## Language Features (B v3.19)

- **Types**: `u8`, `u16`, `u32`, `u64`, `i64`, `char` (alias for u8)
- **Pointers**: `*T`, `**T`, `*tagged T`, `*tagged(Layout) T`
- **Arrays**: `[N]T` (fixed size)
- **Slices**: `[]T` (pointer + length view)
- **Structs**: `struct Name { field: Type; ... }`
- **Enums**: `enum Name { VARIANT1, VARIANT2 }`
- **Impl blocks**: `impl StructName { func method(self: *StructName) { ... } }`
- **Control flow**: `if`/`else`, `while`, `for`, `switch`/`case`/`default`, `break`, `continue`
- **Operators**: Full C-like arithmetic, bitwise, logical, comparison
- **Inline assembly**: `asm { ... }` blocks
- **Macros**: `sizeof(T)`, `__LINE__`

See `v3_19/syntax.md` for complete syntax reference.

## Important Notes

- **Platform**: Currently Linux x86-64 only (Windows support in progress)
- **Output**: x86-64 NASM assembly
- **Self-hosting**: Each version must compile itself identically in 2 stages
- **Versioning**: v3_19 is the current active version. Old versions in `old/` are archived.
- **Language**: Comments and devlogs in Korean. Code/docs in English.
- **No backward compatibility**: Each version can have breaking changes from previous versions.

## Common Tasks

### Adding a new language feature
1. Update AST definitions in `src/ast.b` if needed
2. Update parser in `src/parser/*.b`
3. Implement AST codegen in `src/emitter/gen_*.b`
4. Write tests in `test/b/##_feature_name.b`
5. Run tests to verify
6. Implement SSA version in `src/ssa/builder.b` and `src/ssa/codegen.b`
7. Test SSA path with `Mode: ssa`
8. Update `docs/v3_19_todo.md` and write devlog

### Debugging a test failure
1. Check test output in `v3_19/build/test_results/`
2. Use `-dump-ssa` or `-dump-ir` flags to inspect IR
3. Compile manually with verbose output
4. Compare generated assembly with expected behavior
5. Use debug prints (check for debug flags in source)

### Bootstrapping a new version
1. Copy `v3_N` to `v3_N+1`
2. Update `config.ini` with new VERSION and PREV_VERSION
3. Make changes in new version
4. Run `build_and_test.sh` to verify self-hosting
5. Move old version to `old/v3_N/`
