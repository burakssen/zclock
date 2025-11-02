const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

const time = @cImport(@cInclude("time.h"));

const Digit = @import("digit.zig");
const Layout = @import("layout.zig");

digits: [6]Digit,
accumulated_time: f32,
layout: Layout,

const Clock = @This();

pub fn init(layout: Layout) Clock {
    var digits: [6]Digit = [_]Digit{Digit.init(0, 0, layout.radius)} ** 6;
    for (&digits) |*d| {
        d.setDigit(0);
    }

    return .{
        .layout = layout,
        .digits = digits,
        .accumulated_time = 1.0,
    };
}

fn setDigitPair(digits: []Digit, value: i64) void {
    digits[0].setDigit(@intCast(@divFloor(value, 10)));
    digits[1].setDigit(@intCast(@mod(value, 10)));
}

fn setTime(self: *Clock, local_time: @TypeOf(getLocalTime())) void {
    setDigitPair(self.digits[0..2], local_time.hours);
    setDigitPair(self.digits[2..4], local_time.minutes);
    setDigitPair(self.digits[4..6], local_time.seconds);
}

pub fn update(self: *Clock, delta: f32) void {
    self.accumulated_time += delta;
    if (self.accumulated_time >= 1.0) {
        self.accumulated_time -= 1.0;
        self.setTime(getLocalTime());
    }

    for (&self.digits) |*d| {
        d.update(delta);
    }
}

pub fn draw(self: *const Clock) void {
    for (&self.digits, &self.layout.digit_positions) |*d, x_pos| {
        drawDigitAt(d, x_pos, self.layout.start_y);
    }

    drawColon(self.layout.colon_draw_x1, self.layout.colon_y, self.layout.radius);
    drawColon(self.layout.colon_draw_x2, self.layout.colon_y, self.layout.radius);

    var buffer: [1024]u8 = undefined;
    const day_month_year = getDayMonthYear(&buffer) catch {
        return;
    };

    const c_str = day_month_year;
    buffer[c_str.len] = 0;

    const font_size = 40;
    const size = rl.MeasureText(c_str.ptr, font_size);

    const x: f32 = (self.layout.colon_draw_x1 + self.layout.colon_draw_x2) / 2.0 - @as(f32, @floatFromInt(size)) / 2.0;
    const y: f32 = (self.layout.colon_y - self.layout.digit_height / 2.0) - 2 * @as(f32, @floatFromInt(font_size));

    // Draw below the clock
    rl.DrawText(
        c_str.ptr,
        @as(c_int, @intFromFloat(x)),
        @as(c_int, @intFromFloat(y)),
        font_size,
        rl.Color{ .r = 247, .g = 164, .b = 30, .a = 255 },
    );
}

pub fn handleResize(self: *Clock, new_layout: Layout) void {
    self.layout = new_layout;

    // Update digit sizes and positions
    for (&self.digits) |*d| {
        d.setSize(new_layout.radius);
    }
}

fn drawDigitAt(digit: *const Digit, x: f32, y: f32) void {
    rl.rlPushMatrix();
    rl.rlTranslatef(x, y, 0);
    digit.draw();
    rl.rlPopMatrix();
}

fn drawColon(x: f32, y: f32, radius: f32) void {
    const circle_radius = radius * 0.5;
    const gap = radius;

    const color = rl.Fade(.{ .r = 220, .g = 225, .b = 235, .a = 255 }, 0.15);

    rl.DrawRing(.{ .x = x, .y = y + gap }, circle_radius * 0.8, circle_radius, 0, 360, 30, color);
    rl.DrawRing(.{ .x = x, .y = y + 3.0 * gap }, circle_radius * 0.8, circle_radius, 0, 360, 30, color);
}

fn getLocalTime() struct { hours: i64, minutes: i64, seconds: i64 } {
    var now: time.time_t = time.time(null);
    var local_tm: time.struct_tm = undefined;
    _ = time.localtime_r(&now, &local_tm);

    return .{
        .hours = @intCast(local_tm.tm_hour),
        .minutes = @intCast(local_tm.tm_min),
        .seconds = @intCast(local_tm.tm_sec),
    };
}

pub fn getDayMonthYear(buffer: []u8) ![]const u8 {
    var now: time.time_t = time.time(null);
    var local_tm: time.struct_tm = undefined;
    _ = time.localtime_r(&now, &local_tm);

    const months = [_][]const u8{
        "January", "February", "March",     "April",   "May",      "June",
        "July",    "August",   "September", "October", "November", "December",
    };

    const day = local_tm.tm_mday;
    const month_name = months[@as(usize, @intCast(local_tm.tm_mon))];
    const year = local_tm.tm_year + 1900;

    return std.fmt.bufPrint(buffer, "{d} {s} {d}", .{ day, month_name, year });
}
