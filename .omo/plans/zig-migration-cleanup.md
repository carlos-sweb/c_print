# zig-migration-cleanup - Work Plan

## TL;DR (For humans)
<!-- Fill this LAST, after the detailed plan below is written, so it summarizes the REAL plan. -->
<!-- Plain English for a non-engineer: NO file paths, NO todo numbers, NO wave/agent/tool names. -->

**What you'll get:** A cleaned-up C print library fully migrated to Zig 0.16.0 with all C artifacts removed, Zig idioms applied, and backward compatibility maintained through aliases.

**Why this approach:** We prioritized removing duplicated code and C-isms while maintaining backward compatibility via aliases to ensure a smooth transition for users.

**What it will NOT do:** Change the core functionality, alter the public API behavior, or remove any Zig source files or examples.

**Effort:** Medium
**Risk:** Low - The changes are mostly mechanical refactoring with backward compatibility aliases
**Decisions to sanity-check:** Removing legacy APIs and C-isms while adding backward-compat aliases; removing all C files and build artifacts

Your next move: approve. Full execution detail follows below.

---

> TL;DR (machine): <1 line - effort, risk, deliverables>

## Scope
### Must have
### Must NOT have (guardrails, anti-slop, scope boundaries)

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: <TDD | tests-after | none> + framework
- Evidence: <attemptDir>/task-<N>-zig-migration-cleanup.<ext> (attemptDir = currentAttemptDir from 'omo ulw-loop status --json', .omo/evidence/ulw/<session>/<goalId>/a<attempt>; outside ulw-loop use .omo/evidence/)

## Execution strategy
### Parallel execution waves
> Target 5-8 todos per wave. Fewer than 3 (except the final) means you under-split.

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |

## Todos
> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->
- [x] 1. D1: Remove legacy API functions from c_print.zig
  What to do / Must NOT do: Remove the legacy API functions (c_print_styled, c_print_color, c_print_bg, c_print_style, c_print_full, c_printf_styled, PrintOptions struct) from src/c_print.zig. Do not remove any other functions or change the behavior of the remaining API.
  Parallelization: Wave 1 | Blocked by: None | Blocks: None
  References: src/c_print.zig:462-499 (legacy functions), src/c_print.zig:15 (PrintOptions struct)
  Acceptance criteria: The file src/c_print.zig no longer contains the definitions of c_print_styled, c_print_color, c_print_bg, c_print_style, c_print_full, c_printf_styled, or the PrintOptions struct. All other functions remain unchanged.
  QA scenarios: 
    - happy: Run `grep -n "c_print_styled\\|c_print_color\\|c_print_bg\\|c_print_style\\|c_print_full\\|c_printf_styled\\|PrintOptions" src/c_print.zig` and expect no matches.
    - failure: If any of the above are found, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a1/zegrep_legacy_removal.txt
  Commit: Y | feat(c_print): remove legacy API functions

- [x] 2. D2: Deduplicate helper functions across modules
  What to do / Must NOT do: 
    * In src/c_print.zig: remove duplicate formatSeparatedCorrect, format_int, apply_int_padding, format_float, printFloatWithPrecision, and dead isPointerToArray. Import canonical versions from number_formatter.zig and c_print.zig (for format_int, apply_int_padding, etc.) or define them in the canonical module.
    * In src/c_print_safe.zig: remove duplicate formatSeparatedCorrect, format_int, apply_int_padding, format_float, printFloatWithPrecision and import canonical versions.
    * In src/c_print_generic.zig: remove duplicate isSignedIntType, isUnsignedIntType, isFloatType and import canonical from c_print.zig.
    * In src/pattern_parser.zig: remove duplicate is_all_digits and import from text_alignment.zig.
    * In src/text_alignment.zig: keep is_all_digits (it is the canonical version).
  Do not change the behavior of the functions, only remove duplicates and update imports.
  Parallelization: Wave 1 | Blocked by: None | Blocks: None
  References: 
    - c_print.zig:279-326 (formatSeparatedCorrect), 329-349 (format_int), 352-420 (apply_int_padding), 423-437 (format_float), 440-460 (printFloatWithPrecision), 245-251 (isPointerToArray)
    - c_print_safe.zig:387-426 (formatSeparatedCorrect), 429-445 (format_int), 448-506 (apply_int_padding), 509-523 (format_float), 526-546 (printFloatWithPrecision)
    - c_print_generic.zig:136-140 (isSignedIntType), 143-147 (isUnsignedIntType), 150-152 (isFloatType)
    - pattern_parser.zig:235-241 (is_all_digits)
    - text_alignment.zig:118-124 (is_all_digits)
  Acceptance criteria:
    - The duplicate function definitions are removed from the respective files.
    - The files that removed duplicates now import the canonical versions (e.g., c_print.zig imports format_separated from number_formatter.zig).
    - The function isPointerToArray is removed from c_print.zig (dead code).
    - The function is_all_digits is removed from pattern_parser.zig and present in text_alignment.zig.
  QA scenarios:
    - happy: Run the following greps and expect the indicated results:
        * grep -n "formatSeparatedCorrect" src/c_print.zig src/c_print_safe.zig → no matches
        * grep -n "format_int" src/c_print_safe.zig → no matches
        * grep -n "apply_int_padding" src/c_print_safe.zig → no matches
        * grep -n "format_float" src/c_print_safe.zig → no matches
        * grep -n "printFloatWithPrecision" src/c_print_safe.zig → no matches
        * grep -n "isPointerToArray" src/c_print.zig → no matches
        * grep -n "is_all_digits" src/pattern_parser.zig → no matches
        * grep -n "is_all_digits" src/text_alignment.zig → one match (the canonical)
        * grep -n "isSignedIntType" src/c_print_safe.zig src/c_print_generic.zig → no matches
        * grep -n "isUnsignedIntType" src/c_print_safe.zig src/c_print_generic.zig → no matches
        * grep -n "isFloatType" src/c_print_safe.zig src/c_print_generic.zig → no matches
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a2/deduplication_checks.txt
  Commit: Y | refactor: deduplicate helper functions across modules

- [x] 3. D3: Rename builder functions to Zig idioms in c_print_builder.zig
  What to do / Must NOT do: 
    * Remove standalone cp_new, cp_free, cp_reset (lines 62, 67, 72) as the methods .init(), .deinit(), .reset() already exist.
    * Rename the following functions:
        cp_text → appendText
        cp_str → append
        cp_int → appendInt
        cp_uint → appendUint
        cp_long → appendLong
        cp_ulong → appendUlong
        cp_float → appendFloat
        cp_char → appendChar
        cp_bool → appendBool
        cp_binary → appendBinary
        cp_hex → appendHex
        cp_octal → appendOctal
        cp_color → withColor
        cp_color_str → withColorName
        cp_bg → withBgColor
        cp_bg_str → withBgColorName
        cp_style → withStyle
        cp_style_str → withStyleName
        cp_precision → withPrecision
        cp_zero_pad → withZeroPad
        cp_pad → withPad
        cp_separator → withSeparator
        cp_show_prefix → withPrefix
        cp_show_sign → withSign
        cp_as_percentage → asPercentage
        cp_align_left → alignLeft
        cp_align_right → alignRight
        cp_align_center → alignCenter
        cp_fill_char → withFillChar
    * Add pub const aliases for the old names pointing to the new names (for backward compatibility during transition).
    Do not change the behavior of the functions, only their names and add aliases.
  Parallelization: Wave 1 | Blocked by: None | Blocks: None
  References: src/c_print_builder.zig:62-522 (all functions to rename)
  Acceptance criteria:
    - The old function names (cp_new, cp_free, cp_reset, cp_text, etc.) are no longer defined as functions (except as pub const aliases).
    - The new function names (appendText, append, etc.) are defined.
    - The pub const aliases are present for the old names (e.g., pub const cp_new = Builder.init;).
    - The behavior of the builder remains unchanged (verified by tests).
  QA scenarios:
    - happy: 
        * Check that the old function names are not defined as functions (but may be as consts): 
          grep -n "^fn cp_new\\|^fn cp_free\\|^fn cp_reset\\|^fn cp_text\\|^fn cp_str\\|^fn cp_int\\|^fn cp_uint\\|^fn cp_long\\|^fn cp_ulong\\|^fn cp_float\\|^fn cp_char\\|^fn cp_bool\\|^fn cp_binary\\|^fn cp_hex\\|^fn cp_octal\\|^fn cp_color\\|^fn cp_color_str\\|^fn cp_bg\\|^fn cp_bg_str\\|^fn cp_style\\|^fn cp_style_str\\|^fn cp_precision\\|^fn cp_zero_pad\\|^fn cp_pad\\|^fn cp_separator\\|^fn cp_show_prefix\\|^fn cp_show_sign\\|^fn cp_as_percentage\\|^fn cp_align_left\\|^fn cp_align_right\\|^fn cp_align_center\\|^fn cp_fill_char" src/c_print_builder.zig should show no matches for function definitions (but may show matches for pub const lines).
        * Check that the new function names are defined: 
          grep -n "^fn appendText\\|^fn append\\|^fn appendInt\\|^fn appendUint\\|^fn appendLong\\|^fn appendUlong\\|^fn appendFloat\\|^fn appendChar\\|^fn appendBool\\|^fn appendBinary\\|^fn appendHex\\|^fn appendOctal\\|^fn withColor\\|^fn withColorName\\|^fn withBgColor\\|^fn withBgColorName\\|^fn withStyle\\|^fn withStyleName\\|^fn withPrecision\\|^fn withZeroPad\\|^fn withPad\\|^fn withSeparator\\|^fn withPrefix\\|^fn withSign\\|^fn asPercentage\\|^fn alignLeft\\|^fn alignRight\\|^fn alignCenter\\|^fn withFillChar" src/c_print_builder.zig should show matches.
        * Check that pub const aliases exist for the old names (e.g., "pub const cp_new = Builder.init;").
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a3/builder_rename_checks.txt
  Commit: Y | feat(c_print_builder): rename functions to Zig idioms and add backward-compat aliases

- [x] 4. D4: Rename c_print_generic symbols to Zig conventions in c_print_generic.zig
  What to do / Must NOT do: 
    * Rename:
        CPrintArgType → PrintArgType
        CPrintArg → PrintArg
        C_PRINT → print
        C_PRINT_VALIDATED → printValidated
        C_PRINT_DEBUG_TYPES → debugTypes
        C_PRINT_DEBUG_VALUES → debugValues
        validateAndReport → validateAndReport (already Zig-style, but note the case: it's already correct, so no change needed for the name, but we note it's already Zig-style)
    * Add pub const aliases for the old names pointing to the new names (for backward compatibility during transition).
    Do not change the behavior of the functions, only their names and add aliases.
  Parallelization: Wave 2 | Blocked by: None | Blocks: None
  References: src/c_print_generic.zig:23-54 (CPrintArgType, CPrintArg), 330-460 (the functions to rename)
  Acceptance criteria:
    - The old symbol names (CPrintArgType, CPrintArg, C_PRINT, C_PRINT_VALIDATED, C_PRINT_DEBUG_TYPES, C_PRINT_DEBUG_VALUES) are not defined as types/functions (except as pub const aliases).
    - The new symbol names (PrintArgType, PrintArg, print, printValidated, debugTypes, debugValues) are defined.
    - The pub const aliases are present for the old names (e.g., pub const CPrintArgType = PrintArgType;).
    - The behavior of the generic API remains unchanged (verified by tests).
  QA scenarios:
    - happy:
        * Check that the old symbol names are not defined as types/functions (but may be as consts): 
          grep -n "^const CPrintArgType\\|^const CPrintArg\\|^fn C_PRINT\\|^fn C_PRINT_VALIDATED\\|^fn C_PRINT_DEBUG_TYPES\\|^fn C_PRINT_DEBUG_VALUES" src/c_print_generic.zig should show no matches for type/function definitions (but may show matches for pub const lines).
        * Check that the new symbol names are defined: 
          grep -n "^const PrintArgType\\|^const PrintArg\\|^fn print\\|^fn printValidated\\|^fn debugTypes\\|^fn debugValues" src/c_print_generic.zig should show matches.
        * Check that pub const aliases exist for the old names (e.g., "pub const CPrintArgType = PrintArgType;").
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a4/generic_rename_checks.txt
  Commit: Y | feat(c_print_generic): rename symbols to Zig conventions and add backward-compat aliases

- [x] 5. D5: Remove C-isms from c_print_safe.zig
  What to do / Must NOT do: 
    * Remove the following definitions:
        SUSPICIOUS_PTR_THRESHOLD (line 29)
        isLikelyPointer (line 41)
        isLikelyString (line 47)
        validateStringPointer (line 56)
        DEBUG_C_PRINT (line 33)
        debugLog (function, if exists)
    * In the function format_value_safe, remove the pointer validation for strings (the check that calls validateStringPointer). Keep the char range check (val > 127) and the arg-count mismatch detection.
    Do not change any other behavior.
  Parallelization: Wave 2 | Blocked by: None | Blocks: None
  References: src/c_print_safe.zig:29 (SUSPICIOUS_PTR_THRESHOLD), 41 (isLikelyPointer), 47 (isLikelyString), 56 (validateStringPointer), 33 (DEBUG_C_PRINT), and the format_value_safe function (search for validateStringPointer call)
  Acceptance criteria:
    - The constants SUSPICIOUS_PTR_THRESHOLD, isLikelyPointer, isLikelyString, validateStringPointer, DEBUG_C_PRINT are removed from src/c_print_safe.zig.
    - The function debugLog is removed if it exists.
    - In the function format_value_safe, the call to validateStringPointer is removed, but the char range check (if val > 127) and the arg-count mismatch check remain.
    - The behavior of c_print_safe.zig for valid inputs remains unchanged (verified by tests).
  QA scenarios:
    - happy:
        * Check that the following are not defined in src/c_print_safe.zig (except possibly as comments): 
          grep -n "SUSPICIOUS_PTR_THRESHOLD\\|isLikelyPointer\\|isLikelyString\\|validateStringPointer\\|DEBUG_C_PRINT\\|debugLog" src/c_print_safe.zig → no matches (or only in comments).
        * Check that in format_value_safe, there is no call to validateStringPointer.
          We can check for the absence of the string "validateStringPointer" in the function body (excluding comments).
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a5/c_print_safe_cleanup_checks.txt
  Commit: Y | refactor(c_print_safe): remove C-isms

- [x] 6. D6: Clean up test names in test_pattern_api.zig
  What to do / Must NOT do: 
    * Strip the prefix "zig-c parity: " from all test names in src/test_pattern_api.zig.
    * Do not change the test logic, only the test names.
  Parallelization: Wave 2 | Blocked by: None | Blocks: None
  References: src/test_pattern_api.zig (all test names)
  Acceptance criteria:
    * No test name in src/test_pattern_api.zig starts with the string "zig-c parity: ".
    * The test logic remains unchanged.
  QA scenarios:
    - happy:
        * Run: grep -n '"zig-c parity:' src/test_pattern_api.zig and expect no matches.
        * Alternatively, check that every test line that contains a test name does not have the prefix.
    - failure: If any test name still contains the prefix, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a6/test_name_cleanup_checks.txt
  Commit: Y | refactor(test_pattern_api): remove zig-c parity prefix from test names

- [x] 7. D7: Remove migration comments from source files
  What to do / Must NOT do: 
    * Remove the following comments:
        src/main.zig:2 — "Migration from C to Zig 0.16.0"
        src/c_print_safe.zig:9 — "Migration from C's c_print_safe.c to Zig 0.16.0"
        src/c_print_generic.zig:3 — "Provides C11 _Generic-like functionality"
    * Also remove any other comments that reference C behavior or migration that were found during exploration (as listed in F8 in the findings).
    Do not remove any other comments or change any code.
  Parallelization: Wave 3 | Blocked by: None | Blocks: None
  References: 
    - src/main.zig:2
    - src/c_print_safe.zig:9
    - src/c_print_generic.zig:3
    - Additionally, from findings F8: various comments referencing C behavior throughout test files (we'll focus on the ones in the source files for now; test file comments are less critical but we can do them in this todo or separately. However, the findings mention "various comments referencing C behavior throughout test files", so we should also clean those in the test files if they are migration-related. But to keep the scope, we'll do the ones explicitly listed and then note that we are only removing the explicitly listed migration comments. If we want to be thorough, we can do a broader search, but let's stick to the ones in the findings for the source files and then do a separate pass for test files if needed. However, the findings say "various comments referencing C behavior throughout test files", so we should include test files in this todo or create another. Let's do it in this todo for simplicity, but note that we must not change test logic.
    We'll search for comments that contain "Migration from C" or "zig-c parity" (but note we already handled zig-c parity in test names) or "C's" in comments and remove them if they are migration-related.
  Acceptance criteria:
    * The specific comments listed above are removed from the respective files.
    * No other comments are removed inadvertently (we'll be careful).
    * In test files, any comment that explicitly mentions migration from C or zig-c parity (outside of test names, which we already fixed) is removed.
  QA scenarios:
    - happy:
        * Check that the following lines are no longer present (as code, not in comments):
            src/main.zig:2 does not contain "Migration from C to Zig 0.16.0"
            src/c_print_safe.zig:9 does not contain "Migration from C's c_print_safe.c to Zig 0.16.0"
            src/c_print_generic.zig:3 does not contain "Provides C11 _Generic-like functionality"
        * Additionally, we can do a grep for "Migration from C" in all src and test files and expect no matches (except possibly in comments that we are allowed to leave? but we are removing them). We'll do a grep and if there are any, we'll check if they are the ones we missed.
    - failure: If any of the specified comments are still present, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a7/migration_comment_removal_checks.txt
  Commit: Y | refactor: remove migration comments

- [x] 8. Clean up legacy C files and build system
  What to do / Must NOT do: Remove all remaining C source files (.c), header files (.h), CMakeLists.txt, pkg-config files, and shell scripts related to the C build system. Do not remove any Zig source files (.zig), the build.zig file, the build.zig.zon file, example files, or documentation.
  Parallelization: Wave 4 | Blocked by: None | Blocks: None
  References: 
    - C source files: src/*.c (9 files)
    - Header files: include/*.h (10 files)
    - C test files: test/*.c (13 files)
    - Build system: CMakeLists.txt, c_print.pc.in
    - Shell scripts: compile_and_test.sh, check_headers.sh
  Acceptance criteria:
    - All files matching src/*.c are removed.
    - The entire include/ directory is removed.
    - All files matching test/*.c are removed.
    - The files CMakeLists.txt, c_print.pc.in, compile_and_test.sh, check_headers.sh are removed.
    - No Zig source files (.zig) are removed.
    - The files build.zig, build.zig.zon remain.
    - The examples/ directory remains.
    - The docs/ directory remains.
    - The README.md and README-es.md files remain.
  QA scenarios:
    - happy:
        * Run: find src -name "*.c" | wc -l and expect 0
        * Run: find include -type f | wc -l and expect 0 (or directory does not exist)
        * Run: find test -name "*.c" | wc -l and expect 0
        * Run: test -f CMakeLists.txt && echo "exists" || echo "missing" and expect "missing"
        * Run: test -f c_print.pc.in && echo "exists" || echo "missing" and expect "missing"
        * Run: test -f compile_and_test.sh && echo "exists" || echo "missing" and expect "missing"
        * Run: test -f check_headers.sh && echo "exists" || echo "missing" and expect "missing"
        * Run: find src -name "*.zig" | wc -l and expect > 0 (Zig source files remain)
        * Run: test -f build.zig && echo "exists" || echo "missing" and expect "exists"
        * Run: test -f build.zig.zon && echo "exists" || echo "missing" and expect "exists"
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a8/cleanup_verification.txt
  Commit: Y | chore: remove legacy C files and build system

- [x] 9. Clean up build artifacts
  What to do / Must NOT do: Remove all build artifacts including static libraries (.a), executables, and build output directories. Do not remove source code, documentation, or configuration files.
  Parallelization: Wave 4 | Blocked by: None | Blocks: None
  References: 
    - Static libraries: libmain.a
    - Executables: main, system_dashboard, example_system_dashboard, test_dynprec, test_va, test_va2, test_va3, test_va4, test_variadic, test_variadic2, test_variadic3, test_variadic4, test_variadic5
    - Build output directories: zig-out/, graphify-out/, .zig-cache/
  Acceptance criteria:
    - The file libmain.a is removed.
    - All executable files in the root directory are removed.
    - The directories zig-out/, graphify-out/, .zig-cache/ are removed.
    - No source files (.zig, .md, etc.) are removed.
    - The build.zig and build.zig.zon files remain.
  QA scenarios:
    - happy:
        * Run: test -f libmain.a && echo "exists" || echo "missing" and expect "missing"
        * Run: ls main system_dashboard example_system_dashboard test_dynprec test_va test_va2 test_va3 test_va4 test_variadic test_variadic2 test_variadic3 test_variadic4 test_variadic5 2>/dev/null | wc -l and expect 0
        * Run: test -d zig-out && echo "exists" || echo "missing" and expect "missing"
        * Run: test -d graphify-out && echo "exists" || echo "missing" and expect "missing"
        * Run: test -d .zig-cache && echo "exists" || echo "missing" and expect "missing"
        * Run: find . -name "*.zig" -type f | wc -l and expect > 0
        * Run: test -f build.zig && echo "exists" || echo "missing" and expect "exists"
        * Run: test -f build.zig.zon && echo "exists" || echo "missing" and expect "exists"
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a9/artifact_cleanup_verification.txt
  Commit: Y | chore: remove build artifacts

- [x] 10. Create example_c_simple.c and verify C-ABI compatibility
  What to do / Must NOT do: 
    * Create test/example_c_simple.c that demonstrates using the c_print library from C code.
    * The example should call at least 2-3 functions from the library's C-ABI interface.
    * Update build.zig to add a new build step "example_c_simple" that:
      1. Builds the library as a static .a file with C-ABI compatibility (using `zig build lib`)
      2. Compiles test/example_c_simple.c using the C compiler
      3. Links it against the .a library
      4. Produces an executable
    * Verify that `zig build lib` produces a .a file with properly exported C-ABI symbols.
    * Verify that `zig build example_c_simple` successfully builds and runs the example.
  Parallelization: Wave 5 | Blocked by: Tasks 1-9 | Blocks: None
  References: 
    - build.zig (add new build step)
    - test/example_c_simple.c (create new file)
    - zig-out/lib/libc_print.a (verify C-ABI exports)
  Acceptance criteria:
    - test/example_c_simple.c exists and contains valid C code that calls library functions.
    - build.zig has a new step "example_c_simple" that builds the example.
    - `zig build lib` produces zig-out/lib/libc_print.a (or similar path).
    - `zig build example_c_simple` compiles and links successfully.
    - The compiled example runs without errors.
    - The .a library exports C-ABI compatible symbols (verify with `nm` or `objdump`).
  QA scenarios:
    - happy:
        * Run: zig build lib and verify it exits with code 0 and produces a .a file.
        * Run: zig build example_c_simple and verify it exits with code 0.
        * Run: ./zig-out/bin/example_c_simple (or similar path) and verify it runs successfully.
        * Run: nm zig-out/lib/libc_print.a | grep -E "T (c_print|ansi_|color_|pattern_)" and verify C symbols are exported.
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a10/c_abi_example_verification.txt
  Commit: Y | feat: add C-ABI example and verify library compatibility

- [x] 11. Update documentation
  What to do / Must NOT do: 
    * Update README.md to reflect the Zig migration (remove references to C implementation).
    * Update README-es.md (Spanish version) similarly.
    * Add documentation about the C-ABI compatibility and how C users can use the library.
    * Document the `zig build example_c_simple` command.
    * Remove any references to CMake, Makefiles, or C compilation.
    * Update the "Installation" and "Usage" sections to reflect Zig-only build system.
  Parallelization: Wave 5 | Blocked by: Tasks 1-9 | Blocks: None
  References: 
    - README.md
    - README-es.md
  Acceptance criteria:
    - README.md no longer references C implementation, CMake, or Makefiles.
    - README.md includes instructions for `zig build`, `zig build test`, and `zig build example_c_simple`.
    - README.md documents C-ABI compatibility for C users.
    - README-es.md is updated similarly (in Spanish).
    - All documentation is accurate and reflects the current state of the project.
  QA scenarios:
    - happy:
        * Run: grep -i "cmake\\|makefile\\|gcc\\|clang" README.md README-es.md and expect no matches (or only in historical context).
        * Run: grep -i "zig build" README.md README-es.md and expect matches.
        * Run: grep -i "C-ABI\\|C ABI\\|C compatibility" README.md README-es.md and expect matches.
        * Manually review that the documentation is clear and accurate.
    - failure: If any of the above checks fail, the task fails.
  Evidence: .omo/evidence/ulw/<session>/<goalId>/a11/documentation_update_verification.txt
  Commit: Y | docs: update README for Zig migration and C-ABI support

## Final verification wave
> Runs in parallel after ALL todos. ALL must APPROVE. Surface results and wait for the user's explicit okay before declaring complete.
- [x] F1. Plan compliance audit
- [x] F2. Code quality review
- [x] F3. Real manual QA
- [x] F4. Scope fidelity

## Commit strategy

## Success criteria
