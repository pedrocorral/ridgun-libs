---
id: RB-0001
title: Build, verify, test, and package ridgun-libs
status: approved
---
# RB-0001 — Build, verify, test, and package `ridgun-libs`

## Trigger
- Any modification to `src/main/ridgun/lib/*.ridgun`, `src/test/ridgun/test_*.ridgun`, or `build.ridgun`, or before publishing updated `.ridgunlib` / `.so` artifacts to downstream projects (`Solstice`, `unix-tools`).

## Steps
1. **Format sources**:
   ```bash
   stable format
   ```
2. **Static type & RMM check**:
   ```bash
   stable check
   ```
3. **Execute unit & performance test suites**:
   ```bash
   stable test
   ```
4. **Compile `.rgc`, `.so`, and `.ridgunlib` bundles**:
   ```bash
   stable built lib
   ```
5. **Validate AIX traceability & coverage**:
   ```bash
   aix docs validate
   aix docs coverage
   ```
