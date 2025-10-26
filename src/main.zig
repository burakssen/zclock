const std = @import("std");
const builtin = @import("builtin");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

const Layout = @import("layout.zig");
const Clock = @import("clock.zig");

/// Main application entry point
pub fn main() !void {
    const screen_width: i32 = 1280;
    const screen_height: i32 = 720;

    rl.SetConfigFlags(rl.FLAG_WINDOW_HIGHDPI | rl.FLAG_VSYNC_HINT);

    rl.InitWindow(screen_width, screen_height, "zclock - a digital clock application");
    defer rl.CloseWindow();

    // 1. Initialize Layout and Clock
    const layout = Layout.init(screen_width, screen_height);
    var clock = Clock.init(layout);

    rl.SetTargetFPS(60);

    if (builtin.os.tag == .emscripten) {
        const emsdk = @cImport(@cInclude("emscripten/emscripten.h"));

        const loop = struct {
            fn runLoop(arg: ?*anyopaque) callconv(.c) void {
                const _clock: *Clock = @ptrCast(@alignCast(arg));
                const delta = rl.GetFrameTime();
                _clock.update(delta);
                rl.BeginDrawing();
                rl.ClearBackground(rl.BLACK);
                _clock.draw();
                rl.EndDrawing();
            }
        }.runLoop;

        emsdk.emscripten_set_main_loop_arg(loop, &clock, 0, true);
    } else {
        while (!rl.WindowShouldClose()) {
            const delta = rl.GetFrameTime();

            // 3. Update clock
            clock.update(delta);

            // 4. Draw
            rl.BeginDrawing();
            rl.ClearBackground(rl.BLACK);
            clock.draw();
            rl.EndDrawing();
        }
    }

    // 2. Main Loop

}
