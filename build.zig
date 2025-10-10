const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Declare and add the module
    const zigsdl = b.addModule("zigsdl", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    zigsdl.linkSystemLibrary("SDL3", .{ .needed = true });
    zigsdl.link_libc = true;

    // Add the examples files as executables
    const exm1 = b.addExecutable(.{
        .name = "moving_box_example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/moving_box_example.zig"),
            .target = target,
            .optimize = .Debug,
        }),
    });
    exm1.root_module.addImport("zigsdl", zigsdl);

    b.installArtifact(exm1);

    // Create build steps to run the examples
    const run_cmd = b.addRunArtifact(exm1);
    const run_step = b.step("moving_box_example", "Run moving_box_example");
    run_step.dependOn(&run_cmd.step);

    // Add test step
    const exe_unit_tests = b.addTest(.{
        .root_module = zigsdl,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
