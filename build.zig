const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Root module for the library
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Static library target
    const lib = b.addLibrary(.{
        .name = "z_print",
        .root_module = lib_mod,
        .linkage = .static,
    });
    b.installArtifact(lib);

    // Shared library target
    const lib_shared = b.addLibrary(.{
        .name = "z_print",
        .root_module = lib_mod,
        .linkage = .dynamic,
    });
    b.installArtifact(lib_shared);

    // Tests - use dedicated test runner to include all module tests
    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/test_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    const tests = b.addTest(.{
        .root_module = test_mod,
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // Examples
    const example_names = [_][]const u8{ "pattern_based", "builder", "generic" };
    inline for (example_names) |name| {
        const exe_mod = b.createModule(.{
            .root_source_file = b.path("examples/example_" ++ name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        exe_mod.addImport("z_print", lib_mod);

        const exe = b.addExecutable(.{
            .name = "example_" ++ name,
            .root_module = exe_mod,
        });
        const run_exe = b.addRunArtifact(exe);
        run_exe.step.dependOn(b.getInstallStep());

        const example_step = b.step("run-" ++ name, "Run example_" ++ name);
        example_step.dependOn(&run_exe.step);
    }

    // The C compile steps below write straight to a hardcoded
    // "zig-out/bin/..." path via a raw system command (not through Zig's
    // own output-file/install-dir machinery), so nothing else guarantees
    // that directory exists yet -- `zig build install` only populates
    // zig-out/lib (from the two library artifacts above). Ensure it once
    // and have every C-ABI example step depend on this, not just the
    // library.
    const mkdir_bin = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/bin" });

    // C-ABI example: compile C code using system command and link against the static library
    const c_compile = b.addSystemCommand(&.{
        "cc",
        "test/example_c_simple.c",
        "-L", "zig-out/lib",
        "-lz_print",
        "-o", "zig-out/bin/example_c_simple",
    });
    c_compile.step.dependOn(&lib.step);
    c_compile.step.dependOn(b.getInstallStep());
    c_compile.step.dependOn(&mkdir_bin.step);

    const c_example_step = b.step("example_c_simple", "Build C-ABI example");
    c_example_step.dependOn(&c_compile.step);

    // C-ABI static example: link against libz_print.a (static library)
    const c_static_compile = b.addSystemCommand(&.{
        "cc",
        "test/example_c_simple.c",
        "zig-out/lib/libz_print.a",
        "-o", "zig-out/bin/static_example_c_simple",
    });
    c_static_compile.step.dependOn(&lib.step);
    c_static_compile.step.dependOn(b.getInstallStep());
    c_static_compile.step.dependOn(&mkdir_bin.step);

    const c_static_example_step = b.step("static_example_c_simple", "Build C-ABI static example");
    c_static_example_step.dependOn(&c_static_compile.step);

    // C-ABI shared example: link against libz_print.so (dynamic library)
    const c_shared_compile = b.addSystemCommand(&.{
        "cc",
        "test/example_c_simple.c",
        "-L", "zig-out/lib",
        "-Wl,-rpath,zig-out/lib",
        "-lz_print",
        "-o", "zig-out/bin/share_example_c_simple",
    });
    c_shared_compile.step.dependOn(&lib_shared.step);
    c_shared_compile.step.dependOn(b.getInstallStep());
    c_shared_compile.step.dependOn(&mkdir_bin.step);

    const c_shared_example_step = b.step("share_example_c_simple", "Build C-ABI shared example");
    c_shared_example_step.dependOn(&c_shared_compile.step);
}
