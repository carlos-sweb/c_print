//! Self-contained, synchronous stdout/stderr writers for z_print's Zig API
//! (`CPrintBuilder.print`/`println`) and C-ABI layer (`z_api.zig`).
//!
//! Both call sites previously used `std.debug.print`, which is Zig 0.16's
//! stderr-hardwired DIAGNOSTIC helper (see its doc comment in
//! lib/std/debug.zig) -- unbuffered, error-swallowing, and NOT a real
//! stdout writer, despite z_print_builder.zig's own comment describing it
//! as a "workaround for stdout" (it isn't one: it writes to stderr). A
//! library whose entire purpose is producing colored terminal OUTPUT was
//! silently sending every byte of it to stderr instead.
//!
//! Neither call site has a `std.process.Init` to source a real `Io`
//! instance from (this is library/C-ABI code, not an app's `main`), so
//! this lazily builds its own minimal `Io.Threaded`, with async/
//! concurrent limits set to `.nothing` since nothing here is ever
//! asynchronous -- it exists purely to reach `Io.File.stdout()`/
//! `.stderr()`'s real, correctly-targeted writers.
//!
//! IMPORTANT: the stdout/stderr `File.Writer` is constructed ONCE and
//! reused for every call (module-level static state), never rebuilt per
//! call. Confirmed by hand (not assumed) that rebuilding a fresh
//! `File.stdout().writer(io, buf)` on every write silently drops all but
//! the most recent write once a SECOND independent writer (e.g. a
//! `File.stderr()` one) is created against the same `Io.Threaded` --
//! each `.writer()` call apparently claims the fd in a way a prior,
//! separately-constructed writer's `flush()` doesn't fully release. A
//! single persistent writer per fd, reused across calls, does not have
//! this problem -- matching z-run's own main.zig, which builds its
//! stdout/stderr writers once and reuses them for the process's whole
//! lifetime rather than per print call.
const std = @import("std");

var threaded: ?std.Io.Threaded = null;

fn ioHandle() std.Io {
    if (threaded == null) {
        threaded = std.Io.Threaded.init(std.heap.page_allocator, .{
            .async_limit = .nothing,
            .concurrent_limit = .nothing,
        });
    }
    return threaded.?.io();
}

var stdout_buf: [4096]u8 = undefined;
var stdout_writer: ?std.Io.File.Writer = null;

fn stdoutInterface() *std.Io.Writer {
    if (stdout_writer == null) {
        stdout_writer = std.Io.File.stdout().writer(ioHandle(), &stdout_buf);
    }
    return &stdout_writer.?.interface;
}

var stderr_buf: [4096]u8 = undefined;
var stderr_writer: ?std.Io.File.Writer = null;

fn stderrInterface() *std.Io.Writer {
    if (stderr_writer == null) {
        stderr_writer = std.Io.File.stderr().writer(ioHandle(), &stderr_buf);
    }
    return &stderr_writer.?.interface;
}

pub fn writeStdout(bytes: []const u8) !void {
    const w = stdoutInterface();
    try w.writeAll(bytes);
    try w.flush();
}

pub fn writeStdoutLine(bytes: []const u8) !void {
    const w = stdoutInterface();
    try w.writeAll(bytes);
    try w.writeByte('\n');
    try w.flush();
}

/// Writes each part through the persistent stdout writer, flushing once
/// at the end -- for callers assembling a line from several pieces
/// (color code + message + reset code, say) without an extra flush per
/// piece.
pub fn writeStdoutParts(parts: []const []const u8) !void {
    const w = stdoutInterface();
    for (parts) |p| try w.writeAll(p);
    try w.flush();
}

pub fn writeStderr(bytes: []const u8) !void {
    const w = stderrInterface();
    try w.writeAll(bytes);
    try w.flush();
}

pub fn writeStderrLine(bytes: []const u8) !void {
    const w = stderrInterface();
    try w.writeAll(bytes);
    try w.writeByte('\n');
    try w.flush();
}
