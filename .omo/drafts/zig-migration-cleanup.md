---
slug: zig-migration-cleanup
status: drafting
intent: clear
review_required: false
pending-action: write .omo/plans/zig-migration-cleanup.md
approach: 7-phase cleanup: (1) remove legacy APIs from c_print.zig, (2) deduplicate helpers across modules, (3) rename builder cp_* to Zig idioms, (4) rename generic C_PRINT* to Zig conventions, (5) remove C-isms from c_print_safe.zig, (6) clean up test names, (7) run zig build test to verify
---

# Draft: zig-migration-cleanup

## Components (topology ledger)
<!-- Lock the SHAPE before depth. One row per top-level component that can succeed or fail independently. -->
<!-- id | outcome (one line) | status: active|deferred | evidence path -->
1. `c_print.zig` — Remove legacy API functions + deduplicate helpers | active | src/c_print.zig:462-499, src/c_print.zig:279-420
2. `c_print_safe.zig` — Remove C-isms (pointer validation, debug flags) + deduplicate helpers | active | src/c_print_safe.zig:27-73, src/c_print_safe.zig:387-546
3. `c_print_generic.zig` — Rename C-style symbols to Zig idioms | active | src/c_print_generic.zig:23-54, src/c_print_generic.zig:330-460
4. `c_print_builder.zig` — Rename C-style `cp_*` functions to Zig idioms | active | src/c_print_builder.zig:62-522
5. `pattern_parser.zig` / `text_alignment.zig` — Deduplicate `is_all_digits` | active | src/pattern_parser.zig:235, src/text_alignment.zig:118
6. `test_pattern_api.zig` — Clean up "zig-c parity:" test names | active | src/test_pattern_api.zig (all test names)
7. `main.zig` / module comments — Remove "Migration from C" comments | active | src/main.zig:2, src/c_print_safe.zig:9

## Open assumptions (announced defaults)
<!-- Record any default you adopt instead of asking, so the user can veto it at the gate. -->
<!-- assumption | adopted default | rationale | reversible? -->
1. Legacy API functions (`c_print_styled`, `c_print_color`, `c_print_bg`, `c_print_style`, `c_print_full`, `c_printf_styled`, `PrintOptions`) are removed entirely | Remove — they are thin wrappers over `c_print_styled` which itself is a thin wrapper over `ansi_codes.apply_ansi_codes`. Users should use the pattern API or `ansi_codes` directly. | Reversible: can be re-added if needed.
2. C-style `cp_*` builder functions get Zig-idiomatic names (`init`/`deinit`/`reset` already exist as methods; standalone wrappers are removed) | Keep methods, remove standalone `cp_new`/`cp_free`/`cp_reset`. Rename `cp_text`→`appendText`, `cp_str`→`append`, `cp_int`→`appendInt`, etc. | Reversible: old names can be re-added as `pub const cp_int = appendInt`.
3. `c_print_generic` C-style names (`C_PRINT`, `CPrintArg`, `CPrintArgType`) get Zig names (`print`, `PrintArg`, `PrintArgType`) | Rename to Zig conventions. | Reversible via `pub const C_PRINT = print` aliases.
4. `c_print_safe` C-isms (`isLikelyPointer`, `validateStringPointer`, `SUSPICIOUS_PTR_THRESHOLD`, `DEBUG_C_PRINT`) are removed | These are C concepts. In Zig, a `[]const u8` slice cannot be null and always has a valid length. The pointer-validation logic is dead weight. | Reversible: can be re-added if interfacing with C code.
5. Duplicated helper functions are consolidated into the module that owns the logic (`number_formatter.zig` for number formatting, `string_utils.zig` for string utils) | Move shared logic to the canonical module, have others import it. | Reversible.
6. "zig-c parity:" test prefixes are stripped to just describe what's tested | The migration is complete; parity tests are now just regular tests. | Reversible via git.

## Findings (cited - path:lines)

### F1. Legacy API functions in `c_print.zig` (src/c_print.zig:462-499)
Six functions labeled "Legacy API" — `c_print_styled`, `c_print_color`, `c_print_bg`, `c_print_style`, `c_print_full`, `c_printf_styled` — plus `PrintOptions` struct (line 15). All are thin wrappers. `c_print_full` uses `PrintOptions` which is a C-style options struct pattern.

### F2. Duplicated number formatting logic
- `formatSeparatedCorrect` exists in `c_print.zig:279-326`, `c_print_safe.zig:387-426`, and `number_formatter.zig:10-55` (as `format_separated`) — 3 copies
- `format_int` exists in `c_print.zig:329-349` and `c_print_safe.zig:429-445` — 2 copies
- `apply_int_padding` exists in `c_print.zig:352-420` and `c_print_safe.zig:448-506` — 2 copies
- `format_float` exists in `c_print.zig:423-437` and `c_print_safe.zig:509-523` — 2 copies
- `printFloatWithPrecision` exists in `c_print.zig:440-460` and `c_print_safe.zig:526-546` — 2 copies

### F3. Duplicated comptime type-check helpers
- `isSliceType` in `c_print.zig:225-242` and `c_print_safe.zig:553-569` — 2 copies
- `isSignedIntType` in `c_print.zig:254-258`, `c_print_safe.zig:572-576`, `c_print_generic.zig:136-140` — 3 copies
- `isUnsignedIntType` in `c_print.zig:261-265`, `c_print_safe.zig:579-583`, `c_print_generic.zig:143-147` — 3 copies
- `isFloatType` in `c_print.zig:268-270`, `c_print_safe.zig:586-588`, `c_print_generic.zig:150-152` — 3 copies
- `isPointerToArray` in `c_print.zig:245-251` — unused (dead code)

### F4. Duplicated `is_all_digits` helper
- `pattern_parser.zig:235-241` and `text_alignment.zig:118-124` — 2 identical copies

### F5. C-style naming in `c_print_builder.zig`
- Standalone lifecycle wrappers: `cp_new` (line 62), `cp_free` (line 67), `cp_reset` (line 72) — these just call `.init()`, `.deinit()`, `.reset()` methods that already exist
- Value functions: `cp_text`, `cp_str`, `cp_int`, `cp_uint`, `cp_long`, `cp_ulong`, `cp_float`, `cp_char`, `cp_bool`, `cp_binary`, `cp_hex`, `cp_octal` — C-style `cp_` prefix
- Config functions: `cp_color`, `cp_color_str`, `cp_bg`, `cp_bg_str`, `cp_style`, `cp_style_str`, `cp_precision`, `cp_zero_pad`, `cp_pad`, `cp_separator`, `cp_show_prefix`, `cp_show_sign`, `cp_as_percentage`, `cp_align_left`, `cp_align_right`, `cp_align_center`, `cp_fill_char` — 17 functions with `cp_` prefix

### F6. C-style naming in `c_print_generic.zig`
- `CPrintArgType` enum (line 23) — C-style tagged enum with C type names (string, integer, unsigned, long, ulong, float, double, char, bool, pointer, unknown)
- `CPrintArg` tagged union (line 43) — mirrors C struct
- `C_PRINT` (line 338), `C_PRINT_VALIDATED` (line 346), `C_PRINT_DEBUG_TYPES` (line 365), `C_PRINT_DEBUG_VALUES` (line 387) — SCREAMING_CASE function names
- `validateAndReport` (line 431) — C-style error reporting
- Comments throughout reference C equivalents (lines 3-4, 22, 42)

### F7. C-isms in `c_print_safe.zig`
- `SUSPICIOUS_PTR_THRESHOLD` (line 29) — C concept, meaningless in Zig
- `isLikelyPointer` (line 41) — C pointer validation
- `isLikelyString` (line 47) — C string validation
- `validateStringPointer` (line 56) — C NULL pointer checking
- `DEBUG_C_PRINT` (line 33) — C compile-time flag pattern
- Comment: "Migration from C's c_print_safe.c" (line 9)

### F8. "Migration from C" comments
- `src/main.zig:2` — "Migration from C to Zig 0.16.0"
- `src/c_print_safe.zig:9` — "Migration from C's c_print_safe.c to Zig 0.16.0"
- `src/c_print_generic.zig:3` — "Provides C11 _Generic-like functionality"
- Various comments referencing C behavior throughout test files

### F9. "zig-c parity:" test names in `test_pattern_api.zig`
All ~100+ test names use the prefix "zig-c parity:" — these were migration verification tests. The migration is complete; these should be renamed to describe what they test.

### F10. `c_print_generic.zig` delegates to `c_print_mod.c_print`
`C_PRINT` (line 340) simply calls `c_print_mod.c_print`. The type detection/validation infrastructure (`CPrintArgType`, `CPrintArg`, `detectArgType`, `makeArg`, etc.) is largely unused by the main function — it exists for the debug/validation APIs only.

## Decisions (with rationale)

### D1. Remove legacy API functions from `c_print.zig`
**Decision:** Remove `c_print_styled`, `c_print_color`, `c_print_bg`, `c_print_style`, `c_print_full`, `c_printf_styled`, and `PrintOptions`.
**Rationale:** These are thin wrappers that add no value over the pattern API or direct `ansi_codes` usage. They represent a C-style API surface that the Zig migration was meant to replace.
**Impact:** Breaking change for any code using these functions. Users should migrate to `c_print(&writer, "{s:color}", .{text})` or `ansi_codes.apply_ansi_codes(...)`.

### D2. Deduplicate helpers by consolidating into canonical modules
**Decision:** 
- Keep `format_separated` in `number_formatter.zig` as the single source of truth
- Remove `formatSeparatedCorrect` from `c_print.zig` and `c_print_safe.zig`, import from `number_formatter`
- Remove `format_int`, `apply_int_padding`, `format_float`, `printFloatWithPrecision` from `c_print_safe.zig`, import from `c_print.zig` (or better: move to `number_formatter.zig`)
- Remove duplicate `isSignedIntType`, `isUnsignedIntType`, `isFloatType` from `c_print_safe.zig` and `c_print_generic.zig`, import from `c_print.zig` (or create a shared `type_utils.zig`)
- Remove duplicate `is_all_digits` from `pattern_parser.zig`, import from `text_alignment` (or move to `string_utils`)
- Remove dead `isPointerToArray` from `c_print.zig`

### D3. Rename builder functions to Zig idioms
**Decision:** 
- Remove standalone `cp_new`, `cp_free`, `cp_reset` (methods already exist)
- Rename `cp_text`→`appendText`, `cp_str`→`append`, `cp_int`→`appendInt`, `cp_uint`→`appendUint`, `cp_long`→`appendLong`, `cp_ulong`→`appendUlong`, `cp_float`→`appendFloat`, `cp_char`→`appendChar`, `cp_bool`→`appendBool`, `cp_binary`→`appendBinary`, `cp_hex`→`appendHex`, `cp_octal`→`appendOctal`
- Rename config functions: `cp_color`→`withColor`, `cp_color_str`→`withColorName`, `cp_bg`→`withBgColor`, `cp_bg_str`→`withBgColorName`, `cp_style`→`withStyle`, `cp_style_str`→`withStyleName`, `cp_precision`→`withPrecision`, `cp_zero_pad`→`withZeroPad`, `cp_pad`→`withPad`, `cp_separator`→`withSeparator`, `cp_show_prefix`→`withPrefix`, `cp_show_sign`→`withSign`, `cp_as_percentage`→`asPercentage`, `cp_align_left`→`alignLeft`, `cp_align_right`→`alignRight`, `cp_align_center`→`alignCenter`, `cp_fill_char`→`withFillChar`
- Add `pub const` aliases for backward compatibility during transition

### D4. Rename `c_print_generic` symbols to Zig conventions
**Decision:**
- `CPrintArgType` → `PrintArgType`
- `CPrintArg` → `PrintArg`
- `C_PRINT` → `print`
- `C_PRINT_VALIDATED` → `printValidated`
- `C_PRINT_DEBUG_TYPES` → `debugTypes`
- `C_PRINT_DEBUG_VALUES` → `debugValues`
- `validateAndReport` → `validateAndReport` (already Zig-style)
- Add `pub const` aliases for backward compatibility

### D5. Remove C-isms from `c_print_safe.zig`
**Decision:**
- Remove `SUSPICIOUS_PTR_THRESHOLD`, `isLikelyPointer`, `isLikelyString`, `validateStringPointer`, `DEBUG_C_PRINT`, `debugLog`
- In `format_value_safe`, remove pointer validation for strings — in Zig, a `[]const u8` is always valid
- Keep the char range check (val > 127) as it's a legitimate semantic validation
- Keep the arg-count mismatch detection

### D6. Clean up test names
**Decision:** Strip "zig-c parity: " prefix from all test names in `test_pattern_api.zig`. Rename to describe what's being tested (e.g., "zig-c parity: c_print plain text" → "c_print plain text").

## Scope IN
- Remove legacy API functions from `c_print.zig`
- Deduplicate helper functions across all modules
- Rename C-style symbols in `c_print_builder.zig` and `c_print_generic.zig`
- Remove C-isms from `c_print_safe.zig`
- Clean up migration comments and test names
- Update all tests to use renamed symbols
- Ensure `zig build test` passes after all changes

## Scope OUT (Must NOT have)
- No new features or functionality changes
- No changes to the pattern syntax or formatting behavior
- No changes to `ansi_codes.zig`, `color_parser.zig`, `text_alignment.zig`, `number_formatter.zig`, `string_utils.zig` (except removing `is_all_digits` duplication)
- No changes to `build.zig` or `build.zig.zon`
- No changes to example files (they use the public API which will have backward-compat aliases)

## Open questions
1. Should `c_print_safe.zig` be kept at all? In Zig, the type system already prevents most of the errors it guards against. The only remaining value is the char range check and arg-count mismatch detection.
2. Should the `CPrintArg`/`CPrintArgType` infrastructure in `c_print_generic.zig` be kept? It's not used by the main `C_PRINT` function (which delegates to `c_print_mod.c_print`). It's only used by the debug/validation APIs.

## Approval gate
status: awaiting-approval
<!-- When exploration is exhausted and unknowns are answered, set status: awaiting-approval. -->
<!-- That durable record is the loop guard: on a later turn read it and resume at the gate instead of re-running exploration. -->
