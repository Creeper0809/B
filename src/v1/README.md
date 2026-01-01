# v1 bootstrap scaffold

This folder is a roadmap-aligned scaffold for the first bootstrap iteration.

Module map (from docs/roadmap.md):
- std/: OS wrappers + memory/string/number utils
- core/: Slice/Vec/label_gen and shared layouts
- emit/: output emitter (.asm buffer + file write)
- lex/: token/lexer
- parse/: symbol table + parser + expr/cond/stmt
- driver/: CLI entry / compilation pipeline

This is intentionally just structure + stubs; implement per roadmap and keep smoke tests under test/v1/smoke.
