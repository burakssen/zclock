pub const View = @This();
pub const Layout = @import("layout.zig");

ptr: *anyopaque,
drawOpaquePtr: *const fn (ptr: *anyopaque) void,
updateOpaquePtr: *const fn (ptr: *anyopaque, delta: f32) void,

pub fn init(view_ptr: anytype) View {
    const T = @TypeOf(view_ptr);

    const gen = struct {
        fn drawOpaque(ptr: *anyopaque) void {
            const self: T = @ptrCast(@alignCast(ptr));
            self.draw();
        }

        fn updateOpaque(ptr: *anyopaque, delta: f32) void {
            const self: T = @ptrCast(@alignCast(ptr));
            self.update(delta);
        }
    };

    return View{
        .ptr = view_ptr,
        .drawOpaquePtr = gen.drawOpaque,
        .updateOpaquePtr = gen.updateOpaque,
    };
}

pub fn draw(self: View) void {
    self.drawOpaquePtr(self.ptr);
}

pub fn update(self: View, delta: f32) void {
    self.updateOpaquePtr(self.ptr, delta);
}
