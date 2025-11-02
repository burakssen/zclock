const Analog = @import("analog.zig");
const patterns = @import("patterns.zig");
const PatternChar = patterns.PatternChar;
const DIGIT_PATTERNS = patterns.DIGIT_PATTERNS;

const Digit = @This();

analogs: [24]Analog,
digit_val: u8 = 0,

const ROWS = 6;
const COLS = 4;

pub fn init(start_x: f32, start_y: f32, radius: f32) Digit {
    var analogs: [24]Analog = undefined;

    for (0..ROWS) |row| {
        for (0..COLS) |col| {
            const idx = row * COLS + col;
            analogs[idx] = Analog{
                .pos = .{
                    .x = start_x + @as(f32, @floatFromInt(col)) * (radius * 2.0),
                    .y = start_y + @as(f32, @floatFromInt(row)) * (radius * 2.0),
                },
                .radius = radius,
            };
        }
    }

    return .{ .analogs = analogs };
}

pub fn setDigit(self: *Digit, digit: usize) void {
    const pattern = DIGIT_PATTERNS[digit];
    self.digit_val = @as(u8, @intCast(digit));

    for (pattern, 0..) |char, i| {
        const char_type = PatternChar.fromUtf8(char);
        const angles = char_type.getAngles();
        self.analogs[i].setAngles(angles.hour, angles.minute);
    }
}

pub fn update(self: *Digit, dt: f32) void {
    for (&self.analogs) |*analog| {
        analog.update(dt);
    }
}

pub fn draw(self: Digit) void {
    for (self.analogs) |analog| {
        analog.draw();
    }
}

pub fn getDigitValue(self: Digit) u8 {
    return self.digit_val;
}

pub fn setSize(self: *Digit, radius: f32) void {
    for (0..ROWS) |row| {
        for (0..COLS) |col| {
            const idx = row * COLS + col;
            self.analogs[idx].radius = radius;
            self.analogs[idx].pos = .{
                .x = self.analogs[idx].pos.x, // Keep x position
                .y = self.analogs[idx].pos.y, // Keep y position
            };
        }
    }
}
