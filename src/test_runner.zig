const std = @import("std");
const main = @import("main.zig");

test {
    std.testing.refAllDecls(main);
}
