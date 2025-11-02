const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

const time = @cImport(@cInclude("time.h"));

const Digit = @import("digit.zig");
const Layout = @import("layout.zig");

const CountDownState = enum {
    idle,
    running,
    paused,
    ended,
};

digits: [6]Digit,
layout: Layout,
cursor: u8 = 5,
countdown_state: CountDownState = .idle,
accumulator: f32 = 0.0,
alert_sound: rl.Sound = undefined,
sound_played: bool = false,

const Countdown = @This();

pub fn init(layout: Layout) Countdown {
    var digits: [6]Digit = [_]Digit{Digit.init(0, 0, layout.radius)} ** 6;

    for (&digits) |*d| {
        d.setDigit(0);
    }

    const alert_sound = rl.LoadSound("assets/sounds/countdown.ogg");

    return .{
        .layout = layout,
        .digits = digits,
        .alert_sound = alert_sound,
    };
}

pub fn deinit(self: *Countdown) void {
    rl.UnloadSound(self.alert_sound);
}

pub fn update(self: *Countdown, delta: f32) void {
    if (rl.IsKeyPressed(rl.KEY_R)) {
        for (&self.digits) |*d| {
            d.setDigit(0);
        }
        self.countdown_state = .idle;
        self.cursor = 5;
        self.accumulator = 0.0;
        self.sound_played = false;
    }

    if (self.countdown_state != .running and self.countdown_state != .paused) {
        if (rl.IsKeyPressed(rl.KEY_LEFT) or rl.IsKeyPressed(rl.KEY_A)) {
            if (self.cursor > 0) self.cursor -= 1;
        }

        if (rl.IsKeyPressed(rl.KEY_RIGHT) or rl.IsKeyPressed(rl.KEY_D)) {
            if (self.cursor < 5) self.cursor += 1;
        }

        if (rl.IsKeyPressed(rl.KEY_UP) or rl.IsKeyPressed(rl.KEY_W)) {
            var val = self.digits[self.cursor].getDigitValue();
            val = (val + 1) % 10;

            // Apply constraints based on position
            if (self.cursor == 0 and val > 2) val = 0; // Hours tens: 0-2
            if (self.cursor == 1 and self.digits[0].getDigitValue() == 2 and val > 3) val = 0; // Hours ones: 0-3 when tens is 2
            if (self.cursor == 2 and val > 5) val = 0; // Minutes tens: 0-5
            if (self.cursor == 4 and val > 5) val = 0; // Seconds tens: 0-5

            self.digits[self.cursor].setDigit(@as(usize, val));
        }

        if (rl.IsKeyPressed(rl.KEY_DOWN) or rl.IsKeyPressed(rl.KEY_S)) {
            var val = self.digits[self.cursor].getDigitValue();
            val = if (val == 0) 9 else val - 1;

            // Apply constraints based on position
            if (self.cursor == 0 and val > 2) val = 2; // Hours tens: 0-2
            if (self.cursor == 1 and self.digits[0].getDigitValue() == 2 and val > 3) val = 3; // Hours ones: 0-3 when tens is 2
            if (self.cursor == 2 and val > 5) val = 5; // Minutes tens: 0-5
            if (self.cursor == 4 and val > 5) val = 5; // Seconds tens: 0-5

            self.digits[self.cursor].setDigit(@as(usize, val));
        }
    }

    if (self.countdown_state == .idle and rl.IsKeyPressed(rl.KEY_SPACE)) {
        self.countdown_state = .running;
        self.cursor = 5;
        self.sound_played = false;
    } else if (self.countdown_state == .running and rl.IsKeyPressed(rl.KEY_SPACE)) {
        self.countdown_state = .paused;
    } else if (self.countdown_state == .paused and rl.IsKeyPressed(rl.KEY_SPACE)) {
        self.countdown_state = .running;
        self.cursor = 5;
    } else if (self.countdown_state == .ended and rl.IsKeyPressed(rl.KEY_SPACE)) {
        self.countdown_state = .running;
        self.cursor = 5;
        self.sound_played = false;
    }

    var count: u8 = 0;

    for (self.digits) |d| {
        if (d.getDigitValue() > 0) {
            count += 1;
            break;
        }
    }

    if (count == 0 and self.countdown_state == .running) {
        self.countdown_state = .ended;
        if (!self.sound_played) {
            rl.PlaySound(self.alert_sound);
            self.sound_played = true;
        }
    }

    if (self.countdown_state == .running) {
        self.accumulator += delta;
        if (self.accumulator >= 1.0) {
            self.accumulator -= 1.0;

            count = 5;
            while (count >= 0) : (count -= 1) {
                const val = self.digits[count].getDigitValue();
                if (val == 0) {
                    const max_val: u8 = switch (count) {
                        0 => 2,
                        1 => if (self.digits[count].getDigitValue() == 2) 3 else 9, // Hours ones: max 3 if tens is 2
                        2 => 5,
                        3 => 9,
                        4 => 5,
                        5 => 9,
                        else => 9,
                    };
                    self.digits[count].setDigit(max_val);
                    if (count == 0) break;
                } else {
                    self.digits[count].setDigit(val - 1);
                    break;
                }
                if (count == 0) break;
            }
        }
    }

    for (&self.digits) |*d| {
        d.update(delta);
    }
}

pub fn draw(self: *const Countdown) void {
    const title = "Countdown Timer";
    const title_size = rl.MeasureText(title, 30);
    rl.DrawText(title, @as(i32, @divFloor((rl.GetScreenWidth() - title_size), 2)), 40, 30, rl.DARKGRAY);

    for (&self.digits, &self.layout.digit_positions) |*d, x_pos| {
        drawDigitAt(d, x_pos, self.layout.start_y);
    }

    drawColon(self.layout.colon_draw_x1, self.layout.colon_y, self.layout.radius);
    drawColon(self.layout.colon_draw_x2, self.layout.colon_y, self.layout.radius);

    if (self.countdown_state != .running and self.countdown_state != .paused) {
        const digit_width = self.layout.digit_width;
        const digit_height = self.layout.digit_height / 12;
        const x = self.layout.digit_positions[self.cursor] - self.layout.radius + digit_width / 2.0;
        const y = self.layout.start_y - self.layout.radius + digit_height * 13;

        drawCursor(x, y, digit_width, digit_height, self.layout.radius * 0.5);
    }

    const state_text = switch (self.countdown_state) {
        .idle => "Press SPACE to Start",
        .running => "Running... Press SPACE to Pause",
        .paused => "Paused. Press SPACE to Resume",
        .ended => "Time's Up! Press SPACE to Restart",
    };

    const text_size = rl.MeasureText(state_text, 20);

    rl.DrawText(state_text, @as(i32, @divFloor((rl.GetScreenWidth() - text_size), 2)), @as(i32, @intFromFloat(self.layout.start_y + self.layout.digit_height + 20)), 20, rl.GRAY);
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

fn drawCursor(x: f32, y: f32, width: f32, height: f32, corner_radius: f32) void {
    const color = rl.Fade(.{ .r = 247, .g = 164, .b = 30, .a = 255 }, 0.5);
    const roundness = corner_radius / @min(width, height);
    rl.DrawRectangleRounded(.{ .x = x - width / 2.0, .y = y - height / 2.0, .width = width, .height = height }, roundness, 8, color);
}
