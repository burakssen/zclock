const std = @import("std");
const builtin = @import("builtin");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});
const Layout = @import("layout.zig");
const Clock = @import("clock.zig");
const Countdown = @import("countdown.zig");
const View = @import("view.zig");
const Transition = @import("transition.zig").Transition;
// In main.zig, add to AppState:
const AppState = struct {
    views: []*View,
    transition: Transition,
    screen_width: i32,
    screen_height: i32,
    view_textures: [2]rl.RenderTexture2D, // Change from slice to array

    fn init(views: []*View, screen_width: i32, screen_height: i32) AppState {
        // Allocate textures for each view
        var textures: [2]rl.RenderTexture2D = undefined;
        for (&textures) |*tex| {
            tex.* = rl.LoadRenderTexture(screen_width, screen_height);
        }

        var state = AppState{
            .views = views,
            .transition = Transition.init(0.4),
            .screen_width = screen_width,
            .screen_height = screen_height,
            .view_textures = textures, // Copy the array, not a pointer
        };

        // IMPORTANT: Render all views to textures initially
        for (0..views.len) |i| {
            state.renderViewToTexture(i);
        }

        return state;
    }

    fn update(self: *AppState, delta: f32) void {
        // Handle input for view switching
        if (rl.IsKeyPressed(rl.KEY_TAB) and !self.transition.isTransitioning()) {
            const current = self.transition.getCurrentViewIndex();
            const next = (current + 1) % self.views.len;
            self.transition.startTransition(current, next);

            // Pre-render the next view to texture before transition starts
            self.renderViewToTexture(next);
        }

        self.transition.update(delta);

        // Update all views, but only re-render current view when not transitioning
        for (self.views) |view| {
            view.update(delta);
        }

        if (!self.transition.isTransitioning()) {
            const idx = self.transition.getCurrentViewIndex();
            self.renderViewToTexture(idx);
        }
    }

    fn renderViewToTexture(self: *AppState, idx: usize) void {
        rl.BeginTextureMode(self.view_textures[idx]);
        rl.ClearBackground(rl.BLACK);
        self.views[idx].draw();
        rl.EndTextureMode();
    }

    fn renderTransition(self: *AppState, screen_width: f32) void {
        const current_idx = self.transition.getCurrentViewIndex();
        const next_idx = self.transition.getNextViewIndex();

        const current_offset = self.transition.getCurrentViewOffset(screen_width);
        const next_offset = self.transition.getNextViewOffset(screen_width);

        const src = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.screen_width),
            .height = -@as(f32, @floatFromInt(self.screen_height)), // Flip Y
        };

        const current_dest = rl.Rectangle{ .x = current_offset, .y = 0, .width = @floatFromInt(self.screen_width), .height = @floatFromInt(self.screen_height) };

        const next_dest = rl.Rectangle{ .x = next_offset, .y = 0, .width = @floatFromInt(self.screen_width), .height = @floatFromInt(self.screen_height) };

        rl.DrawTexturePro(self.view_textures[current_idx].texture, src, current_dest, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.WHITE);

        rl.DrawTexturePro(self.view_textures[next_idx].texture, src, next_dest, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.WHITE);
    }

    fn render(self: *AppState) void {
        rl.DrawText("TAB: Next View", 10, 10, 20, rl.GRAY);

        if (self.transition.isTransitioning()) {
            self.renderTransition(@as(f32, @floatFromInt(self.screen_width)));
        } else {
            const idx = self.transition.getCurrentViewIndex();
            // Draw the texture flipped (because RenderTextures are upside down)
            const src = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(self.screen_width),
                .height = -@as(f32, @floatFromInt(self.screen_height)),
            };
            const dest = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(self.screen_width),
                .height = @floatFromInt(self.screen_height),
            };
            rl.DrawTexturePro(self.view_textures[idx].texture, src, dest, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.WHITE);
        }
    }
};

fn gameLoop(state: *AppState) void {
    const delta = rl.GetFrameTime();

    state.update(delta);

    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(rl.BLACK);
    state.render();
}

fn runEmscripten(state: *AppState) void {
    const emsdk = @cImport(@cInclude("emscripten/emscripten.h"));
    const loop = struct {
        fn tick(arg: ?*anyopaque) callconv(.c) void {
            const app_state: *AppState = @ptrCast(@alignCast(arg));
            gameLoop(app_state);
            rl.DrawFPS(100, 100);
        }
    }.tick;
    emsdk.emscripten_set_main_loop_arg(loop, state, 0, true);
}

fn runDesktop(state: *AppState) void {
    while (!rl.WindowShouldClose()) {
        gameLoop(state);
    }
}

pub fn main() !void {
    const screen_width: i32 = 1280;
    const screen_height: i32 = 720;

    rl.SetConfigFlags(rl.FLAG_WINDOW_HIGHDPI | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(screen_width, screen_height, "zclock - a digital clock application");
    rl.InitAudioDevice(); // Must be called before creating Countdown!

    defer rl.CloseWindow();
    defer rl.CloseAudioDevice();

    const layout = Layout.init(screen_width, screen_height);
    var clock = Clock.init(layout);
    var countdown = Countdown.init(layout);
    var clock_view = View.init(&clock);
    var countdown_view = View.init(&countdown);
    var views = [_]*View{ &clock_view, &countdown_view };

    var app_state = AppState.init(&views, screen_width, screen_height);

    rl.SetTargetFPS(60);

    if (builtin.os.tag == .emscripten) {
        runEmscripten(&app_state);
    } else {
        runDesktop(&app_state);
    }
}
