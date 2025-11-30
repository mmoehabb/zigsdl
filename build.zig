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
    zigsdl.linkSystemLibrary("SDL3_ttf", .{ .needed = true });
    zigsdl.linkSystemLibrary("SDL3_image", .{ .needed = true });
    zigsdl.link_libc = true;

    // Add the examples files as executables
    const exm1 = b.addExecutable(.{
        .name = "example:moving-box",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/moving-box.zig"),
            .target = target,
            .optimize = .Debug,
        }),
    });
    exm1.root_module.addImport("zigsdl", zigsdl);
    b.installArtifact(exm1);

    const exm1_run_cmd = b.addRunArtifact(exm1);
    const exm1_run_step = b.step("example:moving-box", "Run examples/moving-box.zig");
    exm1_run_step.dependOn(&exm1_run_cmd.step);

    const exm2 = b.addExecutable(.{
        .name = "example:explosion",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/explosion.zig"),
            .target = target,
            .optimize = .Debug,
        }),
    });
    exm2.root_module.addImport("zigsdl", zigsdl);
    b.installArtifact(exm2);

    const exm2_run_cmd = b.addRunArtifact(exm2);
    const exm2_run_step = b.step("example:explosion", "Run examples/explosion.zig");
    exm2_run_step.dependOn(&exm2_run_cmd.step);

    const exm3 = b.addExecutable(.{
        .name = "example:hello-world",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/hello-world.zig"),
            .target = target,
            .optimize = .Debug,
        }),
    });
    exm3.root_module.addImport("zigsdl", zigsdl);
    b.installArtifact(exm3);

    const exm3_run_cmd = b.addRunArtifact(exm3);
    const exm3_run_step = b.step("example:hello-world", "Run examples/hello-world.zig");
    exm3_run_step.dependOn(&exm3_run_cmd.step);

    const exm4 = b.addExecutable(.{
        .name = "example:moving-scene",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/moving-scene.zig"),
            .target = target,
            .optimize = .Debug,
        }),
    });
    exm4.root_module.addImport("zigsdl", zigsdl);
    b.installArtifact(exm4);

    const exm4_run_cmd = b.addRunArtifact(exm4);
    const exm4_run_step = b.step("example:moving-scene", "Run examples/moving-scene.zig");
    exm4_run_step.dependOn(&exm4_run_cmd.step);

    // Add test step
    const exe_unit_tests = b.addTest(.{
        .root_module = zigsdl,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
