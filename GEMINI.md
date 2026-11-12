Read and follow `AGENTS.md` at the repository root. It is the single source of agent instructions for this project. Skills are available under `.agents/skills/` (installed from `.aix/skills/` by `aix install`).

## Scoped instructions
Read these before working on matching files:
- `aix/languages/ridgun` (when touching **/*.ridgun, build.ridgun): read `.aix/instructions/languages/ridgun.md` — Use when writing, refactoring, or reviewing Ridgun (.ridgun) source files or build.ridgun: syntax rules, idiomatic -> pipeline chaining (xs map f -> filter g -> results), (+ _ _ +) sequence masks, -> () unit discard, _ =-free blocks, type signatures, guards, ADTs, parallel || DAGs, RMM1/RMM2 memory, regions, and stable/ridgunc ELF64 verification.
- `aix/tools/stable` (when touching build.ridgun, plugins/**/*.ridgun, .stable/plugins/**/*.ridgun): read `.aix/instructions/tools/stable.md` — Use when creating, editing, or running build.ridgun, stable plugins (plugins/*.ridgun, .stable/plugins/*.ridgun), custom stable tasks, dependencies, or library/executable builds with stable.

