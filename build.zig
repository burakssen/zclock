const std = @import("std");
const raylib = @import("raylib");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raylib", .module = raylib_artifact.root_module },
        },
    });

    exe_mod.addIncludePath(raylib_dep.path("src"));

    if (target.result.os.tag == .emscripten) {
        const wasm = b.addLibrary(.{ .name = "zclock", .root_module = exe_mod });
        wasm.linkLibrary(raylib_artifact);
        wasm.addIncludePath(raylib_dep.path("src"));

        const emcc_flags = raylib.emsdk.emccDefaultFlags(b.allocator, .{
            .optimize = optimize,
            .asyncify = true,
        });

        var emcc_settings = raylib.emsdk.emccDefaultSettings(b.allocator, .{
            .optimize = optimize,
        });

        try emcc_settings.put("EXPORTED_FUNCTIONS", "[_main, _GetScreenWidth, _GetScreenHeight, _SetWindowSize]");

        const emcc_step = raylib.emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .shell_file_path = b.path("index.html"),
            .install_dir = .{ .custom = "web" },
            .preload_paths = &.{
                .{ .src_path = "assets/", .virtual_path = "/assets" },
            },
        });

        b.getInstallStep().dependOn(emcc_step);

        return;
    }

    const exe = b.addExecutable(.{
        .name = "zclock",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
