/// example_system_dashboard.zig
///
/// Demonstrates building a system status dashboard using the pattern API.
/// Equivalent to the C "Example 1: System Dashboard".
const std = @import("std");
const z_print = @import("z_print");
const cp = z_print.z_print_mod;

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    // Title bar
    try cp.z_print(&writer, "\n{s:*^60:cyan:bold}\n", .{" SYSTEM STATUS "});

    // CPU status
    try cp.z_print(&writer, "{s:<20} [{s:bright_green:bold}]\n", .{ "CPU", "OK" });

    // Memory usage
    try cp.z_print(
        &writer,
        "{s:<20} {d:,} MB ({f:.1%:yellow})\n",
        .{ "Memory", @as(i32, 8192), @as(f64, 0.65) },
    );

    // Disk usage
    try cp.z_print(
        &writer,
        "{s:<20} {d:,} / {d:,} GB\n",
        .{ "Disk", @as(i32, 450), @as(i32, 1000) },
    );

    // Network latency
    try cp.z_print(
        &writer,
        "{s:<20} {f:.2:green} ms\n",
        .{ "Latency", @as(f64, 12.45) },
    );

    // Uptime
    try cp.z_print(
        &writer,
        "{s:<20} {d:,} hours\n",
        .{ "Uptime", @as(i32, 720) },
    );

    // Processes
    try cp.z_print(
        &writer,
        "{s:<20} {d:,} running\n",
        .{ "Processes", @as(i32, 247) },
    );

    // Footer
    try cp.z_print(&writer, "{s:*^60:cyan}\n", .{""});

    _ = try std.io.getStdOut().write(writer.buffered());
}
