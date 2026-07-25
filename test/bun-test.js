#!/usr/bin/env bun
//
// A minimal exploration of how a JS runtime (Bun here, Node's `ffi-napi`/
// `koffi` work the same way in spirit) loads a Zig-compiled shared library
// and calls its exported C-ABI functions directly, with no C compiler or
// glue code involved -- just `dlopen` + a declared signature per symbol.
//
// Build the library first: `zig build` (produces zig-out/lib/libz_print.so).

import { dlopen, FFIType, suffix } from "bun:ffi";
import { join } from "path";

// suffix is "dylib" on macOS, "so" on Linux, "dll" on Windows.
const libraryPath = join(process.cwd(), "zig-out", "lib", `libz_print.${suffix}`);

console.log(`Loading library: ${libraryPath}\n`);

// Each entry declares a symbol's C signature -- FFIType.cstring for a
// null-terminated `[*:0]const u8`, matching what z_api.zig actually
// exports today (src/z_api.zig):
//
//   pub export fn z_print_color_msg(message: [*:0]const u8, color_code: c_int) callconv(.c) c_int
//   pub export fn z_print_bold_msg(message: [*:0]const u8) callconv(.c) c_int
//   pub export fn z_print_puts(message: [*:0]const u8) callconv(.c) c_int
//   pub export fn z_print_version() callconv(.c) [*:0]const u8
const lib = dlopen(libraryPath, {
  z_print_puts: {
    args: [FFIType.cstring],
    returns: FFIType.i32,
  },
  z_print_color_msg: {
    args: [FFIType.cstring, FFIType.i32],
    returns: FFIType.i32,
  },
  z_print_bold_msg: {
    args: [FFIType.cstring],
    returns: FFIType.i32,
  },
  z_print_version: {
    args: [],
    returns: FFIType.cstring,
  },
});

const { symbols } = lib;

// color_code meaning, from z_api.zig's colorToAnsi(): 0=red, 1=green,
// 2=blue, 3=yellow, 4=cyan, 5=magenta, 6=white, 7=black.
const Color = { RED: 0, GREEN: 1, BLUE: 2, YELLOW: 3, CYAN: 4, MAGENTA: 5, WHITE: 6, BLACK: 7 };

console.log("========== z_print via Bun FFI ==========\n");

symbols.z_print_puts(Buffer.from("Hello from Bun, no C glue code!\0"));
symbols.z_print_color_msg(Buffer.from("This is green text\0"), Color.GREEN);
symbols.z_print_color_msg(Buffer.from("This is yellow text\0"), Color.YELLOW);
symbols.z_print_bold_msg(Buffer.from("This is bold text\0"));

// A `cstring`-typed return value already comes back auto-marshaled by
// Bun's FFI (no manual `new CString(ptr)` needed here -- that's only for
// raw `FFIType.ptr` returns).
console.log(`\nz_print_version() -> ${symbols.z_print_version()}`);

// Exported for anyone importing this file as a module instead of running
// it directly.
export { symbols, Color };
