# c-print-to-zig-migration - Work Plan
## TL;DR (For humans)
This plan migrates the C library `c_print` (ANSI-colored console formatting) to idiomatic Zig 0.16.0, reusing Zig's std library where possible (e.g., std.fmt for formatting, std.io for I/O) and reimplementing only the color/style/alignment logic that lacks direct equivalents. The result will be a Zig module offering three APIs mirroring the original C approaches (pattern-based, builder, generic) with compile-time safety where appropriate. Effort: moderate; risk: low (well-defined scope, no external dependencies). Decisions: use Zig std.fmt for core formatting, implement ANSI code generation as a separate module, keep the three API layers.
## Scope
Migrate all functionality of the `c_print` C library to Zig 0.16.0:
- ANSI color/style support (16 colors, 8 styles, background colors)
- Pattern-based formatting with `{type:spec1:spec2...}` syntax
- Builder-pattern API for type-safe construction
- C11 _Generic‑like generic API (using Zig comptime and generics)
- Number formatting (separators, bases, precision, padding, prefixes, signs, percentages)
- Text alignment (left, right, center with custom fill)
- Safe variants (NULL‑pointer checks, debug logging)
Excluded: Windows‑specific console handling without ANSI, integration with Zig's logging subsystem, and any build‑system changes beyond a standard Zig package.
## Verification strategy
1. Unit tests: compare output of each Zig function against the C library for identical inputs (using `std.test.expectEqual` on captured stdout).
2. Property‑based tests: random patterns and values; ensure Zig and C produce same ANSI‑stripped text and same escape sequences.
3. Integration test: compile and run the original C examples with the Zig module via `@cImport` (using `addTranslateC`) to confirm binary compatibility at the API level.
4. Documentation test: all examples from the README compile and run correctly in Zig.
## Execution strategy
1. Set up a new Zig project (`zig init`) and create a `c_print` package.
2. Implement low‑level modules (ANSI codes, color/pattern/number/text alignment parsers) using only Zig std and pure Zig code.
3. Build the pattern‑based `c_print` function on top of those modules, leveraging `std.fmt` for value formatting.
4. Implement the builder API as a wrapper around the pattern API, exposing chainable setters.
5. Implement the generic API using Zig comptime reflection (`@TypeOf`, `@field`) to emulate `_Generic` behavior.
6. Add safe variants (`c_print_safe`) with runtime checks.
7. Write exhaustive tests mirroring the C test suite.
8. Generate documentation (README) with usage examples.
## Todos
- [x] 1. Set up Zig project structure (src/c_print, build.zig, docs).
- [x] 2. Implement ANSI code module: enums for TextColor, BackgroundColor, TextStyle; functions to emit/reset escape sequences.
- [x] 3. Implement color parser: string→enum lookup (case‑insensitive) for fg/bg/style.
- [x] 4. Implement pattern parser: tokenizer for `{type:spec1:spec2...}` producing a PatternStyle struct.
- [x] 5. Implement number formatter: functions for separators, binary/octal/hex prefixes, precision, padding, sign, percentage.
- [x] 6. Implement text alignment: functions for left/right/center with fill character detection.
- [x] 7. Implement string utilities (trim, lowercase, is_number) used by parsers.
- [x] 8. Implement core pattern‑based `c_print` function: variadic, scans pattern, delegates to parsers, uses std.fmt for values, applies ANSI codes.
- [x] 9. Write tests for pattern API matching C library output.
- [x]10. Implement builder API (CPrintBuilder) with type‑safe setters and chaining.
- [x]11. Write tests for builder API.
- [x]12. Implement generic API using Zig comptime to dispatch based on argument types (similar to C11 _Generic).
- [x]13. Write tests for generic API.
- [x]14. Implement safe variant `c_print_safe` with NULL‑pointer and suspicious‑value checks.
- [x]15. Add documentation and usage examples (translated from C README).
- [x]16. Run full test suite and verify parity with C library.
## Final verification wave
- [x] F1. Plan compliance audit: ensure every todo is decision‑complete and traces to explored facts.
- [x] F2. Code quality review: run `zig fmt`, `zig lint`, and check for idiomatic Zig usage.
- [x] F3. Real manual QA: compile and run all original C examples via the Zig module; visually inspect colored output.
- [x] F4. Scope fidelity: confirm no extra features beyond the original C library were added unless justified.
## Commit strategy
- Commit after each major module (ANSII, parsers, core, builder, generic, safe) with clear message.
- Squash commit series into a single logical commit per API layer before final review.
- Ensure `build.zig` passes `zig build -Doptimize=ReleaseSafe` and `zig test`.
## Success criteria
- All original C library tests pass when run against the Zig module (output byte‑for‑byte identical).
- The Zig module builds on major platforms (Linux, macOS, Windows) with no external dependencies.
- The public API is documented and includes usage examples that compile with `zig build-exe`.
- No unsafe code (no `@cImport` of unsafe C; all memory managed via Zig allocators).