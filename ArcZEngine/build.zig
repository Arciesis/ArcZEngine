const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("ArcZEngine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // === libs === //
    const zmath = b.dependency("zmath", .{});
    mod.addImport("zmath", zmath.module("root"));

    const zflecs = b.dependency("zflecs", .{});
    mod.addImport("zflecs", zflecs.module("root"));

    // TODO: Add zgui (ImGUI zig bindings)...

    const zimg = b.dependency("zigimg", .{});
    mod.addImport("zigimg", zimg.module("zigimg"));

    // TODO: to compile shader directly from build...
    //
    // ...
    // const vert_cmd = b.addSystemCommand(&.{
    //     "glslc",
    //     "--target-env=vulkan1.2",
    //     "-o"
    // });
    // const vert_spv = vert_cmd.addOutputFileArg("vert.spv");
    // vert_cmd.addFileArg(b.path("shaders/triangle.vert"));
    // exe.root_module.addAnonymousImport("vertex_shader", .{
    //     .root_source_file = vert_spv
    // });
    // ...

    // === end libs === //

    const lib = b.addLibrary(.{
        .root_module = mod,
        .linkage = .static,
        .name = "ArcZEngine",
    });

    // === system libs linkage === //

    switch (target.result.os.tag) {
        .windows => {
            if (target.result.cpu.arch.isX86()) {
                if (target.result.abi.isGnu() or target.result.abi.isMusl()) {
                    if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
                        lib.addLibraryPath(system_sdk.path("windows/lib/x86_64-windows-gnu"));
                    }
                }
            }
        },
        .macos => {
            if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
                lib.addLibraryPath(system_sdk.path("macos12/usr/lib"));
                lib.addFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));
            }
        },
        .linux => {
            if (target.result.cpu.arch.isX86()) {
                if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
                    lib.addLibraryPath(system_sdk.path("linux/lib/x86_64-linux-gnu"));
                }
            } else if (target.result.cpu.arch == .aarch64) {
                if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
                    lib.addLibraryPath(system_sdk.path("linux/lib/aarch64-linux-gnu"));
                }
            }
        },
        else => {},
    }

    lib.linkLibrary(zflecs.artifact("flecs"));

    lib.linkSystemLibrary("glfw");

    lib.linkLibC();
    lib.linkLibCpp();
    // === end system libs linkage === //

    // === vulkan bindings === //
    const bind_step = b.step("bind", "run vulkan bindings generator");

    const vk_art = b.dependency("vulkan_zig", .{
        .target = target,
        .optimize = optimize,
    }).artifact("vulkan-zig-generator");

    const bind_cmd = b.addRunArtifact(vk_art);
    bind_cmd.addArg("vulkan/vk.xml");
    bind_cmd.addArg("src/vk.zig");

    bind_step.dependOn(&bind_cmd.step);

    // === bindings end === //

    b.modules.put("root", mod) catch unreachable;
    b.installArtifact(lib);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = lib.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
