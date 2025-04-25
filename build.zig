const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "breakout",
        .root_module = exe_mod,
        .link_libc = true,
    });

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = .X11,
    });
    exe.linkLibrary(raylib_dep.artifact("raylib"));

    const assets = [_][]const u8{
        "res/paddle.png",
        "res/tennis.png",
        "res/brick.png",
    };

    for (assets) |asset| {
        exe.root_module.addAnonymousImport(asset, .{ .root_source_file = b.path(asset) });
    }

    const install_step = b.addInstallDirectory(.{
        .source_dir = b.path("res"),
        .install_dir = std.Build.InstallDir{ .custom = "res" },
        .install_subdir = "res",
    });
    exe.step.dependOn(&install_step.step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
