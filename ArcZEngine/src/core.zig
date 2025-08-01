const std = @import("std");
const Allocator = std.mem.Allocator;

const zm = @import("zmath");
// const Renderer = @import("../gfx/renderer.zig").Renderer;
// const Mesh = @import("../gfx/mesh.zig").Mesh;
// const input = @import("input.zig");
// const zgui = @import("zgui");
const vk = @import("vk.zig");

const glfw = @import("glfw");

// DEPRECATED: use of a bindings with vulkan support instead.
// const glfw = @cImport({
//     @cDefine("GLFW_INCLUDE_NONE", {});
//     @cInclude("GLFW/glfw3.h");
//     // @cInclude("GLFW/glfw3native.h");
// });

/// Engine Default Configuration
pub const CoreConfig = struct {
    window_width: c_int = 1080,
    window_height: c_int = 720,
    window_title: [:0]const u8 = "ArcZEngine",
    vsync: bool = true,

    pub fn modifyDefaultWindow(core_config: *CoreConfig, window_width: c_int, window_height: c_int) *CoreConfig {
        core_config.*.window_width = window_width;
        core_config.*.window_height = window_height;

        return core_config;
    }

    pub fn modifyTitle(core_config: *CoreConfig, title: [:0]const u8) *CoreConfig {
        core_config.*.window_title = title;

        return core_config;
    }

    pub fn shouldBeVsync(core_config: *CoreConfig, is_vsync: bool) *CoreConfig {
        core_config.*.vsync = is_vsync;

        return core_config;
    }
};

fn glfwErrorCB(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {any}: {s}\n", .{ error_code, description });
}

fn loaderFn(instance: ?vk.Instance, procname: [*:0]const u8) ?glfw.VKProc {
    if (instance) |actual_instance| {
        const inst: ?*anyopaque = @constCast(@ptrCast(&actual_instance));
        return glfw.getInstanceProcAddress(inst, procname);
    } else {
        return glfw.getInstanceProcAddress(null, procname);
    }
}

pub const Core = struct {
    // window: *glfw.Window,
    wname: [:0]const u8,
    last_time: f32,
    // input_manager: input.InputManager,
    config: CoreConfig,

    /// Initialize engine with default configuration.
    pub fn init() !Core {
        return initWithConfig(CoreConfig{});
    }

    pub fn initWithConfig(config: CoreConfig) !Core {
        glfw.setErrorCallback(glfwErrorCB);
        if (!glfw.init(.{})) {
            std.log.err("failed to init GLFW: {?s}\n", .{glfw.getErrorString()});
            return error.GlfwInitFailed;
        }

        _ = glfw.Window.Hints{ .client_api = .no_api, .doublebuffer = config.vsync };

        // DEPRECATED: need to advance with vulkan.
        // const window = glfw.createWindowSurface(
        //     config.window_width,
        //     config.window_height,
        //     config.window_title,
        //     null,
        //     null,
        // );
        // if (window == null) return glfwError.FailedToInitWindow;
        // glfw.glfwMakeContextCurrent(window.?);

        // const fn_name: [*:0]const u8 = "enumerateInstanceExtensionProperties";
        const maybe_vkb: ?vk.BaseWrapper = vk.BaseWrapper.load(loaderFn);
        var vkb: vk.BaseWrapper = undefined;
        if (maybe_vkb) |val| {
            vkb = val;
        } else {
            return error.CantLoadVulkanProcAddress;
        }

        var ext_count: u32 = 0;
        const res = try vkb.enumerateInstanceExtensionProperties(null, &ext_count, null);
        if (vk.Result.success != res) {
            @panic("UhoH\n");
        } else {
            std.debug.print("extension count: {d}\n", .{ext_count});
        }

        return Core{
            // .window = window.?,
            .wname = config.window_title,
            .last_time = 0.0,
            // .input_manager = input.InputManager.init(),
            .config = config,
        };
    }

    pub fn deinit(self: Core) void {
        // glfw.Window.destroy(self.window);
        _ = self;
        glfw.terminate();
    }

    // fn setupCamera(self: *Core, comptime T: type, game: *T) void {
    //     const cam_ptr: *anyopaque = @ptrCast(@alignCast(&game.cam));
    //     self.window.setUserPointer(cam_ptr);
    //     self.input_manager.setupCallbacks(self.window);
    // }

    pub fn run(self: *Core, comptime T: type, game: *T) !void {
        // comptime {
        //     if (!@hasDecl(T, "update") or !@hasDecl(T, "draw")) {
        //         @compileError("Game type MUST implement update() and draw()");
        //     }
        // }

        // self.setupCamera(T, game);

        _ = game;

        self.last_time = @floatCast(glfw.getTime());

        // while (self.window.shouldClose()) {
        // const now: f32 = @floatCast(glfw.glfwGetTime());
        // const dt = now - self.last_time;
        // self.last_time = now;

        // update things
        // try self.input_manager.update(&game.cam, self.window);
        // try game.update(dt);

        // render things
        // try game.draw();

        //     glfw.pollEvents();
        // }
        // self.deinit();
    }
};
