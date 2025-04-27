const std = @import("std");
const builtin = @import("builtin");

fn addAssets(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const assets = [_][]const u8{
        "res/paddle.png",
        "res/tennis.png",
        "res/brick.png",
    };

    for (assets) |asset| {
        exe.root_module.addAnonymousImport(asset, .{ .root_source_file = b.path(asset) });
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (!target.result.cpu.arch.isWasm()) {
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

        const raylib_lib = raylib_dep.artifact("raylib");
        exe.linkLibrary(raylib_lib);
        const install_step = b.addInstallDirectory(.{
            .source_dir = b.path("res"),
            .install_dir = std.Build.InstallDir{ .custom = "res" },
            .install_subdir = "res",
        });
        exe.step.dependOn(&install_step.step);
        addAssets(b, exe);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);

        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    } else {
        if (b.sysroot == null) {
            @panic("Pass '--sysroot \"[path to emsdk installation]/upstream/emscripten\"'");
        }
        const sysroot_include = b.pathJoin(&.{ b.sysroot.?, "cache", "sysroot", "include" });
        var dir = std.fs.openDirAbsolute(sysroot_include, std.fs.Dir.OpenDirOptions{ .access_sub_paths = true, .no_follow = true }) catch @panic("No emscripten cache. Generate it!");
        dir.close();

        const emcc_exe = switch (builtin.os.tag) { // TODO bundle emcc as a build dependency
            .windows => "emcc.bat",
            else => "emcc",
        };
        const emcc_exe_path = b.pathJoin(&.{ b.sysroot.?, emcc_exe });

        const wasm_target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .cpu_model = .{ .explicit = &std.Target.wasm.cpu.mvp },
            .cpu_features_add = std.Target.wasm.featureSet(&.{
                .atomics,
                .bulk_memory,
            }),
            .os_tag = .emscripten,
        });

        const raylib_dep = b.dependency("raylib", .{
            .target = target,
            .optimize = optimize,
            .rmodels = false,
        });
        const raylib_artifact = raylib_dep.artifact("raylib");

        const app_lib = b.addLibrary(.{
            .linkage = .static,
            .name = "breakout",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = wasm_target,
                .optimize = optimize,
            }),
        });
        app_lib.linkLibC();
        app_lib.shared_memory = true;
        app_lib.linkLibrary(raylib_artifact);
        
        app_lib.addIncludePath(.{ .cwd_relative = ".emscripten_cache-3.1.73/sysroot/include" });

        const assets = [_][]const u8{
            "res/paddle.png",
            "res/tennis.png",
            "res/brick.png",
        };

        for (assets) |asset| {
            app_lib.root_module.addAnonymousImport(asset, .{ .root_source_file = b.path(asset) });
        }

        const emcc = b.addSystemCommand(&[_][]const u8{emcc_exe_path});

        for (app_lib.getCompileDependencies(false)) |lib| {
            if (lib.isStaticLibrary()) {
                emcc.addArtifactArg(lib);
            }
        }

        emcc.addArgs(&.{
            "-sUSE_GLFW=3",
            "-sUSE_OFFSET_CONVERTER",
            //"-sAUDIO_WORKLET=1",
            //"-sWASM_WORKERS=1",
            "-sSHARED_MEMORY=1",
            "-sALLOW_MEMORY_GROWTH=1",

            "-sASYNCIFY",
            "--shell-file",
        });
        emcc.addFileArg(b.path("src/shell.html"));

        const link_items: []const *std.Build.Step.Compile = &.{
            raylib_artifact,
            app_lib,
        };

        for (link_items) |item| {
            emcc.addFileArg(item.getEmittedBin());
            emcc.step.dependOn(&item.step);
        }

        //emcc.addArg("--pre-js");
        emcc.addArg("-o");
        const app_html = emcc.addOutputFileArg("index.html");
        b.getInstallStep().dependOn(&b.addInstallDirectory(.{
            .source_dir = app_html.dirname(),
            .install_dir = .{ .custom = "www" },
            .install_subdir = "",
        }).step);
    }
}
